# Kur'an'da ki Mesaj — Görev Listesi

## FAZ A — Build 4 (2026-08-03)
Plan: `g-rev-bir-implantation-glimmering-dream.md` · Skill/ajan eşlemesi: `SKILL.md`
Kapsam: **yalnız** madde 9 + 8 + 3 + 7-kısmi. Sıfır migration / sıfır native / sıfır yeni paket.

- [x] 9.1 `studio_screens.dart` — önizlemeyi `ListView`'den sabit `FittedBox` tuvale taşı
- [x] 9.2 `.animate().fadeIn()` sil (+ `flutter_animate` importu artık kullanılmıyor)
- [x] 9.3 `_renderPng()` başına `await WidgetsBinding.instance.endOfFrame`
- [x] 9.4 `RecordingSocialRepository.lastBytes` ekle (fake `test/support/`'a taşındı — iki dosya kullanıyor)
- [x] 9.5 `test/studio_render_offscreen_test.dart` — 3 test, **kırmızı olduğu görüldü**
- [x] 8.1 `getUserPosts` → `select('*')` + `FeedPost.fromMap`, try/catch kaldırıldı
- [x] 8.2 `_UserProfileScreenState._load` hata durumu + "Tekrar dene"
- [x] 8.3 "İncelemede" rozeti (`post.isPending`)
- [x] 8.4 `test/profile_posts_test.dart` (4 assert)
- [x] 3.1 `SplashScreen._go` push + **`_onShared` `/splash`teyken push etmiyor** (plandan sapma, aşağıda)
- [x] 3.2 `test/share_cold_start_test.dart` — kırmızı olduğu görüldü
- [x] 7.1 Mesajlar boş-durum metni + ölü kod silme
- [x] A.V `dart analyze` 0 + **136/136 test** (4 ardışık koşum) · cihaz QA **BEKLİYOR**
- [x] A.M `PROJECT_MEMORY.md` güncellendi (sliver-paint · `go` yığın silme · heroTag çakışması)

### Review (2026-08-03 — Faz A)

**Plandan tek sapma — madde 3.** Planın önerdiği düzeltme (yalnız `SplashScreen._go`'ya
`if (ref.read(sharedAyahInputProvider) != null) context.push(...)` eklemek) tek başına
**çalışmıyordu**: `_onShared` t≈0'da `/ayah-finder`'ı push ediyor, o ekran bir frame sonra
provider'ı `clear()` ediyor → splash 2400 ms'de her zaman `null` okuyordu. Kök neden
doğrulaması bunu yakaladı. Düzeltme iki parçalı yapıldı: `_onShared` **hâlâ `/splash`teyken
push etmiyor** (`router.state.uri.path` kontrolü, 2 satır), rotayı splash üstleniyor.
Yavaş cihazda `getInitialMedia` geç dönerse konum `/home` olduğu için normal push çalışır —
iki sıralama da kapalı. Yeni global durum eklenmedi.

**Kırmızı-önce kanıtı (ders #10).** Üç yeni test de düzeltme geçici geri alınarak koşuldu:
- `studio_render_offscreen_test` → 3/3 düştü (`uploads: []`, tuval ağaçta yok)
- `share_cold_start_test` → paylaşımlı vaka düştü (`stub_ayah_finder` bulunamadı)
- İlk yazdığım "PNG Kaydet" testi düzeltmesiz de GEÇİYORDU (hiçbir şey kilitlemiyordu) →
  yapısal bir değişmezle değiştirildi: önizleme tuvali `Scrollable`'ın içinde OLMAMALI.

**Kapsam dışı bırakılanlar:** `StudioScreen` → Notifier refactor'ü (madde 6'ya ertelendi),
madde 1/4/2 (Faz B), madde 7-tam/6/5 (Faz C). Moderasyon kapısı, RLS, `BottomBar`
`heightFactor: 1` ve `receive_sharing_intent` pinine dokunulmadı.

**Kalan tek A kalemi: cihaz QA (Samsung SM S731B), 5 senaryo** — Stüdyo kaydır+yayınla ·
Stüdyo kaydır+PNG Kaydet · Profil ızgarasında görseller · uygulama KAPALIYKEN Instagram
paylaşımı · Mesajlar boş durumu.

**Değişmeyen sınırlar:** `feed_posts_moderation_guard` · `feed_select_visible` / `feed_select_admin` ·
`is_own_post_media` · `revoke update on profiles` · `BottomBar` `heightFactor: 1` ·
`receive_sharing_intent` 1.8.1 pini · `test/bottom_bar_height_test.dart`

---

## FAZ B + FAZ C (2026-08-03, kullanıcı isteğiyle onay beklemeden)

> Plan bu iki fazı **Apple onayından sonraya** koymuştu (madde 2 yeni arka plan
> yeteneği, madde 6/7-tam/5 yeni UGC yüzeyi). Kullanıcı "bütün fazları bitir"
> dediği için uygulandı. **Gönderim önerisi: Faz A'yı ayrı commit/branch olarak
> build 4'e gönder**, B+C'yi 1.0.2'ye bırak — aksi hâlde inceleme yüzeyi büyür.

### Faz B — 1.0.2
- [x] 2.1 `just_audio_background` 0.0.1-beta.17 (**tam sürüme pinlendi**)
- [x] 2.2 `JustAudioBackground.init` (bootstrap, `runApp` öncesi)
- [x] 2.3 `AudioService.playUrl(url, {required title})` → `setAudioSource` + `MediaItem`
- [x] 2.4 `AudioService.mediaTitleFor()` + `test/media_title_test.dart`
- [x] 2.5 `quran_screens.dart` `dispose`taki `_player.stop()` **silindi** (+ gerekçe)
- [x] 2.6 TTS ses odağı: `TtsService(onSpeakStart:)` → `audioService.pause()`
- [x] 2.7 Manifest (`xmlns:tools`, 3 izin, `AudioService` service, `MediaButtonReceiver`)
- [x] 2.8 `MainActivity : AudioServiceActivity()` — manifest'teki activity ADI korundu
- [x] 2.9 iOS `Info.plist` → `UIBackgroundModes: [audio]`
- [x] 1.1 `HomeScreen` kendi `Scaffold`'una FAB + `startFloat` + **`heroTag`**
- [x] 1.2 `ListView` alt padding 24 → 96
- [x] 1.3 `test/home_ai_fab_test.dart` (3 test) · `bottom_bar_height_test` hâlâ yeşil
- [x] 4.1 `FeedPost.caption` + `_Reel.caption` + mapping
- [x] 4.2 `ReelCaption` genişletme affordance'ı (taşmıyorsa "devamı" GÖSTERİLMEZ)
- [x] 4.3 `_ReelComposition` latent `meal` taşması → `maxLines: 10`
- [x] 4.4 `test/reel_caption_test.dart`

### Faz C — 1.0.2 geç / 1.0.3
- [x] 7.1 `openDirectConversation` (RPC YOK — iki insert, sıra zorunlu, id istemcide)
- [x] 7.2 `myConversations` → 1:1'de başlık karşı tarafın adı
- [x] 7.3 Profilde "Mesaj Gönder" + `ChatScreen`de "Kullanıcıyı engelle"
- [x] 7.4 `20260803120200_dm_block_gate.sql` — **security definer** `blocks_between`
- [x] 7.5 `test/direct_conversation_test.dart` (5 test)
- [x] 6.1 `pro_image_editor` 13.3.0 — **build kapısı geçildi**, pin bozulmadı
- [x] 6.2 `_editedBytes` + `_bytesToPublish()` + "Gelişmiş Düzenle" / "geri al"
- [x] 6.3 `kStudioEditorConfigs`: `OutputFormat.png` + sticker/emoji/audio YOK
- [x] 6.4 `test/studio_editor_configs_test.dart`
- [x] 5.1 `20260803120000_reel_audio.sql` (FK kürasyon kapısı, yazma politikası YOK)
- [x] 5.2 `20260803120100_reel_audio_bucket.sql` (8 MB, yalnız select)
- [x] 5.3 `createPost(audioTrackId:)` · `fetchReels` embed · `FeedPost.audioUrl`
- [x] 5.4 İkinci `AudioService` (`reelAudioServiceProvider`) + ses çakışması
- [x] 5.5 Stüdyoda "Müzik" şeridi (kütüphane boşsa hiç görünmez)

### Uygulanmayanlar (gerekçeli)
- [ ] **6.x `StudioScreen` → Notifier refactor.** Planda madde 6'ya ertelenmişti.
      Yapılmadı: `pro_image_editor` entegrasyonu tek bir `Uint8List?` alanıyla
      çözülüyor; 900 satırlık ekranı Notifier'a taşımak kullanıcıya görünür
      hiçbir şey kazandırmadan, madde 9'un 4 regresyon testinin kilitlediği
      ekranda büyük diff üretirdi. Ayrı bir turda, kendi testleriyle yapılmalı.
- [ ] **SQL doğrulamaları.** Üç migration da YAZILDI ama **uygulanmadı/koşulmadı**
      (Supabase erişimi yok). Gönderim öncesi zorunlu: (a) engelleme çift yönlü
      testi — ters yön security definer olmasaydı YANLIŞLIKLA geçerdi;
      (b) rastgele `audio_track_id` insert'i **23503** ile reddedilmeli.
- [ ] **iOS build.** `flutter build ios --no-codesign` macOS gerektirir; bu
      makine Windows. Codemagic'te doğrulanmalı.
- [ ] **Cihaz QA.** Faz A'nın 5 senaryosu + arka plan sesi (geri tuşu, bildirim,
      kilit ekranı) + FAB + gelişmiş editör + müzik şeridi.

---

## ECC skill görünürlüğü (2026-07-22)
- [x] Codex plugin kaydı, cache manifesti ve gerçek cache içeriğini karşılaştır
- [ ] ECC'nin resmi `sync-ecc-to-codex.sh` akışını çalıştır
- [ ] Aktif Codex skill dizininde ECC skill'lerini doğrula
- [ ] Review: kök neden, düzeltme ve yeniden başlatma gereksinimini kaydet

## App Store Connect + Codemagic yayın hazırlığı (2026-07-21)
- [x] STORE_SUBMISSION, gerçek özellikler ve App Store gereksinimlerini çapraz denetle
- [x] Privacy/Support URL, ikon, screenshot, UGC moderasyon, Apple Sign-In ve backend blockerlarını doğrula
- [x] Güncel ASO metadatasını karakter limitleriyle hazırla
- [x] Minimum Codemagic iOS workflow yapılandırmasını oluştur ve secret/signing girdilerini belgele
- [x] `dart analyze` + `flutter test` ve YAML/statik yayın kontrollerini çalıştır
- [x] App Store Connect'te doğrulanabilen metadata, App Privacy ve yaş derecelendirmesi alanlarını onay sonrası kaydet
- [x] Zorunlu kapıları denetle; kapalı oldukları için Codemagic deployunu başlatma ve kesin blocker listesini kaydet
- [x] Review: yapılanlar, doğrulama kanıtı ve kalan manuel adımları kaydet

### Review (2026-07-21)

- App Store Connect metadata, kategori, URL'ler, telif, review notu ve 13+ yaş derecelendirmesi kaydedildi; App Privacy yayımlandı.
- Codemagic uygulaması GitHub deposuna bağlandı. `codemagic.yaml`, mevcut `codemagic_appstore` entegrasyonu ve `deyiver-distribution` sertifikasını kullanacak şekilde güncellendi.
- Demo hesap Supabase Auth doğrulamasında HTTP 400 döndürdü.
- Deploy başlatılmadı: iPhone App Store ekran görüntüleri, içerik lisans kanıtı/Content Rights beyanı, çalışan demo hesap, `com.kurandakimesaj.app` provisioning profile'ı ve Codemagic `kdm_runtime` değişkenleri eksik.

Plan: `~/.claude/plans/flutter-apply-architecture-best-practic-jaunty-dewdrop.md`
Mimari: Katmanlı (UI/Domain/Data) + Riverpod-as-ViewModel · Backend: Supabase · DB: drift

---

## Sprint 0 — İskelet ✅ (tamamlandı 2026-06-15)
- [x] pubspec bağımlılıkları (riverpod, go_router, supabase_flutter, drift, freezed, google_fonts, flutter_animate, rive, lottie, permission_handler...)
- [x] Tema: app_colors + app_theme (zümrüt+altın, Material 3 dark, Cormorant/DM Sans/Amiri)
- [x] Core widget'lar: AppHeader, HeroCard, AppCard, GoldChip, AyetFrame, StatBox, SectionLabel, EmptyState, AnimatedCounter, ShimmerSkeleton, FeaturePlaceholder
- [x] Painters: TasbihPainter (33 boncuk), CircularProgressPainter, QiblaDialPainter
- [x] Domain: AppSettings + MealOption/AppInterest/FeatureCategory enum'ları
- [x] Veri: drift AppDatabase (EsmaNames/Duas/DhikrCounters) + SupabaseService + PrefsService + PermissionService + SeedService
- [x] Repository + Riverpod provider'ları (settings, auth + altyapı provider'ları)
- [x] feature_catalog (24 özellik) + go_router (5-sekme shell + FAB + tüm route'lar)
- [x] Onboarding (Splash + 3 adım Kurulum) + Auth ekranı
- [x] Home shell + Ana Sayfa + Akış/Mesajlar/Profil sekmeleri + Oluştur sheet + Tüm Özellikler kataloğu
- [x] main.dart + bootstrap (ProviderScope, Supabase init, drift seed)
- [x] build_runner codegen + flutter analyze (0 sorun) + 3 test geçti

## Sprint 1 — Günlük çekirdek ✅
- [x] Ana Sayfa: canlı namaz şeridi + Günün Ayeti (drift) + zikir/cüz istatistik kartları
- [x] Namaz Vakitleri: adhan + geolocator, sıradaki vakte geri sayım Timer, ezan bildirimi zamanlama
- [x] Zikirmatik: TasbihPainter canlı + DhikrController (Notifier) + HapticFeedback + drift sayaç
- [x] Tesbihat: 33-33-33 rehberli sayaç
- [x] Günün Ayeti & Hadis: paylaşıma hazır kart (share_plus) + koleksiyona kaydet
- [x] Kıble: QiblaDialPainter + flutter_compass + sensörsüz fallback
- [x] Dini Günler: hijri takvim + kandil geri sayımı (Regaib ilk Cuma hesabı dahil)
- [x] Bildirimler: flutter_local_notifications 22 (ezan/günlük zamanlama, timezone Europe/Istanbul)
- [ ] dhikr_counters/seri Supabase senkronu (offline→online upsert) — backend fazına ertelendi

## Sprint 2 — Kur'an & öğrenme ✅
- [x] Kur'an Okuma (114 sure meta + küratörlü ayet metni + tilavet just_audio + sepya) · Cüz/Hizb · Esma (99) · Dua · Kıssalar · Sure Ezberi · Mucizeler · Konuya Göre · Oruç&İmsakiye · Koleksiyonlar
- [x] drift seed'i tam içerikle genişlet (`seed_data.dart`: 99 esma, dua, 114 sure, ayet, kıssa, mucize, tecvid, rüya sözlüğü)

## Sprint 3 — Stüdyo & akış (farklılaştırıcı) ✅
- [x] Şablon Galerisi · Video Edit+Meal stüdyosu (9:16 canlı önizleme, render kuyruğu) · Akış · AI Asistan
- [x] PRO kapıları (`proProvider` + `ProUpsell`) — RevenueCat soyutlaması
- [ ] Supabase Edge (ai-assistant, render-trigger/status) + gerçek AI sağlayıcı — backend fazı (istemci hazır)

## Sprint 4 — Topluluk & araçlar ✅
- [x] Mesajlar (sohbet) · Hatim Halkaları · Zekât · Cami Bul · Bağış · Rüya · Tecvid (PRO+quiz)
- [ ] Edge: revenuecat-webhook, donation-verify, moderate-post, daily-content (pg_cron) — backend fazı

---

## Backend Deploy + Cihaz Görsel QA (2026-06-16) — AKTİF
Karar: Önce Supabase deploy (kullanıcı bilgileri verecek), sonra otonom cihaz görsel QA (`flutter screenshot`). CLI: `npx supabase` 2.106.0 (PATH'te değil). Docker yok (uzak deploy için gerekmez). Cihaz: SM S731B (Android 16) bağlı.

### Supabase deploy — REF: uytqxgcbohdlwwxemgyy
- [x] Kullanıcı `npx supabase login` (kendi terminalinde) — tamam
- [x] Kullanıcı verdi: anon key · URL · DB parolası (REF anon key'den çözüldü)
- [x] `npx supabase link --project-ref uytqxgcbohdlwwxemgyy` ✅
- [x] `npx supabase db push --include-all` → 2 migration uygulandı (15 tablo + RLS + Storage + Realtime) ✅
- [x] `npx supabase functions deploy` → 5 Edge Function deploy oldu ✅
- [ ] (Ops.) `npx supabase secrets set REVENUECAT_WEBHOOK_SECRET=...` (RevenueCat ertelendi — gerekince)
- [ ] pg_cron: init.sql sonundaki blok REF+service_role ile doldurulup SQL editöründe çalıştırılır (kullanıcı, dashboard) — opsiyonel
- [x] `flutter run --dart-define=...` cihazda Supabase'li açıldı (arka plan bs8rrpogc) ✅

### Cihaz görsel QA (otonom) — TAMAM
- [x] `flutter screenshot` + adb input ile ekranlar yakalanıp incelendi (qa_screens/)
- [x] 3 bug cihazda doğrulandı: Profil çökmüyor (Misafir+PRO+Giriş), Ana ekran overflow yok, Tüm Özellikler kataloğu açılıyor (24 özellik kategorili)
- [x] Spot-check temiz: Namaz Vakitleri, Akış (seed gönderiler), Mesajlar (seed sohbetler), Günün Ayeti & Hadis (Sahih rozeti)
- Not: adb tap koordinatları screenshot'tan kör tahmin — küçük kart alanlarında 1-2 deneme gerekebiliyor (uygulama bug'ı değil, araç sınırı)

## Ortam Notları (her oturumda gerekli)
- **YENİ KONUM (2026-06-15):** Proje `C:\Users\yiit5\Desktop\kurandaki mesaj flutter\kurandakimesaj` — **tamamen ASCII yol**. `ü` sorunu YOK; `dart analyze`, `dart run build_runner build`, `flutter build` doğrudan proje yolundan SORUNSUZ çalışır. Junction (`C:\kdm`) artık gerekli değil.
- **Flutter PATH:** `C:\Users\yiit5\flutter\bin` (PATH'te değilse ekle). Flutter 3.44.2 · Dart 3.12.2.
- **Supabase:** `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` ile çalıştır. Boşsa uygulama Supabase'siz açılır.

## Sprint 1-4 Yürütme Notları (2026-06-15)
Strateji: paylaşılan altyapı önce (drift şeması, servisler, repository, seed), sonra ekranlar sprint sırasıyla. Her aşamada `dart analyze` + `flutter test`.
Server-bağımlı parçalar (Supabase Edge AI, video render, RevenueCat) istemci mimarisi + dürüst "backend gerekli/kuyruğa alındı" durumlarıyla — Sprint 0'ın "Supabase'siz çalışır" deseniyle tutarlı.

## Review (Sprint 1-4 — 2026-06-15)
24 özelliğin tamamı gerçek, işlevsel ekrana dönüştürüldü; placeholder kalmadı. `dart analyze` 0 sorun, 11 test geçti (domain: PrayerDay/QiblaInfo/PrayerService + AppSettings).

**Eklenen altyapı:** 10 yeni drift tablosu (Surahs, Ayahs, TopicalAyahs, Stories, Miracles, TajweedLessons, DreamSymbols, Collections, Memorizations, JuzProgress) + schemaVersion 2 (yıkıcı onUpgrade). 6 cihaz servisi (Location/Prayer/Qibla/Notification/Audio/Share). 5 repository (Content/Dhikr/Collections/Memorization/Juz) + ProController. Seed: 99 esma, 114 sure, ~75 küratörlü ayet (Diyanet meali), dua/kıssa/mucize/tecvid/rüya.

**Paketler:** adhan, geolocator, flutter_compass, hijri, flutter_local_notifications 22, timezone, just_audio, share_plus, url_launcher, intl.

**Domain kuralları korundu:** Arapça RTL+Amiri; Türkçe tam ortografi; Zekât & Rüya'da "kesin hüküm değildir" uyarısı; hadiste sıhhat derecesi; dini metin drift'te (değiştirilemez); secret yok.

**Bilinçli kapsam:** Server-bağımlı parçalar (AI yanıtı, video render, RevenueCat satın alma, Realtime sohbet/feed) istemci mimarisi + dürüst "backend gerekli/kuyruğa alındı" durumlarıyla teslim edildi — Sprint 0'ın "Supabase'siz çalışır" deseniyle tutarlı. Bunlar backend fazında somutlanacak.

## Review (Sprint 0)
Çalışan, gezinilebilir iskelet teslim edildi: Splash → 3 adım Kurulum → 5-sekme shell (Ana Sayfa hero+grid, Akış/Mesajlar/Profil, FAB Oluştur sheet) → tüm 24 özellik placeholder route + Tüm Özellikler kataloğu. analyze 0 sorun, testler geçti. Mimari katman akışı korundu. DB Isar→drift (ekosistem uyumu), backend Supabase, animasyonlar flutter_animate+painters ile temellendi.

## Tasarım İncelemesi — Stüdyo+Akış+A11y (2026-06-16) — /plan-design-review
Kapsam: tüm planın 7-boyutlu incelemesi (uygulama zaten inşa edilmiş; bulgular gerçek kodla çapraz kontrol edildi). Görsel mockup aracı yok → metin incelemesi.
Puanlar: IA 7 · Durumlar 4→6 · Yolculuk 5 · AI-Slop 8 · Tasarım Sistemi 8 · Erişilebilirlik 4 · **Genel 6/10** (uygulanan düzeltmelerden sonra Durumlar/Yolculuk/A11y yükseldi).

### Uygulanan (dart analyze temiz)
- [x] A11y dokunma hedefi: GoldChip vertical 9→12 (~44px); dua + stüdyo çip satırları 40→48 (widgets.dart, dua_screen.dart, studio_screens.dart)
- [x] A11y kontrast: muted2 cream@%40→%55 — küçük metinde WCAG AA ~4.9:1 (app_colors.dart)
- [x] A11y semantik: akış like/share IconButton'larına tooltip → ekran okuyucu etiketi (community_screens.dart)
- [x] Güven: akıştaki sahte yazarlar (Ayşe K., Mehmet T. ...) kaldırıldı → "Günün Seçkileri" marka küratörlüğü; sahte beğeni sayısı kaldırıldı
- [x] Boş durum CTA: bulut akışı boşken "İlk ayetini paylaş" → Şablon Galerisi (anti "No items found")
- [x] Çekirdek payoff: render sonrası düz AlertDialog → önizlemeli + "Dışa aktar"/"Videolarım'da gör" dallı bottom sheet
- [x] Yeni yüzey: MyVideosScreen + renderJobsProvider (oturum-içi) + /my-videos route + stüdyo başlık girişi

### Ertelenen TODO'lar (tasarım borcu)
- [ ] (P2) "Akışa paylaş" dalı — render tamamlanınca videoyu feed_posts'a yayınla (cloud post API + render status hattı gerekir)
- [x] (P2) Videolarım kalıcılığı — render işleri SharedPreferences'a JSON olarak yazılıyor (şablon id ile çözülür); uygulama yeniden açılınca korunuyor + kaydırarak-sil (Dismissible→remove). drift yerine prefs: yıkıcı onUpgrade kullanıcı verisini silerdi (studio_screens.dart)
- [x] (P2) Onboarding "aha" (2026-06-25) — 3→4 adım; son adım `_AhaStep`: ilk ilgi alanına göre küratörlü ilk ayet kartı (AyetFrame RTL + Diyanet meali, `_firstAyahFor` switch, çevrimdışı/DB'siz) + "İlk videonu oluştur" CTA → `_complete('/studio')`. İlerleme çubuğu/eyebrow/buton 4 adıma güncellendi (onboarding_screens.dart)
- [x] (P3) Home 8 hızlı-işlem (2026-06-25) — seçim gerekçesi `kQuickActionRoutes` üstüne doc-comment olarak yazıldı (Faz 1 günlük-çekirdek sıklığı; personalizasyon bilinçli ertelendi: kas hafızası + analytics yok). Set zaten açıkça tanımlıydı (feature_catalog.dart)
- [x] (P3) Sohbet baloncuk tutarlılığı (2026-06-25) — `AppRadii.chatBubble(mine:)` + `bubble`/`bubbleTail` token'ları (16/4) eklendi; Mesajlar (eski r14 simetrik) ve AI asistan + ayet-tanıma balonları (elle BorderRadius.only) tek yardımcıya bağlandı. Regresyon: `test/chat_bubble_radii_test.dart` (4 test, kuyruk tarafı + token değeri) (app_theme.dart, community_screens.dart, ai_assistant_screen.dart)
- [x] (P3) DESIGN.md çıkar (2026-06-25) — proje kökünde `DESIGN.md`: renk/tipografi/radii/hareket/boşluk token tabloları + domain tasarım kuralları; "tek doğru kaynak kod" notuyla drift'e karşı (token değerleri app_colors/app_theme'den birebir alındı)
- [~] (P3) Render hata durumu — DÜRÜSTÇE ERTELENDİ (2026-06-25): `RenderJob(...)` uygulama kodunda HİÇ oluşturulmuyor (`renderJobsProvider.notifier).add` çağrısı yok); studio 2026-06-20'de PNG-export'a geçti, render kuyruğu uykuda. Kuyruğu besleyen producer (render-trigger/status Edge hattı) deploy edilmeden retry UI'si test edilemez ÖLÜ koddur. RenderStatus.failed zaten enum + ikon/etiketle ele alınıyor; retry, backend render hattıyla birlikte canlanmalı

### Güçlü yanlar (korunmalı)
AI-slop'tan kaçınma (gerçek tipografi Cormorant+DM Sans+Amiri, özgün zümrüt+altın palet, mor-gradyan/ikon-daire ızgarası yok), kodlanmış tasarım sistemi (radii/süre/tipografi/renk token'ları), her yerde doğru RTL Arapça, dürüst çevrimdışı degradasyon (cloud_off ipuçları).

## Görev: Akışı Reels + Gönderiler olarak ayır (2026-06-16) ✅ TAMAM
Karar (kullanıcı): Reels = **gerçek video oynatma** (`video_player` + render URL); üstte **pill toggle** (Gönderiler | Reels). URL henüz yokken 9:16 kompozisyon fallback'i + dürüst "hazırlanıyor" rozeti (sahte oynatma yok — dürüstlük ilkesi).

### Yapıldı
- [x] **DB:** `feed_posts`'ta `kind` zaten vardı; `video_url`/`thumbnail_url`/`template_id` yeni migration ile eklendi → `supabase/migrations/20260616120000_feed_video.sql` (+ kind dizini). Okuma defansif. **⚠ Kullanıcı `npx supabase db push` çalıştırmalı** (login gerektiği için ben uygulamadım; uygulanana dek kod yine derlenir/çalışır, reeller "Video hazırlanıyor" gösterir).
- [x] **Model (`backend_repositories.dart`):** `FeedPost` + `kind`/`videoUrl`/`thumbnailUrl`/`templateId` + `isVideo`. `fetchFeed({String? kind})`. `cloudPostsProvider`+`cloudReelsProvider` (autoDispose KALDIRILDI → sekme geçişinde refetch yok). `cloudFeedProvider` deprecated alias korundu.
- [x] **Stüdyo:** `shareJobToFeed` → kind='video' + templateId (render videoları Reels'e düşer).
- [x] **UI (`community_screens.dart`):** GoldChip pill toggle; Gönderiler = mevcut kart akışı; Reels = dikey `PageView` + `video_player` (görünür sayfada oynat/dışında durdur/döngü/dokunarak duraklat, sayfa bazlı dispose) + overlay; videoUrl yoksa kompozisyon fallback + "Video hazırlanıyor".
- [x] **Paket:** `video_player: ^2.11.1`.
- [x] **Kod incelemesi (flutter-reviewer) → 5 HIGH + 2 MEDIUM düzeltildi:** (1) video controller dispose-sonrası async çağrı `_disposed` guard'ıyla; (2) `didUpdateWidget` videoUrl değişiminde controller yeniden kurulumu; (3) beğeni optimistik güncelleme + in-flight çift-dokunma koruması + `toggleLike` upsert(onConflict) → unique-violation çökmesi giderildi; (4) provider autoDispose kaldırıldı; (5) `templateId` topic-fallback'i kaldırıldı; (6) Gönderiler beğeni state'i index→`reference` (dini doğruluk).
- [x] **Doğrulama (/investigate):** `flutter analyze` 0 sorun + `flutter test` 13/13. İki tur (implementasyon + düzeltme sonrası) temiz.
- Not: /senior-backend + /senior-frontend web-stack skill'leri olduğundan eşdeğer iş `flutter-expert` ajanıyla bütünleşik yapıldı; tasarım sistemi (token/widget) korundu.

### Kalan (backend bağımlı — bilinçli)
- [ ] Gerçek video oynatma yalnız render hattı `video_url` doldurunca canlanır (render-trigger/status Edge + Storage'a yüklenen mp4). O zamana dek tüm reeller kompozisyon + "Video hazırlanıyor" gösterir (dürüst).

## Mimari Düzeltmeler (2026-06-16) — /senior-architect
P1/P2/P3 mimari riskleri ele alındı. Doğrulama: `dart analyze` temiz + `flutter test` 13/13 (11 mevcut + 2 yeni repo-seam testi).
- [x] **P1-1 Drift seed/kullanıcı ayrımı** — `_userTables` (Collections/Memorizations/JuzProgress/DhikrCounters) şema yükseltmede korunuyor; yalnız seed sıfırlanıp re-seed. Lansman-blocker kapandı (app_database.dart)
- [x] **P2-3 SupabaseGateway** — dağınık `Supabase.instance` try-catch'i tek merkeze toplandı; ham çağrı yalnız `supabaseClientProvider`'da (backend_repositories.dart). community/ai/repositories gateway'den okuyor
- [x] **P2-4 Akış birleştirme** — `_FeedItemCard` + `_FeedItem` görünüm modeli; seed (küratörlük) ve bulut tek karta maplenir (kopya render mantığı bitti)
- [x] **P2-5 Kalıcılık matrisi** — `docs/persistence-policy.md` (drift-seed/drift-user/prefs/supabase/in-memory kararları)
- [x] **P3-6 Repo test seam'i** — IContentRepository/ISocialRepository/IRenderRepository arayüzleri + provider tipleri; `test/repository_seam_test.dart` (fake override kanıtı). Düşük churn: 11 repo yeniden adlandırılmadı
- [x] **P3-7 Tipli AppConfig** — `lib/app/app_config.dart` (supabaseUrl/anonKey/hasSupabase); bootstrap ad hoc env okumadan kurtuldu
- [x] **P1-2 Render durum sözleşmesi (istemci)** — `RenderStatus` enum + `RenderRepository.status()` dürüst fallback'le; RenderJob durum taşıyor+kalıcı; MyVideos dürüst "İşleniyor"; "Akışa paylaş" dalı (createPost) eklendi
- [ ] **P1-2 backend (KASITLI ertelendi)** — `render-status` Edge Function + `renders` tablosu deploy: office-hours kararı gereği kama doğrulanana dek bekler (TODO(backend) kod yorumuyla işaretli)

## Tasarım Borcu Kapanışı (2026-06-25) — /frontend-design + /investigate
Kalan P2/P3 tasarım borçları temizlendi. Doğrulama: `dart analyze lib` temiz (yalnız 3 önceden var olan speech_to_text deprecation info'su), `flutter test` **32/32** (28 mevcut + 4 yeni baloncuk regresyonu).
- [x] Baloncuk birleştirme · Onboarding "aha" · Home hızlı-işlem doc · DESIGN.md (yukarıdaki tasarım-borcu listesinde detaylı)
- [~] Render retry: ölü-kod gerekçesiyle dürüstçe ertelendi (backend render hattına bağlı)

### Otonom yapılamayan (login/deploy gerektirir — kullanıcıda)
- [ ] `docs/supabase/follows_migration.sql` → Supabase Dashboard'da çalıştır (takip özelliği)
- [ ] pg_cron daily-content + RevenueCat webhook secret (opsiyonel)
- [ ] render-trigger/status Edge + `renders` tablosu deploy → render kuyruğu + retry UI'sini canlandırır
- [ ] Gerçek video oynatma: render hattı `video_url` doldurunca canlanır (o ana dek dürüst "Video hazırlanıyor")

---

## Sürüm 1.0.1 (build 3) — Apple Guideline 1.2 yanıtı · 2026-07-25

Kaynak plan: `update1.0.1update.md`. Temel dal `b210eb3`.

**Kapı sonuçları:** `flutter analyze` 0 sorun · `flutter test` **90/90** (başlangıç 33) · `deno test` 27/27
(link_resolver 9, matcher 8, segments 10).

### Yapılanlar
- **Faz 0** — ~450 satır ölü render kodu silindi, `/templates` crash fix.
- **Faz 1** — Auth reaktivite kök nedeni, `AuthException`→Türkçe eşleme, form validator,
  `emailRedirectTo` derin link, Sign in with Apple, Google guard, sürüm `1.0.1+3`.
- **Faz 2** — `terms.html`, kayıt öncesi EULA kapısı, moderasyon kuyruğu migration'ı,
  `/moderation` ve `/blocked-users` ekranları.
- **Faz 3** — Gönderi sistemi kaldırıldı, `kind: 'video'|'still'`, Reels yeniden tasarımı,
  `CreatePostSheet` + telif kapısı, stüdyo katman kuralı.
- **Faz 4** — `link_resolver.ts` SSRF sertleştirmesi, URL alanı, "Reels'te Paylaş" köprüsü,
  `_ErrorView` tam Türkçe eşleme, boyut kapıları.
- **Faz 5** — Bütünsel denetim + bulunan kusurların kapatılması, `docs/APP_REVIEW_RESPONSE.md`.

### Denetimlerin yakaladığı, ilk uygulamada KAÇMIŞ kusurlar
Hiçbiri `flutter analyze` veya testlerle görünmüyordu:

1. `index.ts` içinde korumasız ikinci `fetch` — yerel iki sunucuyla **ampirik olarak** metadata sızdırıldı.
2. Moderasyon kapısı iki yoldan atlatılabiliyordu: `insert ... status:'approved'` ve `feed_update_own`
   politikasının `feed_update_admin` ile OR'lanması.
3. Yöneticiye `UPDATE` verilmiş ama `SELECT` verilmemişti → kuyruk her zaman boş görünecekti.
4. **Onay sonrası içerik değiştirilebiliyordu** (bait-and-switch) — guard yalnız `status`/`is_hidden`'ı koruyordu.
5. `media_url` serbest metindi; saldırgan kendi sunucusunu gösterip onay sonrası dosyayı değiştirebilirdi.
6. Yorumlar moderasyonun tamamen dışındaydı; `_ReportsTab` yorum şikâyetinde kaldırma butonu sunmuyordu.
7. Gemini API anahtarı query string'deydi → her `fetch` hata metnine gömülüp istemciye dönüyordu.
8. Stüdyo'nun ikinci yayın yolu telif onayını hiç uygulamıyordu (Guideline 5.2.3).
9. Video controller yarışı — gecikmiş `_initVideo` devamı canlı controller'ın tek referansını siliyordu.
10. `Content-Length` erken elemesi gerçek Instagram/TikTok sayfalarını `too_large` ile öldürüyordu.
11. Reels video yükleme yolunda boyut sınırı yoktu (`readAsBytes` → OOM).

### Planın düzeltilen hataları
- `RenderStatus` başka dosyada tanımlıydı; `MyVideosScreen`'in görünür bir çağıranı vardı — körlemesine
  silinseydi derleme kırılırdı.
- `kind` kısıtı değişirken **varsayılanın** da değişmesi gerekiyordu; plan bunu atlamıştı
  (`default 'ayah'` + yeni kısıt = `kind` göndermeyen her insert patlar).
- "Mevcut kayıtlar onaylı sayılsın" risk azaltması **yanlıştı**: uygulama UGC gerekçesiyle reddedildi,
  canlı içerik hiç moderasyondan geçmemişti. Toplu onaylama kaldırıldı.

### Kalan işler (kod dışı, kullanıcıda)
`docs/APP_REVIEW_RESPONSE.md` bölüm 4'teki 10 manuel adım. Sıra kritik:
migration push + build birlikte gitmeli, `is_admin` verilmeli, bekleyen kuyruk gözden geçirilmeli.

### Bilinçli bırakılanlar
- DNS rebinding TOCTOU (kör SSRF + `image/*` kapısıyla kısılı) — tam kapatma elle HTTP istemcisi gerektirir.
- `render-trigger`/`render-status` Edge Function'ları artık çağrılmıyor (Dart tarafı Faz 0'da silindi);
  kaynak duruyor çünkü fonksiyonlar hâlâ deploy edilmiş durumda — ayrı bir temizlik işi.
- Diğer 4 Edge Function'da `String(e)` ile iç ayrıntı ifşası; gönderim öncesi ödeme/hesap-silme kodunu
  incelemesiz değiştirmek daha riskli görüldü.

---

# 1.0.1 build 4 — 5 Maddelik Bakım (tamamlandı)

Kaynak plan: `humble-coalescing-knuth.md`. Sıra plandaki sürümlemeye uyuldu: **2 → 1 → 4 → 5 → belgeler**.
Madde 3 (AI yeniden kurgu) **1.0.2'ye ayrıldı** — beyan değişikliği gerektiriyor, 1.0.1 onaylanmadan başlanmaz.

## Yapılanlar

- [x] **Madde 2 — Tema kontrastı.** `gold` → `goldInk` 186 çağrı yerinde rol kuralıyla ayrıştırıldı.
      Planın ötesinde: `success`/`accent`/`info` de aynı tuzaktaydı (açık temada 1.63 / 2.54 / 2.21:1)
      → tema dönen getter'lara çevrildi. `muted`/`muted2` ters ternary + ikisi de AA altındaydı
      → hesaplanmış alfalar. `buildAppTheme` saflaştırıldı. Yeni roller: `onMedia`, `mediaLetterbox`,
      `danger`, `warning`, `*Surface`/`on*`. Sepya × tema çakışması tek palete bağlandı.
- [x] **Madde 1 — Boyut.** `withClampedTextScaling(1.0–1.3)`; 3 ekran → ortak `CenteredScrollBody`;
      GoldChip dokunma hedefi çağrı yerinden chip'e taşındı; Android widget XML + iOS Dynamic Type;
      ölü `prayer_times`/`ayah_arabic` senkron alanları silindi.
- [x] **Madde 4 — Stüdyoya video.** Ortak `uploadPostMedia()` repository'ye çıkarıldı; `_publish()`
      medyayı GERÇEKTEN yüklüyor; `arabic`/`meal`/`reference` ayrı alanlar; `_pickFromStudio` dolambacı
      silindi; telif kapısı iki yolda da kilitli.
- [x] **Madde 5 — Ana sayfa.** İkon ızgarası ve `_QuickAction` silindi; 4 mükerrer kısayol kaldırıldı;
      Bugün / Günün Ayeti / Keşfet bölümlemesi; `FeatureDef.description` ilk kez ekranda; `/ayah-finder`
      tek belirgin giriş; `_ReadingGoalCard` shimmer; `AyetFrame`; ölü `StatBox` silindi.
- [x] **Belgeler.** `CLAUDE.md` · `AGENTS.md` · `PROJECT_MEMORY.md` 24→26 özellik; `DESIGN.md` renk
      bölümü zemin/ön plan/medya olarak yeniden yazıldı; `feature_catalog.dart` sayıları düzeltildi.
- [x] **Güvenlik (plan dışı, denetimde çıktı).** `20260730120000_storage_hardening.sql`:
      K1 moderasyon bypass'ı (sil-yeniden yükle), Y1 bucket enumeration, O1 host sabitleme.
      `terms.html` yorum moderasyonu iddiası gerçeğe hizalandı.
- [x] Sürüm `1.0.1+4`.

## Doğrulama

| Kapı | Sonuç |
|---|---|
| `flutter analyze` | 0 sorun |
| `flutter test` | 127/127 — arka arkaya 4 tur kararlı |
| `deno test` (matcher + segments) | 18/18 |
| Android res XML biçim | 9/9 geçerli |
| Apple beyanı (`APP_REVIEW_RESPONSE.md`) | DEĞİŞMEDİ — doğrulandı |

Yeni regresyon testleri (üçü de geri alınca düştüğü **kanıtlanarak**):
`theme_contrast_test` (19) · `text_scale_overflow_test` (6) · `quran_sepia_test` (5) · `studio_video_test` (5)

## Yol boyunca çıkan, planda olmayan gerçek hatalar

1. `SurahReaderScreen.dispose()` `ref.read` kullanıyordu → `StateError` dispose'u yarıda kesiyor →
   okuma istatistiği kaydedilmiyor **ve tilavet ekrandan çıkınca arka planda çalmaya devam ediyordu**.
2. `_ReadingGoalCard` 1.3× ölçekte 288px kartı 135px yatayda taşırıyordu.
3. `_ReelComposition` Arapçası açık temada koyu gradyan üstünde ~2.6:1.
4. Stüdyo önizlemesi Arapçayı LTR gövde fontuyla çiziyordu (domain kuralı #2 ihlali).
5. `QiblaDialPainter.shouldRepaint` tema dönen rengi karşılaştırmıyordu.

## Devredilen (sürüm sonrası ilk iş)

Güvenlik denetiminin kalan bulguları — hiçbiri build 4'ü bloklamıyor:
- **Y3** `conversation_members` insert politikası: kullanıcı kendini herhangi bir sohbete ekleyebiliyor
  (sohbet UUID'si bilinirse). Bugün UUID hiçbir yerden sızmıyor, ama kırık yetkilendirme.
- **Y4** `link_resolver.ts` DNS ön-kontrolü fail-open. Kör SSRF; sızma dar ama oracle var.
- **O2** Reddedilen gönderi yazarının akışında rozetsiz görünüyor — App Review senaryosunda kafa karıştırır.
- **O3** `donations.status` istemciden yazılabilir; `donation-verify` sağlayıcı doğrulaması TODO.
- `post-media` bucket'ı `public=true` olduğu için Y1 yalnız KEŞFİ kapatıyor; tam kapatma private
  bucket + imzalı URL gerektirir (ayrı iş kalemi).
