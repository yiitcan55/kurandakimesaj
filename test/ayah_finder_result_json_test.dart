import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/domain/models.dart';

/// `AyahFinderResult.fromJson` sözleşmesi iki yönde uyumlu olmalı:
/// - Eski `ayah-finder` (görsel/bağlantı) yanıtında range/timeline HİÇ YOK →
///   yeni model bunları null/boş kabul etmeli (geriye uyum).
/// - Yeni `ayah-finder-audio` yanıtındaki range/timeline tam parse edilmeli.
void main() {
  test('range/timeline içermeyen eski yanıt sorunsuz parse olur', () {
    final r = AyahFinderResult.fromJson({
      'status': 'matched',
      'extractedArabic': 'قل هو الله أحد',
      'matches': [
        {
          'reference': 'İhlas, 1',
          'surah': 112,
          'ayah': 1,
          'arabic': 'قل هو الله أحد',
          'meal': 'De ki: O Allah birdir.',
          'confidence': 0.95,
        },
      ],
    });

    expect(r.status, AyahFinderStatus.matched);
    expect(r.matches.single.surah, 112);
    expect(r.range, isNull); // görsel yolu aralık üretmez
    expect(r.timeline, isEmpty);
  });

  test('video yanıtındaki range ve timeline tam parse edilir', () {
    final r = AyahFinderResult.fromJson({
      'status': 'matched',
      'extractedArabic': 'سلام قولا من رب رحيم ...',
      'range': {
        'surah': 36,
        'fromAyah': 58,
        'toAyah': 61,
        'reference': 'Yasin, 58-61',
      },
      'matches': [
        {
          'reference': 'Yasin, 58',
          'surah': 36,
          'ayah': 58,
          'arabic': 'سلام',
          'meal': 'Selam vardır.',
          'confidence': 0.9,
        },
      ],
      'timeline': [
        {
          'startSec': 0,
          'endSec': 4.5,
          'surah': 36,
          'ayah': 58,
          'reference': 'Yasin, 58',
          'confidence': 0.9,
        },
        {
          'startSec': 4.5,
          'endSec': 9,
          'surah': 36,
          'ayah': 59,
          'reference': 'Yasin, 59',
          'confidence': 0.8,
        },
      ],
    });

    expect(r.status, AyahFinderStatus.matched);
    expect(r.range, isNotNull);
    expect(r.range!.surah, 36);
    expect(r.range!.fromAyah, 58);
    expect(r.range!.toAyah, 61);
    expect(r.range!.isSingle, isFalse);
    expect(r.range!.reference, 'Yasin, 58-61');
    expect(r.timeline, hasLength(2));
    expect(r.timeline.first.ayah, 58);
    expect(r.timeline.first.startLabel, '00:00');
    expect(r.timeline[1].startLabel, '00:04'); // 4.5 sn → 00:04
  });

  test('tek ayetlik video sonucunda range.isSingle doğru', () {
    final r = AyahFinderResult.fromJson({
      'status': 'matched',
      'range': {'surah': 36, 'fromAyah': 60, 'toAyah': 60, 'reference': 'Yasin, 60'},
      'matches': [
        {'reference': 'Yasin, 60', 'surah': 36, 'ayah': 60, 'arabic': 'x', 'meal': 'y', 'confidence': 0.7},
      ],
    });
    expect(r.range!.isSingle, isTrue);
  });

  test('bilinmeyen status güvenle error olur; eksik alanlar bozmaz', () {
    final r = AyahFinderResult.fromJson({'status': 'wat'});
    expect(r.status, AyahFinderStatus.error);
    expect(r.matches, isEmpty);
    expect(r.range, isNull);
    expect(r.timeline, isEmpty);
  });

  test('startLabel dakikayı doğru biçimler', () {
    final e = AyahTimelineEntry.fromJson({
      'startSec': 125, // 2:05
      'endSec': 130,
      'surah': 2,
      'ayah': 255,
      'reference': 'Bakara, 255',
      'confidence': 1,
    });
    expect(e.startLabel, '02:05');
  });
}
