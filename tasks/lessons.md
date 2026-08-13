# Lessons — Kur'an'da ki Mesaj

Bu projede tekrar eden hataları/öğrenmeleri kaydet. Oturum başında oku.

## Ortam (Windows + OneDrive + non-ASCII path)
- **gen_snapshot non-ASCII path bug:** Proje yolu `OneDrive\Masaüstü` (`ü`) içerdiği için `dart compile aot-snapshot` / build_runner AOT yazma **deterministik olarak** başarısız (exit 78, "Unable to write build.dart.aot"). Junction'ı `.dart_tool`'a koymak yetmez — build_runner yine `ü`'lü string'i geçirir.
  - **ÇÖZÜM:** Projeye işaret eden ASCII junction: `New-Item -ItemType Junction -Path C:\kdm -Target "<proje>"`, sonra `cd C:\kdm` ve oradan `dart run build_runner build` / `flutter build`. Üretilen `.g.dart` junction üzerinden gerçek projeye yazılır.
  - **Kalıcı çözüm:** Projeyi ASCII + OneDrive-dışı yola taşı (`C:\Users\yiit5\dev\kurandakimesaj`).
- `flutter`/`dart` PATH'te değil → `C:\Users\yiit5\flutter\bin` kullan (local.properties'ten bulundu).
- `flutter build bundle/apk` → "Android SDK could not be found"; cihaz testi için Android SDK kurulmalı.
- **`flutter analyze` ü'lü yoldan ÇÖKÜYOR** (analysis server LSP byte-framing, non-ASCII path'te Content-Length bayt/char uyuşmazlığı → "FormatException: Unexpected end of input", exit 255). İZOLE: `dart analyze` (batch CLI, LSP yok) ü'lü yoldan SORUNSUZ çalışır; `flutter analyze` C:\kdm'den SORUNSUZ. Workaround: kod doğrulaması için **`dart analyze`** kullan (her yerden) veya `cd C:\kdm; flutter analyze`. Aynı LSP sunucusunu kullanan VS Code Dart eklentisi de ü'lü yoldan güvenilmez olabilir.

## Ortam (GÜNCEL — 2026-06-15)
- **Proje ASCII yola taşındı:** `C:\Users\yiit5\Desktop\kurandaki mesaj flutter\kurandakimesaj`. Yolda `ü` yok → `dart analyze`, `dart run build_runner build`, `flutter test`, `flutter build` doğrudan proje yolundan SORUNSUZ. Junction (`C:\kdm`) gereksiz. Eski OneDrive\Masaüstü sorunları bu yolda geçerli DEĞİL.
- `flutter`/`dart` PATH'te değil → her PowerShell komutunun başında `$env:PATH += ";C:\Users\yiit5\flutter\bin"` ekle.

## Riverpod 3.3.x (flutter_riverpod 3.3.2)
- **`AsyncValue.valueOrNull` YOK** → `.value` kullan (zaten `T?` döner; loading/error'da null).
- **`StateProvider` core'dan kaldırıldı** → `import 'package:flutter_riverpod/legacy.dart';` gerekir. Tercihen ConsumerStatefulWidget + yerel state ya da Notifier kullan.
- AsyncNotifier: `class X extends AsyncNotifier<T>` + `AsyncNotifierProvider<X, T>(X.new)`; build async olabilir. Yenileme: `state = const AsyncLoading(); state = await AsyncValue.guard(build);`.

## flutter_local_notifications 22.x
- `initialize`, `show`, `zonedSchedule` **tamamen named parametre**: `initialize(settings: ...)`, `show(id:, title:, body:, notificationDetails:)`, `zonedSchedule(id:, title:, body:, scheduledDate:, notificationDetails:, androidScheduleMode: ...)`. Pozisyonel argüman çalışmaz.
- timezone: `tzdata.initializeTimeZones(); tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));` (cihaz tz adı için flutter_timezone yok → Türkiye için sabit İstanbul makul).

## Diğer paket API (2026)
- **share_plus 13:** `SharePlus.instance.share(ShareParams(text:..., subject:...))` (eski `Share.share` değil).
- **geolocator 14:** `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: ...))` (pozisyonel `desiredAccuracy` deprecated).
- **adhan:** `CalculationMethod.turkey.getParameters()..madhab = Madhab.shafi; PrayerTimes(coords, DateComponents.from(date), params)`; vakitler `.toLocal()` ile gösterilmeli. `Qibla(Coordinates(lat,lng)).direction` → kuzeyden derece.
- **hijri 3:** `HijriCalendar()..gregorianToHijri(y,m,d)` → instance.hDay/hMonth/hYear; `HijriCalendar().hijriToGregorian(y,m,d)` → DateTime. Türkçe ay adları yok, kendin eşle.
- **intl `TextDirection` ÇAKIŞMASI:** `package:intl/intl.dart` kendi `TextDirection`'ını export eder (`.LTR/.RTL`). Aynı dosyada Flutter `TextDirection.rtl` kullanıyorsan `import 'package:intl/intl.dart' hide TextDirection;` yap. `DateFormat(..., 'tr')` için bootstrap'ta `initializeDateFormatting('tr', null)` çağır (yoksa runtime LocaleData hatası).

## Paket ekosistemi (2026 / Flutter 3.44)
- **Isar kullanma:** isar_generator ve isar_community_generator eski `source_gen`/`analyzer`'a sabitli; freezed 3 + json_serializable 6.14 (analyzer ^12) ile çakışır. **drift** kullan (SQL+FTS5, güncel analyzer uyumlu).
- `riverpod_lint`/`custom_lint` eski `freezed_annotation 2.x`'e sabitli → freezed 3 ile çakışır; ekleme.
- pub `flutter_riverpod 3.x` çözer → `StateNotifier` yerine `Notifier`/`NotifierProvider` kullan.
- Modern API: `Color.withValues(alpha:)` (withOpacity değil), `CardThemeData` (CardTheme değil), Dart 3.12 wildcard `(_, _)`.

## Supabase (backend'siz açılış — null-guard zorunlu)
- **`Supabase.instance` başlatılmadan çağrılırsa ASSERT fırlatır** (`Failed assertion: _instance._isInitialized`). Uygulama `--dart-define=SUPABASE_URL` olmadan açılabildiği için `Supabase.initialize` koşulludur → `Supabase.instance`'a dokunan HER provider/erişim **try-catch ile guard edilmeli**, aksi halde provider error state'e düşer ve ona bağlı tüm ekran (ör. Profil) `ProviderException` ile kırmızı çöker.
  - Desen: `SupabaseClient? client; try { client = Supabase.instance.client; } catch (_) { client = null; }` → `SupabaseService(client)`. Servis içinde tüm erişimler `_client?.`; auth stream'i yoksa `const Stream<AuthState>.empty()` (StreamProvider'ı error'a düşürmemek için); sign-in/up yoksa `StateError` (UI zaten Türkçe yakalar).
  - **Yeni bir Supabase'e dokunan provider eklerken bu guard'ı UNUTMA** — `supabaseServiceProvider` bir kez bu desenin dışında kaldı ve Profil ekranını çökertti (2026-06-16 cihaz QA).

## Layout / overflow
- **GridView kutucuğunda "BOTTOM OVERFLOWED BY ~2px":** `childAspectRatio` hücre yüksekliğini GENİŞLİĞE bağlar → dar ekranlarda sabit içerik (ikon + N satır metin) birkaç px taşar. Çözüm: `childAspectRatio` yerine **`mainAxisExtent: <sabit px>`** kullan (yüksekliği genişlikten bağımsız, deterministik kılar).

## KGP "Built-in Kotlin" uyarısı (2026-06-16 — araştırıldı, AKSİYON YOK)
- Derlemede `WARNING: ... plugins that apply Kotlin Gradle Plugin (KGP): audio_session, package_info_plus, rive_native, share_plus` çıkıyor. **Bu bir HATA DEĞİL** — Flutter SDK'da `logger.error` ile yazılır ama `throwToolExit` YOK → build durmuyor (kaynak: `flutter/packages/flutter_tools/gradle/.../FlutterPluginUtils.kt` ~599-683). Uyarı app'in kendi Gradle'ını değil, **transitive plugin'lerin yayınlanmış Android kodunu** tarar.
- 4 plugin de **zaten pub.dev'deki son sürümde**; hiçbiri henüz Built-in Kotlin migrasyonu yapmamış (`flutter pub upgrade --dry-run` → "No dependencies would change"). audio_session ← just_audio, rive_native ← rive, package_info_plus ← geolocator ailesi (transitive — elle PINLEME). **Çözüm yukarı-akışta**: paket yazarları migrasyonu yayınlayınca ebeveyni (just_audio/rive vb.) yükselt; transitive'i pinleme.
- Android tarafı zaten doğru: `app/build.gradle.kts` KGP'yi doğrudan uygulamıyor; KGP 2.3.20 / AGP 9.0.1 / Gradle 9.1.0. **Yapılacak bir şey yok** — aylık `flutter pub outdated` ile izle, changelog'da "Built-in Kotlin"/"KGP migration" görünce yükselt.

## Kod kuralları
- Domain enum'ında `IconData` kullanılıyorsa `material.dart` import et (widgets.dart'ta `Icons` yok).
- `const` widget içinde `AppColors.muted/line/goldFaint` (static final) KULLANMA → "Invalid constant". const'u kaldır.
- `// ignore:` direktifi koddan hemen önceki satırda olmalı (araya yorum girmesin).

## İş akışı
- GateGuard (ECC) her yeni dosya `Write`'ını ilk denemede bloklar; **retry geçer**. Mümkünse dosyaları cohesive modüllerde grupla (gate sayısını azaltır).
- **GateGuard ayrıca oturumun İLK `Bash` komutunu da bloklar** (fact-forcing gate) → iki olguyu (kullanıcı isteği + komut ne doğruluyor) sun, sonra aynı komutu tekrar çalıştır.
- IDE diagnostics (PostToolUse) bazen bayat (silinen dosyanın eski hatalarını gösterir) → kesin doğrulama için `flutter analyze` çalıştır.
- **gstack skill'leri (/plan-*-review, /office-hours vb.) burada kısmen geçerli:** proje **git deposu DEĞİL** ve gstack design binary YOK (`DESIGN_NOT_AVAILABLE`). gstack bash preamble'ının çoğu (review-log, telemetry, brain-sync, mockup üretimi) sessizce başarısız/atlanır → asıl işe (analiz + kod) odaklan, ölü seremoniyi atla. AskUserQuestion `dontAsk` modunda reddedilir → kullanıcı `/config` ile `default` moda almalı.

---

## 2026-07-25 — Sürüm 1.0.1 dersleri

### 1. RLS'te "politika ekledim" ≠ "kapı kapandı"
Permissive politikalar **OR'lanır**. `feed_update_admin`'i sıkı yazmak hiçbir şey değiştirmedi çünkü
`init.sql`'den kalma `feed_update_own` hâlâ yürürlükteydi ve yazarın kendi satırında tek başına yetiyordu.
**Kural:** yeni bir kısıt eklerken aynı tablo+komut için var olan TÜM politikaları listele; kapı, en gevşek
politika kadar güçlüdür. Sütun bazlı ayrım gerekiyorsa RLS yetmez — trigger gerekir (kolon grant'i rol
bazlıdır, satır bazlı değil; admin de `authenticated` rolündedir).

### 2. Moderasyon INSERT anını değil, ÖMÜR BOYUNU korumalı
`status`'u INSERT'te kilitlemek yetmedi: yazar onay aldıktan sonra `media_url`'i değiştirip satırı
`approved` bırakabiliyordu. **Kural:** onay durumu olan her tabloda "içerik değişirse yeniden onaya düş"
kuralı olmalı. Yoksa kuyruk yalnız ilk saniyeyi korur.

### 3. İstemciden gelen URL'yi asla doğrulamadan saklama
`media_url` serbest metindi. Saldırgan kendi sunucusunu gösterir, moderatör masum görseli onaylar, sonra
dosya değişir — hiçbir DB yazımı gerekmeden. Ayrıca akışı kaydıran herkesin IP'si saldırgana loglanır.
**Kural:** depolama URL'leri host + yol + sahiplik olarak doğrulanmalı (veya yalnız yol saklanıp URL
istemcide kurulmalı).

### 4. Sırrı query string'e koyma
`?key=${apiKey}` masum görünür, ama `fetch` hataları mesajın içinde TAM URL'yi taşır — ve o mesaj
`String(e)` ile istemciye dönüyordu. **Kural:** kimlik bilgisi başlıkta; ham istisna asla istemciye.

### 5. "Mevcut veriyi koru" refleksi bir uyumluluk yalanına dönüşebilir
Migration'a "eski kayıtlar onaylı sayılsın" yazmak akışı boş bırakmamak için makul görünüyordu. Ama
uygulama tam da moderasyon eksikliğinden reddedilmişti: o kayıtlar hiç incelenmemişti. **Kural:** bir
uyumluluk mekanizması eklerken, geçmiş veriye uyguladığın istisnanın dışarıya verdiğin beyanı çürütüp
çürütmediğini sor.

### 6. `pumpAndSettle` gerçek `dart:io` future'larını beklemez
Ürün koduna `await File.length()` ekleyince widget testi kırıldı; `runAsync`'e geçmek google_fonts'un ağ
erişimini açtığı için başka bir yerden patladı. Doğru çözüm ürünü basitleştirmekti: `lengthSync()` — tek
`stat()` çağrısı, await yok, test jimnastiği yok. **Kural:** test bir API'yi zorlaştırıyorsa önce "bu
gerçekten async olmalı mı?" diye sor.

### 7. Aynı kural iki yoldan uygulanıyorsa ikisini de test et
Telif onayı `CreatePostSheet`'te vardı, `StudioScreen`'de yoktu — iki paralel yayın yolundan biri kuralı
hiç uygulamıyordu. **Kural:** bir politika birden fazla giriş noktasına sahipse, testi "her giriş noktası
aynı kurala tabi" biçiminde yaz (bkz. `test/rights_gate_test.dart`).

### 8. Adversaryal denetim, statik analizin göremediğini görüyor
Bu sürümde bulunan 11 gerçek kusurun **hiçbiri** `flutter analyze` veya testlerle görünmüyordu; çoğu
"kodu okuyup kırmayı dene" ile çıktı, biri (SSRF redirect bypass) yerel iki sunucuyla ampirik olarak
kanıtlandı. **Kural:** güvenlik/uyumluluk yüzeyine dokunan işte, uygulayan ajanın raporuna güvenme —
bağımsız bir mercek koy ve ondan **kırmasını** iste, "kontrol etmesini" değil.

---

## 1.0.1 build 4 dersleri

### 9. Renk rolleri: "zemin mi, ön plan mı" sorusu tasarım değil, tip meselesi
78 kontrast ihlalinin kök nedeni tek bir karışıklıktı: `gold`, `success`, `accent`, `info` SABİT
tanımlanıp hem zemin hem METİN rengi olarak kullanılıyordu. Açık temada metin olarak 1.6–2.5:1
veriyorlardı (AA = 4.5:1) → görünmezdiler. Düzeltme 186 çağrı yerine değil, `app_colors.dart`'a
yapıldı: ön plan rolleri brightness'a göre dönen getter oldu, çağrı yerleri kendiliğinden düzeldi.
**Kural:** yeni bir renk token'ı eklerken önce "bu zeminde mi durur, zeminin ÜSTÜNDE mi" diye sor.
Cevap "ikisi de" ise iki ayrı token gerekiyordur (`gold` + `goldInk`, `dangerSurface` + `onDanger`).
Alfa'lı renkleri ölçmeden önce zemine kompozit et — yoksa ölçüm iyimser çıkar.

### 10. "Geri alınca düşüyor mu" testi, testin kendisinden önemli
Üç regresyon testi de yazıldıktan SONRA düzeltme geçici geri alınıp gerçekten düştükleri
doğrulandı. Kıble testi ilk hâlinde 360×640'ta düzeltme olmadan da geçiyordu — yani hiçbir şey
kilitlemiyordu; gerçekten taştığı 360×560'a çekilince anlamlı oldu. **Kural:** yeşil bir test
kanıt değildir; kanıt, kırmızıya döndüğünü görmektir.

### 11. Test ortamı hatası, testi kararsız yapar — tek koşum yalan söyler
`buildAppTheme` testi tek başına geçip tam pakette rastgele düşüyordu: `google_fonts` fontu
çözemeyip YAKALANMAMIŞ async hata fırlatıyor ve o sırada koşan teste yazılıyor.
`allowRuntimeFetching = false` yalnız ağ bacağını kapatıyor, asset araması kalıyor.
Çözüm: ilgisiz async hatayı `runZonedGuarded` ile kendi zone'unda yut, asıl değişmezi ölç.
**Kural:** kararsızlık şüphesinde paketi arka arkaya en az 4 kez koş; CI `flutter test` çalıştırıyor,
flake build'i rastgele kırar.

### 12. Moderasyon kapısı satırı korur, BAYTLARI korumaz
`feed_posts` üzerindeki RLS + trigger kusursuz çalışıyordu ama `post_media_delete_own` politikası
kullanıcının onaylanmış dosyasını silip AYNI yola yenisini yüklemesine izin veriyordu — veritabanına
hiç dokunulmadığı için guard tetiklenmiyor, `status` `approved` kalıyordu. Tam bypass.
**Kural:** bir kapı "veritabanında zorlanıyor" derken, kapının koruduğu şeyin veritabanı DIŞINDA
bir kopyası var mı diye sor (storage nesnesi, CDN cache, dış URL). Ayrıca yayımlanmış EULA/beyan
metinlerini koda karşı doğrula: `terms.html` yorumlar için pre-moderasyon vaat ediyordu, `comments`
tablosunda `status` kolonu bile yoktu.

---

## 2026-08-03 — Faz A (build 4) dersleri

### 13. Onaylanmış bir plan bile "kanıt" değildir — düzeltmeyi de kök nedene karşı sına
Plan madde 3 için tek satırlık bir düzeltme öneriyordu (`SplashScreen`'de provider doluysa
tekrar push et). Kök neden ajanı bunun **hiç çalışmayacağını** gösterdi: push edilen ekran bir
frame sonra provider'ı `clear()` ediyor, splash 2400 ms'de her zaman `null` okuyor. Aynı ajan
planın iki mekanizma iddiasını daha çürüttü (madde 9'da `.animate().fadeIn()` yakalanan kareyi
etkilemiyormuş; `endOfFrame` tek başına hiçbir şeyi düzeltmezmiş).
**Kural:** keşif fazında doğrulanan şey KÖK NEDENDİR, önerilen düzeltme değil. Düzeltmeyi
uygulamadan önce "bu, zincirin hangi halkasını kesiyor?" sorusunu koda karşı yanıtla. Plan
"reddedilen alternatifler" listeliyorsa bile, önerilen çözümün kendisi hâlâ sınanmamış bir
hipotezdir.

### 14. Kırmızıya dönmeyen test yazıldığı gün silinmeli
Yazdığım dört stüdyo testinden biri ("PNG Kaydet"), düzeltme geri alındığında da GEÇİYORDU —
çünkü `_export` hatayı yutuyor ve gözlenebilir bir çıktı bırakmıyor. Davranışsal assert
bulunamayınca testi **yapısal** bir değişmezle değiştirdim: önizleme tuvali `Scrollable`'ın
DESCENDANT'ı olmamalı. O hâliyle kırmızıya döndü.
**Kural:** bir yolun tek gözlenebilir sonucu yoksa, o yolun dayandığı yapısal değişmezi
kilitle. "Assert edecek bir şey yok" testi atlamanın değil, soruyu değiştirmenin işareti.

### 15. `runAsync` google_fonts'un ağ bacağını açar — `allowRuntimeFetching = false` YETMEZ
Ders 11'in devamı: bayrak yalnız HTTP'yi kapatıyor, asset araması yine YAKALANMAMIŞ async
hata fırlatıyor ve `runAsync` gerçek zamanı açtığı an o sırada koşan teste yazılıyor.
Çözüm, test gövdesini `runZonedGuarded` ile sarıp **yalnız** `GoogleFonts` içeren hatayı
yutmak; `expect` hataları `Completer.completeError` ile aynen yükselmeli, yoksa yeşil test
yalan söyler (bkz. `test/studio_render_offscreen_test.dart` `_fontSafe`).

### 16. Test yüzeyini büyüterek "çözülen" tembel-liste sorunu, kusuru da gizler
`studio_video_test.dart` 400×**2600** kullanıyordu ve yorumu tembel `ListView` sorununu zaten
fark etmişti — ama "butonlar mount olmuyor" diye okuyup yüzeyi büyütmüş. O büyütme, kusuru
doğuran koşulu (**kaydırma**) da yok etmiş; `rights_gate_test` (2500) ve `ugc_safety_test`
(3000) aynı kör noktayı paylaşıyor.
**Kural:** test yüzeyi gerçekçi olmayan bir boyuta çekildiğinde, "bu boyut hangi kullanıcı
davranışını imkânsız kılıyor?" diye sor. Cevap bir davranışsa, o davranış için ayrı ve
gerçekçi yüzeyli bir test gerekir.

---

## 2026-08-03 — Faz B/C dersleri

### 17. Arayüz imzası değişince FAKE'ler derleme zamanında patlar — ve tüm paket düşer
`ISocialRepository.createPost`'a `audioTrackId` eklemek 5 test dosyasını **yükleme
anında** kırdı (test bile koşmadı, "loading ..." satırında düştü). Tek gerçek
uygulama güncellenmişti; 4 fake unutulmuştu.
**Kural:** bir seam arayüzüne parametre eklerken `grep -rn "<son parametre adı>," test/`
ile TÜM implementasyonları çıkar. Fake'i tek bir `test/support/` dosyasında
toplamak bu maliyeti bire indirir (bu turda `RecordingSocialRepository` oraya taşındı).

### 18. Widget testinde "A Timer is still pending" ürün hatası DEĞİLDİR — teardown eksiğidir
Ana Sayfa FAB testleri düştü çünkü `_PrayerStrip` 1 sn'lik `Timer.periodic`
tutuyor ve `flutter_animate`'in `.animate(delay:)` efektleri gecikmeli timer
kuruyor. Navigasyon yapan test geçiyordu (ağaç sökülüyor), yalnız assert eden
testler düşüyordu. Çözüm: önce gecikmeleri boşalt (`pump(3s)`), sonra ağacı sök
(`pumpWidget(SizedBox)`).
**Kural:** sonsuz animasyonu olan ekranda `pumpAndSettle` kullanma; sabit süreli
`pump` + açık teardown kullan.

### 19. Yeni paket eklerken İLK adım kod değil, BUILD
`pro_image_editor` için plan "pub get → build apk → pin kırıldıysa maddeyi geri
al" diyordu ve bu doğru sıraydı: paket compileSdk/minSdk dayatsaydı
`receive_sharing_intent 1.8.1` pini kırılır, tüm entegrasyon çöpe giderdi.
İki paket de (just_audio_background, pro_image_editor) pin'i kırmadı ve APK
derlendi — ama bu ancak ÖLÇÜLDÜĞÜ için biliniyor.
**Kural:** native dokunan paketlerde entegrasyonun ilk adımı derlemedir,
"sonra bakarız" değil.

### 20. Paket varsayılanları depo sözleşmesiyle çelişebilir
`pro_image_editor` varsayılan olarak **JPG** üretiyor; `uploadPostMedia` ise
dosyayı `.png` + `image/png` yazıyor. Hiçbir hata vermez — yalnızca depoda adı
ve MIME'ı yalan söyleyen dosyalar birikir.
**Kural:** üçüncü parti bir üretici (encoder/exporter) eklerken çıktı biçimini
depo/servis sözleşmesine karşı AÇIKÇA doğrula ve bir birim testiyle kilitle;
varsayılana güvenme.
