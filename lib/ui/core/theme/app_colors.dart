import 'package:flutter/material.dart';

/// Kur'an'da ki Mesaj tasarım paleti — zümrüt + altın + krem.
/// Kaynak: Flutter Planı.html §04 ve UI mockup (image.png).
///
/// **Koyu/açık tema:** Yüzey ve metin renkleri tek bir global palet üzerinden
/// brightness'a göre döner ([brightness] setter'ı ile). Çağrı yerleri
/// (`AppColors.emerald950` vb.) DEĞİŞMEDEN kalır — getter aktif palete bakar.
/// `MaterialApp.builder` her karede aktif Theme brightness'ını buraya yazar.
///
/// Anlamsal kurallar:
/// * [onGold] her zaman koyu (altın buton/chip üstündeki metin) — DÖNMEZ.
/// * Altın ailesi (gold/goldBright/goldSoft) marka rengi — sabit `const`.
/// * Altın METİN ([goldInk]) açık temada kontrast için koyulaşır.
enum AppBrightness { dark, light }

abstract class AppColors {
  static AppBrightness _b = AppBrightness.dark;

  /// Aktif paleti ayarlar. Material `Brightness`'tan eşlenir.
  static set brightness(Brightness b) =>
      _b = b == Brightness.light ? AppBrightness.light : AppBrightness.dark;

  /// Aktif palet. `buildAppTheme` global'i geçici değiştirip geri yüklemek
  /// için okur (bkz. app_theme.dart — global mutasyon yarışı düzeltmesi).
  static Brightness get brightness =>
      _light ? Brightness.light : Brightness.dark;
  static bool get _light => _b == AppBrightness.light;

  static Color _pick(Color dark, Color light) => _light ? light : dark;

  // ── Zemin & paneller (DÖNER) ───────────────────────────────────────────
  static Color get emerald950 => _pick(const Color(0xFF08201A), const Color(0xFFF4ECDD)); // scaffold
  static Color get emerald900 => _pick(const Color(0xFF0D2A20), const Color(0xFFFFFFFF)); // panel / kart
  static Color get emerald850 => _pick(const Color(0xFF0F2C22), const Color(0xFFFBF6EC)); // sheet
  static Color get emerald700 => _pick(const Color(0xFF1E4D38), const Color(0xFFF6EAC9)); // hero üst

  // ── Altın vurgu (SABİT marka) ──────────────────────────────────────────
  static const Color gold = Color(0xFFD4B25B);
  static const Color goldBright = Color(0xFFE8CB6F);
  static const Color goldSoft = Color(0xFFB69547);
  static final Color goldFaint = gold.withValues(alpha: 0.12);

  /// Altın renkli METİN (eyebrow, Arapça, fiyat). Açık temada krem zemine
  /// karşı AA için koyulaşır; koyu temada parlak altın.
  ///
  /// Açık ton `#8A6A1F` iken kart zemininde (beyaz) 5.0:1 ama scaffold
  /// zemininde (`#F4ECDD`) 4.30:1 kalıyordu — altın metin her ikisinin de
  /// üstünde duruyor, bu yüzden sıkı olana göre `#7E5F14` (5.1:1) seçildi.
  static Color get goldInk => _pick(const Color(0xFFD4B25B), const Color(0xFF7E5F14));

  /// Altın yüzey ÜSTÜNDEKİ metin/ikon (buton, seçili chip, FAB). Her iki
  /// temada da koyu — altın sabit kaldığı için DÖNMEZ.
  static const Color onGold = Color(0xFF08201A);

  // ── Metin (DÖNER) ──────────────────────────────────────────────────────
  static Color get cream => _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)); // birincil
  static Color get cream2 => _pick(const Color(0xFFE6DCC8), const Color(0xFF2A4034)); // gövde
  /// İkincil metin. Alfa değerleri her iki temada da zemine karşı ≥4.5:1
  /// (WCAG AA) ölçülerek seçildi: koyu 0.62 → 6.2:1, açık 0.74 → 5.8:1.
  static Color get muted =>
      _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)).withValues(alpha: _light ? 0.74 : 0.62);

  /// Üçüncül metin — [muted]'tan DAHA SOLUK olmalı (her iki temada).
  /// Koyu 0.55 → 5.1:1, açık 0.66 → 4.8:1.
  static Color get muted2 =>
      _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)).withValues(alpha: _light ? 0.66 : 0.55);

  // ── Medya üstü metin (SABİT) ───────────────────────────────────────────
  /// Daima koyu kalan yüzeylerin (Reels videosu, stüdyo önizlemesi) üstündeki
  /// metin. Tema DÖNMEZ — yoksa açık temada koyu üstüne koyu yazılır.
  static const Color onMedia = Color(0xFFF3EADB);
  static final Color onMediaMuted = onMedia.withValues(alpha: 0.72);

  /// Medya letterbox / video arkası dolgu. Tema dönmez.
  static const Color mediaLetterbox = Color(0xFF08201A);

  // ── Durum ──────────────────────────────────────────────────────────────
  //
  // Bunlar METİN/İKON (ön plan) rolleridir ve `gold` ile AYNI tuzağa
  // düşmüşlerdi: sabit parlak tonlar açık temada krem zeminde AA'nın çok
  // altında kalıyordu (success 1.63:1, accent 2.54:1, info 2.21:1). Artık
  // brightness'a göre dönüyorlar — tüm çağrı yerleri değişmeden düzeliyor.
  //
  // ZEMİN olarak kullanma. Dolgulu buton gerekiyorsa `*Surface` + `on*` çifti.

  /// Olumlu durum METNİ/İKONU (onaylandı, tamamlandı). Koyu 8.9:1, açık 5.6:1.
  static Color get success => _pick(const Color(0xFF5ED27D), const Color(0xFF186B33));

  /// Vurgu / ikincil eylem METNİ/İKONU (sil, reddet, uyarı ipucu).
  /// Koyu 5.7:1, açık 5.7:1.
  static Color get accent => _pick(const Color(0xFFC9856A), const Color(0xFF8C4A2F));

  /// Bilgi METNİ/İKONU. Koyu 6.4:1, açık 6.0:1.
  static Color get info => _pick(const Color(0xFF5AA9D6), const Color(0xFF1A5F82));

  /// Yıkıcı eylem (silme, hata) METNİ/İKONU. Koyu 6.4:1, açık 6.5:1.
  static Color get danger => _pick(const Color(0xFFE8836F), const Color(0xFFA02216));

  /// Uyarı (dikkat, bekleme) METNİ/İKONU. Koyu 9.0:1, açık 5.1:1.
  static Color get warning => _pick(const Color(0xFFE8B54A), const Color(0xFF8A5A00));

  /// Quiz geri bildirimi — [success]/[danger] ile aynı, çağrı yerinde okunur olsun diye.
  static Color get correct => success;
  static Color get incorrect => danger;

  // ── Durum ZEMİNLERİ (SABİT) + üstlerindeki metin ───────────────────────
  // Dolgulu butonlar için. Zemin tema DÖNMEZ; üstündeki metin sabit eşidir.
  static const Color successSurface = Color(0xFF5ED27D);
  static const Color onSuccess = Color(0xFF08201A); // 8.9:1
  static const Color accentSurface = Color(0xFFC9856A);
  static const Color onAccent = Color(0xFF08201A); // 5.7:1
  static const Color dangerSurface = Color(0xFFA02216);
  static const Color onDanger = Color(0xFFFFF5F3); // 7.2:1

  // ── Hairline / kenarlık (DÖNER) ────────────────────────────────────────
  static Color get line => gold.withValues(alpha: _light ? 0.32 : 0.18);
  static Color get lineSoft =>
      _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)).withValues(alpha: _light ? 0.10 : 0.07);

  // ── Hero / kart gradyanları (DÖNER) ────────────────────────────────────
  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _light
            ? const [Color(0xFFFBEFD0), Color(0xFFF4ECDD)]
            : const [Color(0xFF1E4D38), Color(0xFF08201A)],
      );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _light
            ? const [Color(0xFFFFFFFF), Color(0xFFFBF6EC)]
            : const [Color(0xFF102C22), Color(0xFF0D2A20)],
      );

  // Basılı/etkin kart gradyanı — hızlı işlem kutusu dokununca parlar.
  static LinearGradient get cardGradientActive => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _light
            ? const [Color(0xFFF6ECD4), Color(0xFFEFE3C9)]
            : const [Color(0xFF1B4334), Color(0xFF123528)],
      );

  // FAB (Oluştur) altın gradyanı — her iki temada da parlak altın (SABİT).
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldBright, goldSoft],
  );
}
