# iPhone'da videodan ayet bulma + Groq'un kaldırılması — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iPhone'da Videodan Meal videonun sesini telefonun kendi tanıyıcısıyla çözsün; Groq istemciden ve sunucudan tamamen kalksın; 1.0.3 TestFlight/ASC'ye yüklensin.

**Architecture:** iOS'a `AppDelegate.swift` içinde `VideoSpeechChannel` (aynı `kurandakimesaj/video_speech` kanalı): `AVAssetReader` → 16 kHz mono → ~50 sn parçalar → `SFSpeechRecognizer` → kelime listesi. Dart kelimeleri bölümlere ayırır (`wordsToSegments`) ve mevcut `analyzeRecitation`'a verir. `findFromVideo` yalnız cihaz yolunu bilir; desteklenmeyen cihazda `device_unsupported`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3, Swift (iOS 14+, Speech + AVFoundation), Supabase CLI (`npx supabase`), Codemagic, App Store Connect.

**Spec:** `docs/superpowers/specs/2026-11-08-iphone-videodan-ayet-design.md`

## Global Constraints

- Dal `feat/okuyarak-bul`; commit mesajları Türkçe, sonu `Claude-Session: https://claude.ai/code/session_01E5veHrdS4RcarpL3uXk39x`.
- Flutter PATH'te değil: `export PATH="$PATH:/c/Users/yiit5/flutter/bin"`.
- Kullanıcıya görünen metin Türkçe + tam imla (ç ğ ı ö ş ü).
- iOS dağıtım hedefi 14.0 — iOS 16+ API'leri `#available` ile.
- Yeni Swift DOSYASI yok (pbxproj Windows'ta düzenlenmez); kod `ios/Runner/AppDelegate.swift` içine.
- Yeni paket yok. Moderasyon/feed/router dosyalarına dokunulmaz. `_shared/quran/` (görsel `ayah-finder`) KALIR.
- Kanal adı ve hata kodları Android'le aynı: `speech_permission`, `speech_network`, `speech_language`, `speech_busy`, `speech_no_audio`, `speech_unavailable`; yeni `device_unsupported`.
- Supabase REF `uytqxgcbohdlwwxemgyy`.

## Review Focus

- Sessiz/konuşmasız video (iOS "no speech" hatası) → hata değil, boş sonuç → "tilavet bulunamadı" (Task 1 testi: boş kelime listesi → notFound).
- 55 sn'den kısa video → tek parça; tam 0 kelime → boş liste (Task 1 testi).
- Kelimeler arasında uzun duraklama → yeni bölüm; duraklama yok → tek bölüm (Task 1 testi).
- Konuşma tanıma izni reddedilirse → `speech_permission`, elle seçim (Task 2 testi).
- Android 12 ve altı / masaüstü → `device_unsupported`, Groq çağrısı YOK, oturum şartı YOK (Task 2 testi).

---

### Task 1: `wordsToSegments` (Dart, saf)

**Files:**
- Modify: `lib/domain/recitation_timeline.dart`
- Test: `test/recitation_timeline_test.dart`

**Interfaces:**
- Consumes: `typedef SpeechSegment = ({double start, double end, String text})` (dosyada mevcut), `analyzeRecitation(List<SpeechSegment>, QuranMatcher, Map<int,String>)`.
- Produces: `List<SpeechSegment> wordsToSegments(List<SpeechSegment> words, {double gap = 0.6})`.

- [ ] **Step 1: Failing tests** — `test/recitation_timeline_test.dart` sonuna ekle (mevcut `matcher` kurulumunu kullan):

```dart
  group('wordsToSegments (iOS kelime → bölüm)', () {
    SpeechSegment w(double s, double e, String t) => (start: s, end: e, text: t);

    test('boş liste boş döner', () {
      expect(wordsToSegments(const []), isEmpty);
    });

    test('duraklamasız kelimeler tek bölüm', () {
      final r = wordsToSegments([w(0.7, 1.2, 'الحمد'), w(1.3, 1.8, 'لله'), w(1.9, 2.4, 'رب')]);
      expect(r, hasLength(1));
      expect(r.single.text, 'الحمد لله رب');
      expect(r.single.start, 0.7);
      expect(r.single.end, 2.4);
    });

    test('0,6 sn üstü boşluk yeni bölüm açar', () {
      final r = wordsToSegments([
        w(0.7, 5.5, 'العالمين'),
        w(6.4, 7.0, 'الرحمن'),
        w(7.1, 10.0, 'الرحيم'),
      ]);
      expect(r.map((s) => s.text), ['العالمين', 'الرحمن الرحيم']);
      expect(r[1].start, 6.4);
    });

    test('iOS kelimeleri uçtan uca: Fatiha 2-4 → aralık 1:2-4', () {
      final words = [
        for (final (i, t) in 'الحمد لله رب العالمين'.split(' ').indexed) w(0.7 + i, 1.5 + i, t),
        for (final (i, t) in 'الرحمن الرحيم'.split(' ').indexed) w(6.4 + i, 7.2 + i, t),
        for (final (i, t) in 'مالك يوم الدين'.split(' ').indexed) w(10.9 + i, 11.7 + i, t),
      ];
      final r = analyzeRecitation(wordsToSegments(words), matcher, const {1: 'Fâtiha'});
      expect(r.status, AyahFinderStatus.matched);
      expect(r.range!.surah, 1);
      expect(r.range!.fromAyah, 2);
      expect(r.range!.toAyah, 4);
      expect(r.timeline.first.startSec, closeTo(0.7, 0.01));
    });

    test('kelime yoksa notFound', () {
      expect(analyzeRecitation(wordsToSegments(const []), matcher, const {}).status,
          AyahFinderStatus.notFound);
    });
  });
```

- [ ] **Step 2: Run, verify FAIL** — `flutter test test/recitation_timeline_test.dart` → "wordsToSegments isn't defined".
- [ ] **Step 3: Implement** — `lib/domain/recitation_timeline.dart` içine (analyzeRecitation'ın üstüne):

```dart
/// iOS `SFSpeechRecognizer` kelime düzeyinde zaman verir; Android bölüm verir.
/// Kelimeleri, aralarındaki boşluk [gap] saniyeyi aşınca yeni bölüme ayırır
/// (tilavetteki vakıf duraklamaları ≈ Android tanıyıcısının bölümleri).
List<SpeechSegment> wordsToSegments(List<SpeechSegment> words, {double gap = 0.6}) {
  final out = <SpeechSegment>[];
  final buf = StringBuffer();
  var start = 0.0, end = 0.0;
  for (final w in words) {
    final t = w.text.trim();
    if (t.isEmpty) continue;
    if (buf.isNotEmpty && w.start - end > gap) {
      out.add((start: start, end: end, text: buf.toString()));
      buf.clear();
    }
    if (buf.isEmpty) {
      start = w.start;
    } else {
      buf.write(' ');
    }
    buf.write(t);
    end = w.end;
  }
  if (buf.isNotEmpty) out.add((start: start, end: end, text: buf.toString()));
  return out;
}
```

- [ ] **Step 4: Run, verify PASS** — `flutter test test/recitation_timeline_test.dart`.
- [ ] **Step 5: Commit** — `feat(meal): iOS kelimelerini bölümlere ayıran wordsToSegments`.

### Task 2: Groq'suz `findFromVideo` + iOS servis yolu + hata metinleri

**Files:**
- Modify: `lib/data/video_speech.dart`, `lib/data/backend_repositories.dart` (findFromVideo ~1182, `_bucket` 1118, `_extOf`), `lib/features/ayah_finder/ayah_error_messages.dart`, `lib/domain/models.dart` (yalnız yorumlar 157/183/220), `lib/features/ayah_finder/ayah_finder_screen.dart:370` (yorum), `ios/Runner/Info.plist`
- Test: `test/ayah_finder_device_route_test.dart`, gerekiyorsa `test/ayah_finder_error_view_test.dart` (silinen kodları kullanan beklentiler)

**Interfaces:**
- Consumes: `wordsToSegments` (Task 1), `analyzeRecitation`, `quranMatcherProvider`, `surahsProvider`.
- Produces: `VideoSpeechService.isSupported()` iOS'ta da kanal sorar; `requestPermission()` iOS'ta kanalın `requestPermission`'ı; `transcribe()` iOS'ta kelimeleri `wordsToSegments`'ten geçirir. `findFromVideo` hata kodu `device_unsupported`.

- [ ] **Step 1: Failing tests** — `test/ayah_finder_device_route_test.dart`'te sunucu yoluna giden beklentileri şu ikisiyle değiştir (mevcut sahte servis/`repoWith` yardımcılarını kullan; sahte servis `isSupported` false dönsün):

```dart
  test('cihaz desteklemiyorsa device_unsupported; sunucuya/yüklemeye gidilmez, oturum şartı yok', () async {
    final r = await repoWith(FakeSpeech(supported: false)).findFromVideo(video.path);
    expect(r.status, AyahFinderStatus.error);
    expect(r.errorCode, 'device_unsupported');
  });

  test('izin reddi speech_permission', () async {
    final r = await repoWith(FakeSpeech(supported: true, permission: false)).findFromVideo(video.path);
    expect(r.errorCode, 'speech_permission');
  });
```
(Sahte sınıfın gerçek adı/kurucusu dosyadakine uyarlanır; davranış aynı kalır.)
- [ ] **Step 2: Run, verify FAIL** — eski kod oturum yoksa `auth_required` döner.
- [ ] **Step 3: Implement**
  - `video_speech.dart`:

```dart
  Future<bool> isSupported() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Android: tanıyıcı `RECORD_AUDIO` ister (mikrofon açılmasa bile).
  /// iOS: dosyadan tanıma yalnız konuşma tanıma iznini ister (mikrofon değil).
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      try {
        return await _channel.invokeMethod<bool>('requestPermission') ?? false;
      } on PlatformException {
        return false;
      }
    }
    return (await Permission.microphone.request()).isGranted;
  }
```
    `transcribe` sonunda: `final items = [...]` (mevcut eşleme) → `return Platform.isIOS ? wordsToSegments(items) : items;` (`wordsToSegments`'i `recitation_timeline.dart`'tan içe aktar). Sınıf yorumunu iOS'u da kapsayacak şekilde güncelle.
  - `backend_repositories.dart` `findFromVideo`: gövde yalnız şu olur:

```dart
  @override
  Future<AyahFinderResult> findFromVideo(String filePath) async {
    final ref = _ref;
    if (ref == null || !await ref.read(videoSpeechServiceProvider).isSupported()) {
      return _error('device_unsupported');
    }
    return _findOnDevice(ref, filePath);
  }
```
    `_bucket`, `_extOf`, yükleme/`ayah-finder-audio` kodu silinir; kullanılmayan import'lar (`dart:math` Random vb.) temizlenir. Arayüz yorumu (`findFromVideo` ~1097) "cihazda tanır" diye güncellenir.
  - `ayah_error_messages.dart`: `upload_failed`, `asr_failed`, `forbidden_path`, `no_video`, `rate_limited` dalları silinir; eklenir:

```dart
    'device_unsupported' => (
        Icons.phonelink_erase_rounded,
        'Bu telefonda videodan otomatik ayet bulma desteklenmiyor (Android 13 ve '
            'üstü ya da iPhone gerekir). Ayetleri elle seçebilirsin.',
      ),
```
    Dosya başı yorumu: kod listesi artık `ayah-finder` (görsel) + cihaz tanıyıcısı.
  - `Info.plist` `NSSpeechRecognitionUsageDescription` → `Okuduğunuz ya da videodaki ayeti bulmak için konuşma tanıma kullanılır.`
  - `models.dart` ve `ayah_finder_screen.dart:370` yorumlarında `ayah-finder-audio` → "cihaz tanıyıcısı (`analyzeRecitation`)".
- [ ] **Step 4: Run** — `dart analyze` 0; `flutter test` hepsi yeşil (silinen kodları bekleyen testler güncellenir).
- [ ] **Step 5: Commit** — `feat(meal): Groq yolu kaldırıldı; iOS cihaz tanıyıcısı yolu, device_unsupported`.

### Task 3: iOS `VideoSpeechChannel` (Swift, `AppDelegate.swift`)

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`

**Interfaces:**
- Consumes: Dart çağrıları — `isSupported` → `Bool`; `requestPermission` → `Bool`; `transcribe({path: String, locale: String})` → `[[String: Any]]` her biri `text: String, start: Double, end: Double`; `cancel` → nil.
- Produces: `FlutterError` kodları global listedeki gibi.

- [ ] **Step 1: Write** — `ios/Runner/AppDelegate.swift` tamamı:

```swift
import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VideoSpeechChannel") {
      VideoSpeechChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Videodan Meal (iOS): videonun sesini CİHAZIN konuşma tanıyıcısıyla metne
/// çevirir; video uygulamadan yüklenmez. Android karşılığı VideoSpeechChannel.kt.
/// Ses AVAssetReader ile 16 kHz mono'ya çevrilir, ~50 sn'lik parçalar (kesim en
/// sessiz 100 ms'de) SFSpeechRecognizer'a verilir. Kelime düzeyinde zaman döner;
/// bölümlere ayırma Dart'ta (wordsToSegments). Şartname:
/// docs/superpowers/specs/2026-11-08-iphone-videodan-ayet-design.md
final class VideoSpeechChannel {
  private static var instance: VideoSpeechChannel?
  private let channel: FlutterMethodChannel
  private var session: VideoSpeechSession?

  static func register(messenger: FlutterBinaryMessenger) {
    instance = VideoSpeechChannel(messenger: messenger)
  }

  private init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "kurandakimesaj/video_speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))?.isAvailable == true)
    case "requestPermission":
      SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async { result(status == .authorized) }
      }
    case "transcribe":
      transcribe(call.arguments as? [String: Any], result)
    case "cancel":
      session?.cancel()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(_ args: [String: Any]?, _ result: @escaping FlutterResult) {
    if session != nil {
      result(FlutterError(code: "speech_busy", message: "Başka bir tanıma sürüyor", details: nil))
      return
    }
    guard let path = args?["path"] as? String, FileManager.default.isReadableFile(atPath: path) else {
      result(FlutterError(code: "speech_no_audio", message: "Video okunamadı", details: nil))
      return
    }
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      result(FlutterError(code: "speech_permission", message: "Konuşma tanıma izni yok", details: nil))
      return
    }
    let locale = args?["locale"] as? String ?? "ar-SA"
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)), recognizer.isAvailable else {
      result(FlutterError(code: "speech_language", message: "Tanıyıcı bu dili desteklemiyor", details: nil))
      return
    }
    let s = VideoSpeechSession(url: URL(fileURLWithPath: path), recognizer: recognizer) { [weak self] outcome in
      self?.session = nil
      switch outcome {
      case .success(let words): result(words)
      case .failure(let f): result(FlutterError(code: f.code, message: f.message, details: nil))
      }
    }
    session = s
    s.start()
  }
}

struct VideoSpeechFailure: Error {
  let code: String
  let message: String
}

/// Tek tanıma oturumu. Sonuç yalnız BİR kez döner; tanıyıcı işleri ana iş
/// parçacığında, ses okuma arka planda.
final class VideoSpeechSession {
  static let rate = 16000.0
  private let url: URL
  private let recognizer: SFSpeechRecognizer
  private let completion: (Result<[[String: Any]], VideoSpeechFailure>) -> Void
  private var useOnDevice: Bool
  private var task: SFSpeechRecognitionTask?
  private var timeout: DispatchWorkItem?
  private var words: [[String: Any]] = []
  private var finished = false

  init(url: URL, recognizer: SFSpeechRecognizer,
       completion: @escaping (Result<[[String: Any]], VideoSpeechFailure>) -> Void) {
    self.url = url
    self.recognizer = recognizer
    self.completion = completion
    self.useOnDevice = recognizer.supportsOnDeviceRecognition
  }

  func start() {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let pcm = try VideoSpeechSession.readPCM(self.url)
        let ranges = VideoSpeechSession.chunkRanges(count: pcm.count, pcm: pcm)
        DispatchQueue.main.async { self.run(pcm, ranges, 0, retried: false) }
      } catch let f as VideoSpeechFailure {
        DispatchQueue.main.async { self.finish(.failure(f)) }
      } catch {
        DispatchQueue.main.async {
          self.finish(.failure(VideoSpeechFailure(code: "speech_no_audio", message: error.localizedDescription)))
        }
      }
    }
  }

  func cancel() {
    task?.cancel()
    finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "iptal edildi")))
  }

  private func finish(_ outcome: Result<[[String: Any]], VideoSpeechFailure>) {
    if finished { return }
    finished = true
    timeout?.cancel()
    task = nil
    completion(outcome)
  }

  /// Video → 16 kHz mono 16-bit PCM (AVAssetReader dönüştürür).
  static func readPCM(_ url: URL) throws -> [Int16] {
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else {
      throw VideoSpeechFailure(code: "speech_no_audio", message: "Videoda ses izi yok")
    }
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: rate,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ])
    reader.add(output)
    guard reader.startReading() else {
      throw VideoSpeechFailure(code: "speech_no_audio", message: reader.error?.localizedDescription ?? "Ses okunamadı")
    }
    var pcm: [Int16] = []
    while let sample = output.copyNextSampleBuffer() {
      guard let block = CMSampleBufferGetDataBuffer(sample) else { continue }
      let length = CMBlockBufferGetDataLength(block)
      if length < 2 { continue }
      var chunk = [Int16](repeating: 0, count: length / 2)
      chunk.withUnsafeMutableBytes { raw in
        _ = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: (length / 2) * 2, destination: raw.baseAddress!)
      }
      pcm.append(contentsOf: chunk)
    }
    if reader.status == .failed {
      throw VideoSpeechFailure(code: "speech_no_audio", message: reader.error?.localizedDescription ?? "Ses okunamadı")
    }
    if pcm.isEmpty {
      throw VideoSpeechFailure(code: "speech_no_audio", message: "Ses izi boş")
    }
    return pcm
  }

  /// ~50 sn'lik parçalar; kesim 45–55 sn arasındaki en sessiz 100 ms'nin ortası.
  static func chunkRanges(count: Int, pcm: [Int16]) -> [Range<Int>] {
    let r = Int(rate)
    let lo = 45 * r, hi = 55 * r, win = r / 10
    var ranges: [Range<Int>] = []
    var start = 0
    while count - start > hi {
      var bestCut = start + 50 * r
      var bestEnergy = Int64.max
      var w = start + lo
      while w + win <= start + hi {
        var e: Int64 = 0
        for i in w..<(w + win) {
          let v = Int64(pcm[i])
          e += v * v
        }
        if e < bestEnergy {
          bestEnergy = e
          bestCut = w + win / 2
        }
        w += win
      }
      ranges.append(start..<bestCut)
      start = bestCut
    }
    ranges.append(start..<count)
    return ranges
  }

  private func run(_ pcm: [Int16], _ ranges: [Range<Int>], _ index: Int, retried: Bool) {
    if finished { return }
    if index >= ranges.count {
      finish(.success(words))
      return
    }
    let range = ranges[index]
    let offset = Double(range.lowerBound) / VideoSpeechSession.rate
    guard let format = AVAudioFormat(standardFormatWithSampleRate: VideoSpeechSession.rate, channels: 1) else {
      finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "Ses biçimi kurulamadı")))
      return
    }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = false
    request.taskHint = .dictation
    request.requiresOnDeviceRecognition = useOnDevice
    if #available(iOS 16.0, *) {
      request.addsPunctuation = false
    }

    var handled = false
    let resume: (Error?, SFSpeechRecognitionResult?) -> Void = { [weak self] error, result in
      guard let self = self, !self.finished, !handled else { return }
      if let result = result, !result.isFinal, error == nil { return }
      handled = true
      self.timeout?.cancel()
      if let result = result, result.isFinal {
        for seg in result.bestTranscription.segments {
          let start = offset + seg.timestamp
          self.words.append(["text": seg.substring, "start": start, "end": start + seg.duration])
        }
        self.run(pcm, ranges, index + 1, retried: false)
        return
      }
      let ns = (error ?? NSError(domain: "VideoSpeech", code: -1)) as NSError
      // "Konuşma algılanmadı" (kAFAssistantErrorDomain 1110; sunucu modunda bazen
      // 203 "Retry"): boş parça, hata değil — o parçadan kelime gelmez.
      if ns.domain == "kAFAssistantErrorDomain" && (ns.code == 1110 || ns.code == 203) {
        self.run(pcm, ranges, index + 1, retried: false)
        return
      }
      // Cihaz üstü model yok/inmedi: aynı parçayı bir kez sunucu moduyla dene.
      if self.useOnDevice && !retried {
        self.useOnDevice = false
        self.run(pcm, ranges, index, retried: true)
        return
      }
      let code = ns.domain == NSURLErrorDomain ? "speech_network" : "speech_unavailable"
      self.finish(.failure(VideoSpeechFailure(code: code, message: "\(ns.domain) \(ns.code): \(ns.localizedDescription)")))
    }

    task = recognizer.recognitionTask(with: request) { result, error in
      DispatchQueue.main.async { resume(error, result) }
    }

    var i = range.lowerBound
    let step = Int(VideoSpeechSession.rate)
    while i < range.upperBound {
      let n = min(step, range.upperBound - i)
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)),
            let dst = buffer.floatChannelData?[0] else { break }
      buffer.frameLength = AVAudioFrameCount(n)
      for k in 0..<n {
        dst[k] = Float(pcm[i + k]) / 32768.0
      }
      request.append(buffer)
      i += n
    }
    request.endAudio()

    let work = DispatchWorkItem { [weak self] in
      guard let self = self, !self.finished, !handled else { return }
      handled = true
      self.task?.cancel()
      self.finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "Tanıyıcı 60 sn yanıt vermedi")))
    }
    timeout = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: work)
  }
}
```

- [ ] **Step 2: Statik kontrol (Windows)** — derlenemez; şu üç şeyi elle doğrula: (a) `GeneratedPluginRegistrant.register` satırı korunmuş; (b) dosyada başka `@main` yok; (c) `import Speech` + `import AVFoundation` var.
- [ ] **Step 3: Commit** — `feat(ios): VideoSpeechChannel — videonun sesi SFSpeechRecognizer ile, Groq'suz`.
- [ ] **Step 4: Derleme doğrulaması Codemagic'te (Task 6).** Hata gelirse burada düzeltilip yeniden derlenir.

### Task 4: Gizlilik/koşul metinleri ve belgeler

**Files:**
- Modify: `docs/legal/privacy.html`, `docs/legal/terms.html`, `PRIVACY_POLICY.md` (Groq geçen paragraflar), `CLAUDE.md` (Meal Düzenle paragrafı + `segments.test.ts` deno komutu), `PROJECT_MEMORY.md`, `tasks/todo.md`

- [ ] **Step 1:** Her dosyada `grep -n -i groq` ile satırları bul. Videodan sesin Groq'a gönderildiğini anlatan cümleleri şununla değiştir (HTML'de aynı anlamı koruyan biçimde): "Videodan Meal'de videodaki ses, tanınmak üzere telefonunuzun ses tanıma servisine (iPhone'da Apple, Android'de Google) iletilebilir; uygulama videoyu ya da sesi kendi sunucusuna yüklemez." Hizmet sağlayıcı listelerinde Groq satırı silinir; Gemini (görsel) kalır.
- [ ] **Step 2:** `CLAUDE.md`: Meal Düzenle paragrafında "iOS ve Android ≤12'de `ayah-finder-audio` (Groq) sürer" → "iPhone'da `AppDelegate.swift` `VideoSpeechChannel` (SFSpeechRecognizer); Android ≤12'de otomatik analiz yok (elle seçim). Groq 2026-11-08'de tamamen kaldırıldı." ve komut listesinden `deno test ... ayah-finder-audio/segments.test.ts` satırı silinir.
- [ ] **Step 3: Commit** — `docs: Groq kaldırıldı; gizlilik metinleri cihaz tanıyıcısına göre`.

### Task 5: Sunucu temizliği (üretim — denetleyici yapar)

**Files:**
- Create: `supabase/migrations/20261108120000_drop_ayah_audio.sql`
- Delete: `supabase/functions/ayah-finder-audio/`; Modify: `supabase/config.toml` (`[functions.ayah-finder-audio]` bloğu)

- [ ] **Step 1:** Kovada nesne sayısını kontrol et (SQL: `select count(*) from storage.objects where bucket_id = 'ayah-audio';`).
- [ ] **Step 2: Migration:**

```sql
-- Groq (ayah-finder-audio) kaldırıldı (2026-11-08): videonun sesi artık cihazda
-- tanınıyor, video yüklenmiyor. Geçici yükleme kovası ve politikaları silinir.
do $$
declare p record;
begin
  for p in select policyname from pg_policies
           where schemaname = 'storage' and tablename = 'objects'
             and (qual ilike '%ayah-audio%' or with_check ilike '%ayah-audio%')
  loop
    execute format('drop policy if exists %I on storage.objects', p.policyname);
  end loop;
end $$;
delete from storage.objects where bucket_id = 'ayah-audio';
delete from storage.buckets where id = 'ayah-audio';
```
- [ ] **Step 3:** `npx supabase functions delete ayah-finder-audio --project-ref uytqxgcbohdlwwxemgyy` → `functions list`'te yok.
- [ ] **Step 4:** `npx supabase secrets unset GROQ_API_KEY --project-ref uytqxgcbohdlwwxemgyy` → `secrets list`'te yok.
- [ ] **Step 5:** `npx supabase db push` → kova yok (SQL ile doğrula).
- [ ] **Step 6:** Repodan fonksiyon klasörü + config girdisi sil; commit `chore(supabase): Groq/ayah-finder-audio ve ayah-audio kovası kaldırıldı`.

### Task 6: Deploy (denetleyici, Claude in Chrome)

- [ ] **Step 1:** `flutter test` + `dart analyze` yeşil; `git push`.
- [ ] **Step 2:** GitHub `sqlite3-3.3.3` sürüm indirmesi 200 dönüyor mu (`curl -sI .../libsqlite3.arm64.ios.dylib`); dönmüyorsa bekle/yeniden dene.
- [ ] **Step 3:** Codemagic → kurandakimesaj → Start new build → `feat/okuyarak-bul` / iOS App Store. Swift derleme hatası olursa Task 3'e dön, düzelt, push, yeniden derle.
- [ ] **Step 4:** ASC → 1.0.3: yeni build'i ekle; What's New'e iPhone'da videodan ayet bulma maddesi; inceleme notuna Meal Düzenle test yolu + konuşma izni açıklaması; Save. **Submit for Review'a basma** (kullanıcı basar, TestFlight testinden sonra).
- [ ] **Step 5:** Test videolarını (Fatiha 2-4, Kürsî, Yâsîn 58-61) kullanıcıya gönder; TestFlight test adımlarını yaz.
