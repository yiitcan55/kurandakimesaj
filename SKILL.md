---
name: build4-9madde-skill-eslemesi
description: "Kur'an'da ki Mesaj 9 maddelik düzeltme planının (build 4 / 1.0.2 / 1.0.3) faz faz skill ve ajan eşlemesi. Bu plandaki maddelerden birine dokunurken hangi skill'i çağıracağını, hangi ajanı Agent tool ile paralel çalıştıracağını ve hangilerinden uzak duracağını bulmak için kullan."
---

# 9 Maddelik Plan — Skill & Ajan Eşlemesi

> Kaynak: `.claude/plans/g-rev-bir-implantation-glimmering-dream.md`
> Kural: **skill = iş akışı reçetesi** (sen `/` ile çağırırsın) · **ajan = paralel alt görev** (Agent tool ile çalışır).
> Sıra plandaki fazlamaya birebir uyar: **Faz A (build 4) → Faz B (1.0.2) → Faz C (1.0.2 geç / 1.0.3)**.

## Değişmeyen Sınırlar — hiçbir skill/ajan bunlara dokunamaz

`feed_posts_moderation_guard` · `feed_select_visible` / `feed_select_admin` · `is_own_post_media` ·
`revoke update on profiles` · `BottomBar` `heightFactor: 1` · `receive_sharing_intent` 1.8.1 pini ·
`test/bottom_bar_height_test.dart`

> Ajan çağırırken bu listeyi prompt'a **kopyala**. App Store onayı moderasyon kapısına bağlı; `ecc:refactor-cleaner` ve `ecc:database-reviewer` gibi "iyileştirici" ajanlar bu satırları kendiliğinden sadeleştirmeye kalkabilir.

---

# FAZ A — Build 4 (bugün, tek PR)

## Madde 9 — `!debugNeedsPaint` çökmesi (EN KRİTİK)

| Adım | Skill | Ajan |
|---|---|---|
| Kök nedeni kodda tekrar doğrula (sliver-paint tuzağı, `_previewKey` → tembel `ListView` çocuğu) | `investigate` (Iron Law) | `error-detective` |
| `_renderPng` / `RepaintBoundary` / `_previewKey`'in **tüm** çağıranlarını çıkar (`_export` de aynı kökten besleniyor) | — | `Explore` (dokunmadan önce referans taraması) |
| Önizlemeyi `ListView`'den `Flexible > Padding > FittedBox > SizedBox(360×640)` sabit tuvale taşı | `flutter-fix-layout-issues` · `flutter-build-responsive-layout` | `ecc:flutter-reviewer` |
| `endOfFrame` + `pixelRatio: 3.0` determinizmi, `.animate().fadeIn()` silinmesi | `ecc:flutter-review` | `ecc:performance-optimizer` (boundary katmanı / kare yakalama) |
| `test/studio_render_offscreen_test.dart` — **önce kırmızı** (390×760 yüzey + drag) | `flutter-add-widget-test` · `ecc:flutter-test` · `superpowers:test-driven-development` | `ecc:tdd-guide` |
| `_RecordingSocialRepository.lastBytes` harness eklemesi | `ecc:flutter-test` | — |

**Kapı:** düzeltmesiz test `'!debugNeedsPaint': is not true` ile **düşüyor** · düzeltmeyle `takeException() == null` · IHDR genişliği `1080`.

**Bu maddede kullanma:** `ecc:code-architect` / `flutter-apply-architecture-best-practices` — `StudioScreen`'in `setState` → Notifier refactor'ü **madde 6'ya ertelendi**; inceleyicinin test edeceği ekranda büyük diff istemiyoruz.

---

## Madde 8 — Profilde gönderiler gözükmüyor

| Adım | Skill | Ajan |
|---|---|---|
| `FeedPost.fromMap` ve `getUserPosts` tüketicilerini haritala (dönüş tipi değişiyor) | `ecc:repo-scan` | `ecc:code-explorer` |
| `select('*')` + `FeedPost.fromMap` — fallback'i tek yerde tut | `ecc:dart-flutter-patterns` | `ecc:flutter-reviewer` |
| `catch(_) { return []; }` → hata yayılımı + `String? _error` + "Tekrar dene" | `ecc:error-handling` | `ecc:silent-failure-hunter` |
| RLS'in **doğru** davrandığını doğrula (`feed_select_visible`) — **değiştirme** | `ecc:postgres-patterns` | `ecc:database-reviewer` (salt okunur denetim) |
| "İncelemede" rozeti (`status == 'pending'`) | `mobile-design` | `ui-ux-designer` |
| `test/profile_posts_test.dart` — iki `fromMap` assert'i | `flutter-add-widget-test` | `ecc:tdd-guide` |

**Kapı:** ızgarada görseller var (boş yeşil kutu yok) · RLS reddi "Henüz gönderi yok" diye maskelenmiyor.

---

## Madde 3 — Instagram/TikTok paylaşımı açılmıyor (soğuk başlatma)

| Adım | Skill | Ajan |
|---|---|---|
| `go('/home')` yığın silme tuzağını doğrula (`_onShared` + `_onWidgetClick` ikisi de kırık) | `investigate` | `error-detective` |
| `sharedAyahInputProvider`'ın tek seferlik tüketimini ve tüm okuyucularını çıkar | — | `Explore` |
| `SplashScreen._go` sonrasına koşullu `context.push('/ayah-finder')` | `flutter-setup-declarative-routing` | — |
| `singleTop` **korunuyor** kararının platform doğrulaması (taskAffinity, `home_widget` deep-link) | — | `mobile-developer` |
| `test/share_cold_start_test.dart` — 3 stub rotalı mini `GoRouter` | `flutter-add-widget-test` · `ecc:flutter-test` | `ecc:tdd-guide` |

**Kapı:** uygulama **kapalıyken** paylaşım → Ayet Bul açılıyor · paylaşım yokken `/home`'da kalıyor.

**Bu maddede kullanma:** router-level `redirect` (push edemez) · `singleTask` (recents ve widget deep-link'ini bozar) · `pendingDeepLinkProvider` genellemesi (yeni global durum → 1.0.2).

---

## Madde 7-kısmi — Mesajlar boş-durum dürüstlüğü

| Adım | Skill | Ajan |
|---|---|---|
| Ölü kodun gerçekten çağrılmadığını kanıtla (`_offlineMessages`, `_sendOffline`, `conversationId == null` dalı) | — | `Explore` |
| Silme + dürüst boş-durum metni | `ecc:refactor-clean` · `mobile-design` | `ecc:refactor-cleaner` |

**Kapı:** sekme "yarım özellik" değil, dürüst boş durum. **Sekmeyi kaldırma** — `bottom_bar_height_test.dart` build 3 bug'ının kilidi.

---

## Faz A Doğrulama Kapısı

| Adım | Skill | Ajan |
|---|---|---|
| `flutter analyze` 0 · 95/95 test | `ecc:flutter-build` | `ecc:dart-build-resolver` |
| Değişen kodun bütünsel incelemesi | `/code-review` · `ecc:flutter-review` | `ecc:code-reviewer` · `ecc:flutter-reviewer` |
| Yeni 3 regresyon testinin gerçekten ayırt edici olduğu | `ecc:test-coverage` · `ecc:quality-gate` | `ecc:pr-test-analyzer` |
| Cihaz E2E (5 senaryo, Samsung SM S731B) | `qa` | `ecc:e2e-runner` |
| Tamamlandı demeden önce kanıt | `superpowers:verification-before-completion` | — |
| `PROJECT_MEMORY.md` Karar Günlüğü (sliver-paint · `go` yığın silme · heroTag çakışması) | `docs-writing` · `ecc:update-docs` | — |
| Sürüm `1.0.1+4` + Codemagic | `ecc:deployment-patterns` | `deployment-engineer` |

---

# FAZ B — 1.0.2 (native içerir, ayrı TestFlight turu)

## Madde 2 — Arka plan ses + bildirim medya çubuğu

| Adım | Skill | Ajan |
|---|---|---|
| `just_audio_background` güncel API sözleşmesi + **tam sürüm pinleme** | `ecc:documentation-lookup` | `ecc:docs-lookup` (Context7) |
| `JustAudioBackground.init` + `AudioSource.uri(tag: MediaItem)` + `show MediaItem` isim çakışması | `ecc:dart-flutter-patterns` · `flutter-apply-architecture-best-practices` | `ecc:flutter-reviewer` |
| Manifest izinleri, `foregroundServiceType`, `MediaButtonReceiver`, `MainActivity : AudioServiceActivity()`, iOS `UIBackgroundModes` | — | `mobile-developer` |
| `pub add` sonrası bağımlılık/minSdk çakışması | `ecc:flutter-build` | `ecc:dart-build-resolver` |
| TTS ses odağı (`onSpeakStart` → `audioService.pause()`) | `ecc:error-handling` | `ecc:silent-failure-hunter` (yutulan çakışma) |
| `mediaTitleFor()` birim testi + cihaz senaryoları | `flutter-add-widget-test` · `qa` | `ecc:tdd-guide` |

**Kapı:** geri tuşunda ses sürüyor · bildirimden oynat/duraklat · iOS kilit ekranı · `launchMode="singleTop"` korunmuş.

---

## Madde 1 — Ana sayfa sol-alt AI butonu

| Adım | Skill | Ajan |
|---|---|---|
| `heroTag`'siz **tüm** FAB'ları bul (`feed_create_fab` çakışması uygulamayı düşürür) | — | `Explore` |
| `HomeScreen` kendi `Scaffold`'una FAB + `startFloat` + `heroTag` | `mobile-design` · `ecc:make-interfaces-feel-better` | `ui-ux-designer` |
| `ListView` alt padding 24 → 96 | `flutter-fix-layout-issues` | — |
| `home_ai_fab_test.dart` + `bottom_bar_height_test.dart` **hâlâ yeşil** | `flutter-add-widget-test` | `ecc:tdd-guide` |

**Bu maddede kullanma:** `HomeShell` / `BottomBar` düzenlemesi — `heightFactor: 1` hücresi build 3 bug'ının düzeltmesi.

---

## Madde 4 — Reels açıklamaları

| Adım | Skill | Ajan |
|---|---|---|
| `caption`'ın DB → `fromMap` → `_Reel` → UI yolunu haritala | `ecc:repo-scan` | `ecc:code-explorer` |
| `FeedPost.caption` alanı + `_Reel` mapping | `ecc:orch-add-feature` | `ecc:flutter-reviewer` |
| `ReelCaption` genişletme affordance'ı (efemer durum → Notifier **yok**) | `mobile-design` · `ecc:motion-ui` | `ui-ux-designer` |
| `_ReelComposition` latent `meal` taşması (`maxLines: 10`) | `flutter-fix-layout-issues` | — |
| `test/reel_caption_test.dart` | `flutter-add-widget-test` | `ecc:tdd-guide` |

---

# FAZ C — 1.0.2 geç / 1.0.3

## Madde 7-tam — Profilden DM başlat

| Adım | Skill | Ajan |
|---|---|---|
| Mevcut politikaların iki-insert yolunu desteklediğini doğrula (`conv_insert_own` + `cmembers_insert`) — **RPC yazma** | `ecc:postgres-patterns` | `ecc:database-reviewer` |
| `openDirectConversation` + tekilleştirme tek sorgusu + `myConversations` embed | `ecc:blueprint` · `ecc:orch-add-feature` | `ecc:code-architect` · `fullstack-developer` |
| Migration `20260803120200_dm_block_gate.sql` — engelleme **veritabanında** zorlanır | `ecc:database-migrations` | `ecc:database-reviewer` |
| `user_blocks` kolon adları + çift yönlü `not exists` denetimi | `ecc:security-review` | `ecc:security-reviewer` |
| ChatScreen "Kullanıcıyı engelle" (1.2 gereği) | `mobile-design` | `ui-ux-designer` |
| İki oturumlu SQL doğrulaması + idempotent `openDirectConversation` | `ecc:e2e-testing` | `ecc:tdd-guide` |

---

## Madde 6 — Stüdyo: `pro_image_editor` (**madde 9'a bağımlı**)

| Adım | Skill | Ajan |
|---|---|---|
| **İlk adım:** `pub get` → `flutter build apk --debug` + `ios --no-codesign`; `receive_sharing_intent` 1.8.1 pini kırılırsa **maddeyi geri al** | `ecc:flutter-build` | `ecc:dart-build-resolver` |
| Paketin güncel `ImageGenerationConfigs` / tool API'si | `ecc:documentation-lookup` | `ecc:docs-lookup` (Context7) |
| `_bytesToPublish()` akışı + `_editedBytes` + "Düzenlemeyi geri al" | `ecc:blueprint` · `ecc:orch-add-feature` | `ecc:code-architect` |
| `StudioScreen` → Notifier refactor (**burada yapılır**, madde 9'da değil) | `flutter-apply-architecture-best-practices` · `ecc:refactor-clean` | `ecc:code-architect` · `ecc:refactor-cleaner` |
| `outputFormat: OutputFormat.png` (`uploadPostMedia` `.png` + `image/png` yazıyor) | `ecc:flutter-review` | `ecc:flutter-reviewer` |
| Bellek / büyük bayt dizisi yaşam döngüsü | `ecc:flutter-review` | `ecc:performance-optimizer` |
| PNG imza testi (`lastBytes`) | `ecc:flutter-test` | `ecc:tdd-guide` |

**Bu maddede kullanma:** `sticker` ve `audio` araçları — sticker yeni UGC yüzeyi (1.2), audio madde 5'in küratörlü kütüphanesiyle çakışır.

---

## Madde 5 — Reels küratörlü arka plan sesi

| Adım | Skill | Ajan |
|---|---|---|
| Migration 1 (`feed_audio_tracks` + FK + RLS `select using (is_active)`, **yazma politikası yok**) | `ecc:database-migrations` · `ecc:postgres-patterns` | `ecc:database-reviewer` |
| Migration 2 (`reel-audio` bucket, yalnız select) | `ecc:database-migrations` | `ecc:database-reviewer` |
| `audio_track_id`'nin trigger demetine **bilerek eklenmemesi** — gerekçe SQL'e yazılır | `ecc:security-review` | `ecc:security-reviewer` |
| `createPost` opsiyonel kolon kalıbı + `fetchReels` embed + `FeedPost.audioUrl` | `ecc:orch-add-feature` · `ecc:dart-flutter-patterns` | `ecc:code-architect` |
| İkinci `AudioService` örneği (tilaveti öldürmeden) + `isActive` yaşam döngüsü + ses çakışması | `ecc:flutter-review` | `ecc:performance-optimizer` · `ecc:flutter-reviewer` |
| Stüdyoda "Müzik" şeridi ("Arka Plan" kalıbıyla) | `mobile-design` | `ui-ux-designer` |
| **Kürasyon kanıtı:** rastgele `audio_track_id` insert'i FK 23503 ile reddedilmeli | `ecc:e2e-testing` | `ecc:tdd-guide` |

---

# Bu Plan İçin Kısa Liste

```
Dokunmadan önce:        Explore (ajan) — çağıranları sen değil o bulsun
Çökme / "neden olmuyor": investigate  →  error-detective (ajan)
Yutulan hata / boş liste: ecc:error-handling  →  ecc:silent-failure-hunter (ajan)
Layout & render tuzağı:  flutter-fix-layout-issues  →  ecc:flutter-reviewer (ajan)
Kırmızı-önce test:       flutter-add-widget-test  →  ecc:tdd-guide (ajan)
Yeni paket / native:     ecc:documentation-lookup  →  ecc:docs-lookup + mobile-developer (ajan)
DB / RLS / migration:    ecc:database-migrations  →  ecc:database-reviewer + ecc:security-reviewer (ajan)
Her fazın sonunda:       ecc:flutter-build  →  ecc:dart-build-resolver (ajan)
Gönderim öncesi:         ecc:quality-gate · qa  →  ecc:pr-test-analyzer · ecc:e2e-runner (ajan)
```

# Bu Planda Kullanma

| Skill/Ajan | Neden |
|---|---|
| `ecc:code-architect` / mimari refactor — **Faz A'da** | Madde 9 dört küçük editle çözülüyor; Notifier taşıması madde 6'ya ertelendi (inceleyicinin ekranında büyük diff yok) |
| `ecc:refactor-cleaner` — `studio_screens.dart` üzerinde Faz A'da | Aynı gerekçe; yalnız madde 7'nin ölü kodunda serbest |
| `ai-video-generation` · `ecc:manim-video` · `remotion*` | Gerçek mp4 render **kapsam dışı** (ffmpeg_kit emekli) |
| `ecc:orch-build-mvp` | Sıfırdan modül yok — hepsi mevcut kod üstünde düzeltme |
| Faz B ve Faz C'nin tamamı | Build 4 Apple'dan **onay almadan** başlanmaz; madde 2 yeni arka plan yeteneği açıyor → ikinci inceleme yüzeyi |
| `seo-*`, `game-development`, `3d-*` | Bu projeyle ilgisiz |

> **Not:** Bu kurulumda `flutter-expert` ve `ecc:ui-ux-designer` ajanları **yok**. Karşılıkları: `ecc:flutter-reviewer` / `ecc:code-architect` ve `ui-ux-designer`.
