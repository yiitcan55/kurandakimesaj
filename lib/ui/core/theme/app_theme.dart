import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Köşe yarıçapı token'ları — 3 katman (Flutter Planı.html §04).
abstract class AppRadii {
  static const double sm = 12.0;
  static const double md = 18.0;
  static const double lg = 28.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(lg));

  // Sohbet baloncuğu — Mesajlar ve AI asistan tek dili paylaşır.
  static const double bubble = 16.0;
  static const double bubbleTail = 4.0;

  /// Sohbet baloncuğu köşe yarıçapı. Üst köşeler yumuşak; gönderen tarafında
  /// (`mine`) sağ-alt kuyruk, karşı tarafta sol-alt kuyruk sivrilir.
  static BorderRadius chatBubble({required bool mine}) => BorderRadius.only(
        topLeft: const Radius.circular(bubble),
        topRight: const Radius.circular(bubble),
        bottomLeft: Radius.circular(mine ? bubble : bubbleTail),
        bottomRight: Radius.circular(mine ? bubbleTail : bubble),
      );
}

/// Animasyon süre + eğri token'ları. Bol animasyonun tutarlı temposu için
/// tüm geçiş/giriş animasyonları bu değerleri kullanır.
abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration entrance = Duration(milliseconds: 650);
  static const Duration stagger = Duration(milliseconds: 60);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve spring = Curves.elasticOut;
}

/// Tipografi yardımcıları — Cormorant Garamond (başlık), DM Sans (gövde),
/// Amiri Quran (Arapça). google_fonts ile çalışma zamanında çekilir.
abstract class AppTypography {
  static TextStyle display({double size = 34, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: -0.5,
        color: color ?? AppColors.cream,
      );

  static TextStyle body({double size = 15.5, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        height: 1.5,
        color: color ?? AppColors.cream2,
      );

  static TextStyle eyebrow() => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.4,
        color: AppColors.goldInk,
      );
}

/// Arapça hat metni için ortak stil (RTL, Amiri Quran).
TextStyle arabicStyle({double size = 26, Color? color}) => GoogleFonts.amiriQuran(
      fontSize: size,
      height: 1.9,
      color: color ?? AppColors.goldInk,
    );

/// Material 3 tema — seed = altın, yüzey = zümrüt (koyu) / krem (açık).
/// [brightness] aktif paleti belirler; `AppColors` getter'ları buna göre döner.
ThemeData buildAppTheme(Brightness brightness) {
  // ThemeData içindeki AppColors getter'larının doğru paleti döndürmesi için
  // global brightness'ı bu tema kurulmadan ÖNCE ayarla. Renkler ThemeData'ya
  // somut değer olarak gömülür, dolayısıyla sonraki tema kurulumu bunu bozmaz.
  AppColors.brightness = brightness;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: brightness,
    surface: AppColors.emerald900,
  ).copyWith(
    primary: AppColors.gold,
    secondary: AppColors.goldBright,
    onPrimary: AppColors.onGold,
    onSurface: AppColors.cream,
    surfaceContainerHighest: AppColors.emerald850,
  );

  final baseText = GoogleFonts.dmSansTextTheme(
      (brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light())
          .textTheme);
  final textTheme = baseText.copyWith(
    displayLarge: AppTypography.display(size: 56, color: AppColors.cream),
    displayMedium: AppTypography.display(size: 44, color: AppColors.cream),
    headlineMedium: AppTypography.display(size: 30, color: AppColors.cream),
    headlineSmall: AppTypography.display(size: 24, color: AppColors.cream),
    titleLarge: AppTypography.display(size: 22, color: AppColors.cream),
    bodyLarge: AppTypography.body(size: 16, color: AppColors.cream2),
    bodyMedium: AppTypography.body(size: 14.5, color: AppColors.cream2),
    labelLarge: AppTypography.body(size: 14, weight: FontWeight.w600, color: AppColors.cream),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: AppColors.emerald950,
    colorScheme: scheme,
    textTheme: textTheme,
    splashColor: AppColors.goldFaint,
    highlightColor: AppColors.goldFaint,
    iconTheme: const IconThemeData(color: AppColors.gold),
    dividerColor: AppColors.lineSoft,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.cream,
    ),
    cardTheme: CardThemeData(
      color: AppColors.emerald900,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdAll,
        side: BorderSide(color: AppColors.line),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.emerald850,
      modalBackgroundColor: AppColors.emerald850,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.emerald900,
      hintStyle: AppTypography.body(color: AppColors.muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.smAll,
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.smAll,
        borderSide: BorderSide(color: AppColors.gold, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
        textStyle: AppTypography.body(size: 15, weight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.smAll),
      ),
    ),
  );
}
