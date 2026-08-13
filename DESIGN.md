# DESIGN.md — Kur'an'da ki Mesaj Tasarım Sistemi

> Tek doğru kaynak **koddur**: `lib/ui/core/theme/app_colors.dart`, `app_theme.dart`
> ve `lib/ui/core/widgets.dart`. Bu doküman o token'ların **özetidir** — yeni token
> eklerken önce kodu güncelle, sonra burayı eşitle. Değer ihtilafında **kod kazanır**.

Estetik: **zümrüt + altın + sıcak krem**, koyu/manevi, editoryal serif başlık.
İlke: yapay-zekâ-slop'tan kaçın (gerçek tipografi, özgün palet, mor-gradyan/ikon-daire
ızgarası yok); her yerde doğru RTL Arapça; dürüst çevrimdışı degradasyon.

---

## 1. Renk (`app_colors.dart`)

> **Renk rolleri ZEMİN ve ÖN PLAN diye ikiye ayrılır ve karıştırılamaz.**
> Bu, 1.0.1 build 4'te düzeltilen 78 kontrast ihlalinin tek kök nedeniydi:
> sabit marka/durum renkleri metin rengi olarak kullanılıyordu ve açık temada
> krem zemine karşı 1.6–2.5:1 veriyorlardı (WCAG AA = 4.5:1) → görünmezdiler.
> Kilit: `test/theme_contrast_test.dart`.

### Zemin / yüzey (tema DÖNER)

| Token | Koyu | Açık | Kullanım |
|-------|------|------|----------|
| `emerald950` | `#08201A` | `#F4ECDD` | Scaffold zemini |
| `emerald900` | `#0D2A20` | `#FFFFFF` | Panel / kart |
| `emerald850` | `#0F2C22` | `#FBF6EC` | Sheet / yükseltilmiş yüzey |
| `emerald700` | `#1E4D38` | `#F6EAC9` | Hero gradyan üst |

### Ön plan / metin (tema DÖNER)

| Token | Koyu | Açık | Kullanım |
|-------|------|------|----------|
| `cream` | `#F3EADB` | `#16271F` | Birincil metin |
| `cream2` | `#E6DCC8` | `#2A4034` | Gövde metni |
| `muted` | `cream @ %62` | `@ %74` | İkincil metin — ≥4.5:1 |
| `muted2` | `cream @ %55` | `@ %66` | Üçüncül metin — `muted`'tan DAHA SOLUK olmalı |
| **`goldInk`** | `#D4B25B` | `#7E5F14` | **Altın METİN/İKON** — altın renkli her ön plan |
| `success` | `#5ED27D` | `#186B33` | Onay / tamamlandı metni |
| `accent` | `#C9856A` | `#8C4A2F` | Vurgu / ikincil eylem metni |
| `info` | `#5AA9D6` | `#1A5F82` | Bilgi metni |
| `danger` | `#E8836F` | `#A02216` | Yıkıcı eylem (sil, hata) metni |
| `warning` | `#E8B54A` | `#8A5A00` | Uyarı metni |
| `correct`/`incorrect` | = `success`/`danger` | | Quiz geri bildirimi |

### Marka altını — yalnız ZEMİN/KENARLIK (tema DÖNMEZ)

| Token | Değer | Kullanım |
|-------|-------|----------|
| `gold` | `#D4B25B` | Altın **zemin**, kenarlık, dekoratif dolgu. **Metin rengi olarak KULLANMA** → `goldInk` |
| `goldBright` | `#E8CB6F` | Parlak vurgu / FAB üst |
| `goldSoft` | `#B69547` | FAB alt / yumuşak altın |
| `goldFaint` | `gold @ %12` | Altın dolgu zeminleri |
| `onGold` | `#08201A` | Altın **yüzey üstündeki** metin (yüzey olarak kullanma) |
| `line` | `gold @ %18/%32` | Hairline kenarlık |
| `lineSoft` | `cream @ %7/%10` | Çok ince ayraç |

### Daima koyu yüzeyler + dolgulu durum butonları (tema DÖNMEZ)

| Token | Değer | Kullanım |
|-------|-------|----------|
| `onMedia` / `onMediaMuted` | `#F3EADB` / `@ %72` | Reels videosu, stüdyo önizlemesi gibi **daima koyu** yüzeylerin üstündeki metin. Buralarda `cream`/`muted` kullanmak açık temada koyu üstüne koyu yazar. |
| `mediaLetterbox` | `#08201A` | Video arkası / letterbox dolgusu |
| `successSurface` + `onSuccess` | `#5ED27D` + `#08201A` | Dolgulu onay butonu |
| `accentSurface` + `onAccent` | `#C9856A` + `#08201A` | Dolgulu vurgu butonu |
| `dangerSurface` + `onDanger` | `#A02216` + `#FFF5F3` | Dolgulu yıkıcı buton ("Hesabı sil") |

**Gradyanlar:** `heroGradient` (emerald700→950, ↘), `cardGradient`, `cardGradientActive`
(dokununca parlar), `fabGradient` (goldBright→goldSoft).

**Kontrast kuralı:** Ön plan rolleri her üç yüzeyde de (scaffold/kart/sheet) ≥4.5:1
tutar; alfa'lı renkler ölçülmeden ÖNCE zemine kompozit edilir. Yeni bir renk rolü
eklerken `test/theme_contrast_test.dart`'a çiftini de ekle.

**`buildAppTheme` saflığı:** `theme:`/`darkTheme:` arka arkaya değerlendirildiği için
global `AppColors.brightness` eskiden hep `dark`'ta kalıyordu; builder alt-ağacının
DIŞINDA renk okuyan her yer (route inşası, `showModalBottomSheet`/`showDialog`
argümanları, `ScaffoldMessenger`) yanlış paleti alıyordu. `buildAppTheme` artık
global'i geçici değiştirip çıkışta geri yükler — bu davranışı bozma.

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
`AyetActionBar` (Anla·Düşün·Paylaş) · `SectionLabel` · `EmptyState` · `AnimatedCounter` ·
`ShimmerSkeleton` · `CenteredScrollBody` ·
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
