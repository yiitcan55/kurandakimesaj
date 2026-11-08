# Videodan Meal: videonun sesini cihazda tanıma — tasarım (2026-11-07)

Dal: `feat/okuyarak-bul` · Kaynak plan: `../sound to ted.md` + `../kuran_eslestirici/`

## Amaç ve kullanıcı kararları

Asıl hedef **videodaki sesi metne çevirip hangi ayet olduğunu bulmak** ve Videodan Meal'i (Meal Düzenle) bu yönteme geçirmek.
Kullanıcı kararları (2026-11-07):
- Ses motoru **cihazın tanıyıcısı** olacak (Groq Whisper değil). Video sunucuya yüklenmeyecek.
- Ayet **cihazdaki** `QuranMatcher` (`lib/domain/quran_matcher.dart`) ile bulunacak.
- Canlı mikrofonlu "Okuyarak Bul" **kalacak**.

Kapsam: **Android 13+ (API 33)**. iOS ve Android 12 ve altı, bugünkü sunucu yolunu (Groq) kullanmaya devam eder: davranış gerilemez. iOS'un Swift tarafı (`SFSpeechURLRecognitionRequest`) bu Windows makinesinde derlenemediği için sonraki adıma kalır; derlenmeden App Store derlemesine Swift kodu koymak tüm iOS sürümünü kırma riski taşır.

## Deneme (spike) bulguları — emülatör API 36, Google tanıyıcısı, Husarî/Alafasy kayıtları

1. `SpeechRecognizer.createSpeechRecognizer` + `RecognizerIntent`: `EXTRA_LANGUAGE="ar-SA"`, `LANGUAGE_MODEL_FREE_FORM`, `EXTRA_AUDIO_SOURCE` = `ParcelFileDescriptor.createPipe()`'ın okuma ucu, `EXTRA_AUDIO_SOURCE_CHANNEL_COUNT=1`, `EXTRA_AUDIO_SOURCE_ENCODING=ENCODING_PCM_16BIT`, `EXTRA_AUDIO_SOURCE_SAMPLING_RATE=16000`, `EXTRA_SEGMENTED_SESSION=EXTRA_AUDIO_SOURCE`. Her bölüm için `onBeginningOfSpeech` → `onEndOfSpeech` → `onSegmentResults` (`RESULTS_RECOGNITION[0]`, baştaki boşluk olabilir → trim); EOF'ta `onEndOfSegmentedSession`.
2. **Düz dosya FD'si çalışmaz:** tanıyıcı hepsini anında okur, EOF'a çarpar, `Failed uploading data to S3` → `ERROR_NETWORK`. Ses pipe'a **ölçülü hızla** yazılmalı. **4x gerçek zaman** sorunsuz: Âyetü'l-Kürsî (61 sn) 15 sn'de, 7 bölüm, neredeyse kusursuz metin. 4x'i aşma.
3. **Yalnız 16 kHz mono s16le.** 44,1 kHz verilince Google'ın Opus kodlayıcısı tanıyıcı SÜRECİNİ çökertir (`ogg_opus_encoder.cc:56`, geçerli hızlar 8/12/16/24/48k). Videonun sesi cihazda çözülüp mono'ya indirilip 16 kHz'e örneklenmeli.
4. **`RECORD_AUDIO` izni şart** (yoksa `ERROR 9`), mikrofon açılmasa bile.
5. Çevrimiçi tanıyıcıda kelime zamanlaması yok (`EXTRA_REQUEST_WORD_TIMING` → "not supported when EXTRA_PREFER_OFFLINE is false"). Zamanlama olaylardan: olay anında yazılmış örnek sayısı / 16000 = ses konumu (sn). Yazıcı ölçülü olduğu için gecikme küçük.
6. `SpeechRecognizer` ana iş parçacığında oluşturulup kullanılır; çözme/yazma arka plan iş parçacığında.
7. Örnek bölümler (Kürsî, 4x): `الله لا اله الا هو الحي القيوم` / `لا تاخذه سنه ولا نوم` / `له ما في السماوات وما في الارض` / `من ذا الذي يشفع عنده الا باذنه` / `يعلم ما بين ايديهم وما خلفهم ولا يحيطون بشيء من علمه الا بما شاء` / `وسع كرسيه السماوات والارض ولا يؤوده حفظهما` / `وهو العلي العظيم`.
   Fatiha 2-4: `الحمد لله رب العالمين` / `الرحمن الرحيم` / `مالك يوم الدين`.

Deneme kodu (atılacak, yalnız referans): oturum scratchpad'inde `FileSpeechSpike.kt.ref`.

## Bileşenler

### A. Android yerel: `android/app/src/main/kotlin/com/kurandakimesaj/app/VideoSpeechChannel.kt`
`MethodChannel("kurandakimesaj/video_speech")`, `MainActivity.configureFlutterEngine` içinde kaydedilir (MainActivity'deki `sanitizeShareIntent` ve `AudioServiceActivity` tabanı korunur).
- `isSupported` → `SDK_INT >= 33 && SpeechRecognizer.isRecognitionAvailable(ctx)`.
- `transcribe({path, locale})` → `List<Map>`: `{start: Double sn, end: Double sn, text: String}` (boş metinli bölüm atlanır). Hatalar `PlatformException` kodlarıyla: `speech_permission` (ERROR 9 / izin yok), `speech_network` (ERROR 1/2), `speech_language` (ERROR 12/13), `speech_busy` (aynı anda ikinci çağrı ya da ERROR 8), `speech_no_audio` (ses izi yok / çözülemedi), `speech_unavailable` (diğer).
- `cancel` → tanıyıcıyı iptal et, yazıcıyı durdur, her şeyi bırak.
- Çözme: `MediaExtractor` (ilk `audio/` iz) → `MediaCodec` çözücü → PCM16 (çıktı biçimi değişince örnekleme hızı/kanal güncellenir) → kanalların ortalamasıyla mono → 16 kHz'e doğrusal örnekleme → pipe'a 4x hızla yazım (100 ms'lik parçalar). Yazım bitince pipe yazma ucu kapanır (EOF = oturum sonu).
- Zamanlama: `onBeginningOfSpeech` → `start = yazılan/16000`; `onEndOfSpeech` → `end`; `onSegmentResults` bölümü yayar (end yoksa o anki konum).
- Korumalar: tek eşzamanlı oturum; 60 sn boyunca hiçbir geri çağrı gelmezse `speech_unavailable` ile bitir; her yolda PFD/codec/extractor/recognizer serbest bırakılır; sonuç yalnız bir kez döner.

### B. Dart servis: `lib/data/video_speech.dart`
`VideoSpeechService` (MethodChannel sarmalayıcı; `isSupported()`, `transcribe(path)`, `cancel()`), `typedef SpeechSegment = ({double start, double end, String text})`, `videoSpeechServiceProvider`. Android dışında `isSupported` false.

### C. Domain (saf, test edilebilir): `lib/domain/recitation_timeline.dart`
`AyahFinderResult analyzeRecitation(List<SpeechSegment> segments, QuranMatcher matcher, Map<int, String> surahNames)` — sunucudaki `segments.ts`'in fikri, yeni eşleştiricinin ölçeğiyle:
0. Ritüel önekler (sunucudaki `isRitualPrefix` karşılığı): normalize kelimelerinin tamamı istiaze (`اعوذ بالله من الشيطان الرجيم`) ya da besmele kümesinde olan bölüm eşleştirmeye girmez. **Neden:** istiaze `الشيطان` yüzünden Yâsîn 36:60'a oturup sıralı atamada 58-59'u düşürür. Besmele yalnız baskın sure Fatiha ise (1:1) geri eklenir.
1. Her bölüm: `matcher.match(text, limit: 8, minScore: 0.35)`.
2. Baskın sure: her bölümün sure başına en iyi skoru toplanır; en yüksek toplamın payı ≥ %60 değilse `ambiguous`.
3. Sıralı atama: bölümler sırayla, baskın suredeki adaylardan `fromAyah ≥ önceki toAyah` olan en yüksek skorlu seçilir (eşitlikte öncekine en yakın); yoksa bölüm düşer (istiaze/besmele/alakasız konuşma böyle elenir; Fatiha'da besmele 1:1 olarak kalabilir).
4. Aralık: atananların min `fromAyah` – max `toAyah`; en çok 2 ayetlik boşluklar doldurulur; aralık > 30 ayet → `ambiguous`.
5. Zaman çizelgesi: her atanan bölümün [start, end]'i kapsadığı ayetlere kelime sayısıyla orantılı bölünür → `AyahTimelineEntry(reference: "<nameTr>, a", confidence: skor)`.
6. `matches`: aralıktaki HER ayet için bir `AyahMatch` (Arapça + meal `matcher.versesOf`'tan) — `MealEditController` bunları cue ağırlığı olarak kullanır (sunucuyla aynı şekil).
7. Durum: en az bir atama ve atanan skor ortalaması ≥ 0.6 → `matched` (+ `range`); hiçbir bölümde aday yoksa `notFound`; aksi `ambiguous` (tüm metnin `match` sonuçlarıyla). `extractedArabic` = bölümlerin birleşimi.

### D. Repository: `AyahFinderRepository.findFromVideo`
Cihaz yolu destekleniyorsa (Android 13+): dosya var mı / 20 MB sınırı (mevcut kontroller) → `Permission.microphone` (permission_handler; reddedilirse `speech_permission`) → `transcribe` → `analyzeRecitation` (eşleştirici `quranMatcherProvider`'dan, sure adları `surahsProvider`'dan; sağlayıcıya `ref` geçirilerek) → sonuç. **Oturum açmak gerekmez, video yüklenmez.** Değilse bugünkü sunucu yolu aynen.

### E. Hata metinleri: `lib/features/ayah_finder/ayah_error_messages.dart`
Yeni kodlar, Türkçe ve tam imla:
- `speech_permission`: "Videodaki sesi tanımak için Android ses tanıma izni gerekiyor (mikrofon açılmaz). Ayarlar'dan izin verip tekrar deneyin."
- `speech_network`: "Ses tanıma için internet bağlantısı gerekiyor. Bağlantını kontrol edip tekrar dene."
- `speech_language`: "Telefonun ses tanıyıcısı Arapçayı desteklemiyor. Ayetleri elle seçebilirsin."
- `speech_busy`: "Ses tanıyıcı meşgul. Birkaç saniye sonra tekrar dene."
- `speech_no_audio`: "Videoda okunabilir bir ses bulunamadı."
- `speech_unavailable`: "Ses tanıma şu an kullanılamıyor. Tekrar dene ya da ayetleri elle seç."

## Doğrulama
- `dart analyze` 0 · `flutter test` hepsi · `flutter build apk --debug`.
- Testler: `test/recitation_timeline_test.dart` gerçek korpusla (`assets/quran/quran_full.json`): Fatiha 2-4 bölümleri → `matched`, aralık 1:2-4, zaman çizelgesi monoton; Kürsî 7 bölümü → 2:255; istiaze + besmele + Yâsîn 58-61 bölümleri → aralık 36:58-61 (istiaze düşer); boş liste → `notFound`; alakasız Arapça → `notFound` ya da `ambiguous`. Repo yönlendirmesi için sahte servisle bir test.
- Emülatör E2E (denetleyici yapar): Husarî sesinden üretilen mp4 → Meal Düzenle → ayet aralığı + altyazılar.

## Uygulama sonucu (2026-11-07)

**Kontroller:** `dart analyze` 0 · `flutter test` 313/313 · debug APK ✓.

**İşçinin şartnameden gerekçeli sapmaları:** (1) baskın sure payı = en yüksek toplam / ilk İKİ surenin toplamı (korpus her surenin 1. ayetine besmele eklediği için `الرحمن الرحيم` 8 surede 0,91 alıyor, tüm sureler paydaya girince Fatiha payı ~0,16 çıkıyordu); (2) ritüel bölüm yalnız `بسم`/`اعوذ` içeriyorsa sayılır (yoksa Fatiha 3 besmele sanılıyordu), Fatiha'da besmele doğrudan 1:1; (3) 2 ayetten büyük boşluk kümeyi böler, skoru en yüksek küme kalır; (4) aynı ayete düşen ardışık bölümler tek çizelge girdisinde birleşir; (5) Kotlin'de ERROR 6/7 (konuşma yok) toplanan bölümlerle başarı döner → Dart `notFound`.

**E2E'de bulunup düzeltilen 3 zamanlama kusuru (Kotlin):**
1. Pipe varsayılanı 64 KB ≈ 2 sn: tanıyıcı ~0,7 sn geç okumaya başlıyor, yazıcı önde kalıyor → altyazılar ~3 sn geç. `Os.fcntlInt(F_SETPIPE_SZ=1031, 4096)` ile kapasite 4 KB.
2. Tanıyıcının konuşma başı/sonu olayları sesin ~0,6 sn gerisinden geliyor (ölçüm: Fatiha 0,49-0,68, Kürsî 0,53-0,84 sn; gerçek sınırlar ffmpeg `silencedetect`) → kalibrasyon sabiti `DETECT_LAG_S = 0.6`.
3. Bir bölüm sonucu BİRDEN ÇOK konuşma aralığını kapsayabiliyor (Alafasy Yâsîn: 5 aralık, 2 sonuç) → sonuç gelene kadar kapanmış tüm aralıklar o bölümün.

**E2E (emülatör API 36, AAC 44,1 kHz stereo mp4, Meal Düzenle → Video Seç):**
| Video | Sonuç | Bölüm başlangıçları (bulunan / gerçek, sn) |
|---|---|---|
| Husarî Fatiha 2-4 (17 sn) | **Fâtiha, 2-4** | 0,50/0,68 · 6,30/6,41 · 10,80/10,91 |
| Husarî Âyetü'l-Kürsî (62 sn) | **Bakara, 255** | 1,20/1,19 · 10,20/10,22 · 16,20/16,26 · 22,60/22,51 · 31,20/31,06 · 48,10/47,96 · 56,50/56,27 |
| Alafasy Yâsîn 58-61 (46 sn) | **Yâsîn, 58-61** | 58: 0,30/0 · 59: 7,75/7,94 · 60: 13,72/15,31 · 61: 33,70/34,62 |
| 440 Hz ton (8 sn) | "tilavet bulunamadı" + elle seçim | — |

Altyazı oynatmada doğru anda değişiyor (0:09 → 59. ayet, 0:36 → 61. ayet). Analiz süresi ≈ video süresi / 4. Yâsîn 59-60 sınırındaki ~1,5 sn sapma, tanıyıcının 58-60'ı tek bölüm döndürmesinden (bölüm içi orantılı paylaştırma). Not: paketli Diyanet meali 36:59-61'i tek birleşik cümle olarak veriyor; üç ayette aynı metin görünmesi veri kaynaklı.

**Borç:** `backend_repositories.dart` (data) `quranMatcherProvider` ve `surahsProvider`'ı features katmanından alıyor; sağlayıcılar data'ya taşınmalı.

## Kapsam dışı / sonraki
iOS Swift yolu (macOS gerekir) · Android < 13 için cihaz yolu (API yok) · sunucu `ayah-finder-audio` silinmez (eski istemciler ve iOS kullanıyor).
