# Plan — 5 Maddelik Bakım + AI Yeniden Kurgu

## Context

Kullanıcı 5 iş bildirdi: (1) widget boyut hataları, (2) koyu/açık temada görünmeyen yazılar,
(3) AI'ın istenen gibi çalışmaması — ana sayfada bir "AI balonu" ve sosyal medya linklerinden
ayet/meal/tefsir çıkarımı + sonucu Reels'te video/görsel/müzikle paylaşma, (4) stüdyoya video
eklenememesi, (5) ana sayfanın "AI slop" görünen özellik butonları.

Zamanlama kritik: `1.0.1` Apple'ın **Guideline 1.2** reddine yanıt olarak hazırlandı, build 3
bozuk çıktı (düzeltildi), **build 4 henüz gönderilmedi**, PR #1 açık. `docs/APP_REVIEW_RESPONSE.md:65`
Apple'a yazılı olarak *"the app never downloads or re-hosts third-party video... we only read the
public preview image"* beyanını veriyor.

Hedef sonuç: 1-2-4-5 düşük riskli düzeltmeler olarak **1.0.1 build 4**'e girer (Apple'a verilen
beyan değişmez, red yanıtı gecikmez); madde 3 beyan değişikliği gerektirdiği için **1.0.2**'ye
ayrılır ve 1.0.1 onaylandıktan sonra gönderilir.

---

## Araştırma bulguları (madde 3'ü şekillendiren sert kısıtlar)

**Gemini video anlama** (Context7 → `/websites/ai_google_dev_gemini-api`):
- `fileData.fileUri` ile **yalnızca herkese açık/liste dışı YouTube URL'si** doğrudan video olarak
  işlenir. İstek başına 1 YouTube URL. Ücretsiz katman: günde toplam 8 saat video.
- **TikTok ve Instagram URL'si desteklenmiyor.** Bu platformlar için tek yol ya cihazdaki video
  dosyası (base64/Files API) ya da mevcut `og:image` önizleme görseli OCR'ı.
- Uygulama YouTube linkini Gemini'ye verdiğinde **videoyu indiren taraf Google'dır**, uygulama
  değil → Guideline 5.2.3'ün "kullanıcıya indirme/kaydetme yeteneği verme" yasağı kapsamı dışında.
  Ancak Apple'a verilen mevcut beyan bunu kapsamıyor → beyan güncellenmeli (1.0.2).

**Flutter video render** (web araştırması):
- `ffmpeg_kit_flutter` emekli, birebir yerine geçen yok. `easy_video_editor` metin overlay ve ses
  miksleme **desteklemiyor** (yalnız trim/merge/speed). `pro_video_editor` ve IMG.LY `video_editor_sdk`
  seçenek ama ilki olgunlaşmamış, ikincisi ticari lisanslı.
- Sonuç: **cihaz üstü gerçek mp4 render bu sprintte kapsam dışı.** Yerine render gerektirmeyen
  "kompozisyon" yaklaşımı (aşağıda).

---

## Madde 2 — Tema kontrast hataları (KÖK NEDEN BULUNDU)

Denetim: **78 ihlal** (46 kritik). Kullanıcının "yazılar gözükmüyor" şikâyetinin tek bir baskın
kök nedeni var.

### Kök neden: `AppColors.gold` metin rengi olarak kullanılıyor

`lib/ui/core/theme/app_colors.dart` iki ayrı rol tanımlar:
- `gold` (#D4B25B) — **SABİT**, altın *zemin/ikon/kenarlık* içindir.
- `goldInk` — altın **METİN** rolü; açık temada `#8A6A1F`'e koyulaşır.

Kod tabanında `goldInk` yalnızca **6** yerde, `gold` ise **46 metin bağlamında** kullanılıyor.
Açık temada `#D4B25B` metin, `#F4ECDD` zemin üzerinde **1.66:1** kontrast veriyor (WCAG AA = 4.5:1)
→ pratikte görünmez.

### Düzeltme sırası

1. **`gold` → `goldInk` (46 satır).** En yüksek etki. Sırayla:
   - Çekirdek widget'lar (her ekranı etkiler): `lib/ui/core/widgets.dart:416` (`_ReflectionSheet`
     künyesi), `:476-478` (`StatBox` 28px rakam), `:575` (`AnimatedCounter` 48px sayaç).
   - Kur'an içeriği: `quran_screens.dart:407` (Besmele), `:683` (**ayet Arapçası**, 28px),
     `:256`, `:618-626` (ayet no rozeti — `goldFaint` zemin + `gold` metin ≈ 1.3:1, her iki temada bozuk).
   - Kalan ~35 satır aynı mekanik değişiklik: `home_screens.dart`, `community_screens.dart`,
     `fasting_screen.dart`, `dhikr_screens.dart`, `ayah_finder_screen.dart`, `daily_ayah_screen.dart`,
     `prayer_screen.dart`, `holy_days_screen.dart`, `learning_screens.dart`, `khatm_screen.dart`,
     `onboarding_screens.dart`, `dua_screen.dart`, `studio_screens.dart`, `qibla_screen.dart`,
     `tools_screens.dart`, `topical_screen.dart`, `collections_screen.dart`, `progress_screens.dart`,
     `moderation_screen.dart:591`.
   - **Ayrım kuralı:** `color:`/`foregroundColor:` bir *metin veya metin-benzeri ikon* içinse
     `goldInk`; `backgroundColor`/`border`/dekoratif ikon ise `gold` kalır.

2. **Yeni `onMedia` rolü** — daima koyu kalan yüzeyler (Reels videosu, stüdyo önizlemesi) tema
   dönen `cream`/`muted` kullanıyor → açık temada koyu üstü koyu.
   - `app_colors.dart`'a sabit `onMedia` (#F3EADB) + `onMediaMuted` ekle.
   - Uygula: `community_screens.dart:1195` (yazar adı), `:1207` (**meal metni**),
     `studio_screens.dart:240` (önizleme placeholder).
   - Not: `community_screens.dart:1211-1213`'teki yorum bu tuzağı zaten tanımlamış ve künye chip'i
     için çözmüş; hemen üstündeki iki satır düzeltilmemiş — yarım kalmış düzeltmeyi tamamla.

3. **Sepia × tema çakışması** — `quran_screens.dart:365-382`. Sepia kendi sabit paletini kurar
   (`bg #F3EADB`, `fg #2C2418`) ama `AppHeader` (`:375`) global temadan `cream` alır.
   **Koyu tema + sepia açık** → `#F3EADB` metin, `#F3EADB` zemin = tamamen görünmez.
   - `AppHeader`'a sepia `fg`'sini geçir; `_TilawahBar` (`:472-478`, `:634`, `:664`) içindeki
     `gold` ikonlar ve `lineSoft` ayracı da sepia paletinden beslenmeli.

4. **`app.dart:123-124` global mutasyon yarışı** — `buildAppTheme(Brightness.light)` ve
   `...dark` arka arkaya çağrıldığı için global `AppColors.brightness` **her zaman dark'ta kalır**;
   `builder` (`:126-139`) sonradan düzeltir ama builder alt-ağacının DIŞINDA renk okuyan her yer
   (route inşası, `showModalBottomSheet`/`showDialog` argümanları, `ScaffoldMessenger`) yanlış
   palet alır. Düzeltme: `buildAppTheme`'i global'i kalıcı değiştirmeyecek şekilde saf hale getir
   (girişte mevcut brightness'ı sakla, çıkışta geri yükle).

5. **Sabit Flutter renkleri (20 ihlal)** — `AppColors`'a `danger` (silme/hata) ve `warning` rolleri
   ekleyip şunları taşı: `learning_screens.dart:823-847`, `:905-911` (quiz yeşil/kırmızı),
   `settings_screen.dart:122-132`, `:183` (salmon "Hesabı sil" — **açık temada zemin salmon + metin
   `cream`=#16271F → 2.9:1**), `home_screens.dart:658` (`Colors.orange`), `:689` (`Colors.green`),
   `:1722-1724` (**beyaz buton + beyaz kenarlık + krem sayfa → açık temada buton sınırı kaybolur**),
   `community_screens.dart:2465-2469` (`Colors.grey.shade200` placeholder),
   `painters.dart:58` (sönük boncuk renkleri `_pick`'e taşınmalı).

6. **`muted2` ters ternary** — `app_colors.dart:53-54`: koyu temada `muted2`(0.55) `muted`(0.62)'den
   soluk, açık temada `muted2`(0.62) `muted`(0.60)'tan **KOYU** → hiyerarşi ters. `:52`'deki yorum
   da bayat (%40/%55 yazıyor, kod farklı).

7. **`onGold` yüzey olarak kullanılmış** — `community_screens.dart:213`, `:827`
   (`Scaffold.backgroundColor` / `ColoredBox`). `onMedia`/yeni `mediaLetterbox` sabitine taşı.

8. **Gizli borç:** `painters.dart:81/118/167` `shouldRepaint` tema alanını karşılaştırmıyor;
   şu an `KeyedSubtree(ValueKey(isDark))` (`app.dart:138`) ağacı komple yeniden kurduğu için
   sorun görünmüyor. O hack kaldırılırsa 3 painter bayat renkle donar — `shouldRepaint`'lere
   renk karşılaştırması eklenmeli.

### Regresyon testi
`test/theme_contrast_test.dart` (yeni): her iki brightness için `AppColors` rollerinin
metin/zemin çiftlerini WCAG kontrast oranıyla ölçen saf birim testi. En az `goldInk`×`emerald950`,
`cream`×`emerald900`, `onGold`×`gold`, `onMedia`×siyah-scrim çiftlerini ≥4.5:1 doğrular.
Bu test, düzeltme geri alındığında düşer.

---

## Madde 4 — Stüdyoya video ekleme (DOĞRULANDI + kolay çözüm bulundu)

### Bulgu
`lib/features/studio/studio_screens.dart` bir **görsel** editörü (başlık literal olarak "Görsel Editör",
`:326`). Tek picker çağrısı `pickImage` (`:123-131`); dosyada `pickVideo` **hiç geçmiyor**,
`video_player` import edilmemiş, `_bgImage` tipi `File?`. Arka plan = 6 gradyan şablonu (`kTemplates`
`:33-40`) veya tek statik görsel. Çıktı `RepaintBoundary.toImage()` → PNG (`_export()` `:135-156`).

### Daha ağır ikinci kusur (kullanıcı henüz fark etmemiş ama aynı kökten)
`StudioScreen._publish()` (`:168-203`) **medyayı hiç yüklemiyor** — `mediaUrl`/`videoUrl` geçmeden
post oluşturuyor; PNG yalnızca geçici dizine yazılıp `share_plus`'a veriliyor. Üstelik `arabic: ''`
gönderdiği için Arapça metin `meal`/`caption` içine gömülü kalıyor ve Reels'in RTL Arapça bloğu boş
kalıyor. Kodda `ponytail:` yorumuyla işaretli (`:160-167`). Stüdyo çıktısının yayına çıkmasının tek
yolu şu an dolambaçlı: PNG geçici dizine yazılır → `CreatePostSheet._pickFromStudio()` (`community_screens.dart:1669-1697`)
o dizini `ayet_*.png` diye tarar → oradan yüklenir.

### Çözüm — render GEREKMİYOR
Reels oynatıcısı zaten iki katmanı ayrı çiziyor: `_ReelPage._background()` (video ise `video_player`,
still ise `_ReelComposition` gradyan) + `_ReelOverlay` (`community_screens.dart:1023-1242`) metni ÜSTE
çizer. Yani "arka planda video, üstünde ayet" **zaten mimaride var**; eksik olan tek şey
`CreatePostSheet._publish()`'in video yüklerken `arabic`/`meal`/`reference` alanlarını boş göndermesi
(`:1752-1758`).

1. `studio_screens.dart`'a `_pickVideo()` ekle (`image_picker` zaten bağımlılıkta, `pickVideo`
   deseni `community_screens.dart:1637-1664`'te hazır — 20 MB `lengthSync()` ön kontrolüyle birlikte
   kopyala, yeniden yazma).
2. `_bgImage` → `_background` (`File? file, bool isVideo`). Video seçiliyken önizleme
   `video_player` ile oynar; **"PNG Kaydet" butonu gizlenir** (video frame'i PNG'ye indirgemek
   kullanıcıyı yanıltır), yerine yalnız "Reels'te Paylaş" kalır.
3. `_publish()` düzelt: medyayı `post-media`'ya yükle (yükleme kodu `community_screens.dart:1734-1760`'ta
   hazır — ortak bir `uploadPostMedia()` yardımcısına çıkarıp iki yayın yolundan da çağır),
   `arabic`/`meal`/`reference`'ı **ayrı alanlar** olarak gönder, `kind` video ise `'video'`.
4. `_pickFromStudio()` dolambacı ve "yayınlanan kartta yalnız şablon+metin kullanılır" uyarısı
   (`studio_screens.dart:552-556`) artık geçersiz → kaldır.
5. **Telif kutusu her iki yolda da korunmalı** — `test/rights_gate_test.dart:11-13` bunu Guideline
   5.2.3 kanıtı olarak kilitliyor; video eklenince bu test daha da kritik.

### Müzik
Ayrı müzik pisti = gerçek mp4 render = kapsam dışı (ffmpeg_kit emekli, `easy_video_editor` overlay/ses
miksleme desteklemiyor, IMG.LY ticari). Bu sprintte müzik **videonun kendi sesidir**. Sonraki adım
(1.0.2+): ayetin mevcut tilavet kaydını (`just_audio`, `device_services.dart:282-284`) Reels
oynatıcısında video sesinin üstüne bindirmek — yine render yok, yalnız oynatıcıda iki kanal.
Telifli müzik yükleme **önerilmiyor**: Guideline 5.2 riski + moderasyon yükü.

---

## Madde 3 — AI'ın yeniden kurgusu

### Mevcut durum (doğrulandı)
- 5 giriş yolu zaten var: galeri görsel, **galeri video**, paylaş-intent görsel, paylaş-intent video, URL.
  Hafızada "URL alanı kaldırıldı" yazıyor ama **kaldırılmamış** — `ayah_finder_screen.dart:120-123`
  (`_LinkField`, `:218-381`) ve `fromUrl` (`controller:34`, `index.ts:98`) tam aktif.
- Görsel/link hattı: Gemini `gemini-2.5-flash` OCR → yalnız Arapça metin çıkarır, sure:ayet TAHMİN
  ETMEZ → otoriter `_shared/quran/quran_data.ts` + IDF-F1 `matcher.ts`.
- Video hattı: private bucket → imzalı URL → Groq `whisper-large-v3-turbo` → `segments.ts`
  (pencereleme + baskın sure oylaması + monoton çapa + aralık). Zaten çalışıyor.
- **Tefsir hiçbir yerde yok.** `Ayahs.tafsir` kolonu var (`app_database.dart:45-52`) ama
  `quran_full.json` şeması `{s, a, ar, meal}` — `tafsir` anahtarı 0 kez geçiyor; hiçbir kod yazmıyor.
  6236 satırın tamamı NULL. `AyahMatch`/`AyahFinderResult` modellerinde tafsir alanı yok.
  "Anla" sheet'i her zaman `daily_ayah_screen.dart:172` fallback'ini gösteriyor:
  *"Bu ayet için tefsir yakında eklenecek."*

### 3a. Ana sayfa AI balonu
Ana ekranda tek, belirgin bir AI FAB'ı → `/ayah-finder`. (Konum ve görsel dil madde 5 ile birlikte
tasarlanacak — mevcut altın FAB ve "Ayet Bul" sheet öğesi dağınık.)

### 3b. YouTube = gerçek video analizi (yeni)
Gemini `fileData.fileUri` **public/unlisted YouTube URL'sini doğrudan yutuyor** — uygulama videoyu
indirmez, Google işler. `ayah-finder/index.ts`'e üçüncü dal:
- URL YouTube ise (`youtube.com/watch`, `youtu.be`, `/shorts/`) → og:image OCR yerine
  `fileData` ile video analizi; prompt yine katı: **yalnız duyulan/görülen Arapça metni döndür**,
  sure:ayet tahmin etme. Sonuç aynı `matcher` kapısından geçer → uydurma imkânsız.
- İstek başına 1 URL; ücretsiz katman günde 8 saat → kullanıcı başına günlük kota sayacı gerekir
  (`profiles`'a basit sayaç veya Edge tarafında rate-limit).
- Süre kapısı: uzun videoyu reddet (kota ve gecikme için), kullanıcıya "kısa klip / Shorts kullan" de.

### 3c. TikTok / Instagram — dürüst yönlendirme
Gemini bu URL'leri **video olarak kabul etmiyor**; yapılabilecek tek şey mevcut og:image OCR'ı
(kapakta yazı yoksa sonuç çıkmaz). Kod tarafında değişiklik minimal, asıl iş UX dürüstlüğü:
- `link_unresolved` şu an 8 farklı nedeni tek mesaja katlıyor (`index.ts:105-119`). Nedeni ayır:
  giriş duvarı / önizleme görselinde ayet yok / desteklenmeyen bağlantı.
- TikTok/IG linki yapıştırıldığında **birincil çözümü öne çıkar**: "Uygulamada videoyu Paylaş →
  Kur'an'da ki Mesaj seç — sesi de dinleyip çok daha doğru sonuç veriyoruz." Paylaş-intent zaten
  kablolu (`app.dart:99-101`, AndroidManifest `video/*`), ama kullanıcı bunu bilmiyor.

### 3d. Tefsir — VERİ SORUNU, kod sorunu değil
Kullanıcının istediği "tefsiri ne" çıktısı, tefsir metni olmadan üretilemez.
**LLM'e tefsir yazdırmak yasak** (CLAUDE.md domain kuralı 1: meal/tefsir onaylı kaynaklardan —
Diyanet, Elmalılı, TDV). Uydurma tefsir hem dini hem hukuki risk.

Bu yüzden madde 3d ayrı bir iş kalemidir ve **lisans kararı gerektirir**:
1. Kaynak seç ve izin/lisans durumunu netleştir (Diyanet Kur'an Yolu, Elmalılı sadeleştirilmiş —
   ikincisi telif süresi dolmuş olabilir, doğrulanmalı). Bu zaten bekleyen bir mağaza işi:
   `PROJECT_MEMORY` "Content Rights = third-party content" maddesi.
2. `tool/fetch_quran.dart`'ı tefsir alanı üretecek şekilde genişlet → `quran_full.json` şemasına
   `tafsir` ekle → `seed_service.dart:75-89` yazsın → drift `schemaVersion` 6→7 (seed tablosu,
   `_userTables` korumasını bozmaz).
3. `AyahMatch` + `AyahFinderResult` + `matcher.ts` `AyahMatch`'e `tafsir` alanı ekle
   (JSON'da opsiyonel → geriye uyumlu).
4. Bu hazır olana kadar Ayet Bulucu'da tefsir bölümü **gösterilmez** (boş vaat verilmez).

### 3e. Doğruluk artışı (ucuz kazanımlar)
- Ayet Bulucu'daki iki buton — "Videoya Aktar" ve "Reels'te Paylaş" — **ikisi de aynı
  `_openStudio()`'yu çağırıyor** (`ayah_finder_screen.dart:576-592`). Madde 4 sonrası ayrış:
  biri stüdyo, diğeri doğrudan video arka planlı paylaşım.
- Eşikler tek yerde toplanmalı: görsel hattı `index.ts:136-147` (0.5 / 0.12 / 0.2), ses hattı
  `segments.ts:48-60`. Aynı sözleşme iki dosyada kopyalanmış; `_shared/quran/thresholds.ts`'e çek.

---

## Madde 1 — Widget boyut hataları

### Kök neden: yazı ölçeği hiç kısıtlanmamış
`lib/app/app.dart:120-141` `builder`'ı yalnız `KeyedSubtree` sarıyor. Projede **hiçbir yerde**
`textScaler` / `MediaQuery.withClampedTextScaling` geçmiyor. Android "Yazı tipi boyutu" (1.0→2.0)
ve iOS Dynamic Type (AX5 ≈ 3.1×) doğrudan her sabit-piksel kabı zorluyor. Aşağıdaki 1-3 bunun türevi.

**Düzeltme:** `builder`'da `MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor: 1.3)`
— erişilebilirliği tamamen kesmez, kapları korur. Bunun ÜSTÜNE aşağıdaki yapısal düzeltmeler gelir
(clamp tek başına yeterli değil, 1.3'te de taşan yerler var).

### 1. Ana sayfa "Hızlı İşlemler" ızgarası — en olası şikâyet kaynağı
`home_screens.dart:321` `mainAxisExtent: 120`. İçerik 1.0 ölçekte 116px (72 kutu + 8 boşluk +
2×18 satır) → 4px pay. **1.15× (Android "Büyük") ölçekte taşıyor** ve 360dp ekranda 8 başlığın 7'si
2 satıra sardığı için **7 hücrede aynı anda**. İroni: `:318-320`'deki yorum `mainAxisExtent`'in
eski bir `childAspectRatio` taşmasını çözmek için konduğunu söylüyor — genişlik taşması,
yazı-ölçeği taşmasıyla takas edilmiş. Madde 5 bu ızgarayı zaten kaldırıyor; kalan kartlarda
sabit yükseklik yerine içeriğe uyan kap kullanılacak.

### 2. Kaydırılamayan Column + sabit büyük daire (3 ekran)
Üçünde de `Expanded > Column(center)` var, `SingleChildScrollView` yok:
- `dhikr_screens.dart:111-159` — `SizedBox(280×280)` (`:126-128`), içerik ≈563px → 640dp'de sınırda,
  yatayda ve textScale ≥1.3'te kesin taşar.
- `dhikr_screens.dart:267-313` (Tesbihat) — `SizedBox(200×200)` (`:290-292`), ≈404px.
- `qibla_screen.dart:54-96` — `SizedBox(300×300)` (`:65-67`), sensör uyarısıyla ≈500px.

**Düzeltme:** üçünde de gövdeyi `SingleChildScrollView` + `ConstrainedBox(minHeight)` içine al;
daire boyutunu `LayoutBuilder` ile kullanılabilir yüksekliğe göre sınırla (sabit 280/200/300 yerine
`min(300, maxHeight * 0.45)` gibi).

### 3. GoldChip şeritleri — belgelenen düzeltme geri sürüklenmiş
`GoldChip` gerçek yüksekliği ≈40.3px (`widgets.dart:184-201`). `PROJECT_MEMORY` "chip overflow fix
52→56px" diyor ama bugün: `dhikr_screens.dart:160-161` = **48**, `dua_screen.dart:155-157` = **48**,
`topical_screen.dart:50-55` = 56 ama ListView `vertical:4` padding'i yüzünden efektif **48**.
48px, textScale ~1.4'te patlıyor. **Düzeltme:** sabit yükseklikli `SizedBox` yerine
`ConstrainedBox(minHeight: 48)` + chip'in kendi yüksekliğini belirlemesine izin ver
(alt bar dersini tekrar etme: `Center`/`Align` varsa `heightFactor: 1` kontrol et).

### 4. Telefon ana ekran widget'ları (Android)
- `res/xml/prayer_widget_info.xml:5,8` — `minHeight="70dp"`, `targetCellHeight="1"`; gerçek içerik
  **≈111dp**. Android 12+'ta `targetCellHeight` varsayılan yerleşim boyutu → widget eklenince
  konum satırı (ve muhtemelen saat satırı) kırpılıyor. → `targetCellHeight="2"`, `minHeight≈110dp`.
- `res/layout/prayer_widget.xml` — **hiçbir yerde `layout_weight` yok**, hepsi `wrap_content`;
  `tv_next_name` (`:37-45`) `maxLines`/`ellipsize` taşımıyor. → ayet widget'ındaki sağlıklı deseni
  kopyala (`ayah_widget.xml:22-32`: `height=0dp` + `weight=1` + `maxLines` + `ellipsize`).
- Her iki widget'ta da `minResizeWidth`/`minResizeHeight` yok → kullanıcı içeriğin altına
  küçültebiliyor, RemoteViews sessizce kırpıyor.
- `ayah_widget_info.xml:5,9` — `minHeight=110dp` / içerik ≈143dp → `targetCellHeight="3"`.
- iOS `KuranWidgets.swift:74-77` — `.systemSmall`'da iki `.title2` metni büyük Dynamic Type'ta
  kesiliyor. → `.lineLimit(1).minimumScaleFactor(0.7)`.
- Ölü veri: `widget_sync_service.dart:58` `ayah_arabic` ve `:44-47` `prayer_times` yazılıyor,
  **hiçbir platform okumuyor**. Arapça olan domain kuralı #2 gereği kasıtlı (widget'ta Amiri yok) —
  yorumla işaretle veya kaldır.

### 5. Regresyon testleri
Mevcut boyut testleri: `bottom_bar_height_test.dart`, `esma_overflow_test.dart`. **Hiçbiri
textScale > 1.0 ile çalışmıyor.** Yeni `test/text_scale_overflow_test.dart`: ana sayfa, zikirmatik,
tesbihat, kıble ekranlarını 360×640 @ `textScaler: 1.3` ile pump edip `takeException() == null`
doğrula. Düzeltmeler geri alındığında düşer.

---

## Madde 5 — Ana sayfa düzeni ("AI slop" butonları)

### Neden slop okunuyor (3 yapısal sebep, tespit edildi)
1. **8 hücre birebir aynı obje** — aynı 72px gradyan kutu, aynı ailenin Material ikonu, aynı 2 satır
   ortalanmış caption, düzgün 4×4 ızgara, kademeli animasyon. `DESIGN.md:8-9` bunu **adıyla
   yasaklıyor**: *"yapay-zekâ-slop'tan kaçın (…) ikon-daire ızgarası yok"*. Ana sayfa kendi tasarım
   dokümanının yasakladığı deseni uyguluyor.
2. **8 kısayolun 4'ü sayfanın üstüyle mükerrer** — `/prayer` zaten `_PrayerStrip` (`:304`),
   `/qibla` zaten `_QiblaMosqueCard` (`:306`), `/daily-ayah` zaten `_DailyAyahHero` (`:308`),
   `/dhikr` zaten `_HomeStats` (`:359`).
3. **11 bölümün 5'i aynı AppCard deseni** (ikon + metin + chevron), `SectionLabel` sayfada
   yalnız **1 kez** (`:310`) → görsel hiyerarşi yok, tek ritim 8 kez tekrarlıyor.

### Yeniden düzen
- **Izgarayı kaldır.** Mükerrer 4 kısayolu sil. Kalan 4 (`/quran`, `/esma`, `/dua`, `/zakat`)
  ikon-kutusu yerine **metin öncelikli satırlara** dönüşsün: sol tarafta ince ikon, sağda başlık +
  `FeatureDef.description` (26 açıklama yazılmış, **hiçbiri hiçbir ekranda gösterilmiyor** —
  `feature_catalog.dart`). Bu hem slop desenini kırar hem yazılmış içeriği kullanır.
- **Sayfayı bölümle.** Uygulamanın çekirdek döngüsü "Anla → Düşün → Paylaş"; ana sayfa bunu
  yansıtmalı. Üç `SectionLabel` altında grupla: *Bugün* (hicri + namaz şeridi + okuma hedefi),
  *Ayet* (Günün Ayeti hero + `AyetActionBar` — zaten var), *Keşfet* (kalan kısayollar + Tüm Özellikler).
- **Görsel ağırlık farklılaştır.** Günün Ayeti tek `HeroCard` olarak baskın kalsın; diğer kartlar
  daha sakin (ince kenarlık, gradyansız) olsun. Şu an hepsi aynı ağırlıkta yarışıyor.
- **AI balonu (madde 3a) buraya oturur** — ana sayfada tek belirgin giriş. Şu an `/ayah-finder`
  ızgarada YOK, yalnız alt bar FAB sheet'inin ilk satırından erişiliyor (`home_screens.dart:201-207`).
- `_ReadingGoalCard` (`:610-706`) yüklenene kadar `SizedBox.shrink()` döndürüyor (`:645`) →
  **ilk karede sayfa zıplıyor**. `ShimmerSkeleton` (zaten var, `widgets.dart:583`) ile yer tut.
- Ana sayfa Arapçayı `:518-524`'te **elle inline** render ediyor; paylaşılan `AyetFrame`
  (`widgets.dart:218-244`) varken. Ona geç.
- Ölü kod: `StatBox` (`widgets.dart:462-489`) hiçbir yerde kullanılmıyor — ana sayfa aynı işi kendi
  `_StreakCard`'ıyla yapıyor. Sil veya `_StreakCard`'ı ona indirge.
- Bayat yorum: `home_screens.dart:183` sheet'i hâlâ *"Video Edit / AI / Paylaşım / Hikaye"* diye
  tarif ediyor; gerçekte 3 öğe var ve ayrı "AI" öğesi yok.

### `feature_catalog.dart` tutarsızlıkları (aynı dokunuşta düzelt)
- Dosya `24` diyor (`:25`), gerçek **26** kayıt var.
- Kur'an kategorisi yorumu "8" (`:37`), gerçek **10**; İçerik "3" (`:48`), gerçek **4**.
- `/progress` (`:55`) `FeatureCategory.kuran` etiketli ama "İstatistikler" — yanlış kategori.
- `CLAUDE.md` ve `PROJECT_MEMORY` de "24 özellik" diyor → belgeler de güncellenmeli.

---

## Sıralama ve sürümleme

**1.0.1 build 4 (bu sprint — Apple'a verilen beyan DEĞİŞMEZ):**
1. Madde 2 — tema kontrastı (en yüksek etki, en düşük risk; `gold`→`goldInk` mekanik)
2. Madde 1 — boyut hataları (textScale clamp + 3 ekran scroll + chip'ler + Android widget XML)
3. Madde 4 — stüdyoya video + `_publish()` medya yükleme düzeltmesi
4. Madde 5 — ana sayfa düzeni + katalog tutarsızlıkları
5. `PROJECT_MEMORY.md` + `CLAUDE.md` güncelle; PR #1'e ekle

**1.0.2 (1.0.1 ONAYLANDIKTAN sonra — yeni App Review beyanı gerekir):**
6. Madde 3b — YouTube URL → Gemini `fileData` gerçek video analizi + kota
7. Madde 3c — TikTok/Instagram dürüst yönlendirme + `link_unresolved` neden ayrıştırması
8. Madde 3a/3e — ana sayfa AI balonu son hâli, eşiklerin `_shared/quran/thresholds.ts`'e toplanması
9. Madde 3d — tefsir verisi (**lisans kararı gerektirir**, ayrı iş kalemi)
10. `docs/APP_REVIEW_RESPONSE.md:65` beyanını güncelle: *"we only read the public preview image"*
    → YouTube analizinin uygulamada indirme yapmadığını açıkça yaz.

> **Neden ayrık:** `1.0.1` Guideline 1.2 reddine yanıt; build 4 hâlâ gönderilmedi. Madde 3'ün
> gerektirdiği beyan değişikliği bu yanıtı geciktirir ve yeni bir red yüzeyi açar.

---

## Doğrulama

Her adımdan sonra:
```
flutter analyze                                    # 0 sorun beklenir
flutter test                                       # mevcut 92 + yeni testler
deno test --allow-read supabase/functions/...      # 27/27 (madde 3'te)
```

Yeni regresyon testleri (her biri düzeltme geri alınınca DÜŞMELİ):
- `test/theme_contrast_test.dart` — `goldInk`/`cream`/`onGold`/`onMedia` çiftleri her iki
  brightness'ta ≥4.5:1
- `test/text_scale_overflow_test.dart` — home/dhikr/tesbihat/qibla @ 360×640 textScale 1.3
- `test/studio_video_test.dart` — video seçiliyken "PNG Kaydet" gizli, telif kutusu hâlâ kilitliyor
  (`rights_gate_test.dart` desenini izle)

Cihaz doğrulaması (Samsung SM S731B) — statik analiz yakalamayan sınıf:
1. Ayarlar → Görünüm → Açık tema; Kur'an okuma + sepya modu + Reels + Ayet Bulucu ekranlarını gez,
   ekran görüntüsü al (koyu tema + sepya kombinasyonu `quran_screens.dart:375` için kritik).
2. Android Ayarlar → Ekran → Yazı tipi boyutu = en büyük; ana sayfa, zikirmatik, tesbihat, kıble.
3. Ana ekrana namaz + ayet widget'larını ekle, varsayılan boyutta kırpılma var mı bak, yeniden boyutlandır.
4. Stüdyo → video seç → Reels'te paylaş → moderasyon kuyruğunda "Onay bekliyor" rozetiyle görün →
   `/moderation`'dan onayla → Reels'te video arka plan + ayet overlay birlikte görünüyor mu.
