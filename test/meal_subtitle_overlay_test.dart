// MealSubtitleOverlay: konuma göre etkin cue'nun meali + ayet no'su, kırpma yok.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_subtitle_overlay.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';
import 'package:video_player/video_player.dart';

Ayah _ayah(int n, String arabic, String meal) => Ayah(
      id: n,
      surahNumber: 1,
      numberInSurah: n,
      arabic: arabic,
      meal: meal,
    );

VideoPlayerValue _at(double sec) => VideoPlayerValue(
      duration: const Duration(seconds: 20),
      position: Duration(milliseconds: (sec * 1000).round()),
    );

const _cues = [
  MealCue(startSec: 0, endSec: 10, surah: 1, ayah: 1),
  MealCue(startSec: 10, endSec: 20, surah: 1, ayah: 2, approx: true),
];

Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<VideoPlayerValue> pos, {
  List<MealCue> cues = _cues,
  MealCueStyle style = MealCueStyle.standard,
  List<Ayah>? ayahs,
  double width = 400,
  double scale = 1.0,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      surahAyahsProvider(1).overrideWith((ref) async =>
          ayahs ??
          [
            _ayah(1, 'بِسْمِ اللَّهِ', 'Birinci ayetin meali'),
            _ayah(2, 'الْحَمْدُ لِلَّهِ', 'İkinci ayetin meali'),
          ]),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
            size: Size(width, 800), textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: width,
              child: MealSubtitleOverlay(position: pos, cues: cues, style: style),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('cue içindeyken meal ve ayet numarası görünür', (tester) async {
    await _pump(tester, ValueNotifier(_at(2)));
    expect(find.text('Birinci ayetin meali'), findsOneWidget);
    expect(find.text('1. ayet'), findsOneWidget);
  });

  testWidgets('cue dışında hiçbir şey çizilmez', (tester) async {
    await _pump(tester, ValueNotifier(_at(25)));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('konum ilerleyince metin değişir, approx etiketlenir',
      (tester) async {
    final pos = ValueNotifier(_at(2));
    await _pump(tester, pos);
    pos.value = _at(12);
    await tester.pump();
    expect(find.text('İkinci ayetin meali'), findsOneWidget);
    expect(find.text('2. ayet · yaklaşık'), findsOneWidget);
    expect(find.text('Birinci ayetin meali'), findsNothing);
  });

  testWidgets('arabic stilinde Arapça metin RTL çizilir', (tester) async {
    await _pump(tester, ValueNotifier(_at(2)), style: MealCueStyle.arabic);
    final ar = find.text('بِسْمِ اللَّهِ');
    expect(ar, findsOneWidget);
    expect(Directionality.of(tester.element(ar)), TextDirection.rtl);
    expect(find.text('Birinci ayetin meali'), findsOneWidget);
  });

  testWidgets('uzun meal sayfalanır, kırpılmaz', (tester) async {
    final meal = List.generate(60, (i) => 'kelime$i').join(' ');
    final pos = ValueNotifier(_at(0.5));
    final cues = [const MealCue(startSec: 0, endSec: 10, surah: 1, ayah: 1)];
    final ayahs = [_ayah(1, 'ب', meal)];
    String shown() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    await _pump(tester, pos, cues: cues, ayahs: ayahs);
    // Cue boyunca tara: görünen sayfalar birleşince tüm kelimeler var olmalı.
    final seen = <String>{};
    for (var sec = 0.1; sec < 10; sec += 0.5) {
      pos.value = _at(sec);
      await tester.pump();
      seen.add(shown());
    }
    expect(seen.length, greaterThan(1));
    final all = seen.join(' ');
    expect(all.contains('…'), isFalse);
    for (var i = 0; i < 60; i++) {
      expect(all.contains('kelime$i'), isTrue, reason: 'kelime$i eksik');
    }
  });

  testWidgets('320 genişlik ve 1.3 ölçekte taşma yok', (tester) async {
    final meal = List.generate(30, (i) => 'uzunuzunkelime$i').join(' ');
    for (final style in MealCueStyle.values) {
      await _pump(tester, ValueNotifier(_at(1)),
          style: style,
          ayahs: [_ayah(1, 'ب' * 40, meal)],
          width: 320,
          scale: 1.3);
      expect(tester.takeException(), isNull, reason: '$style');
    }
  });

  testWidgets('FittedMealSubtitle 288x162 kartta büyük stil ve 1.3 ölçekte kart içinde kalır',
      (tester) async {
    final meal = List.generate(
      20,
      (i) => 'kelime$i',
    ).join(' ').padRight(140, 'x').substring(0, 140);
    const card = Size(288, 162);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        surahAyahsProvider(1).overrideWith((ref) async => [_ayah(1, 'ب', meal)]),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 700), textScaler: TextScaler.linear(1.3)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.fromSize(
              size: card,
              child: Stack(
                key: const Key('card'),
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 40,
                    child: FittedMealSubtitle(
                      position: ValueNotifier(_at(1)),
                      cues: const [MealCue(startSec: 0, endSec: 10, surah: 1, ayah: 1)],
                      style: MealCueStyle.large,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final cardRect = tester.getRect(find.byKey(const Key('card')));
    final box = tester.getRect(find.byType(DecoratedBox).last);
    expect(box.top, greaterThanOrEqualTo(cardRect.top));
    expect(box.bottom, lessThanOrEqualTo(cardRect.bottom - 40 + 0.5));
    expect(box.left, greaterThanOrEqualTo(cardRect.left));
    expect(box.right, lessThanOrEqualTo(cardRect.right));
  });
}
