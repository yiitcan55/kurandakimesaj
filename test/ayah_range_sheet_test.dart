// Elle ayet aralığı seçici (T5): arama süzgeci, geçersiz aralıkta kapalı onay
// + yazılı neden, onayda beklenen record.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/features/meal_edit/ayah_range_sheet.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

const _sureler = [
  Surah(number: 1, nameTr: 'Fâtiha', nameArabic: 'الفاتحة', meaning: 'Açılış', ayahCount: 7, revelation: 'Mekki', juzStart: 1),
  Surah(number: 36, nameTr: 'Yasin', nameArabic: 'يس', meaning: 'Yâ-Sîn', ayahCount: 83, revelation: 'Mekki', juzStart: 22),
];

AyahRangePick? _sonuc;

Future<void> _ac(WidgetTester tester, {int maxAyahs = 60}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  _sonuc = null;
  await tester.pumpWidget(ProviderScope(
    overrides: [surahsProvider.overrideWith((ref) async => _sureler)],
    child: MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          key: const Key('ac'),
          onPressed: () async =>
              _sonuc = await showAyahRangeSheet(c, maxAyahs: maxAyahs),
          child: const Text('ac'),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('ac')));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100)); // surahsProvider çözülsün
}

Future<void> _sec(WidgetTester tester, Key dd, int v) async {
  await tester.tap(find.byKey(dd));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text('$v').last);
  await tester.pump(const Duration(milliseconds: 500));
}

bool _onayAcik(WidgetTester t) =>
    t.widget<FilledButton>(find.byKey(const Key('rangeConfirm'))).onPressed != null;

void main() {
  testWidgets('arama sureyi süzer', (tester) async {
    await _ac(tester);
    expect(find.byKey(const Key('rangeSurah_1')), findsOneWidget);
    expect(find.byKey(const Key('rangeSurah_36')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rangeSearch')), 'yas');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('rangeSurah_1')), findsNothing);
    expect(find.byKey(const Key('rangeSurah_36')), findsOneWidget);
  });

  testWidgets('bitiş başlangıçtan küçükse onay kapalı ve neden yazılı', (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('rangeSurah_1')));
    await tester.pump(const Duration(milliseconds: 300));
    await _sec(tester, const Key('rangeFrom'), 5);
    expect(find.text('Bitiş ayeti başlangıçtan küçük olamaz.'), findsOneWidget);
    expect(_onayAcik(tester), isFalse);
  });

  testWidgets('üst sınırı aşan aralıkta onay kapalı ve neden yazılı', (tester) async {
    await _ac(tester, maxAyahs: 3);
    await tester.tap(find.byKey(const Key('rangeSurah_1')));
    await tester.pump(const Duration(milliseconds: 300));
    await _sec(tester, const Key('rangeTo'), 5);
    expect(find.text('En fazla 3 ayet seçebilirsin.'), findsOneWidget);
    expect(_onayAcik(tester), isFalse);
  });

  testWidgets('onay seçimi döndürür', (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('rangeSurah_1')));
    await tester.pump(const Duration(milliseconds: 300));
    await _sec(tester, const Key('rangeFrom'), 2);
    await _sec(tester, const Key('rangeTo'), 4);
    expect(find.text('Fâtiha, 2-4 · 3 ayet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rangeConfirm')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_sonuc, (surah: 1, from: 2, to: 4));
  });
}
