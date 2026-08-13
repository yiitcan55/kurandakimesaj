# Kur'an'da ki Mesaj — 9 Maddelik Düzeltme & Özellik Planı

**Tarih:** 2026-08-03 · **Sürüm:** 1.0.1+4 → build 4 · **Proje:** `kurandakimesaj`

---

## Context

Uygulama App Store'da **Guideline 1.2 (UGC)** ile reddedildi; 1.0.1 yanıtı hazır ama **build 3 bozuk** (alt bar tüm ekranı kaplıyordu, `b7cc67c` ile düzeltildi). Kullanıcı şu an redde yanıt vermek ve **build 4** almak üzere.

Bu sırada cihaz kullanımında 9 sorun/eksik tespit edildi. Keşifte **hepsinin kök nedeni kodda doğrulandı** — üçü inceleyicinin göreceği kırık akış, altısı özellik eksiği.

**En kritik bulgu:** "Reels'e Yayınla" butonu **çalışmıyor** (madde 9). Apple'a "her gönderi moderasyondan geçer" derken gönderi hiç yayınlanamıyor — bu hâliyle gönderirsen Guideline 2.1 riski var.

**Ana ilke:** Build 4'e yalnız **sıfır migration / sıfır native / sıfır yeni paket** olan düzeltmeler girer. Moderasyon kapısı (`feed_posts_moderation_guard` trigger + `feed_select_visible` RLS) **hiçbir fazda değişmez**.

---

## Faz Planı ve Risk

| Faz | Maddeler | Native/DB | Neden burada |
|---|---|---|---|
| **A — build 4** | **9**, **8**, **3**, 7-boş-durum | Yok | İnceleyicinin göreceği kırık akışlar. Saf Dart. |
| **B — 1.0.2** | **1**, **4**, **2** | 2 → manifest + Info.plist | Madde 2 yeni arka plan yeteneği açıyor; redde yanıt sırasında ikinci inceleme konusu istemiyoruz. |
| **C — 1.0.2 geç / 1.0.3** | **7-tam**, **6**, **5** | 3 migration + 1 büyük paket | Üçü de yeni UGC/telif yüzeyi. DM açmak, engellemenin mesajlarda da kanıtlanmasını gerektirir. |

**Karar:** Build 4 = madde 9 + 8 + 3 + tek satır boş-durum metni. Başka hiçbir şey.

---

# FAZ A — Build 4 (bugün, tek PR)

## Madde 9 — `!debugNeedsPaint` çökmesi (EN KRİTİK)

**Kök neden:** `studio_screens.dart:207-214` `_renderPng()` → `_previewKey` → `RepaintBoundary` (`:372-373`) → `build()`'in **tembel `ListView`'inin [1]. çocuğu** (`:492`). "Reels'e Yayınla" [8]. çocuk (`:663`). 9:16 önizleme ekran genişliğinin ~1.78 katı → butona ulaşmak için önizlemeyi **zorunlu** kaydırmak gerekiyor. `RenderSliverMultiBoxAdaptor.paint` görünür alan dışındaki çocuğu layout eder ama **boyamaz** → `_needsPaint == true` → `toImage()`'ın `assert(!debugNeedsPaint)`'i patlar.

**İki ek tetikleyici:** (2) `_publish:263` / `_export:218` `setState` ile `toImage()` **aynı mikro görevde** — bekleyen kare koşmadı. (3) `:492-494` `.animate().fadeIn()` her build'de yeni efekt üretiyor → yakalanan kare yarı saydam olabilir.

> Release'de assert derlenmez ama `layer! as OffsetLayer` cast'i patlar / bayat kare gider → **debug'a özel değil.**

**Düzeltme — 4 küçük edit, hepsi `lib/features/studio/studio_screens.dart`:**

1. **Önizlemeyi tembel listeden çıkar.** `:491-495` (`Center(_buildPreview()).animate().fadeIn()` + `SizedBox(20)`) silinir; `AppHeader` (`:464`) ile `Expanded(ListView)` (`:465`) arasına `Flexible > Padding > FittedBox > SizedBox(width: 360, height: _storyMode ? 640 : 360)` olarak taşınır. Neden `FittedBox` + sabit tuval: `pixelRatio: 3.0` ile çıktı **her cihazda tam 1080×1920 / 1080×1080** olur (bugün tuval ekran genişliği → aynı 22pt farklı telefonda farklı büyüklükte çıkıyor). `FittedBox` yalnız gösterimi küçültür, boundary katmanı 360×640'ta kaydedilir.
2. **Fade'i sil** — kozmetik, yakalamayı bozuyor.
3. **`_renderPng()`'in ilk satırı:** `await WidgetsBinding.instance.endOfFrame;` — projede bu API hiç kullanılmıyordu, eksik halka buydu.
4. **`pixelRatio: 3.0` aynen kalır** — (1) sayesinde artık deterministik. (1)'i yapıp bunu düşünmezsen çözünürlük cihaza göre değişmeye devam eder.

`_buildPreview()` içindeki `AspectRatio` (`:374-375`) gereksizleşir, kaldırılabilir.

**Mimari sapma — ŞİMDİ REFACTOR ETME.** `StudioScreen` tüm durumu `setState` ile View'da tutuyor (CLAUDE.md'ye aykırı). Çökme yukarıdaki 4 editle **kökünden** gidiyor; Notifier'a taşımak inceleyicinin test edeceği ekranda büyük diff demek. Refactor madde 6 ile birlikte gelir.

**Regresyon testi — mevcut 92 testin neden kaçırdığı:** `test/studio_video_test.dart:143` `setSurfaceSize(Size(400, 2600))` kullanıyor. 2600px'te hiçbir şey kaydırılmıyor → önizleme daima boyalı. `:294-300`'deki test PNG yolunu **gerçekten sürüyor** ama asla ekran-dışı senaryoda değil.

Yeni `test/studio_render_offscreen_test.dart`:
- `setSurfaceSize(Size(390, 760))` — **gerçek telefon yüzeyi, testin tek ayırt edici noktası bu**
- `drag(Scrollable, Offset(0, -1400))` → telif checkbox → `_tapPublish` (harness `studio_video_test.dart:139-214`'ten kopyalanır)
- `expect(tester.takeException(), isNull)` ← assert'i yakalayan satır
- `expect(repo.uploads, [false])` + PNG imzası `[0x89,0x50,0x4E,0x47]` + IHDR genişliği (byte 16..19 BE) `== 1080`
- İkinci case: aynı kaydırmadan sonra `Key('studio_export_png')` → `takeException()` null (`_export` aynı kökten besleniyor)

**Gerekli harness eklemesi:** `_RecordingSocialRepository` (`studio_video_test.dart:39-53`) bugün baytları atıyor → `Uint8List? lastBytes` alanı eklenmeli. Madde 6'nın PNG-format testini de bedavaya getirir.

**KIRMIZI-ÖNCE ADIMI (atlanmamalı):** Testi **önce düzeltmesiz** çalıştır. `'!debugNeedsPaint': is not true` ile **düşmeli**. Düşmüyorsa yüzeyi 390×640'a indir / drag mesafesini artır. Düşmeyen regresyon testi regresyon testi değildir.

---

## Madde 8 — Profilde gönderiler gözükmüyor

**Kök neden A (asıl):** `backend_repositories.dart:312` `select('id, kind, thumbnail_url, caption, created_at')` — ama `thumbnail_url` **hiç yazılmıyor** (`createPost` payload'ı `:498-509` yalnız `media_url`/`video_url`/`template_id` yazar) ve `media_url` select listesinde bile yok → `community_screens.dart:2343` `thumb` daima null → her kare boş `ColoredBox` + ikon (`:2354-2357`). Kullanıcı "Gönderi: 3" sayacını görüyor ama ızgarada boş yeşil kutular.

Reels tarafı bunu `FeedPost.fromMap:140`'taki `m['thumbnail_url'] ?? m['media_url']` fallback'iyle çözmüş. **Fallback'i profilde tekrarlamak yerine aynı fonksiyondan geç** — düzeltme tek yerde kalır:

- `backend_repositories.dart:306-320` → dönüş `Future<List<FeedPost>>`, `select('*')`, `FeedPost.fromMap(r, myId: null)`. (`fromMap` `profiles`/`likes` yokken zaten defansif: `:122-128`, `:136`.)
- `community_screens.dart:2148` → `List<FeedPost> _posts = [];` · `:2182` cast · `:2343` → `_posts[i].thumbnailUrl` (fallback bedava)
- **Bonus 4 satır:** `post.status == 'pending'` ise kare köşesine "İncelemede" rozeti — "gönderim nerede" şikâyetini doğrudan karşılar.

**Kök neden B:** `:317-319` `catch(_) { return []; }` → RLS reddi / ağ hatası "Henüz gönderi yok" diye görünüyor.
- `getUserPosts`'tan `try/catch` **kaldırılır** (moderasyon dörtlüsündeki `:386-388` kalıbı: hata çağırana yayılır)
- `community_screens.dart:2158-2186` `_load()` → `try/catch` + `String? _error`; `:2325-2329`'da hata varsa "Gönderiler yüklenemedi." + "Tekrar dene", yoksa "Henüz gönderi yok"

**C — RLS'e DOKUNMA.** `feed_select_visible` = `(status='approved' and is_hidden=false) or auth.uid()=author_id` doğru davranıyor: kendi pending'ini görürsün, başkasının onaysızını görmezsin. Bu tam olarak 1.2 vaadidir.

**Test — `test/profile_posts_test.dart`, iki assert:**
```
fromMap({'id':'1','media_url':'https://x/a.png'}).thumbnailUrl == 'https://x/a.png'
fromMap({...,'thumbnail_url':'https://x/t.png'}).thumbnailUrl == 'https://x/t.png'
```

---

## Madde 3 — Instagram/TikTok paylaşımı açılmıyor

**Kök neden (kullanıcı semptomu doğruladı):** `app.dart:106` `push('/ayah-finder')` t≈0'da çalışıyor; `onboarding_screens.dart:31` `context.go('/home')` t=2400ms'de **tüm yığını değiştiriyor** → push edilen rota siliniyor, kullanıcı ana sayfada kalıyor. Router'da hiç `redirect` yok. **Aynı hata `app.dart:82-86` widget deep-link'inde de var.**

**Düzeltme — en kısa diff, sıfır yeni durum.** `sharedAyahInputProvider` **zaten var** (`ayah_finder_controller.dart:113`), **zaten tek seferlik tüketiliyor** (`ayah_finder_screen.dart:45-47`). Yeni provider gerekmez.

`lib/features/onboarding/onboarding_screens.dart:27-32` — `go('/home')` sonrasına:
```
// `go` yığını TAMAMEN değiştirir → _onShared'ın t=0'da push ettiği rota silinir.
// Soğuk başlatmada paylaşılan içeriği burada geri koyuyoruz (push: geri tuşu
// ana sayfaya döner, `go` olsaydı uygulamadan çıkardı).
if (ref.read(sharedAyahInputProvider) != null) context.push('/ayah-finder');
```
`_onShared`'daki push **kalır** — sıcak başlatmada (uygulama açıkken paylaşım) çalışan tek yol odur.

**Reddedilen:** router-level `redirect` — go_router redirect push edemez (yalnız değiştirir), yine "bekleyen rota" durumu tutmak gerekirdi.

**`singleTop` → `singleTask` YAPMA.** Plugin README'si isteyebilir ama: tek-Activity'li Flutter'da `singleTop` `onNewIntent`i doğru teslim ediyor; `android:taskAffinity=""` (`AndroidManifest.xml:17`) ile birleşince `singleTask` recents davranışını değiştirir ve `home_widget` deep-link'ini bozabilir; ayrıca madde 2 (`audio_service`) `singleTop` istiyor. Cihaz testinde **sıcak** paylaşım kırık çıkarsa o zaman değiştir.

**1.0.2'de genelleme (build 4'e girmez — yeni global durum):** `pendingDeepLinkProvider` ile `_onShared` + `_onWidgetClick` ikisini birden kapat (~10 satır).

**Test — `test/share_cold_start_test.dart`:** gerçek router yerine 3 stub rotalı küçük `GoRouter` (`/splash` → gerçek `SplashScreen`, `/home` + `/ayah-finder` → `Placeholder`). `sharedAyahInputProvider` set → pump 2500ms → `find.byKey(Key('stub_ayah_finder'))` bulunmalı (**bugün bulunamaz**). İkinci case: paylaşım yokken `/home`'da kalmalı.

---

## Madde 7-kısmi — Mesajlar boş-durum dürüstlüğü

Sekme şu an **çıkmaz sokak**: `conversations`'a insert eden hiçbir kod yok (`createConversation` → 0 eşleşme), kullanıcı arama yok, FAB yok → liste kalıcı boş. İnceleyicide "yarım özellik" (4.2) refleksi riski.

**Build 4'e giren tek şey:** `community_screens.dart:2056-2061` boş-durum metni dürüstleştirilir + ölü kod silinir (`:2436-2438` `_offlineMessages`, `_sendOffline`, build'deki `conversationId == null` dalı — tek çağıran `:2079` her zaman id geçiyor, grep ile doğrulandı).

**Sekmeyi KALDIRMA.** `BottomBar` ve `test/bottom_bar_height_test.dart` build 3'ü bozan bug'ın kilidi.

---

## Faz A Doğrulama Kapısı

```bash
flutter analyze                    # 0 sorun
flutter test                       # 92 mevcut + 3 yeni = 95/95
```
**Cihazda (Samsung SM S731B) zorunlu:**
1. Stüdyo → metin yaz → **aşağı kaydır** → "Reels'e Yayınla" → **çökme YOK**, "İncelemeye alındı" mesajı
2. Aynı akış "PNG Kaydet" ile
3. Profil → gönderi ızgarasında **görseller görünüyor** (boş yeşil kutu değil)
4. Instagram'dan bir gönderi paylaş → **uygulama kapalıyken** → Ayet Bul ekranı açılıyor
5. Mesajlar sekmesi → dürüst boş durum metni

---

# FAZ B — 1.0.2 (native içerir, ayrı TestFlight turu)

## Madde 2 — Arka plan ses + bildirim medya çubuğu

**Paket:** `just_audio_background` (`audio_service`'in tam `BaseAudioHandler` mimarisi **gerekmiyor** — tek oynatıcı `device_services.dart:283-299`, tek kaynak, kuyruk yok). `flutter pub add` sonrası **tam sürüme pinle** (`receive_sharing_intent` dersi).

**Kullanıcının gerçek isteği:** "durdurma, bildirimden kontrol ettir" → `quran_screens.dart:404`'teki `_player.stop()` **SİLİNİR**. Bugünkü kod zaten doğru çalışıyor (`:360-365` yorumu bir kez kırılıp düzeltildiğini anlatıyor); sorun stop'un çalışmaması değil, **çalışması**.

**Dart:**
- `app.dart` `bootstrap():26-27` → `JustAudioBackground.init(androidNotificationChannelId: 'com.kurandakimesaj.app.channel.audio', androidNotificationChannelName: 'Tilavet', androidNotificationOngoing: true, androidStopForegroundOnPause: true)`
- `device_services.dart:286-294` → `playUrl(String url, {required String title})`; `setUrl` yerine `setAudioSource(AudioSource.uri(..., tag: MediaItem(...)))`. **`import ... show MediaItem;` ŞART** — paketin `AudioService` sınıfı bu dosyadaki kendi `AudioService`'inle isim çakışır.
- `quran_screens.dart:137,:156` → `title: '${surahName}, ${ayah}. ayet'`
- `quran_screens.dart:395-406` → `stop()` sil + gerekçe yorumu

**TTS ses odağı (4 satır, aynı fazda):** `services.dart:495-518` `TtsService({this.onSpeakStart})`, `speak()` başında `await onSpeakStart?.call();`; `repositories.dart:187-192` → `TtsService(onSpeakStart: () => ref.read(audioServiceProvider).pause())`. Tilavet artık ekran dışında da çalacağı için üst üste binme olasılığı bugünkünden çok yüksek.

**Android** (`AndroidManifest.xml`): `xmlns:tools` ns + `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (targetSdk 34+ şart) izinleri + `com.ryanheise.audioservice.AudioService` service (`foregroundServiceType="mediaPlayback"`, `MediaBrowserService` intent-filter) + `MediaButtonReceiver`. `launchMode="singleTop"` **korunur**.

**MainActivity.kt** (4 satırlık dosya) → `class MainActivity : AudioServiceActivity()`. README'nin "manifest'te activity adını değiştir" yolunu **kullanma**: `.MainActivity` adı widget provider'ları ve deep-link filtreleriyle bağlı.

**minSdk etkisi yok** (audio_service 21, projede 23). **iOS:** `Info.plist` → `UIBackgroundModes: [audio]`.

**Doğrulama:** (1) `mediaTitleFor(surahName, ayah)` yardımcısını public yap → tek assert birim testi. (2) Cihaz: tilavet başlat → geri tuşu → ses devam ediyor mu → ana ekrana çık → bildirimde oynat/duraklat → iOS kilit ekranı → duraklatınca bildirim kaydırılabilir mi.

## Madde 1 — Ana sayfa sol-alt AI butonu

`HomeScreen`'in **kendi** `Scaffold`'una (`home_screens.dart:303`) `floatingActionButton` + `FloatingActionButtonLocation.startFloat`. `HomeShell` (`:48-56`) ve `BottomBar`'a **hiç dokunma** (`heightFactor: 1` hücresi build 3 bug'ının düzeltmesi).

**⚠ Kaçırılırsa çöker:** `FeedScreen`'in FAB'ı (`community_screens.dart:214`, `key: 'feed_create_fab'`) **`heroTag`'siz** ve `StatefulShellRoute.indexedStack` her iki dalı ağaçta canlı tutuyor → ikinci tag'siz FAB `multiple heroes share the same tag` assertion'ı patlatır. **`heroTag: 'home_ayah_finder_fab'` ZORUNLU.**

```
key: Key('home_ai_fab') · heroTag: 'home_ayah_finder_fab'
tooltip: 'Ayet Bul' · Icon(Icons.auto_awesome_rounded)
onPressed: () => context.push('/ayah-finder')
```
`ListView` alt padding `24 → 96` (FAB son satırı örtmesin).

**Test:** `test/home_ai_fab_test.dart` — FAB bulunur + tap → `AyahFinderScreen`. Ayrıca `bottom_bar_height_test.dart` **hâlâ yeşil olmalı** (bu maddenin gerçek regresyon kapısı).

## Madde 4 — Reels açıklamaları

**(a) `caption` DB'ye yazılıyor ama hiç okunmuyor.** `fetchReels` (`backend_repositories.dart:429-431`) `select('*')` yapıyor — caption map'te **var**, `FeedPost.fromMap` (`:121-145`) parse etmiyor, `FeedPost`/`_Reel` sınıflarında alan yok. Ekranda görünen aslında `meal`.
- `backend_repositories.dart` → `final String caption;` + `fromMap`'te `m['caption'] as String? ?? ''`
- `community_screens.dart:261-311` `_Reel.caption` + `:348-368` mapping

**(b) Genişletme affordance'ı yok.** `:1205-1216` `maxLines: 2, overflow: ellipsis`, dokunma yok, "devamı" grep'te 0 sonuç.
- Yeni `@visibleForTesting class ReelCaption extends StatefulWidget` (aynı dosyada, ~25 satır): `maxLines: _expanded ? 8 : 2` + "…devamı"/"daha az" + `GestureDetector`. Genişleme efemer UI durumu → Notifier gereksiz soyutlama olurdu.
- Metin: `reel.caption.isEmpty ? reel.meal : reel.caption`. Bugün ikisi aynı (her iki yayın yolu caption'ı meal'e de yazıyor) → **davranış bugün değişmez**, ayrıştıkları an doğru olur.
- **Aynı satırda düzelt:** `_ReelComposition:933-940` `meal`'i sınırsız basıyor → uzun mealde Column taşar. `maxLines: 10, overflow: ellipsis` — mevcut latent overflow'u kapatır.

**Yorumlar sheet'ine dokunma** — `CommentsSheet` (`:1319-1533`) sağlam, sorun değil.

**Test — `test/reel_caption_test.dart`:** (1) `fromMap({'caption':'X'}).caption == 'X'` (2) tap → `maxLines` 2 → 8.

---

# FAZ C — 1.0.2 geç / 1.0.3

## Madde 7-tam — Profilden DM başlat

**RPC YAZMA.** `init.sql:170-196` politikaları okundu: istemci **iki insert ile** doğrudan sohbet açabiliyor — `conv_insert_own` (`auth.uid() = created_by`) + `cmembers_insert` (`auth.uid() = user_id OR is_conversation_member(...)`: kendi üyeliğini birinci dalla, karşı tarafı artık üye olduğu için ikinci dalla ekler). `create_direct_conversation` **gereksiz**, sıfır politika değişikliğiyle çalışır.

**Tekilleştirme tek sorguyla:** `conversation_members` RLS'i zaten "yalnız benim üye olduğum sohbetler" diyor → `from('conversation_members').select('conversation_id, conversations(is_group)').eq('user_id', otherId)` tam olarak ikimizin de üye olduğu sohbetleri döner. `is_group == false` ilkini al, yoksa oluştur.

- `backend_repositories.dart:776-813` → `openDirectConversation(String otherId)` (~20 satır)
- `:780-789` `myConversations` → 1:1'de `conversations.title` olamaz (tek kolon, iki taraf): `conversation_members` + `profiles(display_name, avatar_url)` embed, Dart'ta `user_id != benimId` olanı seç
- `community_screens.dart:2305-2320` → "Mesaj Gönder" butonu (`!isOwnProfile && myId != null`)
- `ChatScreen` AppBar overflow → "Kullanıcıyı engelle" (mevcut `blockUser`). 1.2 gereği mesajlaşma açıyorsan engelleme oradan da erişilebilir olmalı.

**Migration `20260803120200_dm_block_gate.sql` — ŞART.** Engelleme veritabanında zorlanmalı: `messages_insert_member` politikası yeniden yazılır, `user_blocks` çift yönlü `not exists` koşulu eklenir. `feed_posts`'a ve moderasyon trigger'ına **dokunmaz**. `user_blocks` kolon adları `20260721121000_ugc_safety.sql`'e karşı doğrulanmalı.

**Doğrulama:** SQL editöründe iki oturum — (1) A→B sohbet + mesaj başarılı, (2) B, A'yı engeller → A'nın insert'i RLS ile reddedilir. Artı: `openDirectConversation` iki kez çağrılınca **aynı** id dönmeli.

## Madde 6 — Stüdyo: `pro_image_editor`

> **Madde 9'a BAĞIMLI** — `_renderPng()` güvenilir olmadan bu iş yapılamaz. Ayrıca `StudioScreen` → Notifier refactor'ü burada yapılır (çok katmanlı/geri-al durumu bedeli hak eder).

**Akış:** marka bestecisi (Amiri/RTL/zümrüt-altın) **birincil** kalır → `_renderPng()` → `ProImageEditor.memory(bytes)` → dönen bytes `_editedBytes` → önizleme `Image.memory` → yayın `_editedBytes`. Marka kartı korunur çünkü **düzenleme ondan başlar**.

- `studio_screens.dart:104` → `Uint8List? _editedBytes;` · yeni `_bytesToPublish() => _editedBytes ?? await _renderPng()`
- `:219` (`_export`) ve `:267` (`_publish`) → `_bytesToPublish()`
- `:372-423` `_buildPreview` → `_editedBytes != null` ise `Image.memory`. **Metin katmanını üstüne YENİDEN ÇİZME** (düzenlenen görselde metin zaten var → çift görünür)
- `:699-721` yanına "Gelişmiş Düzenle" + `_editedBytes != null` iken "Düzenlemeyi geri al" (kullanıcı kapana kısılmasın)

**İki kritik ayar:**
- `ImageGenerationConfigs(outputFormat: OutputFormat.png)` — **`uploadPostMedia` (`backend_repositories.dart:461,468`) dosyayı `.png` + `image/png` olarak yazıyor**; paket varsayılanı JPG, adı ve content-type'ı yalan söylerdi
- `tools: [paint, text, cropRotate, tune, filter, blur]` — **sticker/audio YOK**: sticker kendi asset seti + builder ister ve yeni UGC yüzeyi açar (1.2); audio madde 5'in küratörlü kütüphanesiyle çakışır

**1 numaralı risk:** `flutter pub get` sonrası **hemen** `flutter build apk --debug` + `flutter build ios --no-codesign`. Paket compileSdk/minSdk yükseltmesi dayatırsa `receive_sharing_intent 1.8.1` pinini kırar → maddeyi geri al. Bu "sonra bakarız" değil, **entegrasyonun ilk adımı**.

**Test:** `_RecordingSocialRepository.lastBytes` (madde 9'da eklendi) → `expect(bytes.sublist(0,4), [0x89,0x50,0x4E,0x47])`.

## Madde 5 — Reels küratörlü arka plan sesi

**Kürasyon kapısı uygulamada değil, FK'da.** `feed_posts.audio_track_id → feed_audio_tracks(id)`; tabloya yalnız service_role yazar → kullanıcı keyfi ses URL'i gösteremez, **moderasyon trigger'ına hiç dokunmadan** telif güvence altına alınır.

**Migration 1 `20260803120000_reel_audio.sql`:** `feed_audio_tracks` (id, title, artist, url, **license not null**, source_url, duration_seconds, sort_order, is_active) + RLS `for select using (is_active)`, **yazma politikası YOK** → yalnız service_role ekler. `feed_posts.audio_track_id uuid references ...` + index.

**⚠ Moderasyon trigger'ı ile ilişki — bilinçli karar, gerekçe SQL'e yazılmalı:**
> `audio_track_id` BİLEREK trigger'ın "onay sonrası değişiklik" demetinde (`media_url, video_url, thumbnail_url, caption, meal, arabic, reference, kind, topic` — `20260725120000:216-223`) **DEĞİL**. O demetteki kolonlar serbest metin/serbest URL: değişmeleri moderatörün görmediği içerik demektir. `audio_track_id` ise FK ile küratörlü tabloya kilitli — her olası değeri zaten önceden onaylanmış. Demete eklersek kullanıcı müziğini değiştirdiği için onaylı reel'i tekrar kuyruğa düşürürüz; kazanç yok, kullanıcı cezası var.

INSERT tarafında bir şey gerekmez: trigger zaten `status := 'pending'` yazıyor (`:192-197`). **Kapı zayıflamıyor.**

**Migration 2 `20260803120100_reel_audio_bucket.sql`:** `reel-audio` bucket (public, 8MB, `audio/mpeg|mp4|aac`), yalnız select politikası — `authenticated` insert politikası **yazma** (yükleme dashboard'dan). Kalıp: `20260721120100_legal_pages_bucket.sql`.

**İstemci:** `createPost` → `String? audioTrackId` (mevcut `:507-509` opsiyonel-kolon kalıbı, göç uygulanmamışsa kırılmaz) · `fetchReels` select'e `feed_audio_tracks(url,title)` embed · `FeedPost.audioUrl` · `reelAudioTracksProvider` · stüdyoda "Arka Plan" şeridinin (`:497-533`) altına aynı kalıpta "Müzik" şeridi.

**Reels oynatıcısı:** `repositories.dart:181-185` yanına **ikinci `AudioService` örneği** (`reelAudioServiceProvider`) — reels kaydırmak kullanıcının süren tilavetini öldürmemeli. `_ReelPageState`'in mevcut `isActive` yaşam döngüsüne bağla, `reelsMutedProvider`'a uy. **Çakışma:** `community_screens.dart:755` → `setVolume(muted || reel.audioUrl != null ? 0 : 1)` (müzik varken videonun kendi sesi susar).

**Paket yok** — `just_audio` zaten var. **Gerçek mp4 render kapsam dışı** (ffmpeg_kit emekli).

**Doğrulama — kürasyon kapısının kanıtı:** kullanıcı oturumunda `insert into feed_posts (..., audio_track_id) values (..., gen_random_uuid())` → **FK ihlali 23503 ile reddedilmeli.**

---

## Task Dosyası

Onay sonrası ilk iş: bu plandan `tasks/todo.md` üretilir (CLAUDE.md görev yönetimi kuralı). Faz A kalemleri:

- [ ] 9.1 `studio_screens.dart` — önizlemeyi `ListView`'den sabit `FittedBox` tuvale taşı
- [ ] 9.2 `.animate().fadeIn()` sil
- [ ] 9.3 `_renderPng()` başına `await WidgetsBinding.instance.endOfFrame`
- [ ] 9.4 `_RecordingSocialRepository.lastBytes` ekle
- [ ] 9.5 `test/studio_render_offscreen_test.dart` — **önce kırmızı olduğunu doğrula**
- [ ] 8.1 `getUserPosts` → `select('*')` + `FeedPost.fromMap`, try/catch kaldır
- [ ] 8.2 `_UserProfileScreenState._load` hata durumu + "Tekrar dene"
- [ ] 8.3 "İncelemede" rozeti
- [ ] 8.4 `test/profile_posts_test.dart`
- [ ] 3.1 `SplashScreen._go` → `sharedAyahInputProvider` kontrolü + push
- [ ] 3.2 `test/share_cold_start_test.dart`
- [ ] 7.1 Mesajlar boş-durum metni + ölü kod silme
- [ ] A.V `flutter analyze` 0 + 95/95 test + 5 maddelik cihaz QA
- [ ] A.M `PROJECT_MEMORY.md` güncelle (Karar Günlüğü: sliver-paint tuzağı, `go` yığın silme tuzağı, heroTag çakışması)

---

## Değişmeyen Sınırlar

`feed_posts_moderation_guard` · `feed_select_visible` / `feed_select_admin` · `is_own_post_media` · `revoke update on profiles` · `BottomBar` `heightFactor: 1` · `receive_sharing_intent` 1.8.1 pini · `bottom_bar_height_test.dart`
