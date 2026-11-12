// "Okuyucuda Aç" / Reels künyesi: uzun surenin SONLARINDAKİ ayete (30/40)
// gidilmeli. Kök neden: `ListView(children:)` tembel; ekran dışındaki hedef
// ayetin `GlobalKey.currentContext`i null olduğu için `_scrollToInitial`
// sessizce çıkıyor, okuyucu sure başında kalıyordu.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/tafsir.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

const _surah = Surah(
  number: 99,
  nameTr: 'Uzun Sûre',
  nameArabic: 'سورة',
  meaning: 'Test',
  ayahCount: 40,
  revelation: 'Mekke',
  juzStart: 1,
);

final _ayahs = <Ayah>[
  for (var n = 1; n <= 40; n++)
    Ayah(
      id: n,
      surahNumber: 99,
      numberInSurah: n,
      arabic: 'يَا أَيُّهَا الْمُزَّمِّلُ',
      meal: 'Ey örtüsüne bürünen! [ayet-$n]',
    ),
];

// Gerçek varlık (1,9 MB + Isolate) FakeAsync'te yüklenmez; her ayetin tefsiri var.
final _tafsir = Tafsir(
  byAyah: {for (var n = 1; n <= 40; n++) '99:$n': 'Muhtasar tefsir [tefsir-$n]'},
  title: "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi",
  source: 'QuranEnc.com',
  fetched: '2026-11-09',
);

class _IdlePlayer extends QuranPlayerController {
  @override
  QuranPlayback build() => const QuranPlayback();

  @override
  Future<void> stop() async {}
}

Future<void> _pumpReader(
  WidgetTester tester,
  int? initialAyah, {
  Future<Tafsir>? tafsir,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        surahAyahsProvider(_surah.number).overrideWith((ref) async => _ayahs),
        tafsirProvider.overrideWith((ref) => tafsir ?? Future.value(_tafsir)),
        quranPlayerProvider.overrideWith(_IdlePlayer.new),
        ttsServiceProvider.overrideWithValue(TtsService()),
      ],
      child: MaterialApp(
        home: SurahReaderScreen(surah: _surah, initialAyah: initialAyah),
      ),
    ),
  );
  // Veri + (varsa) atlama denemeleri + 450 ms kaydırma + vurgu; ders 18:
  // sonsuz animasyon yok ama gecikmeli Timer var → pumpAndSettle yerine süreli pump.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump(const Duration(seconds: 3));
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('uzun surenin sonundaki ayet (30) görünür alana kaydırılır', (
    tester,
  ) async {
    await _pumpReader(tester, 30);

    final target = find.textContaining('[ayet-30]');
    expect(target, findsOneWidget, reason: 'hedef ayet hiç kurulmadı');
    final top = tester.getTopLeft(target).dy;
    expect(
      top,
      inInclusiveRange(0, 800),
      reason: 'hedef ayet (30) ekranın dışında: okuyucu sure başında kaldı',
    );
    expect(find.textContaining('[ayet-1]'), findsNothing,
        reason: 'liste hâlâ sure başında');
    await _teardown(tester);
  });

  // Gerçek uygulamada tefsir varlığı oturumda İLK kez okunurken 100-400 ms sürer;
  // kaydırma bitmiş olabilir. Katlı "Tefsir" başlığı veriden bağımsız çizilmezse
  // her ayetin altına ~56 px eklenir, üstteki kutucuklar büyür ve hedef ayet
  // (30) ekrandan düşer.
  testWidgets('tefsir kaydırmadan SONRA yüklense de hedef ayet (30) yerinde kalır', (
    tester,
  ) async {
    final late = Completer<Tafsir>();
    await _pumpReader(tester, 30, tafsir: late.future);

    final target = find.textContaining('[ayet-30]');
    expect(target, findsOneWidget, reason: 'hedef ayet hiç kurulmadı');
    expect(tester.getTopLeft(target).dy, inInclusiveRange(0, 800));
    final before = tester.getTopLeft(target).dy;

    late.complete(_tafsir);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(target, findsOneWidget, reason: 'tefsir gelince hedef ayet düştü');
    final after = tester.getTopLeft(target).dy;
    expect(
      after,
      inInclusiveRange(0, 800),
      reason: 'tefsir geç yüklenince hedef ayet ekrandan çıktı (önce: $before, sonra: $after)',
    );
    expect(after, closeTo(before, 0.5), reason: 'yerleşim sabit kalmalı');
    await _teardown(tester);
  });

  testWidgets('hedef ayet yoksa (initialAyah null) kaydırma olmaz', (
    tester,
  ) async {
    await _pumpReader(tester, null);

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SurahReaderScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.pixels, 0);
    await _teardown(tester);
  });
}
