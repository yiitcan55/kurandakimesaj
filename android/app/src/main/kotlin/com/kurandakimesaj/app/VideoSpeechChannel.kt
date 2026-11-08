package com.kurandakimesaj.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.system.Os
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.OutputStream
import java.nio.ByteOrder

/**
 * Videodan Meal: videonun sesini CİHAZIN ses tanıyıcısıyla metne çevirir
 * (Android 13+, `EXTRA_AUDIO_SOURCE` + `EXTRA_SEGMENTED_SESSION`). Video
 * uygulamadan çıkmaz; ayeti Dart tarafındaki eşleştirici bulur.
 *
 * Deneme bulguları (şartname `docs/superpowers/specs/2026-11-07-...`):
 * - Düz dosya FD'si çalışmaz (tanıyıcı hepsini anında okur → ERROR_NETWORK);
 *   ses bir pipe'a ÖLÇÜLÜ hızla (en çok 4x gerçek zaman) yazılır.
 * - Yalnız 16 kHz mono PCM16: 44,1 kHz tanıyıcı SÜRECİNİ çökertir.
 * - `RECORD_AUDIO` izni şart (mikrofon açılmasa bile; yoksa ERROR 9).
 * - Kelime zamanlaması yok: bölüm zamanı = olay anında yazılmış örnek / 16000.
 */
class VideoSpeechChannel(private val ctx: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "transcribe" -> transcribe(call, result)
            "cancel" -> {
                active?.fail("speech_unavailable", "iptal edildi")
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isSupported() =
        Build.VERSION.SDK_INT >= 33 && SpeechRecognizer.isRecognitionAvailable(ctx)

    private fun transcribe(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val locale = call.argument<String>("locale") ?: "ar-SA"
        when {
            active != null -> result.error("speech_busy", "Başka bir tanıma sürüyor", null)
            !isSupported() -> result.error("speech_unavailable", "Cihazda ses tanıma yok", null)
            ctx.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED ->
                result.error("speech_permission", "RECORD_AUDIO izni yok", null)
            path == null || !File(path).canRead() ->
                result.error("speech_no_audio", "Video okunamadı", null)
            else -> Session(ctx, path, locale, result).also { active = it }.start()
        }
    }

    /**
     * Tek tanıma oturumu. Tanıyıcı ve bitiş ana iş parçacığında; çözme/yazma
     * arka planda. Sonuç [finish] ile yalnız BİR kez döner ve her yolda
     * tanıyıcı + pipe uçları bırakılır; codec/extractor'ı yazıcı kendisi bırakır.
     */
    private class Session(
        private val ctx: Context,
        private val path: String,
        private val locale: String,
        private val result: MethodChannel.Result,
    ) : RecognitionListener {
        private val main = Handler(Looper.getMainLooper())
        private var recognizer: SpeechRecognizer? = null
        private var readSide: ParcelFileDescriptor? = null
        private var writeSide: ParcelFileDescriptor? = null
        private var done = false
        @Volatile private var stopped = false
        @Volatile private var written = 0L // pipe'a yazılan 16 kHz mono örnek

        private val segments = ArrayList<Map<String, Any>>()
        // Konuşma aralıkları [başlangıç, bitiş(<0 = açık)]; sonuç gecikirse
        // sonraki bölümün başlangıcı öncekinin zamanını ezmesin diye kuyruk.
        private val spans = ArrayDeque<DoubleArray>()
        private val watchdog = Runnable { fail("speech_unavailable", "60 sn tanıyıcıdan yanıt yok") }

        fun start() {
            try {
                val (read, write) = ParcelFileDescriptor.createPipe()
                readSide = read
                writeSide = write
                // Pipe varsayılanı 64 KB ≈ 2 sn ses: tanıyıcı ~0,7 sn geç okumaya
                // başlar, yazıcı o kadar önde kalır ve `now()` (yazılan örnek)
                // bölümleri ~3 sn geç gösterir (emülatörde Fatiha 2-4 ile ölçüldü).
                // Kapasite bir sayfaya (4 KB ≈ 0,13 sn) iner; parça 3,2 KB sığar.
                runCatching { Os.fcntlInt(write.fileDescriptor, F_SETPIPE_SZ, 4096) }
                    .onFailure { Log.w(TAG, "Pipe kapasitesi küçültülemedi", it) }
                val sr = SpeechRecognizer.createSpeechRecognizer(ctx)
                recognizer = sr
                sr.setRecognitionListener(this)
                sr.startListening(intent(read))
                kick()
                Thread({ pump(write) }, "video-speech-pump").start()
            } catch (e: Exception) {
                Log.w(TAG, "Tanıma başlatılamadı", e)
                fail("speech_unavailable", e.message)
            }
        }

        private fun intent(source: ParcelFileDescriptor) =
            Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, source)
                putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
                putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
                putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, RATE)
                putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
            }

        // ── Bitiş (yalnız ana iş parçacığı) ─────────────────────────────────

        private fun succeed() = finish { it.success(segments) }

        fun fail(code: String, message: String?) = finish { it.error(code, message, null) }

        private fun finish(reply: (MethodChannel.Result) -> Unit) {
            if (done) return
            done = true
            stopped = true
            main.removeCallbacks(watchdog)
            recognizer?.let { r ->
                runCatching { r.cancel() }
                runCatching { r.destroy() }
            }
            recognizer = null
            // Yazma ucunu kapatmak, pipe'ta bloklanmış yazıcıyı da serbest bırakır.
            runCatching { writeSide?.close() }
            runCatching { readSide?.close() }
            if (active === this) active = null
            reply(result)
        }

        /** 60 sn hiçbir geri çağrı gelmezse oturum biter. */
        private fun kick() {
            if (done) return
            main.removeCallbacks(watchdog)
            main.postDelayed(watchdog, WATCHDOG_MS)
        }

        // ── Tanıyıcı geri çağrıları (ana iş parçacığı) ──────────────────────

        /** Tanıyıcının bulunduğu ses konumu (sn); algılama gecikmesi düşülür. */
        private fun now() = maxOf(0.0, written / RATE.toDouble() - DETECT_LAG_S)

        override fun onReadyForSpeech(params: Bundle?) = kick()
        override fun onRmsChanged(rmsdB: Float) = kick()
        override fun onBufferReceived(buffer: ByteArray?) = kick()
        override fun onPartialResults(partialResults: Bundle?) = kick()
        override fun onEvent(eventType: Int, params: Bundle?) = kick()

        override fun onBeginningOfSpeech() {
            if (done) return
            kick()
            spans.addLast(doubleArrayOf(now(), -1.0))
        }

        override fun onEndOfSpeech() {
            if (done) return
            kick()
            spans.lastOrNull()?.takeIf { it[1] < 0 }?.set(1, now())
        }

        override fun onSegmentResults(segmentResults: Bundle) {
            if (done) return
            kick()
            addSegment(segmentResults)
        }

        override fun onEndOfSegmentedSession() {
            if (!done) succeed()
        }

        /** Bölümlü oturumda gelmez; bölümsüz çalışan tanıyıcı için yedek. */
        override fun onResults(results: Bundle?) {
            if (done) return
            if (segments.isEmpty()) addSegment(results)
            succeed()
        }

        override fun onError(error: Int) {
            if (done) return
            when (error) {
                // Konuşma yok / anlaşılmadı: altyapı hatası değil; elde ne varsa
                // döner, boşsa Dart "tilavet bulunamadı" der.
                SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> succeed()
                else -> fail(codeOf(error), "SpeechRecognizer hata $error")
            }
        }

        private fun codeOf(error: Int) = when (error) {
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "speech_permission"
            SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "speech_network"
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "speech_language"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "speech_busy"
            else -> "speech_unavailable"
        }

        /**
         * Bir bölüm sonucu BİRDEN ÇOK konuşma aralığını kapsayabilir: Alafasy
         * Yâsîn 58-61'de 5 aralık, 2 sonuç geldi; aralık başına bir sonuç
         * varsaymak 58-60 metnini 0,2-7,6 sn'ye (gerçek 0-34 sn) sıkıştırıyordu.
         * Sonuç gelene kadar KAPANMIŞ tüm aralıklar bu bölümündür; açık aralık
         * sonraki bölüme kalır (başlangıcı şimdiye çekilir ki örtüşmesin).
         */
        private fun addSegment(bundle: Bundle?) {
            var start: Double? = null
            var end: Double? = null
            while (spans.firstOrNull()?.let { it[1] >= 0 } == true) {
                val s = spans.removeFirst()
                if (start == null) start = s[0]
                end = s[1]
            }
            if (start == null) {
                val open = spans.firstOrNull()
                start = open?.get(0) ?: (segments.lastOrNull()?.get("end") as? Double ?: 0.0)
                end = now()
                open?.set(0, end)
            }
            val text = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()?.trim().orEmpty()
            if (text.isEmpty()) return
            segments.add(mapOf("start" to start, "end" to maxOf(start, end ?: start), "text" to text))
        }

        // ── Çözme + yazma (arka plan) ───────────────────────────────────────

        private fun report(code: String, message: String?) = main.post { fail(code, message) }

        private fun pump(sink: ParcelFileDescriptor) {
            var extractor: MediaExtractor? = null
            var codec: MediaCodec? = null
            val out = ParcelFileDescriptor.AutoCloseOutputStream(sink)
            try {
                val ex = MediaExtractor().also { extractor = it }
                ex.setDataSource(path)
                val track = (0 until ex.trackCount).firstOrNull {
                    ex.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
                }
                if (track == null) {
                    report("speech_no_audio", "Videoda ses izi yok")
                    return
                }
                ex.selectTrack(track)
                val format = ex.getTrackFormat(track)
                val dec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
                codec = dec
                dec.configure(format, null, null, 0)
                dec.start()
                decode(ex, dec, format, out)
                if (written == 0L && !stopped) report("speech_no_audio", "Ses izi boş")
            } catch (e: Exception) {
                if (!stopped) {
                    Log.w(TAG, "Ses çözülemedi", e)
                    // Hiç ses yazılmadıysa tanınacak bir şey yok; yazıldıysa
                    // aşağıdaki EOF ile tanıyıcı elindekini bitirir.
                    if (written == 0L) report("speech_no_audio", e.message)
                }
            } finally {
                runCatching { out.close() } // EOF = oturum sonu
                runCatching { codec?.stop() }
                runCatching { codec?.release() }
                runCatching { extractor?.release() }
            }
        }

        /**
         * Çözücü → PCM16 → kanalların ortalamasıyla mono → 16 kHz'e doğrusal
         * örnekleme → 100 ms'lik parçalarla en çok 4x hızla pipe'a.
         * ponytail: doğrusal örneklemede kenar yumuşatma süzgeci yok; tanıyıcı
         * kaldırıyor (E2E: AAC 44,1 kHz stereo mp4 → Fatiha 2-4 ve Kürsî metni
         * kusursuz). Gürültülü kayıtta isabet düşerse FIR alçak geçiren ekle.
         */
        private fun decode(ex: MediaExtractor, dec: MediaCodec, input: MediaFormat, out: OutputStream) {
            var rate = input.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = input.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            val info = MediaCodec.BufferInfo()
            val chunk = ByteArray(CHUNK_SAMPLES * 2)
            var fill = 0
            var prev = 0f // bir önceki giriş örneği (mono)
            var pos = 1.0 // sonraki çıkış örneğinin [prev, x] arasındaki konumu
            var next = SystemClock.elapsedRealtime()
            var inputDone = false

            fun emit(sample: Int) {
                chunk[fill++] = sample.toByte()
                chunk[fill++] = (sample shr 8).toByte()
                if (fill < chunk.size) return
                out.write(chunk)
                fill = 0
                written += CHUNK_SAMPLES
                // Geride kalınca yetişmek için hızlanma yok: 4x tavandır.
                next += CHUNK_MS / SPEED
                val wait = next - SystemClock.elapsedRealtime()
                if (wait > 0) Thread.sleep(wait) else next = SystemClock.elapsedRealtime()
            }

            while (!stopped) {
                if (!inputDone) {
                    val i = dec.dequeueInputBuffer(TIMEOUT_US)
                    if (i >= 0) {
                        val n = ex.readSampleData(dec.getInputBuffer(i)!!, 0)
                        if (n < 0) {
                            dec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            dec.queueInputBuffer(i, 0, n, ex.sampleTime, 0)
                            ex.advance()
                        }
                    }
                }
                val o = dec.dequeueOutputBuffer(info, TIMEOUT_US)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    rate = dec.outputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = dec.outputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                } else if (o >= 0) {
                    val buf = dec.getOutputBuffer(o)!!
                    buf.position(info.offset)
                    buf.limit(info.offset + info.size)
                    val pcm = buf.order(ByteOrder.nativeOrder()).asShortBuffer()
                    val step = rate.toDouble() / RATE
                    val ch = channels.coerceAtLeast(1)
                    for (f in 0 until pcm.remaining() / ch) {
                        var sum = 0
                        for (c in 0 until ch) sum += pcm.get(f * ch + c)
                        val x = sum.toFloat() / ch
                        while (pos <= 1.0) {
                            emit((prev + (x - prev) * pos).toInt())
                            pos += step
                        }
                        pos -= 1.0
                        prev = x
                    }
                    dec.releaseOutputBuffer(o, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
            if (fill > 0 && !stopped) {
                out.write(chunk, 0, fill)
                written += fill / 2
            }
        }
    }

    private companion object {
        const val CHANNEL = "kurandakimesaj/video_speech"
        const val TAG = "VideoSpeech"
        const val RATE = 16000
        const val CHUNK_MS = 100L
        const val CHUNK_SAMPLES = 1600 // 100 ms @ 16 kHz
        const val SPEED = 4 // gerçek zamanın en çok 4 katı (denemede sorunsuz)
        const val TIMEOUT_US = 10_000L
        const val WATCHDOG_MS = 60_000L
        const val F_SETPIPE_SZ = 1031 // Linux fcntl; OsConstants'ta tanımlı değil

        /**
         * Kalibrasyon: tanıyıcının konuşma başı/sonu olayları sesin ~0,6 sn
         * gerisinden gelir. Emülatörde 4x hızla ölçüldü (Fatiha 2-4: 0,49-0,68;
         * Kürsî, 7 bölüm: 0,53-0,84 sn; gerçek sınırlar ffmpeg silencedetect).
         * Gerçek cihazda altyazılar sürekli erken/geç kalırsa burası ayarlanır.
         */
        const val DETECT_LAG_S = 0.6

        /** Tek eşzamanlı oturum (ana iş parçacığı); motor yeniden bağlansa da tek. */
        var active: Session? = null
    }
}
