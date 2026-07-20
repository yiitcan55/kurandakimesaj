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
  static Color get goldInk => _pick(const Color(0xFFD4B25B), const Color(0xFF8A6A1F));

  /// Altın yüzey ÜSTÜNDEKİ metin/ikon (buton, seçili chip, FAB). Her iki
  /// temada da koyu — altın sabit kaldığı için DÖNMEZ.
  static const Color onGold = Color(0xFF08201A);

  // ── Metin (DÖNER) ──────────────────────────────────────────────────────
  static Color get cream => _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)); // birincil
  static Color get cream2 => _pick(const Color(0xFFE6DCC8), const Color(0xFF2A4034)); // gövde
  static Color get muted =>
      _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)).withValues(alpha: _light ? 0.60 : 0.62);
  // %40 küçük metinde 4.5:1 kontrastın altındaydı (WCAG AA); %55 ~4.9:1 sağlar.
  static Color get muted2 =>
      _pick(const Color(0xFFF3EADB), const Color(0xFF16271F)).withValues(alpha: _light ? 0.62 : 0.55);

  // ── Durum (SABİT) ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF5ED27D);
  static const Color accent = Color(0xFFC9856A);
  static const Color info = Color(0xFF5AA9D6);

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
