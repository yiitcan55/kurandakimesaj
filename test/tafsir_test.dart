// Muhtasar tefsir (QuranEnc "turkish_mokhtasar") — varlık sözleşmesi + AyahNote.
//
// Yeniden yayın koşulu: metin DEĞİŞTİRİLMEZ, kaynak açıkça anılır. Bu yüzden
// varlık testi yalnız sayıyı değil, 114 surenin her ayetinin varlığını ve
// ilk ayetin birebir başlangıcını da kilitler.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart'; // TtsService'i de dışa verir
import 'package:kurandakimesaj/data/seed/seed_data.dart' show kSurahSeed;
import 'package:kurandakimesaj/data/tafsir.dart';
import 'package:kurandakimesaj/features/daily_ayah/daily_ayah_screen.dart';
import 'package:kurandakimesaj/ui/core/ayah_note.dart';

const _kaynakSatiri =
    "Kaynak: Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi — QuranEnc.com";

const _sahte = Tafsir(
  byAyah: {'1:2': 'SAHTE MUHTASAR METNİ'},
  title: "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi",
  source: 'QuranEnc.com',
  fetched: '2026-11-09',
);

Widget _host(Widget child, {required List<Override> overrides}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('varlık sözleşmesi', () {
    late Map<String, dynamic> json;
    setUpAll(() {
      json = jsonDecode(File('assets/quran/tafsir_muhtasar_tr.json').readAsStringSync())
          as Map<String, dynamic>;
    });

    test('6236 ayetin tamamı var, hiçbiri boş değil', () {
      final t = (json['tafsir'] as Map).cast<String, String>();
      expect(t.length, 6236);
      expect(t.values.where((v) => v.trim().isEmpty), isEmpty);
      for (final s in kSurahSeed) {
        for (var a = 1; a <= s.$5; a++) {
          expect(t.containsKey('${s.$1}:$a'), isTrue, reason: '${s.$1}:$a eksik');
        }
      }
    });

    test('"1:1" birebir başlangıcı ve künye alanları', () {
      final t = (json['tafsir'] as Map).cast<String, String>();
      expect(t['1:1'], startsWith('Kendisinden yardım dileyip'));
      final m = json['meta'] as Map;
      expect(m['title'], "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi");
      expect(m['source'], 'QuranEnc.com');
      expect(m['key'], 'turkish_mokhtasar');
      expect(m['fetched'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('"2:105" metni birebir saklanır: sondaki boşluk trim edilmez', () {
      // Varlıkta bu kayıt boşlukla biter; trim eklenirse bu test düşer.
      final t = (json['tafsir'] as Map).cast<String, String>();
      expect(t['2:105'], isNot(equals(t['2:105']!.trim())));
    });
  });

  testWidgets('"Tefsir" katlı başlar; açılınca metin + kaynak satırı görünür', (tester) async {
    await tester.pumpWidget(_host(
      const AyahNote(surah: 1, ayah: 2, fg: Colors.black, ink: Colors.green),
      overrides: [tafsirProvider.overrideWith((ref) async => _sahte)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tefsir'), findsOneWidget);
    expect(find.text('SAHTE MUHTASAR METNİ'), findsNothing, reason: 'katlı başlar');

    await tester.tap(find.text('Tefsir'));
    await tester.pumpAndSettle();
    expect(find.text('SAHTE MUHTASAR METNİ'), findsOneWidget);
    expect(find.text(_kaynakSatiri), findsOneWidget);
  });

  testWidgets('kısa açıklaması olan ayette ikisi de görünür, tefsir altta', (tester) async {
    await tester.pumpWidget(_host(
      const AyahNote(surah: 2, ayah: 153, fg: Colors.black, ink: Colors.green),
      overrides: [
        tafsirProvider.overrideWith(
          (ref) async => const Tafsir(
            byAyah: {'2:153': 'BAKARA MUHTASAR'},
            title: "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi",
            source: 'QuranEnc.com',
            fetched: '2026-11-09',
          ),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    final kisa = tester.getTopLeft(find.text('Kısa açıklama')).dy;
    final tefsir = tester.getTopLeft(find.text('Tefsir')).dy;
    expect(tefsir, greaterThan(kisa));
  });

  testWidgets('yükleme hatasında AyahNote çökmez, tefsir bölümü görünmez', (tester) async {
    await tester.pumpWidget(_host(
      const AyahNote(surah: 2, ayah: 153, fg: Colors.black, ink: Colors.green),
      overrides: [
        tafsirProvider.overrideWith((ref) async => throw StateError('asset yok')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tefsir'), findsNothing);
    expect(find.text('Kısa açıklama'), findsOneWidget, reason: 'mevcut not korunur');
  });

  group('Günün Ayeti "Anla" sayfası', () {
    const surah = Surah(
      number: 1,
      nameTr: 'Fâtiha',
      nameArabic: 'الفاتحة',
      meaning: 'Açılış',
      ayahCount: 7,
      revelation: 'Mekke',
      juzStart: 1,
    );
    const ayah = Ayah(
      id: 2,
      surahNumber: 1,
      numberInSurah: 2,
      arabic: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
      meal: "Hamd, âlemlerin Rabbi Allah'a mahsustur.",
    );

    Future<void> pumpAndAnla(WidgetTester tester, Override tafsir) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dailyAyahProvider.overrideWith((ref) async => (ayah, surah)),
          ttsServiceProvider.overrideWithValue(TtsService()),
          tafsir,
        ],
        child: const MaterialApp(home: DailyAyahScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anla'));
      await tester.pumpAndSettle();
    }

    testWidgets('Muhtasar metni ve kaynak satırı gösterilir', (tester) async {
      await pumpAndAnla(tester, tafsirProvider.overrideWith((ref) async => _sahte));

      expect(find.text('SAHTE MUHTASAR METNİ'), findsOneWidget);
      expect(find.text(_kaynakSatiri), findsOneWidget);
      expect(find.text('Bu ayet için henüz açıklama eklenmedi.'), findsNothing);
    });

    testWidgets('tefsir yüklenemezse eski "henüz açıklama eklenmedi" yolu korunur', (tester) async {
      await pumpAndAnla(
        tester,
        tafsirProvider.overrideWith((ref) async => throw StateError('asset yok')),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Bu ayet için henüz açıklama eklenmedi.'), findsOneWidget);
    });
  });
}
