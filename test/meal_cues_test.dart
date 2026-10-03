import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/domain/models.dart';

AyahTimelineEntry _t(int surah, int ayah, double s, double e) =>
    AyahTimelineEntry(
      startSec: s,
      endSec: e,
      surah: surah,
      ayah: ayah,
      reference: '$surah:$ayah',
      confidence: 1,
    );

void _expectWellFormed(List<MealCue> cues, List<CueAyah> ayahs) {
  expect(cues.length, ayahs.length, reason: 'aralıktaki hiçbir ayet düşmez');
  for (var i = 0; i < cues.length; i++) {
    expect(cues[i].surah, ayahs[i].surah);
    expect(cues[i].ayah, ayahs[i].ayah);
    expect(cues[i].endSec, greaterThan(cues[i].startSec));
    if (i > 0) {
      expect(cues[i].startSec, greaterThanOrEqualTo(cues[i - 1].endSec));
    }
  }
}

void main() {
  const ayahs3 = <CueAyah>[
    (surah: 1, ayah: 1, weight: 10),
    (surah: 1, ayah: 2, weight: 30),
    (surah: 1, ayah: 3, weight: 60),
  ];

  group('buildCues', () {
    test('çapasız aralık süreye harf ağırlığıyla dağılır ve hepsi approx', () {
      final c = buildCues(ayahs: ayahs3, durationSec: 100);
      expect(c.map((e) => e.startSec), [0, 10, 40]);
      expect(c.map((e) => e.endSec), [10, 40, 100]);
      expect(c.every((e) => e.approx), isTrue);
    });

    test('çapalı ayet tam timeline başlangıcında başlar', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [_t(1, 1, 2, 5), _t(1, 2, 5, 9), _t(1, 3, 9, 14)],
        durationSec: 20,
      );
      expect(c.map((e) => e.startSec), [2, 5, 9]);
      expect(c.last.endSec, 14);
      expect(c.every((e) => !e.approx), isTrue);
    });

    test('çapalar arası eksik ayet aradaki boşluğa yerleşir', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [_t(1, 1, 1, 4), _t(1, 3, 10, 12)],
        durationSec: 20,
      );
      expect(c[0].startSec, 1);
      expect(c[1].startSec, 4);
      expect(c[1].endSec, 10);
      expect(c[1].approx, isTrue);
      expect(c[2].startSec, 10);
      expect(c[2].endSec, 12);
      _expectWellFormed(c, ayahs3);
    });

    test('tekrar eden ve geri dönen timeline zaman sırasını korur', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [
          _t(1, 1, 0, 3),
          _t(1, 2, 3, 6),
          _t(1, 1, 6, 9), // tekrar: ilk çapa geçerli
          _t(1, 3, 2, 4), // geri dönüş: 2 < 3 → çapasız sayılır
        ],
        durationSec: 12,
      );
      _expectWellFormed(c, ayahs3);
      expect(c[0].startSec, 0);
      expect(c[1].startSec, 3);
      expect(c[2].approx, isTrue);
      expect(c[2].startSec, greaterThanOrEqualTo(c[1].endSec));
      expect(c[2].endSec, 12);
    });

    test('baştaki çapasız ayet 0dan çapaya kadar dağılır', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [_t(1, 3, 8, 10)],
        durationSec: 10,
      );
      _expectWellFormed(c, ayahs3);
      expect(c[0].startSec, 0);
      expect(c[2].startSec, 8);
      expect(c[1].endSec, 8);
    });

    test('süre 0 iken son çapanın bitişi süre sayılır; çapa yoksa boş', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [_t(1, 1, 0, 3), _t(1, 2, 3, 6), _t(1, 3, 6, 9)],
        durationSec: 0,
      );
      expect(c.last.endSec, 9);
      expect(buildCues(ayahs: ayahs3, durationSec: 0), isEmpty);
    });

    test('aralık dışı timeline girdileri yok sayılır', () {
      final c = buildCues(
        ayahs: ayahs3,
        timeline: [_t(2, 1, 0, 5), _t(1, 1, 1, 3)],
        durationSec: 10,
      );
      _expectWellFormed(c, ayahs3);
      expect(c.first.startSec, 1);
    });
  });

  group('cueAt', () {
    const cues = [
      MealCue(startSec: 1, endSec: 3, surah: 1, ayah: 1),
      MealCue(startSec: 3, endSec: 5, surah: 1, ayah: 2),
    ];
    test('start dahil, end hariç', () {
      expect(cueAt(cues, 0.99), isNull);
      expect(cueAt(cues, 1)?.ayah, 1);
      expect(cueAt(cues, 2.99)?.ayah, 1);
      expect(cueAt(cues, 3)?.ayah, 2);
      expect(cueAt(cues, 5), isNull);
    });
  });

  group('splitMealPages', () {
    test('hiçbir kelimeyi kaybetmez ve sınırı aşmaz', () {
      const meal = "Rahman ve Rahim olan Allah'ın adıyla. Hamd, "
          "âlemlerin Rabbi Allah'a mahsustur.";
      final pages = splitMealPages(meal, maxChars: 20);
      expect(pages.join(' '), meal);
      expect(pages.every((p) => p.length <= 20), isTrue);
    });
    test('uzun tek kelime kendi sayfasında bütün kalır; boş metin boş', () {
      final pages = splitMealPages('a bbbbbbbbbbbb c', maxChars: 5);
      expect(pages, ['a', 'bbbbbbbbbbbb', 'c']);
      expect(splitMealPages('   '), isEmpty);
    });
  });

  group('MealCue json', () {
    test('toJson yalnız s,e,su,a üretir ve iki ondalığa yuvarlar', () {
      const c = MealCue(
        startSec: 1.23456,
        endSec: 2.5,
        surah: 2,
        ayah: 255,
        approx: true,
      );
      expect(c.toJson(), {'s': 1.23, 'e': 2.5, 'su': 2, 'a': 255});
    });

    test('listFromJson gidiş-dönüş', () {
      const l = [MealCue(startSec: 0, endSec: 1.5, surah: 1, ayah: 1)];
      expect(MealCue.listFromJson(l.map((e) => e.toJson()).toList()), l);
    });

    test('listFromJson bozuk girdide [] döner, fırlatmaz', () {
      expect(MealCue.listFromJson(null), isEmpty);
      expect(MealCue.listFromJson('x'), isEmpty);
      expect(MealCue.listFromJson([1]), isEmpty);
      expect(MealCue.listFromJson([{'s': 0, 'e': 1, 'su': 1}]), isEmpty);
      expect(MealCue.listFromJson([{'s': 'a', 'e': 1, 'su': 1, 'a': 1}]), isEmpty);
      expect(MealCue.listFromJson([{'s': 0, 'e': 1, 'su': 115, 'a': 1}]), isEmpty);
      expect(MealCue.listFromJson([{'s': 0, 'e': 1, 'su': 1, 'a': 287}]), isEmpty);
      expect(MealCue.listFromJson([{'s': 2, 'e': 2, 'su': 1, 'a': 1}]), isEmpty);
      // bir bozuk öğe tüm listeyi düşürür
      expect(
        MealCue.listFromJson([
          {'s': 0, 'e': 1, 'su': 1, 'a': 1},
          {'s': 0, 'e': 1, 'su': 0, 'a': 1},
        ]),
        isEmpty,
      );
    });
  });

  test('MealCueStyle.fromDb bilinmeyende standard', () {
    expect(MealCueStyle.fromDb('large'), MealCueStyle.large);
    expect(MealCueStyle.fromDb('arabic'), MealCueStyle.arabic);
    expect(MealCueStyle.fromDb(null), MealCueStyle.standard);
    expect(MealCueStyle.fromDb('zzz'), MealCueStyle.standard);
    expect(MealCueStyle.standard.db, 'default');
  });
}
