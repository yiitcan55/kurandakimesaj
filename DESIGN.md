# DESIGN.md — Kur'an'da ki Mesaj Tasarım Sistemi

> Tek doğru kaynak **koddur**: `lib/ui/core/theme/app_colors.dart`, `app_theme.dart`
> ve `lib/ui/core/widgets.dart`. Bu doküman o token'ların **özetidir** — yeni token
> eklerken önce kodu güncelle, sonra burayı eşitle. Değer ihtilafında **kod kazanır**.

Estetik: **zümrüt + altın + sıcak krem**, koyu/manevi, editoryal serif başlık.
İlke: yapay-zekâ-slop'tan kaçın (gerçek tipografi, özgün palet, mor-gradyan/ikon-daire
ızgarası yok); her yerde doğru RTL Arapça; dürüst çevrimdışı degradasyon.

---

## 1. Renk (`app_colors.dart`)

| Token | Değer | Kullanım |
|-------|-------|----------|
| `emerald950` | `#08201A` | Scaffold zemini |
| `emerald900` | `#0D2A20` | Panel / kart |
| `emerald850` | `#0F2C22` | Sheet / yükseltilmiş yüzey |
| `emerald700` | `#1E4D38` | Hero gradyan üst |
| `gold` | `#D4B25B` | Birincil vurgu, ikon, kenarlık |
| `goldBright` | `#E8CB6F` | Parlak vurgu / FAB üst |
| `goldSoft` | `#B69547` | FAB alt / yumuşak altın |
| `goldFaint` | `gold @ %12` | Altın dolgu zeminleri |
| `cream` | `#F3EADB` | Birincil metin |
| `cream2` | `#E6DCC8` | Gövde metni |
| `muted` | `cream @ %62` | İkincil metin |
| `muted2` | `cream @ %55` | Küçük metin — WCAG AA ~4.9:1 (≥%55 koru) |
| `success` | `#5ED27D` | Onay / hazır |
| `accent` | `#C9856A` | Sil / uyarı vurgusu |
| `info` | `#5AA9D6` | Bilgi |
| `line` | `gold @ %18` | Hairline kenarlık |
| `lineSoft` | `cream @ %7` | Çok ince ayraç |

**Gradyanlar:** `heroGradient` (emerald700→950, ↘), `cardGradient`, `cardGradientActive`
(dokununca parlar), `fabGradient` (goldBright→goldSoft).

**Kontrast kuralı:** Küçük gövde metninde `muted` altına inme; `muted2` zaten AA sınırında.

---

## 2. Tipografi (`app_theme.dart` · `AppTypography`)

| Rol | Font | Varsayılan | Özellik |
|-----|------|------------|---------|
| `display()` | Cormorant Garamond | 34px · w600 | `height 1.05`, `letterSpacing -0.5` — başlık/serif |
| `body()` | DM Sans | 15.5px · w400 | `height 1.5` — gövde/arayüz |
| `eyebrow()` | DM Sans | 11px · w700 | `letterSpacing 2.4`, altın — bölüm etiketi (UPPERCASE) |
| `arabicStyle()` | Amiri Quran | 26px | `height 1.9`, altın — **her zaman `Directionality(rtl)`** |

Theme ölçeği: displayLarge 56 / displayMedium 44 / headlineMedium 30 / headlineSmall 24 /
titleLarge 22 / bodyLarge 16 / bodyMedium 14.5.

---

## 3. Köşe yarıçapı (`AppRadii`)

| Token | Değer | Kullanım |
|-------|-------|----------|
| `sm` / `smAll` | 12 | Çip, küçük kart, buton |
| `md` / `mdAll` | 18 | Kart, kutu |
| `lg` / `lgAll` | 28 | Hero, büyük yüzey |
| `sheetTop` | 28 (üst) | Bottom sheet |
| `bubble` / `bubbleTail` | 16 / 4 | Sohbet baloncuğu (üst yumuşak + kuyruk) |

**Sohbet baloncuğu:** `AppRadii.chatBubble(mine:)` — Mesajlar ve AI asistan **tek dili
paylaşır** (gönderen tarafında sağ-alt kuyruk, karşı tarafta sol-alt kuyruk). Yeni sohbet
yüzeyleri elle `BorderRadius.only` yazmaz, bu yardımcıyı çağırır.

---

## 4. Hareket (`AppDurations`)

| Token | Süre | Kullanım |
|-------|------|----------|
| `fast` | 180ms | Mikro etkileşim (hover/press) |
| `normal` | 320ms | Sayfa içi geçiş, fade |
| `slow` | 520ms | Büyük geçiş |
| `entrance` | 650ms | İlk giriş animasyonu |
| `stagger` | 60ms | Liste/grid kademeli giriş |

Eğriler: `easeOut` (easeOutCubic) · `emphasized` (easeOutQuart) · `spring` (elasticOut).
"Hareketi azalt" (`MediaQuery.disableAnimations`) açıkken paralaks/efektler atlanır
(bkz. `onboarding_screens.dart` `_ParallaxPage`).

---

## 5. Boşluk & dokunma

- Yatay ekran kenar boşluğu: **20px** (liste/sayfa padding'i).
- Dikey ritim: 6 / 8 / 12 / 14 / 18 / 24px adımları.
- **Dokunma hedefi ≥44px** (WCAG 2.2). `GoldChip` dikey 12; çip satırları ≥48.
- Grid: sabit `mainAxisExtent` kullan (dar ekranda `childAspectRatio` taşar — bkz.
  `tasks/lessons.md`).

---

## 6. Temel widget'lar (`widgets.dart`)

`AppHeader` · `HeroCard` · `AppCard` · `GoldChip` · `AyetFrame` (RTL Arapça çerçevesi) ·
`StatBox` · `SectionLabel` · `EmptyState` · `AnimatedCounter` · `ShimmerSkeleton` ·
`FeaturePlaceholder`. Painters: `TasbihPainter`, `CircularProgressPainter`, `QiblaDialPainter`.

---

## 7. Domain-bağlı tasarım kuralları (çiğnenemez)

1. **Arapça** her zaman `Directionality(textDirection: rtl)` + `arabicStyle()` (Amiri Quran).
2. **Türkçe** tüm metinlerde tam ortografi (ç/ğ/ı/ö/ş/ü) — ASCII'ye düşürme.
3. **Zekât** ve **Rüya Tabiri** ekranlarında "kesin hüküm değildir" uyarısı görünür olmalı.
4. Hadiste **sıhhat derecesi** rozeti gösterilir.
5. **Dürüst boş/degradasyon:** sahte içerik/etkileşim yok; backend yoksa `cloud_off` ipucu +
   CTA (örn. "İlk ayetini paylaş"), "No items found" değil.

---

## İlgili dokümanlar
- `docs/community-design-2026-06-20.md` — topluluk/akış yüzeyi
- `docs/wedge-validation-design-2026-06-20.md` — kama doğrulama
- `docs/persistence-policy.md` — verinin nerede yaşadığı (drift/prefs/supabase)
- `tasks/lessons.md` — ortam + paket API + layout dersleri
