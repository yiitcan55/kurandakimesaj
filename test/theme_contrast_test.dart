// Tema kontrast regresyon testi — WCAG 2.1 AA.
//
// Kullanıcı şikâyeti: "koyu/açık temada yazılar gözükmüyor". Kök neden,
// SABİT marka/durum renklerinin (gold, success, accent, info) METİN rolünde
// kullanılmasıydı: açık temada krem zemine karşı 1.6–2.5:1 veriyorlardı
// (AA = 4.5:1) → pratikte görünmez.
//
// Bu test saf birim testidir (widget pump etmez) ve düzeltme geri alındığında
// DÜŞER: `goldInk` yerine `gold` yazılırsa ya da durum renkleri tekrar sabit
// yapılırsa aşağıdaki beklentiler patlar.
//
// Alfa kritik: `muted`/`muted2` yarı saydam. Kontrast ölçmeden ÖNCE zemine
// kompozit edilmeleri gerekir, yoksa ölçüm yanlış (iyimser) çıkar.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/ui/core/theme/app_colors.dart';
import 'package:kurandakimesaj/ui/core/theme/app_theme.dart';

/// WCAG kontrast oranı. [fg] saydam olabilir — [bg] üstüne kompozit edilir.
/// [bg] opak varsayılır (scaffold/kart/zemin rolleri opak).
double contrast(Color fg, Color bg) {
  final f = Color.alphaBlend(fg, bg).computeLuminance();
  final b = bg.computeLuminance();
  final hi = math.max(f, b);
  final lo = math.min(f, b);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG AA — normal boyutlu metin.
const double aa = 4.5;

/// WCAG AA — büyük metin (≥24px veya ≥18.66px kalın) ve arayüz bileşenleri.
const double aaLarge = 3.0;

void main() {
  // buildAppTheme → google_fonts → AssetBundle zinciri binding istiyor.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Global palet testler arası sızmasın.
  tearDown(() => AppColors.brightness = Brightness.dark);

  for (final brightness in Brightness.values) {
    group('${brightness.name} tema', () {
      setUp(() => AppColors.brightness = brightness);

      // Metin bu üç yüzeyin herhangi birinin üstünde durabilir; en sıkı
      // olanı geçmek zorunda. `gold` metin rolünde kullanıldığında açık
      // temada emerald950 (#F4ECDD) üstünde 1.66:1 veriyordu.
      List<(String, Color)> surfaces() => [
            ('scaffold', AppColors.emerald950),
            ('kart', AppColors.emerald900),
            ('sheet', AppColors.emerald850),
          ];

      test('altın METİN (goldInk) tüm yüzeylerde AA', () {
        for (final (name, bg) in surfaces()) {
          expect(contrast(AppColors.goldInk, bg), greaterThanOrEqualTo(aa),
              reason: 'goldInk × $name');
        }
      });

      test('birincil ve gövde metni tüm yüzeylerde AA', () {
        for (final (name, bg) in surfaces()) {
          expect(contrast(AppColors.cream, bg), greaterThanOrEqualTo(aa),
              reason: 'cream × $name');
          expect(contrast(AppColors.cream2, bg), greaterThanOrEqualTo(aa),
              reason: 'cream2 × $name');
        }
      });

      test('soluk metinler (alfa kompozit edilerek) AA', () {
        for (final (name, bg) in surfaces()) {
          expect(contrast(AppColors.muted, bg), greaterThanOrEqualTo(aa),
              reason: 'muted × $name');
          expect(contrast(AppColors.muted2, bg), greaterThanOrEqualTo(aa),
              reason: 'muted2 × $name');
        }
      });

      // Ters ternary regresyonu: `muted2` üçüncül metindir, `muted`'tan DAHA
      // SOLUK olmalı. Açık temada alfalar terstir (0.60 vs 0.62) ve hiyerarşi
      // tersine dönüyordu — muted2 muted'tan KOYU çiziliyordu.
      test('muted2, muted\'tan daha soluk (hiyerarşi ters değil)', () {
        final bg = AppColors.emerald950;
        expect(contrast(AppColors.muted2, bg),
            lessThan(contrast(AppColors.muted, bg)),
            reason: '${brightness.name}: muted2 muted\'tan koyu çiziliyor');
      });

      test('durum renkleri METİN rolünde AA', () {
        final roles = <String, Color>{
          'success': AppColors.success,
          'accent': AppColors.accent,
          'info': AppColors.info,
          'danger': AppColors.danger,
          'warning': AppColors.warning,
        };
        for (final (name, bg) in surfaces()) {
          roles.forEach((role, color) {
            expect(contrast(color, bg), greaterThanOrEqualTo(aa),
                reason: '$role × $name');
          });
        }
      });

      // Ayet numarası rozeti: `goldFaint` ZEMİN + altın METİN. `gold` metin
      // olarak kullanılırken bu çift HER İKİ temada da ≈1.3:1 veriyordu.
      test('ayet no rozeti (goldFaint zemin) AA', () {
        for (final (name, bg) in surfaces()) {
          final badge = Color.alphaBlend(AppColors.goldFaint, bg);
          expect(contrast(AppColors.goldInk, badge), greaterThanOrEqualTo(aa),
              reason: 'goldInk × goldFaint@$name');
        }
      });
    });
  }

  // ── Tema DÖNMEYEN çiftler — brightness'tan bağımsız olmalı ─────────────

  group('sabit çiftler (tema dönmez)', () {
    for (final brightness in Brightness.values) {
      test('${brightness.name}: altın yüzey üstündeki metin AA', () {
        AppColors.brightness = brightness;
        expect(contrast(AppColors.onGold, AppColors.gold),
            greaterThanOrEqualTo(aa));
      });

      // Reels videosu / stüdyo önizlemesi daima koyu kalır. Buralarda tema
      // DÖNEN `cream`/`muted` kullanılırsa açık temada koyu üstüne koyu yazılır.
      test('${brightness.name}: medya üstü metin (onMedia) AA', () {
        AppColors.brightness = brightness;
        expect(contrast(AppColors.onMedia, AppColors.mediaLetterbox),
            greaterThanOrEqualTo(aa));
        expect(contrast(AppColors.onMedia, Colors.black),
            greaterThanOrEqualTo(aa));
        expect(contrast(AppColors.onMediaMuted, AppColors.mediaLetterbox),
            greaterThanOrEqualTo(aa));
        // Video karesi üstündeki tipik scrim.
        final scrim =
            Color.alphaBlend(Colors.black.withValues(alpha: 0.45), Colors.grey);
        expect(contrast(AppColors.onMedia, scrim),
            greaterThanOrEqualTo(aaLarge));
      });

      test('${brightness.name}: dolgulu durum butonları AA', () {
        AppColors.brightness = brightness;
        expect(contrast(AppColors.onDanger, AppColors.dangerSurface),
            greaterThanOrEqualTo(aa),
            reason: '"Hesabı sil" butonu — eskiden açık temada 2.9:1');
        expect(contrast(AppColors.onSuccess, AppColors.successSurface),
            greaterThanOrEqualTo(aa));
        expect(contrast(AppColors.onAccent, AppColors.accentSurface),
            greaterThanOrEqualTo(aa));
      });
    }
  });

  // ── buildAppTheme saflığı ──────────────────────────────────────────────
  //
  // `theme:` ve `darkTheme:` arka arkaya değerlendirildiği için global palet
  // her zaman SON çağrıda (dark) kalıyordu; builder alt-ağacının DIŞINDA renk
  // okuyan her yer (route inşası, showModalBottomSheet/showDialog argümanları,
  // ScaffoldMessenger) yanlış paleti alıyordu.
  test('buildAppTheme global paleti kalıcı değiştirmez', () async {
    // google_fonts fontu ne asset'ten ne ağdan çözebiliyor. `allowRuntimeFetching`
    // yalnız ağ bacağını kapatır; asset araması yine YAKALANMAMIŞ bir async hata
    // fırlatabiliyor ve o sırada koşan teste yazılıyor — testi KARARSIZ yapar
    // (tek başına geçer, tam pakette rastgele düşer; CI `flutter test` koşuyor).
    // Bu testin konusu font değil, global paletin geri yüklenmesi. Font
    // hatasını kendi zone'unda yutup asıl değişmezi ölç.
    GoogleFonts.config.allowRuntimeFetching = false;

    AppColors.brightness = Brightness.light;
    final lightScaffold = AppColors.emerald950;

    await runZonedGuarded(() async {
      buildAppTheme(Brightness.light);
      buildAppTheme(Brightness.dark); // eskiden global burada dark'ta kalıyordu
    }, (_, _) {});

    expect(AppColors.brightness, Brightness.light);
    expect(AppColors.emerald950, lightScaffold);
  });
}
