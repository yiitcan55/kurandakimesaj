# iPhone'da videodan ayet bulma + Groq'un kaldırılması — tasarım (2026-11-08)

Dal: `feat/okuyarak-bul` · Önceki şartname: `2026-11-07-videodan-meal-cihaz-tanima-design.md` (Android yolu)

## Amaç ve kullanıcı kararları (2026-11-08)

- iPhone'da Videodan Meal (Meal Düzenle), Android 13+'taki gibi videonun sesini **telefonun kendi tanıyıcısıyla** çözer; video yüklenmez; ayet aralığı ve altyazı zamanlaması cihazda bulunur.
- **Yaklaşım A:** klasik `SFSpeechRecognizer` + `AVAssetReader` + ~50 sn'lik parçalar.
- **Groq tamamen kalkar:** istemcide yedek yol YOK; sunucu tarafı (`ayah-finder-audio`, `GROQ_API_KEY`, `ayah-audio` kovası) **hemen** silinir. Kullanıcı sonucu kabul etti: güncellemeyen eski sürümlerde (≤1.0.2) Meal Düzenle otomatik analizi hata verip elle seçime düşer; Android 12 ve altında otomatik analiz olmaz, elle seçim kalır.
- **Sürüm:** 1.0.3 bekler; iPhone video + Okuyarak Bul aynı TestFlight build'inde denenir, birlikte incelemeye gider.
- **Doğrulama:** Kullanıcının iPhone'u var, TestFlight'ta dener. Bu makine Windows: Swift burada derlenemez; tek derleyici Codemagic (Mac mini M2).

## Teknik zemin

- `SFSpeechRecognizer(locale: ar-SA)` destekli; sonuçta `bestTranscription.segments` her kelime için `timestamp` + `duration` verir (Android'den hassas; kalibrasyon gerekmez).
- Arapça **cihaz üstü** tanıma belirsiz: `supportsOnDeviceRecognition` true olsa da model inmeyebiliyor (Apple forumları). Önce cihaz üstü denenir; olmazsa sunucu modu.
- Sunucu modunda istek başına ~1 dk sınırı bildiriliyor (doğrulanmadı) → ses ~50 sn'lik parçalarla verilir; her durumda güvenli.
- iOS 26 `SpeechAnalyzer`/`SpeechTranscriber`'da Arapça güvenilmez (listede görünüp model indirilemiyor) → kullanılmaz.
- Dosyadan tanıma iOS'ta **mikrofon izni istemez**; yalnız konuşma tanıma izni (`SFSpeechRecognizer.requestAuthorization`).
- Proje: dağıtım hedefi iOS 14; `AppDelegate` `FlutterImplicitEngineDelegate` kullanıyor (eklentiler `didInitializeImplicitFlutterEngine` içinde kaydediliyor). `addsPunctuation` iOS 16+ → `#available` ile.

## Bileşenler

### A. iOS yerel: `ios/Runner/AppDelegate.swift` içinde `VideoSpeechChannel` sınıfı
Yeni dosya DEĞİL: yeni Swift dosyası `project.pbxproj` kaydı ister ve Windows'ta elle düzenlemek riskli; zaten hedefte olan `AppDelegate.swift`'e eklenir. Kayıt: `didInitializeImplicitFlutterEngine` içinde `engineBridge.pluginRegistry.registrar(forPlugin: "VideoSpeechChannel")` → `messenger()` → `FlutterMethodChannel("kurandakimesaj/video_speech")`.
- `isSupported` → `SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))?.isAvailable == true`.
- `requestPermission` → `SFSpeechRecognizer.requestAuthorization`; `.authorized` → true.
- `transcribe({path, locale})` → `[{text, start, end}]` **kelime** listesi (sn, video başına göre). Mantık:
  1. `AVAssetReader` + `AVAssetReaderTrackOutput` (ilk ses izi) → `kAudioFormatLinearPCM`, 16 kHz, mono, 16-bit. Ses izi yoksa `speech_no_audio`.
  2. PCM bellekte toplanır (en çok 3 dk ≈ 5,8 MB) ve parçalara bölünür: hedef 50 sn; kesim noktası 45–55 sn arasındaki en sessiz 100 ms'lik pencere (RMS en düşük).
  3. Her parça sırayla `SFSpeechAudioBufferRecognitionRequest`'e `AVAudioPCMBuffer`'larla verilir: `shouldReportPartialResults = false`, `taskHint = .dictation`, `requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition`, iOS 16+'da `addsPunctuation = false`; `endAudio()`; son sonuç beklenir.
  4. Cihaz üstü istek "model yok / dil yok" hatasıyla düşerse aynı parça bir kez `requiresOnDeviceRecognition = false` ile tekrar denenir ve sonraki parçalar sunucu modunda gider.
  5. "Konuşma algılanmadı" hatası (boş parça) hata değil, o parçadan kelime gelmez. Diğer hatalar kodlara çevrilir: yetki yok → `speech_permission`, ağ → `speech_network`, dil/tanıyıcı yok → `speech_language`, eşzamanlı çağrı → `speech_busy`, diğer → `speech_unavailable`.
  6. Kelimeler `{text: substring, start: parçaKayması + timestamp, end: start + duration}` olarak eklenir.
- `cancel` → çalışan görev `cancel()`, okuyucu durur, sonuç bir kez `speech_unavailable` ile döner.
- Tek eşzamanlı oturum; tanıyıcı işleri ana iş parçacığında, okuma/bölme arka planda; sonuç yalnız bir kez döner.

### B. Dart
- `lib/data/video_speech.dart`
  - `isSupported`: Android **veya iOS** → kanal; diğerleri false.
  - `requestPermission`: Android → `Permission.microphone` (bugünkü gibi); iOS → kanalın `requestPermission`'ı (permission_handler'da `Permission.speech` iOS'ta Podfile makrosu ister; kanal yolu buna gerek bırakmaz).
  - `transcribe`: Android `{start,end,text}` bölümleri döndürür (değişmez); iOS kelimeler döndürür → `wordsToSegments` ile bölüme çevrilir.
- `lib/domain/recitation_timeline.dart` (saf, testli): `List<SpeechSegment> wordsToSegments(List<SpeechSegment> words, {double gap = 0.6})` — ardışık kelimeler arası boşluk > `gap` ise yeni bölüm; bölüm metni kelimelerin birleşimi, zamanı ilk kelimenin başı – son kelimenin sonu.
- `lib/data/backend_repositories.dart` `findFromVideo`: **Groq dalı silinir.** Cihaz destekliyorsa cihaz yolu (bugünkü `_findOnDevice`); değilse `device_unsupported`. Silinenler: depolama yüklemesi, `ayah-audio` sabiti, `ayah-finder-audio` çağrısı, `_extOf`. Video için oturum açma şartı da kalkar.
- `lib/features/ayah_finder/ayah_error_messages.dart`: Yeni `device_unsupported`: "Bu telefonda videodan otomatik ayet bulma desteklenmiyor (Android 13 ve üstü ya da iPhone gerekir). Ayetleri elle seçebilirsin." Yalnız Groq yolunun ürettiği kodlar silinir: `upload_failed`, `asr_failed`, `forbidden_path`, `no_video`, `rate_limited` (2026-11-08 kontrol: görsel `ayah-finder` yalnız `no_api_key`/`no_image`/`server_error` üretir; `auth_required`/`network`/`bad_response`/`file_too_large`/`video_missing` istemcide başka yollarca kullanıldığı için KALIR).
- `ios/Runner/Info.plist` `NSSpeechRecognitionUsageDescription`: "Okuduğunuz ya da videodaki ayeti bulmak için konuşma tanıma kullanılır."
- Model/belge yorumlarındaki `ayah-finder-audio` atıfları güncellenir.

### C. Sunucu temizliği (hemen, üretim — her adım çıktısıyla doğrulanır)
1. `npx supabase functions delete ayah-finder-audio` (REF `uytqxgcbohdlwwxemgyy`).
2. `npx supabase secrets unset GROQ_API_KEY`.
3. Yeni migration: `ayah-audio` kovasının RLS politikalarını düşür, kovadaki nesneleri sil, kovayı sil; `db push`. (Kova geçici dosya tutar; fonksiyon işi bitince siliyordu, kalıcı kullanıcı verisi yok — silmeden önce nesne sayısı kontrol edilir.)
4. Repodan `supabase/functions/ayah-finder-audio/` ve `config.toml` girdisi silinir; `_shared/quran/` KALIR (görsel `ayah-finder` kullanıyor). `CLAUDE.md`'deki `segments.test.ts` deno komutu kaldırılır.

### D. Gizlilik ve mağaza
- Gizlilik/koşul metinleri — Groq geçen dosyalar: `docs/legal/privacy.html`, `docs/legal/terms.html`, `PRIVACY_POLICY.md` (GitHub Pages'te yayında; yansıması dalın main'e girmesine bağlı). Groq'a ses gönderimi kaldırılır; yerine "Videodaki ses telefonun ses tanıma servisine (Apple/Google) iletilebilir; uygulama sesi kendi sunucusuna yüklemez."
- ASC 1.0.3: What's New'e iPhone'da videodan ayet bulma eklenir; inceleme notuna test yolu (Meal Düzenle → Video Seç → tilavet videosu) ve konuşma izni açıklaması eklenir.
- Play Veri güvenliği ve Android sürümü ayrı adım (bu işin dışında, kullanıcıya bildirilir).

## Doğrulama
1. Dart birim testleri: `wordsToSegments` (boşluk eşiği, tek kelime, boş liste), iOS kelime girdisiyle uçtan uca `analyzeRecitation` (Fatiha 2-4 kelimeleri → aralık 1:2-4), `findFromVideo` Groq'suz yönlendirme (destek yok → `device_unsupported`, oturum şartı yok). `dart analyze` 0, `flutter test` hepsi.
2. Android gerilemesi: emülatörde Fatiha/Yâsîn videoları (önceki ölçümlerle aynı sonuç).
3. Codemagic iOS derlemesi: Swift'in ilk derlenmesi (hata çıkarsa düzeltilip yeniden).
4. TestFlight: kullanıcı iPhone'da üç tilavet videosunu (Fatiha 2-4, Kürsî, Yâsîn 58-61; dosyaları gönderilir) + Okuyarak Bul'u dener; ekran görüntüsü/sonuç yazar. Beklenen: doğru aralık; altyazı ayet geçişleri ±1 sn.
5. Sunucu temizliği: fonksiyon listesinde `ayah-finder-audio` yok, `secrets list`'te `GROQ_API_KEY` yok, kova yok.

## Riskler
- Swift kör yazılıyor: derleme hatası tüm iOS build'ini durdurur → feature dalında Codemagic'te düzelt, release'e öyle gir.
- Arapça tanıma iPhone'da sunucu moduna düşerse ses Apple'a gider (gizlilik metni bunu kapsar) ve Apple'ın cihaz başı istek kotası uygulanır (3 dk video ≈ 4 istek).
- Eski sürümler (≤1.0.2) ve Android ≤12 otomatik analizi kaybeder (kullanıcı kararı).
- Codemagic şu an GitHub 503/504 yüzünden `sqlite3` hazır kitaplığını indiremiyor (geçici; özet tutmazlığının kaynağı GitHub hata sayfası, 2026-11-08 doğrulandı).

## Kapsam dışı
Google Play sürümü · iOS 26 `SpeechAnalyzer` · whisper.cpp · görsel `ayah-finder` (Gemini) değişmez.
