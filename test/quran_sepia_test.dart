// Sepya okuma modu kontrast regresyon testi — WCAG 2.1 AA.
//
// Kök neden: `SurahReaderScreen` sepya için KENDİ sabit paletini kuruyor ve
// global temadan bağımsız. Ama sepya zemininin üstünde duran widget'lar
// renklerini global temadan okuyordu; global tema ise sepyayı bilmiyor.
//
// En sert sonuç KOYU tema + sepya: `AppHeader` başlığını `AppColors.cream`
// ile çiziyordu, koyu temada `cream` = #F3EADB — sepya zemini de #F3EADB.
// Kontrast 1.0:1, başlık tamamen görünmez. Aynı sınıf hata sepya zeminindeki
// her altın metin/ikonda vardı (`goldInk` koyu temada #D4B25B → 1.66:1).
//
// Bu fazın kabul kapısı "cihazda açık tema + sepya ekran görüntüsü" idi;
// cihaz erişimi olmadığı için bu hata sınıfının TEK otomatik koruması bu
// dosya. Assert kasten kontrast ORANI — "renk != zemin" zayıftır, 1.1:1 de
// eşit değildir ama yine görünmezdir.
//
// `contrast()` ve `aa` eşiği tema testinden yeniden kullanılır (tek kaynak).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart'; // TtsService'i de dışa verir
import 'package:kurandakimesaj/features/quran/quran_screens.dart';
import 'package:kurandakimesaj/ui/core/theme/app_colors.dart';

import 'theme_contrast_test.dart' show aa, contrast;

const _surah = Surah(
  number: 1,
  nameTr: 'Fâtiha',
  nameArabic: 'الفاتحة',
  meaning: 'Açılış',
  ayahCount: 1,
  revelation: 'Mekke',
  juzStart: 1,
);

const _besmele = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

const _ayahs = <Ayah>[
  Ayah(
    id: 1,
    surahNumber: 1,
    numberInSurah: 1,
    arabic: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
    meal: 'Hamd, âlemlerin Rabbi Allah\'a mahsustur.',
  ),
];

/// Tilaveti audio katmanına dokunmadan "boşta" tutar — gerçek
/// [QuranPlayerController.build] just_audio akışlarına abone oluyor.
///
/// [stop] da susturulur: ekran `dispose`'ta onu çağırıyor ve testte
/// `ProviderScope` widget ağacıyla AYNI anda yıkıldığı için notifier o sırada
/// çoktan atılmış oluyor. Üründe kök scope ekrandan uzun yaşar, sorun değil.
class _IdlePlayer extends QuranPlayerController {
  @override
  QuranPlayback build() => const QuranPlayback();

  @override
  Future<void> stop() async {}
}

/// Ekranda GERÇEKTEN çizilen metin rengi (DefaultTextStyle ile birleşmiş
/// hâli). Widget'ın `style` alanını okumak yetmez — miras alınan renkleri
/// kaçırır ve test yalancı-yeşil olur.
Color _painted(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style!.color!;

Color _bg(WidgetTester tester) =>
    tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;

Future<void> _pumpReader(WidgetTester tester, Brightness brightness) async {
  // Okuyucu renkleri global paletten okur; testte doğrudan onu kur
  // (uygulamada bunu `MaterialApp.builder` yapıyor).
  AppColors.brightness = brightness;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        surahAyahsProvider(_surah.number).overrideWith((ref) async => _ayahs),
        quranPlayerProvider.overrideWith(_IdlePlayer.new),
        ttsServiceProvider.overrideWithValue(TtsService()),
      ],
      child: const MaterialApp(home: SurahReaderScreen(surah: _surah)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sepya varsayılan KAPALI gelir; başlıktaki güneş simgesi onu açar.
Future<void> _enableSepia(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.wb_sunny_rounded));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget,
      reason: 'sepya açılmadı — simge değişmedi');
}

void main() {
  tearDown(() => AppColors.brightness = Brightness.dark);

  for (final brightness in Brightness.values) {
    // ASIL HATA. Koyu temada bu 1.0:1 veriyordu (başlık = zemin).
    testWidgets(
        '${brightness.name} tema + sepya AÇIK: başlık zeminden ayırt edilebilir',
        (tester) async {
      await _pumpReader(tester, brightness);
      await _enableSepia(tester);

      final bg = _bg(tester);
      final title = _painted(tester, find.text(_surah.nameTr));

      expect(contrast(title, bg), greaterThanOrEqualTo(aa),
          reason: '${brightness.name} + sepya: başlık $title, zemin $bg');
    });

    // Regresyon güvencesi: opsiyonel parametreler varsayılanda kaldığında
    // sepya kapalı yol BİREBİR eskisi gibi davranmalı.
    testWidgets('${brightness.name} tema + sepya KAPALI: tema paleti değişmedi',
        (tester) async {
      await _pumpReader(tester, brightness);

      expect(_bg(tester), AppColors.emerald950);
      expect(_painted(tester, find.text(_surah.nameTr)), AppColors.cream);
      expect(_painted(tester, find.text(_besmele)), AppColors.goldInk);
      expect(_painted(tester, find.text(_ayahs.first.arabic)),
          AppColors.goldInk);
      expect(_painted(tester, find.text(_ayahs.first.meal)), AppColors.cream);
    });
  }

  // Sepya zemininin üstündeki ALTIN ön plan. Marka altını (#D4B25B) burada
  // 1.66:1 kalıyordu; sepya eşi (#7E5F14) 5.0:1 verir.
  testWidgets('sepya zemininde altın ön plan (Besmele + ayet Arapçası) AA',
      (tester) async {
    await _pumpReader(tester, Brightness.dark);
    await _enableSepia(tester);

    final bg = _bg(tester);
    for (final (label, text) in [
      ('Besmele', _besmele),
      ('ayet Arapçası', _ayahs.first.arabic),
      ('meal', _ayahs.first.meal),
    ]) {
      final fg = _painted(tester, find.text(text));
      expect(contrast(fg, bg), greaterThanOrEqualTo(aa),
          reason: 'sepya zemininde $label: $fg × $bg');
    }
  });
}
