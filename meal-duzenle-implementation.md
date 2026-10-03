# Meal Düzenle — videodan zaman kodlu meal altyazısı

Proje: `C:\Users\yiit5\Desktop\PROJELER 2\kurandaki mesaj flutter\kurandakimesaj` · dal `release/1.0.1` → yeni dal `feat/meal-duzenle`

## Context

Kullanıcı bir tilavet videosundaki ayetlerin mealini görmek istiyor. Bugün bu iş "Ayet Bul" ekranında yarım duruyor: video tanınıyor ama sonuç bir liste; altyazı yok, elle aralık seçimi yok, "Bağlantı Yapıştır" alanı ise diğer uygulamaların kısıtları yüzünden çalışmıyor.

Hedef: görseldeki tasarımla yeni bir **Meal Düzenle** ekranı. Video paylaş menüsünden ya da galeriden gelir, tilavet tanınır, meal oynatıcının üstünde zaman kodlu altyazı olarak akar, istenirse Reels'e altyazılı yayınlanır.

**Onaylanan kararlar**
1. Bağlantı paylaşılırsa indirme yok; "videoyu kaydet, galeriden seç" yönlendirmesi (App Store 5.2.3).
2. Altyazı oynatıcının üstüne çizilir, Reels'e zaman kodlu yayınlanır. Gömülü mp4 / galeriye kayıt bu planda yok (K1 geçerli).
3. Ses tanıma mevcut Groq Whisper hattında kalır; Edge Function'lar **değişmez**.

**Keşif sonucu:** `ayah-finder-audio` zaten ayet başına `startSec/endSec` döndürüyor; Android `video/*` paylaşımı zaten uygulamaya düşüyor. Yeni paket **yok**, sunucuda tek değişiklik bir migration.

## Varsayılanlar (itiraz yoksa böyle)

- **Renk:** yeni token yok. Nane vurgusu = mevcut `AppColors.success / successSurface / onSuccess`; zemin mevcut tema yüzeyleri. Açık tema ve kontrast testi bozulmaz.
- **Dalga formu:** çubuk yükseklikleri dekoratif, vurgulu bölgeler gerçek (cue aralıkları). Gerçek dalga formu için yükseltme yolu `just_waveform` (`ponytail:` yorumu).
- **"Video kalır":** yayınlayanın dosyası yalnızca silinmez (taşınmaz); kalıcı kopya `post-media`'dadır. Saklananları listeleyen ekran yok.
- **Ayet Bul** yalnız görsel OCR olarak kalır; "Video Seç" kutucuğu Meal Düzenle'ye götürür. Katalog 26 → 27.
- **iOS:** Share Extension kapsam dışı (Xcode gerekir); iOS'ta ekran "Video Seç" ile çalışır.
- **20 MB üstü video:** analiz ve yayın kapalı, elle aralıkla yalnız okuma.
- Elle seçimde zamanlama yaklaşıktır; altyazı satırı ayet numarasını gösterir.
- Alt düğme etiketi maketteki gibi "Meal Edit". Uygulama adı kanonik yazımla "Kur'an'da ki Mesaj".

## Dokunulmaz liste (her ajan prompt'una aynen girer)

`feed_posts_moderation_guard` · `feed_select_visible` / `feed_select_admin` · `is_own_post_media` · `revoke update on profiles` · `BottomBar` `heightFactor: 1` · `receive_sharing_intent` 1.8.1 pini · `test/bottom_bar_height_test.dart` · `launchMode="singleTop"` · `supabase/functions/**` (bu planda diff yok)

## Arayüz sözleşmeleri (paralel ajanlar buna göre kodlar)

```dart
// lib/domain/meal_cues.dart (T1)
const int kMealCueMax = 60;
enum MealCueStyle { standard('default','Varsayılan'), large('large','Büyük'), arabic('arabic','Arapça + Meal');
  final String db; final String label; static MealCueStyle fromDb(String? v); }
class MealCue { const MealCue({required double startSec, required double endSec,
    required int surah, required int ayah, bool approx = false});
  Map<String, Object> toJson();                  // yalnız s,e,su,a — serbest metin YOK
  static List<MealCue> listFromJson(Object? j);  // bozuk girdide [] — ASLA fırlatmaz
}
typedef CueAyah = ({int surah, int ayah, int weight});   // weight = Arapça metin uzunluğu
List<MealCue> buildCues({required List<CueAyah> ayahs,
    List<AyahTimelineEntry> timeline = const [], required double durationSec});
MealCue? cueAt(List<MealCue> cues, double sec);          // start dahil, end hariç
List<String> splitMealPages(String meal, {int maxChars = 140});  // kırpma yok, sayfalama

// lib/data/backend_repositories.dart (T1)
// FeedPost: + List<MealCue> mealCues = const [], MealCueStyle mealCueStyle
// ISocialRepository.createPost(..., List<MealCue>? mealCues, MealCueStyle? mealCueStyle)  // opsiyonel-kolon kalıbı

// lib/data/meal_video_store.dart (T3)
class MealVideoStore { MealVideoStore({required SharedPreferences prefs, Future<List<String>> Function()? roots});
  Future<bool> isOwned(String path);      // kökler: getTemporaryDirectory + Directory.systemTemp; resolveSymbolicLinksSync
  Future<void> discard(String path);      // sahip değilse NO-OP; '$path.png' ve boş üst klasör dahil
  Future<void> markPending(String path);  // prefs 'meal_edit_pending_path'
  Future<void> clearPending();
  Future<void> sweepOrphan({String? except}); }
final mealVideoStoreProvider = Provider<MealVideoStore>(...);

// lib/features/ayah_finder/ (T4)
String sharedRouteFor(SharedAyahInput input);          // imagePath → '/ayah-finder', aksi '/meal-edit'
(IconData, String)? ayahErrorMessage(String? code);    // ayah_error_messages.dart — iki ekran ortak

// lib/features/meal_edit/ (T5, T6, T8, T9)
typedef AyahRangePick = ({int surah, int from, int to});
Future<AyahRangePick?> showAyahRangeSheet(BuildContext c, {int maxAyahs = 60, int? initialSurah});
Future<void> showMealPublishSheet(BuildContext c,
    {required Future<void> Function(String caption) onPublish, String? disabledReason});
class MealSubtitleOverlay extends StatelessWidget { const MealSubtitleOverlay({super.key,
    required ValueListenable<VideoPlayerValue> position, required List<MealCue> cues, MealCueStyle style}); }
class MealTimeline extends StatelessWidget { const MealTimeline({super.key,
    required ValueListenable<VideoPlayerValue> position, required List<MealCue> cues, ValueChanged<Duration>? onSeek}); }

// lib/features/meal_edit/meal_edit_controller.dart (T7)
enum MealEditPhase { idle, analyzing, ready, needsManual }
class MealEditState { String? videoPath; int loadSeq; MealEditPhase phase; String? errorCode; AyahRange? range;
  List<MealCue> cues; MealCueStyle style; double durationSec; bool tooLarge, linkShared, publishing, published;
  bool get canPublish; }
class MealEditController extends Notifier<MealEditState> {
  Future<void> loadVideo(String path); Future<void> pickVideo(); Future<void> analyze();
  Future<void> setManualRange({required int surah, required int from, required int to});
  void setDuration(double sec); void setStyle(MealCueStyle s); void showLinkHint();
  Future<void> publish({required String caption}); }
final mealEditProvider = NotifierProvider.autoDispose<MealEditController, MealEditState>(MealEditController.new);
// Silme `ref.onDispose` içinde: published değilse store.discard. Widget dispose'unda provider'a DOKUNULMAZ.
```

`buildCues` kuralları: çapa = aralıktaki bir ayete düşen timeline girdisi (timeline monoton **değildir**, zaman sırası korunur) · çapasız ayetler komşu çapalar arasına ağırlıkla dağılır ve `approx` olur · hiç çapa yoksa `[0, süre]` bölünür · her cue bir sonrakinin başında biter. Meal metni cue'da taşınmaz; iki ekranda da `surahAyahsProvider`'dan (`quran_screens.dart:53`) çözülür.

## Görevler (her biri önce-kırmızı test → uygulama)

### Dalga 1 — paralel, dosya sahipliği ayrık

| # | Amaç | Sahip olduğu dosyalar | Önce-kırmızı testler |
|---|---|---|---|
| T1 | Cue modeli + veri katmanı | `lib/domain/meal_cues.dart`, `lib/data/backend_repositories.dart`, `test/meal_cues_test.dart`, `test/feed_post_meal_cues_test.dart`, `test/support/recording_social_repository.dart`, `test/support/fake_ayah_finder_repository.dart` (yeni), `test/repository_seam_test.dart`, `test/ugc_safety_test.dart`, `test/moderation_queue_test.dart` (yalnız fake imzası) | çapasız aralık ağırlıkla dağılır · çapalı ayet timeline başında başlar · geri dönen timeline sırayı korur · cue'lar çakışmasız, ayet düşmez · `cueAt` sınırları · `splitMealPages` kelime kaybetmez · `toJson` yalnız s,e,su,a · bozuk `meal_cues` akışı düşürmez · `createPost` cue+stili iletir |
| T2 | Migration | `supabase/migrations/20261003120000_meal_cues.sql` | SQL sondaları dosyada yorum olarak (aşağıda) |
| T3 | Dosya yaşam döngüsü | `lib/data/meal_video_store.dart`, `test/meal_video_store_test.dart` | kök dışı dosya asla silinmez · `..` ile çıkan yol sahipli değil · sahipli dosya `.png` ve boş klasörle silinir · `sweepOrphan` bekleyeni siler, `except`'e dokunmaz |
| T4 | Ayet Bul sadeleştirme | `lib/features/ayah_finder/ayah_finder_controller.dart`, `ayah_finder_screen.dart`, `ayah_error_messages.dart` (yeni), `test/ayah_finder_url_test.dart` (silinir), `test/ayah_finder_controller_test.dart`, `test/ayah_finder_error_view_test.dart` | Bağlantı Yapıştır alanı yok · Video kutucuğu `/meal-edit`'e gider · `sharedRouteFor` yönleri · her hata kodu kendi Türkçe mesajı |
| T5 | Elle aralık seçici | `lib/features/meal_edit/ayah_range_sheet.dart`, `test/ayah_range_sheet_test.dart` | arama sureyi süzer · bitiş < başlangıç onay kapalı · üst sınır aşımı onay kapalı + nedeni · onay seçimi döndürür |
| T6 | Yayın sayfası + telif kapısı | `lib/features/meal_edit/meal_publish_sheet.dart`, `test/meal_publish_sheet_test.dart`, `test/rights_gate_test.dart` | telif işaretsizken yayın kapalı (üçüncü yayın yolu, aynı kural) · açıklama `onPublish`'e ulaşır · hata gösterilir, düğme yeniden açılır · `disabledReason` varken kapalı |

T4'te silinenler: `_LinkField` (L213-381), `fromUrl`, `normalizeAyahUrl`, `fromVideo*`, `_videoPending`, `_RangeHeader`, `_TimelineCard`, bağlantı hata kodları. `_consumeInitialInput` yalnız `imagePath` doluysa tüketir.

T2 içeriği: `feed_posts.meal_cues jsonb` + `meal_cue_style text` · CHECK `meal_cues is null or (kind='video' and is_valid_meal_cues(meal_cues))` (dizi, 1..60 öğe, tam dört anahtar, `s>=0`, `e>s`, `e<=7200`, `su` 1..114, `a` 1..286) · ayrı `feed_posts_meal_cues_lock` BEFORE UPDATE trigger'ı (istemci cue'ları yayın sonrası değiştiremez, 42501). Guard fonksiyonu **yeniden tanımlanmaz**. İdempotent kalıp: `20260725130000_reels_kind.sql`.

### Dalga 2 — paralel

| # | Amaç | Bağımlı | Sahip olduğu dosyalar | Önce-kırmızı testler |
|---|---|---|---|---|
| T7 | Controller | T1, T3 | `meal_edit_controller.dart`, `test/meal_edit_controller_test.dart` | <20 MB analiz → aralık+cue · >20 MB'ta repo hiç çağrılmaz · bulunamadı/hata elle seçime düşer · geç gelen analiz elle seçimi ezmez · kapanınca sahipli video silinir · yayından sonra silinmez · aynı yol yeniden yüklenince silinmez · yayın `kind=video` + cue + stil ile `createPost` çağırır |
| T8 | Altyazı bindirme | T1 | `meal_subtitle_overlay.dart`, `test/meal_subtitle_overlay_test.dart` | cue içindeyken meal + ayet no görünür · cue dışında boş · Arapça stilde RTL · uzun meal sayfalanır · 320 px / 1.3 ölçekte taşma yok |
| T9 | Zaman çizelgesi + dalga formu | T1 | `meal_timeline.dart`, `test/meal_timeline_test.dart` | etiketler doğru · kaydırıcı `onSeek`'i doğru süreyle çağırır · süre 0'ken kapalı |
| T10 | Paylaşım yönlendirme + katalog | T3, T4 | `lib/app/app.dart`, `lib/features/onboarding/onboarding_screens.dart`, `lib/app/feature_catalog.dart`, `lib/features/home/home_screens.dart`, `test/share_cold_start_test.dart` | soğuk başlatmada video → Meal Düzenle · bağlantı → Meal Düzenle · görsel → Ayet Bul · katalogda `/meal-edit` tekil |
| T11 | Moderasyon kartında cue özeti | T1 | `lib/features/moderation/moderation_screen.dart`, `test/moderation_queue_test.dart` | cue'lu bekleyen gönderide altyazı ayetleri listelenir |

T10 ayrıntısı: iki push noktası `sharedRouteFor` kullanır; zaten o rotadaysa push edilmez; `getInitialMedia` sonrası `sweepOrphan(except: ilk yol)`; `'26 özelliğin tamamı'` metni `kFeatures.length`'ten üretilir.

### Dalga 3 — paralel

| # | Amaç | Bağımlı | Sahip olduğu dosyalar | Önce-kırmızı testler |
|---|---|---|---|---|
| T12 | Ekran + rota | T4–T9 | `meal_edit_screen.dart`, `lib/app/router.dart` (tek satır), `test/meal_edit_screen_test.dart` | boşta galeri düğmesi · analizde "Analiz Ediliyor…" hapı · aralık yokken kesikli kutu metni · hazır değilken alt düğme kapalı · bağlantıda yönlendirme, indirme çağrısı yok · >20 MB'ta yayın nedeniyle kapalı · hata kodu Türkçe mesaj |
| T13 | Reels'te altyazı | T1, T8 | `lib/features/community/community_screens.dart`, `test/reel_caption_test.dart` | cue varken sabit meal'e düşülmez · cue yokken eski davranış |
| T14 | `findFromUrl` kaldırma | T4, T7 | `lib/data/backend_repositories.dart`, `test/support/fake_ayah_finder_repository.dart` | `grep findFromUrl\|normalizeAyahUrl\|ayahLink lib test` boş |

T12 ekran sırası (maket): marka satırı (geri · `إقرأ` karosu · ad · slogan · (i)) → başlık → video kartı ("Video Yüklendi" rozeti, oynat, süre, tam ekran) → "Yapay Zeka Analizi" kartı + durum hapı → `MealTimeline` → "Ayet Aralığını Manuel Seç" → "Altyazı Tipi" → "Seçilen Ayet Aralığı" → "Meal Edit". Oynatıcı kalıbı `studio_screens.dart:226-238`. Testlerde `pumpAndSettle` yok (ders 18).
T13: overlay `VideoProgressIndicator` ile aynı koşulda (`community_screens.dart:806`); `_initVideo/_releaseVideo/didUpdateWidget/dispose` gövdelerinde diff yok.

### Dalga 4 — seri

- **T15 Belgeler:** `PROJECT_MEMORY.md` (Active Context + Karar Günlüğü), `CLAUDE.md` (27 özellik, Meal Düzenle), `STORE_SUBMISSION.md` ve `docs/APP_REVIEW_RESPONSE.md` ("bağlantı" ifadeleri), gerekiyorsa `tasks/lessons.md`.

## Skill ve ajan eşlemesi (`SKILL.md` kısa listesinden)

Uygulayıcı ajanlar varsayılan Workflow ajanıdır ve prompt'larının ilk adımı ilgili skill'i **Skill aracıyla çağırmaktır**; inceleyiciler `agentType` ile gelir. Tüm ajanlar `model: 'sonnet'` (Sonnet 5.5).

| İş | Skill | İnceleyici ajan |
|---|---|---|
| Tüm görevler (kırmızı-önce) | `superpowers:test-driven-development` · `flutter-add-widget-test` | `ecc:tdd-guide` kuralları prompt'ta |
| T1, T7 mimari/Notifier | `flutter-apply-architecture-best-practices` · `ecc:dart-flutter-patterns` | `ecc:flutter-reviewer` |
| T2 migration | `ecc:database-migrations` · `ecc:postgres-patterns` · `ecc:security-review` | `ecc:database-reviewer` · `ecc:security-reviewer` |
| T3 silme güvenliği, hata yolları | `ecc:error-handling` | `ecc:silent-failure-hunter` |
| T4, T14 ölü kod | `ecc:refactor-clean` | `ecc:refactor-cleaner` (yalnız `ayah_finder`) |
| T5, T6, T8, T9, T12 arayüz | `mobile-design` · `flutter-build-responsive-layout` · `flutter-fix-layout-issues` · `flutter-animations` · `ecc:make-interfaces-feel-better` | `ui-ux-designer` · `ecc:flutter-reviewer` |
| T10 yönlendirme | `flutter-setup-declarative-routing` | `mobile-developer` (singleTop, soğuk başlatma) |
| Her dalga sonu | `ecc:flutter-build` | `ecc:dart-build-resolver` |
| Son inceleme | `ecc:flutter-review` · `/code-review` · `ecc:quality-gate` | `ecc:code-reviewer` · `ecc:pr-test-analyzer` |
| Emülatör | `qa` · `superpowers:verification-before-completion` | ana döngü + adb |
| T15 | `docs-writing` · `ecc:update-docs` | — |

**Kullanma:** `ecc:refactor-cleaner`'ı `studio_screens.dart` / `community_screens.dart` üzerinde · video render skill'leri (`remotion*`, `ecc:manim-video`) · `ecc:orch-build-mvp` · yeni paket ekleyen her şey.

## Yürütme

**Adım 0 (ana döngü):** dal `feat/meal-duzenle` · bu planı proje köküne `meal-duzenle-implementation.md` olarak yaz · `tasks/todo.md` başına `## Meal Düzenle (2026-10-03)` bölümü (T1–T15 onay kutuları, mevcut biçim) · `tasks/lessons.md` oku. Commit yalnız istenirse.

**Adım 1 (Workflow, tüm ajanlar Sonnet 5.5):**
```
phase Dalga 1: parallel(T1..T6)   → kapı: dart analyze + ilgili testler, kırıksa dart-build-resolver döngüsü
phase Dalga 2: parallel(T7..T11)  → kapı
phase Dalga 3: parallel(T12..T14) → kapı
phase İnceleme: parallel(flutter-reviewer, security-reviewer, database-reviewer,
                         silent-failure-hunter, pr-test-analyzer)
              → her bulgu için çürütmeye çalışan doğrulayıcı → doğrulananları düzelten ajan → kapı
phase Son kapı: dart analyze 0 · flutter test ×4 (ders 11) · flutter build apk --debug
```
Dalgalar arası bariyer gerçek bağımlılık (sözleşmeler yukarıda). Ajan kuralları: yalnız sahip olduğu dosyalara yazar, yalnız kendi test dosyasını koşar, kırmızı koşum çıktısını raporlar, dokunulmaz listeye uyar. `pr-test-analyzer` her yeni testin düzeltme geri alınınca kırmızıya döndüğünü sınar (ders 10).

**Adım 2 (ana döngü):** migration'ı üretime uygula (`npx supabase db push`, REF `uytqxgcbohdlwwxemgyy`) — istemciden **önce**; SQL sondalarını koş.

**Adım 3:** emülatör testi (aşağıda) → T15 → `tasks/todo.md` Review bölümü.

## Doğrulama

**Otomatik:** `dart analyze` 0 · `flutter test` art arda 4 kez yeşil · `flutter build apk --debug` · dokunulmaz dosyalarda `git diff` boş · `supabase/functions` diff boş.

**SQL sondaları (kullanıcı oturumu):** fazladan anahtarlı cue → 23514 · `su=115` → 23514 · geçerli ekleme `pending` · yazarın `meal_cues` güncellemesi → 42501 · onaylı satırda `caption` değişince `pending`.

**Android emülatör** (`flutter run --dart-define-from-file=env.json`, demo hesap; PowerShell'den):
```
adb push tilavet.mp4 /sdcard/Movies/tilavet.mp4
adb shell content query --uri content://media/external/video/media --projection _id:_display_name
adb shell am start -n com.kurandakimesaj.app/.MainActivity -a android.intent.action.SEND -t video/mp4 -d content://media/external/video/media/ID --eu android.intent.extra.STREAM content://media/external/video/media/ID --grant-read-uri-permission
adb shell am start -n com.kurandakimesaj.app/.MainActivity -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://example.com/reel/abc"
adb shell run-as com.kurandakimesaj.app find cache -name "*.mp4*"
```

| # | Senaryo | Beklenen |
|---|---|---|
| S1 | Soğuk başlatma + <20 MB tilavet videosu paylaşımı | Meal Düzenle açılır, analiz biter, aralık dolar, oynatınca altyazı zamanla değişir |
| S2 | Yayınlamadan geri | `find` boş (video silindi) |
| S3 | Ekran açıkken ikinci video | İkinci ekran yığılmaz, önceki dosya silinir |
| S4 | Bağlantı paylaşımı | Yönlendirme kartı, analiz başlamaz |
| S5 | >20 MB video | Analiz çağrılmaz, elle seçim, yayın nedeniyle kapalı |
| S6 | Tilavetsiz video | "Bulunamadı" → elle aralık → yaklaşık altyazı |
| S7 | Telif onayı + Reels'e Yayınla | "İncelemede"; Reels'te zaman kodlu altyazı; `find` dosyayı gösterir; `feed_posts.meal_cues` dolu, `status=pending` |
| S8 | Ekran açıkken `force-stop`, sonra açılış | Açılışta yetim dosya silinir |
| S9 | Galeriden seçip geri | `cache/<uuid>/` klasörü de silinir |
| S10 | Görsel paylaşımı | Ayet Bul açılır |

Her senaryo ekran görüntüsüyle kayda geçer. **Ön koşul:** 20 MB altı gerçek bir tilavet videosu ve 20 MB üstü herhangi bir video (yoksa yürütme sırasında istenir).

## Riskler

- **Kullanıcının kendi dosyasını silmek:** eklenti bazı URI'lerde orijinal yolu döndürür → `isOwned` kapısı + T3 birim testleri.
- **Moderasyon:** cue'lar yayın sonrası kilitli (ayrı trigger) + moderasyon kartında özet; guard'a dokunulmaz.
- **Dini doğruluk:** uzun meal kırpılmaz, sayfalanır; meal her zaman yerel otoriter veriden gelir.
- **Dağıtım sırası:** migration istemciden önce.
- **Paralel `flutter test` çakışması:** ajanlar yalnız kendi dosyasını koşar; dalga kapısı seri koşar.
- **Tanıma isabeti:** Groq genel model; S1/S6 sonuçları kayda geçer, yetersizse Tarteel barındırma ayrı plan.

## Kapsam dışı

Gömülü mp4 dışa aktarım ve galeriye kayıt · iOS Share Extension · bağlantıdan indirme · Tarteel barındırma · kelime düzeyi zaman damgası · sunucudaki `postUrl` dalının silinmesi (eski istemciler kullanıyor) · saklanan videolar listesi.

## Uygulama sonrası sapmalar (2026-10-03)

Plan "sıfır native" diyordu; emülatör testi bunu değiştirdi.

- **`MainActivity.sanitizeShareIntent` (native, plan dışı):** Dosyalar uygulamasından paylaşımda mevcut bir çökme vardı (eklenti ExternalStorage URI'sinde ham yol döndürüyor) ve niyetteki veri URI'si "Page Not Found" açıyordu. İkisi de eklentilere ulaşmadan burada düzeltiliyor. Manifest ve eklenti sürümü değişmedi.
- **Oynat düğmesi:** altyazı varken alt satıra iner (ortadaki büyük düğme yalnız altyazı yokken).
- **Durum hapı:** elle seçimde "Elle Seçildi", 20 MB üstünde "Analiz Yok" (yapay zekânın yapmadığı iş "Tamamlandı" diye gösterilmez).
- **Ayet Bul:** ekran açıkken gelen görsel paylaşımını da dinler (yönlendirme kuralının gerileme düzeltmesi).
- **Yayınlanan videonun yerel kopyası:** taşınmaz, önbellekte kalır (planın varsayılanı). Aynı adla yeni bir video paylaşılırsa üzerine yazılır.
- **Yetim yükleme:** `createPost` başarısız olursa yüklenen mp4 `post-media`'da kalır (istemcinin silme yetkisi yok; stüdyodaki mevcut davranışla aynı).
