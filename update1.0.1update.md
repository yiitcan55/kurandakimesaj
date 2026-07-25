# Plan: Sürüm 1.0.1 — Auth + UGC Güvenliği + Reels Tekleştirme + Link Akışı

> **Hedef:** 1.0.1 (build 3) · Tek büyük sürüm · Apple reddine tam yanıt
> **Kaynak:** Apple Review reddi (Submission `cf08e6a4-b956-46b3-9064-2ecc40fa5742`, 24 Tem 2026, **Guideline 1.2**) + 3 ürün isteği
> **Repo:** `C:\Users\yiit5\Desktop\kurandaki mesaj flutter\kurandakimesaj` (git, branch `main`, son commit `b210eb3`)

---

## Context — Neden bu değişiklik

Uygulama App Store'a yüklendi (Build 2) ve **Guideline 1.2 (User-Generated Content)** gerekçesiyle reddedildi. Apple beş şart sayıyor: kayıt öncesi EULA onayı, uygunsuz içerik **filtreleme yöntemi**, şikayet mekanizması, engelleme mekanizması, 24 saat içinde aksiyon.

Kodda şikayet + engelleme **zaten var** (2026-07-21 `ugc_safety` göçü: `reports`, `user_blocks`, `_ModerationMenuButton`, `filterBlockedFeedPosts`). Reddin gerçek sebebi **eksik olan ikisi**: kayıt öncesi EULA onayı ve içerik filtreleme yöntemi. `grep -i "eula|kabul ed|kullanım koşul"` → onboarding ve auth ekranında 0 sonuç; `docs/legal/` altında sadece `privacy.html` + `support.html` var, **kullanım koşulları metni hiç yok**.

Buna dört ürün sorunu ekleniyor:

| # | Sorun | Kanıt |
|---|---|---|
| 1 | **Giriş kırık** — iOS'ta Google gizli, Apple hiç yok, e-posta güvenilmez | `home_screens.dart:1252` platform guard'ı · `sign_in_with_apple` paketi yok · `isSignedInProvider` reaktif değil |
| 2 | **Link akışı istenen davranışı vermiyor** | `link_resolver.ts` sadece `og:image` çeker; Instagram/TikTok bot duvarı → her zaman `link_unresolved`. UI'da URL alanı yok. |
| 3 | **İki paralel içerik sistemi** (Gönderiler + Reels) | `_FeedTab { posts, reels }` · tek tablo `feed_posts` + `kind` kolonu |
| 4 | **Stüdyo video üretmiyor, yüklemesi de bozuk** | `studio_screens.dart:290-295` `user_id`/`kind:'image'` yazıyor → şema `author_id`/`check(kind in ('ayah','video'))` → **her zaman hata** |

**Hedef çıktı:** Apple'ın beş şartını karşılayan, tek içerik sistemi (Reels) etrafında toplanmış, üç giriş yolu çalışan bir 1.0.1.

---

## Onaylanan kararlar

| Konu | Karar |
|---|---|
| Link akışı | **İkisi birden** — (a) link → ayet tanı → uygulama **kendi** kartını/videosunu üretir, (b) paylaş menüsü/galeriden kullanıcının kendi videosu. Üçüncü taraf videosu **indirilmez** (Guideline 5.2.3). |
| Moderasyon | **Manuel onay kuyruğu** — her reels yayına girmeden önce admin onayından geçer |
| Reels kaynağı | Stüdyo üretimi + galeri/paylaş menüsü + küratörlü "Günün Seçkileri" |
| Sürüm | Tek büyük sürüm (1.0.1) |

---

## Mimari kararlar (uygulamadan önce oku)

### K1 — Reels "video" değil, "medya" olur
Stüdyo bugün PNG üretiyor (`RepaintBoundary.toImage`); gerçek video render hattı (`render-trigger`/`render_jobs`) **hiç tetiklenmeyen ölü koddur** ve ffmpeg_kit emekli. Video render'ı bu sürümde inşa etmiyoruz.

Bunun yerine `feed_posts.kind` iki değere daralır: **`video`** (kullanıcının mp4'ü) ve **`still`** (stüdyo PNG'si). Reels pager ikisini de tam ekran oynatır: `video` → `video_player`; `still` → mevcut `_ReelComposition` gradyan/görsel kompozisyonu + opsiyonel tilavet sesi. Kullanıcı farkı hissetmez, biz ffmpeg borcuna girmeyiz.

### K2 — Onay kuyruğu tek kolonla çözülür
`feed_posts`'a `status text default 'pending' check (status in ('pending','approved','rejected'))`. RLS `feed_select_visible` politikası `status='approved' or auth.uid()=author_id` olur. Küratörlü seed içeriği DB'de değil, istemcide (`feedProvider`) — onaydan etkilenmez, akış boş kalmaz. Bu tek kolon Apple'ın hem "filtreleme yöntemi" hem "24 saat içinde aksiyon" şartını karşılar: **onaylanmamış içerik hiç yayına girmez**.

### K3 — Auth reaktivitesi kök nedendir
`isSignedInProvider` (`backend_repositories.dart:38`) düz `Provider` — giriş başarılı olsa bile hiç invalidate olmaz, ekranlar "Misafir" kalır. Google için 2026-07-01'de düzeltilen pop bug'ının reaktivite versiyonu bu. Tek düzeltme (auth stream'e bağlama) hem e-posta hem Google hem Apple yolunu birden onarır — her çağrı yerine guard eklemeye gerek yok.

---

## Faz 0 — Temizlik (önce bu; sonraki fazların yüzeyini küçültür)

| Dosya | Eylem |
|---|---|
| `lib/features/home/home_screens.dart:203` | **CRASH FIX:** FAB sheet'inde `/templates` rotası var ama router'da yok → go_router "no routes for location". Bu girişi kaldır (şablon galerisi 2026-06-20'de silinmişti). |
| `lib/features/studio/studio_screens.dart:50-150, 750-946` | `RenderJob`, `RenderJobsNotifier`, `renderJobsProvider`, `MyVideosScreen`, `_RenderPreview`, `shareJobToFeed`, `_statusLabel/_statusIcon` sil (~300 satır ölü kod — `.add` hiç çağrılmıyor) |
| `lib/data/backend_repositories.dart:611-677` | `IRenderRepository` + `RenderRepository` + provider sil (~67 satır); `test/repository_seam_test.dart:92-97` güncelle |
| `lib/app/router.dart:96-100` | `/my-videos` rotası sil |
| `lib/features/studio/studio_screens.dart:260-311` | Bozuk `_uploadToSupabase` sil — yerine Faz 3'te `ISocialRepository.createPost` çağrısı gelir |

**Doğrulama:** `flutter analyze` 0 · `flutter test` (33 → ~31, silinen render testleri düşer)

---

## Faz 1 — Giriş: Apple + Google + e-posta onarımı

### 1a. Reaktivite (kök neden — önce bu)

`lib/data/backend_repositories.dart:38` ve `lib/data/repositories.dart:120`:

```dart
// authStateProvider zaten tanımlı (repositories.dart:120) ama HİÇ tüketilmiyor.
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);          // auth değişiminde yeniden hesapla
  return ref.watch(supabaseGatewayProvider).isSignedIn;
});
```

`_afterAuthSuccess()` (`home_screens.dart:1146-1158`) içinde ek olarak `ref.invalidate(myProfileProvider)`. Bu tek değişiklik Profil/Ayarlar/Topluluk/Reels ekranlarının hepsini onarır.

### 1b. E-posta akışı — `home_screens.dart:1160-1181` + `services.dart:140-150`

| Sorun | Düzeltme |
|---|---|
| `catch (_)` gerçek hatayı yutuyor, herkese "Supabase yapılandırmasını kontrol edin" diyor | `on AuthException catch (e)` → `e.message`'ı Türkçe'ye eşleyen `_authErrorText(e)` yardımcısı (`invalid_credentials` → "E-posta veya parola hatalı", `email_not_confirmed` → "E-postanı doğrula", `weak_password` → "Parola en az 6 karakter olmalı", `over_email_send_rate_limit` → "Çok fazla deneme…") |
| Form doğrulama sıfır | `TextField` → `Form` + `TextFormField` + validator (boş, e-posta formatı, min 6 karakter) |
| `signUp` sonucu kontrol edilmiyor → onay açıksa session null, kullanıcı sessizce hiçbir şey görmüyor | `SupabaseService.signUpWithEmail` `AuthResponse` döndürsün; `res.session == null` ise ekranda "Doğrulama e-postası gönderildi" durumu göster, `_afterAuthSuccess()` çağırma |
| `emailRedirectTo` yok, dönüş şeması hiçbir platformda kayıtlı değil | `signUp(..., emailRedirectTo: 'io.kurandakimesaj://login-callback')` + iOS `Info.plist` `CFBundleURLTypes`'a `io.kurandakimesaj` şeması ekle (bugün sadece `homeWidget` var) + Android manifest'e `VIEW/BROWSABLE` intent-filter ekle |
| Şifre sıfırlama yolu yok | "Şifremi unuttum" → `resetPasswordForEmail(email, redirectTo: ...)` + bilgi SnackBar |

### 1c. Sign in with Apple (yeni)

- `pubspec.yaml`: `sign_in_with_apple: ^7.0.1`
- `ios/Runner/Runner.entitlements`: `com.apple.developer.applesignin` = `[Default]` (bugün sadece app-group var) + Apple Developer Portal'da App ID'ye capability ekle → **provisioning profile yeniden üretilmeli** (Codemagic Fetch profiles)
- `lib/data/services.dart` — `signInWithGoogle` (`:152-199`) kalıbını birebir izle:
```dart
Future<void> signInWithApple() async {
  final c = _client; if (c == null) throw StateError('Supabase yapılandırılmamış.');
  final raw = _generateNonce();                       // nonce ZORUNLU
  final cred = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: sha256ofString(raw),
  );
  await c.auth.signInWithIdToken(
    provider: OAuthProvider.apple, idToken: cred.identityToken!, nonce: raw);
}
```
- `AuthRepository.signInWithApple()` (`repositories.dart:97-117` kalıbı) + `_AuthScreenState._appleSignIn()` (`_googleSignIn` `:1183-1206` kalıbı, `SignInWithAppleAuthorizationException` → `canceled` sessiz yutulur)
- UI: siyah Apple butonu, **yalnız iOS'ta** (`defaultTargetPlatform == TargetPlatform.iOS`); Google butonu iOS'ta da **açılır** (Apple girişi sunulduğu için Guideline 4.8 artık karşılanıyor)
- **Supabase Dashboard (manuel):** Auth → Providers → Apple etkinleştir, Services ID + Team ID + Key ID + `.p8` gir

### 1d. Google — Android release riski

`AppConfig.hasGoogleSignIn` (`app_config.dart:30`) tanımlı ama **hiç kullanılmıyor** → key'siz build'de buton görünüp `StateError` atıyor. Butonu bu getter ile koşullandır. Ayrıca `codemagic.yaml:37-41` iOS build'e `GOOGLE_WEB_CLIENT_ID` + `GOOGLE_IOS_CLIENT_ID` dart-define'ları eklenmeli (iOS'ta Google artık görünür olacak). `android/app/build.gradle.kts:30-34` release build hâlâ **debug keystore** ile imzalıyor — gerçek keystore'a geçildiğinde Google Cloud'a yeni SHA-1 eklenmeli (Play sürümü öncesi, bu sürümü bloklamaz).

**Yeni testler:** `test/auth_navigation_test.dart`'a e-posta yolu (bugün 0 test) + Apple butonu görünürlüğü + `isSignedInProvider` reaktivite testi.

---

## Faz 2 — UGC güvenliği (Apple 1.2 yanıtı)

### 2a. Kullanım Koşulları / EULA metni

- **Yeni** `docs/legal/terms.html` — `privacy.html` (2.6 KB, aynı stil bloğu) kalıbını birebir izle. **Zorunlu madde:** *"Uygunsuz içeriğe ve taciz edici kullanıcılara sıfır tolerans"* + ihlal → içerik kaldırma + hesap kapatma. Apple bu ifadeyi arıyor.
- GitHub Pages'e yayınla → `https://yiitcan55.github.io/kurandakimesaj-legal/terms.html`
- `lib/features/settings/settings_screen.dart:61-71` — `_LegalRow` "Kullanım Koşulları" satırı ekle (mevcut `_openExternalUrl` `:119-128` yardımcısını kullan)

### 2b. Kayıt öncesi onay (Apple'ın 1. şartı — reddin ana sebebi)

`_AuthScreenState` (`home_screens.dart:1209-1325`), gönder butonunun **üstünde**:

```
☐ Kullanım Koşulları'nı ve Gizlilik Politikası'nı okudum, kabul ediyorum.
```

- `Checkbox` + `RichText` (iki tıklanabilir link → `_openExternalUrl`)
- **Kabul edilmeden `FilledButton` disabled** — hem kayıt hem giriş için (Apple "before registering or **logging in**" diyor)
- Onay `PrefsService`'e (`terms_accepted_version = 1`) yazılır; sürüm artarsa yeniden sorulur
- Google/Apple butonları da aynı checkbox'a bağlı

### 2c. Onay kuyruğu (Apple'ın 2. şartı: "method for filtering")

**Yeni migration** `supabase/migrations/20260725120000_moderation_queue.sql`:

```sql
alter table public.feed_posts
  add column if not exists status text not null default 'pending'
    check (status in ('pending','approved','rejected'));
create index if not exists feed_posts_status_idx on public.feed_posts (status, created_at desc);

-- Yayın kapısı: yalnız onaylı içerik veya kendi içeriğin görünür
drop policy if exists feed_select_visible on public.feed_posts;
create policy feed_select_visible on public.feed_posts for select
  using ((status = 'approved' and is_hidden = false) or auth.uid() = author_id);

alter table public.profiles add column if not exists is_admin boolean not null default false;

-- Admin: raporları görebilsin + içerik durumu değiştirebilsin
create policy reports_select_admin on public.reports for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));
create policy feed_update_admin on public.feed_posts for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));
```

> Not: `reports` bugün yalnız `reports_select_own` politikasına sahip — **geliştirici bile kendi uygulamasından raporları göremiyor.** Bu politika onu açar.

### 2d. Admin onay ekranı (24 saat şartının kanıtı)

**Yeni** `lib/features/moderation/moderation_screen.dart` (~180 satır), rota `/moderation`, Ayarlar'da yalnız `profile.is_admin` ise görünür:

- Sekme 1 **Bekleyenler**: `status='pending'` reels listesi → önizleme + **Onayla** / **Reddet**
- Sekme 2 **Şikayetler**: `reports` join `feed_posts` → **İçeriği kaldır** (`status='rejected'`) / **Kullanıcıyı askıya al**
- Repo: `ISocialRepository`'ye `fetchPendingPosts()`, `setPostStatus(id, status)`, `fetchReports()` ekle (`_report` `:491-502` kalıbı)

### 2e. Eksik moderasyon parçaları

| Eksik | Düzeltme |
|---|---|
| `unblockUser()` yazılmış ama **hiçbir UI'dan çağrılmıyor** — kullanıcı engeli geri alamıyor | Ayarlar → "Engellenen kullanıcılar" ekranı (liste + Engeli kaldır) |
| Kendi gönderisini silme UI'ı yok (`feed_delete_own` RLS var) | Reels overlay menüsüne kendi içeriğinde "Sil" |
| Yorum silme UI'ı yok (`comments_delete_own` RLS var) | `_CommentTile:1709` menüsüne kendi yorumunda "Sil" |
| `follows` tablosunda **iki göçten çift politika** biniyor (`init.sql:123-136` vs `20260630120000_follows.sql`) | Aynı migration'da eski adlandırmayı `drop policy if exists` ile temizle |

### 2f. Ekran kaydı (Apple'ın istediği kanıt)

Fiziksel cihazda tek kayıt: **(1)** kayıt ekranında EULA onay kutusu ve linkler → **(2)** bir reels'te ⋯ → Bildir → onay → **(3)** ⋯ → Kullanıcıyı engelle → içeriğin akıştan anında kaybolması. App Store Connect → App Review Information → Notes alanına ekle.

---

## Faz 3 — Gönderi sistemini kaldır, Reels'i yeniden tasarla

### 3a. Silinecek (~405 satır, hepsi `community_screens.dart`)

`_FeedItem` (`:180-217`) · `_FeedItemCard` (`:221-376`) · `_CloudFeedList`+State (`:521-650`) · `_FeedScreenState._buildPosts()` (`:468-517`) · `enum _FeedTab` (`:385`) · `GlassSegmentedToggle` çağrısı (`:440-447`) · `AnimatedSwitcher` sarmalı (`:448-460`) · `cloudPostsProvider` (`backend_repositories.dart:881-885`) · `cloudFeedProvider` deprecated alias (`:896-899`).

`FeedScreen` ~140 satırdan ~35 satıra iner, `body: _ReelsView()`. `GlassSegmentedToggle` widget'ı `widgets.dart:224-310`'da **kalır** (testi var, ileride kullanılabilir).

### 3b. Şema sadeleştirme (aynı migration içinde)

```sql
-- 'ayah' (metin/görsel gönderi) → artık üretilmiyor. Mevcut kayıtları still'e çevir.
update public.feed_posts set kind = 'still' where kind = 'ayah';
alter table public.feed_posts drop constraint if exists feed_posts_kind_check;
alter table public.feed_posts add constraint feed_posts_kind_check
  check (kind in ('video','still'));
```

`ISocialRepository.fetchFeed({String? kind})` → `fetchReels()`; gövdede `.eq('kind','video')` yerine kind filtresi kalkar (ikisi de reels), `.eq('status','approved')` istemci tarafında da uygulanır. `FeedPost.isVideo` → `kind == 'video'` (artık anlamlı: video mu still mi).

### 3c. Reels yeniden tasarım — `_ReelPage` / `_ReelOverlay`

Mevcut yapı sağlam (dikey `PageView`, `video_player`, çift dokun beğeni, `reelsMutedProvider`, `VideoProgressIndicator`, in-flight guard'lı optimistik beğeni). Yapılacaklar:

| Değişiklik | Yer |
|---|---|
| `kind='still'` dalı: `thumbnail_url` görselini tam ekran + yavaş Ken Burns (`flutter_animate` scale 1.0→1.08, 12 sn) + mevcut gradyan fallback | `_ReelComposition:1132-1179` |
| Video poster: `thumbnail_url` ilk kare hazır olana kadar gösterilsin (bugün siyah ekran) | `_ReelPage._initVideo:962-983` |
| Ayet künyesi: overlay'de `reference` + sure adı `GoldChip`, dokununca `SurahReaderScreen(initialAyah:)` — Ayet Bulucu'daki `_openInReader` (`ayah_finder_screen.dart:421-431`) kalıbının aynısı | `_ReelOverlay:1235-1400` |
| Kendi içeriğinde "Sil", başkasında Bildir/Engelle (bugün yalnız ikincisi) | `_ReelOverlay` menüsü |
| Boş durum CTA'sı `/studio`'ya gitsin | `_ReelsEmpty:828-844` |
| Bottom bar etiketi "Akış" → "Reels" | `home_screens.dart:79` |

### 3d. Yükleme akışı — `CreatePostSheet` yeniden yazımı

Bugünkü sheet (`:1721-1971`) metin+fotoğraf+video karışımı. Yeni hali **yalnız dikey medya**:

- `_pickImage` dalı kaldırılır; **Video Seç** (galeri) + **Stüdyodan seç** (üretilmiş PNG)
- Yayınla → `createPost(kind: 'video'|'still', videoUrl/mediaUrl, caption, reference, arabic, meal)`
- **Yayın sonrası bilgi kartı:** *"İçeriğin incelemeye alındı. Onaylandığında Reels'te yayınlanacak."* (onay kuyruğu şeffaflığı — Apple'a da bunu gösteriyoruz)
- Telif beyanı checkbox'ı: *"Bu içeriğin bana ait olduğunu veya paylaşma hakkım olduğunu onaylıyorum."* (5.2.3 + 1.2 için)

### 3e. Stüdyo — `studio_screens.dart`

- Bozuk `_uploadToSupabase` yerine **`ISocialRepository.createPost(kind:'still')`** (mimari kural: View → Notifier → Repository → Service; doğrudan `client.from()` yazma)
- `initialReference` parametresi (`:167`) bugün **hiç okunmuyor** → ayet künyesi olarak kaydedilsin (`reference` alanı), Reels'te künye bundan gelir
- `kReciters` (`:44`) UI'da hiç kullanılmıyor → ya tilavet seçimi bağlanır (still reel'e ses) ya silinir. **Öneri: sil** (ses miksleme ffmpeg gerektirir; ponytail)
- `feature_catalog.dart:49` açıklaması gerçeğe çekilsin: "Video Edit + Meal / reels/TikTok videosu" → "Ayet Kartı Stüdyosu / şablon + arka plan + metin ile paylaşılabilir ayet kartı"
- `AppHeader` başlığı zaten `'Görsel Editör'` (`:432`) — tutarlı

---

## Faz 4 — Link akışı (5.2.3 uyumlu)

### 4a. Bugünkü durum (keşif bulgusu)

`link_resolver.ts` (66 satır) yalnız **`og:image` / `twitter:image`** meta'sı arıyor; `og:video` hiç aranmıyor, `content-type: video/*` eleniyor. UA'sı kendini bot ilan ediyor (`KuranAyetBulucu/1.0`) → Instagram giriş duvarı ve TikTok bot koruması **her zaman** `null` → `link_unresolved`. UI'da URL alanı 2026-07-16'da silinmiş; `fromUrl` yalnız paylaş-intent'ten ulaşılabilir ve **iOS'ta Share Extension kurulmadığı için iOS'ta tamamen ölü**.

### 4b. Yol A — Link → ayet → kendi içeriğimiz

- **URL alanını geri getir** (`ayah_finder_screen.dart`, silinen `_UrlField` kalıbı) + "Bağlantı Yapıştır" kartı. Pano okuma (`Clipboard.getData`) ile tek dokunuş.
- `link_resolver.ts` iyileştirmeleri (hepsi mevcut regex hattında):
  - UA'yı gerçek tarayıcı UA'sına çevir (bot ilanı kaldır)
  - `_META_PATTERNS`'e **oEmbed** yolu ekle: TikTok'un `https://www.tiktok.com/oembed?url=...` açık uç noktası **giriş gerektirmeden** `thumbnail_url` döner — TikTok için tek güvenilir yol
  - `og:image` bulunamazsa dönen `link_unresolved` mesajı zaten doğru fallback'i öneriyor (ekran görüntüsü / video seç) — korunur
  - **SSRF sertleştirme (güvenlik borcu):** `:35` sadece protokol filtreliyor; private/loopback/`169.254.169.254` engellenmeli, `res.text()` boyut sınırı konmalı
- **Sonuç → Reels köprüsü (yeni):** `_MatchCard`'daki "Videoya Aktar" (`:401-412`) butonunun yanına **"Reels'te Paylaş"** — `StudioScreen(initialText:, initialReference:)` ön-dolu açılır, kullanıcı arka plan seçer, `createPost(kind:'still')`. **Üçüncü taraf videosu kopyalanmaz; paylaşılan bizim ürettiğimiz karttır.**

### 4c. Yol B — Paylaş menüsü / galeri (mevcut, tamamlanacak)

Android tarafı çalışıyor (`AndroidManifest` `ACTION_SEND` × 3). Eksik olan **iOS Share Extension** (`ios/SHARE_EXTENSION_SETUP.md`, 6 adım, macOS+Xcode şart). Bu sürümde:

- iOS Share Extension **macOS'ta yapılacak manuel iş** olarak işaretle (Windows'ta imkânsız); `NSExtensionActivationRule`'a **video** de eklenmeli (belge bugün image+webURL+text diyor)
- iOS'ta Share Extension yoksa da **galeri "Video Seç" yolu çalışıyor** → iOS kullanıcısı engellenmiyor
- `SEND_MULTIPLE` desteklenmiyor, `_onShared` yalnız `files.first` alıyor — bu sürümde kabul (ponytail)

### 4d. Ayet Bulucu ikincil düzeltmeler

- `_ErrorView` (`:451-505`) kapsanmayan kodları ele almıyor: `bad_response`, `no_image`, `no_video`, `server_error`, `network` → hepsi "Bağlantı sorunu" gösteriyor. Her birine ayrı Türkçe mesaj.
- `findFromImage` (`backend_repositories.dart:747-754`) **boyut kontrolü yok** — base64 ~1.33x şişiyor; video için `kAyahVideoMaxBytes` kapısı var, görsel için yok. 10 MB kapısı ekle.

---

## Faz 5 — Doğrulama ve gönderim

### Yerel doğrulama

```bash
cd "C:/Users/yiit5/Desktop/kurandaki mesaj flutter/kurandakimesaj"
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift/freezed değişirse
flutter analyze                        # hedef: 0 sorun
flutter test                           # hedef: yeşil (yeni testlerle ~40)
deno test --allow-read supabase/functions/_shared/quran/matcher.test.ts
deno test --allow-read supabase/functions/ayah-finder-audio/segments.test.ts
flutter run --dart-define-from-file=env.json   # env.json'a GOOGLE_IOS_CLIENT_ID eklenmeli
```

### Yeni testler (yazılacak)

| Test | Neyi kilitler |
|---|---|
| `test/auth_email_test.dart` | `AuthException` → Türkçe mesaj eşlemesi; boş/kısa parola validator'ı; `session==null` → doğrulama ekranı |
| `test/auth_navigation_test.dart` (genişlet) | Apple butonu yalnız iOS'ta; EULA onaylanmadan gönder disabled |
| `test/moderation_queue_test.dart` | `status='pending'` içerik akışta görünmez; onaylanınca görünür |
| `supabase/functions/ayah-finder/link_resolver.test.ts` | **Bugün 0 test var** — og:image çıkarımı, göreli URL mutlaklaştırma, oEmbed yolu, SSRF reddi |

### Cihaz E2E (Samsung SM S731B + TestFlight iPhone)

1. Kayıt → EULA onayı zorunlu mu · e-posta doğrulama mesajı görünüyor mu · şifre sıfırlama maili geliyor mu
2. Apple ile giriş (iPhone) · Google ile giriş (her iki platform) → **Profil ekranı anında giriş yapılmış gösteriyor mu** (reaktivite testi)
3. Reels yükle → "incelemeye alındı" mesajı · admin hesabıyla onayla → akışta beliriyor mu
4. Bildir + Engelle → içerik anında kayboluyor mu · Engeli kaldır çalışıyor mu
5. Link yapıştır (TikTok + Instagram) → ayet bulunuyor mu / dürüst hata mı · "Reels'te Paylaş" → stüdyo ön-dolu açılıyor mu
6. Video seç (galeri) → ayet aralığı + zaman çizelgesi

### Gönderim öncesi manuel adımlar

| # | İş | Nerede |
|---|---|---|
| 1 | Apple provider (Services ID, Team ID, Key ID, `.p8`) | Supabase Dashboard → Auth → Providers |
| 2 | App ID'ye **Sign in with Apple** capability + provisioning profile yenile | Apple Developer Portal → Codemagic Fetch profiles |
| 3 | `supabase db push` (moderasyon migration'ı) | Terminal (`npx supabase@latest`) |
| 4 | Kendi hesabına `is_admin = true` | Supabase SQL Editor |
| 5 | `terms.html` GitHub Pages'e yayınla | `kurandakimesaj-legal` reposu |
| 6 | Ekran kaydı (EULA + Bildir + Engelle) → App Review Notes | Fiziksel cihaz + ASC |
| 7 | ASC'de reddedilen gönderime **yanıt yaz** (üç mekanizmayı ve kaydı belirt) | App Store Connect mesajı |
| 8 | `codemagic.yaml` → `GOOGLE_WEB_CLIENT_ID` + `GOOGLE_IOS_CLIENT_ID` dart-define | `kdm_runtime` env grubu |
| 9 | Sürüm `1.0.0+1` → `1.0.1+3` | `pubspec.yaml` |

---

## Riskler

| Risk | Olasılık | Azaltma |
|---|---|---|
| Sign in with Apple provisioning profile yenilenmezse iOS build patlar | Yüksek | Faz 1c'de capability eklendikten **hemen sonra** Codemagic'te profil çek; build'i erken dene |
| Onay kuyruğu akışı boşaltır (onaysız içerik görünmez) | Orta | Küratörlü seed (`feedProvider`) DB'de değil istemcide → akış hiç boş kalmaz |
| `status` kolonu + RLS değişimi mevcut içeriği gizler | Orta | Migration'da `update feed_posts set status='approved' where created_at < now()` ile mevcut kayıtlar onaylı sayılsın |
| TikTok oEmbed uç noktası kapanırsa link yolu bozulur | Orta | Zaten fallback var (`link_unresolved` → "ekran görüntüsü/video seç"); kullanıcı engellenmez |
| Apple 1.2'yi yine yetersiz bulur | Düşük-Orta | Beş şartın **beşi de** kod + ekran kaydıyla kanıtlanıyor; onay kuyruğu "filtering method" şartının en güçlü hali |
| Gönderi kaldırma mevcut kullanıcı içeriğini kaybettirir | Düşük | `kind='ayah'` → `'still'` migration'ı veri silmez, dönüştürür |

---

## Uygulama sırası (özet)

```
Faz 0  Temizlik + /templates crash fix          → analyze/test yeşil
Faz 1  Auth reaktivite → e-posta → Apple → Google → yeni testler
Faz 2  terms.html → EULA checkbox → migration → admin ekranı → unblock/sil UI
Faz 3  Gönderi sil → şema sadeleştir → Reels redesign → CreatePostSheet → Studio
Faz 4  URL alanı geri → link_resolver (oEmbed + UA + SSRF) → "Reels'te Paylaş" köprüsü
Faz 5  Testler + cihaz E2E + manuel adımlar + build 3 + ASC yanıtı
```

Fazlar sırayla yapılmalı: Faz 1 reaktivite düzeltmesi Faz 2/3'ün test edilebilirliğini açar; Faz 3 şema değişimi Faz 4'ün "Reels'te Paylaş" hedefini var eder.

---

## Kapsam dışı (bilinçli)

- **Gerçek video render** (ffmpeg/sunucu worker) — K1'de gerekçelendirildi; stüdyo çıktısı `still` reel olarak yayınlanır
- **Üçüncü taraf videosunu indirme** — Guideline 5.2.3, kalıcı ret riski (`PROJECT_MEMORY.md:123`)
- **Otomatik AI içerik moderasyonu** — manuel onay kuyruğu seçildi; ölçek büyürse Edge Function'a taşınır
- **iOS Share Extension'ın kendisi** — macOS/Xcode gerektirir, belge hazır (`ios/SHARE_EXTENSION_SETUP.md`)
- **Android release keystore** — Play sürümü işi, bu sürümü bloklamaz
