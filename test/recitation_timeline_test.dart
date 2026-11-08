import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/domain/quran_matcher.dart';
import 'package:kurandakimesaj/domain/recitation_timeline.dart';

/// Videodan Meal (cihaz yolu): tanıyıcı bölümleri -> ayet aralığı + zaman
/// çizelgesi. GERÇEK paketli Kur'an'a karşı; Fatiha ve Kürsî bölüm metinleri
/// emülatördeki Google tanıyıcısının gerçek çıktısıdır (bkz. şartname).
void main() {
  late QuranMatcher matcher;
  const names = {1: 'Fâtiha', 2: 'Bakara', 36: 'Yâsîn'};

  setUpAll(() {
    matcher = QuranMatcher.fromJson(
      File('assets/quran/quran_full.json').readAsStringSync(),
    );
  });

  /// Bölümleri ardışık zamanlara yerleştirir (kelime başına 0,6 sn, arada 0,4 sn).
  List<SpeechSegment> segs(List<String> texts) {
    var t = 0.0;
    final out = <SpeechSegment>[];
    for (final text in texts) {
      final end = t + 0.6 * text.split(' ').length;
      out.add((start: t, end: end, text: text));
      t = end + 0.4;
    }
    return out;
  }

  void expectMonotone(List<AyahTimelineEntry> timeline) {
    for (var i = 0; i < timeline.length; i++) {
      expect(timeline[i].endSec, greaterThan(timeline[i].startSec));
      if (i > 0) {
        expect(timeline[i].startSec, greaterThanOrEqualTo(timeline[i - 1].endSec));
      }
    }
  }

  const fatiha = ['الحمد لله رب العالمين', 'الرحمن الرحيم', 'مالك يوم الدين'];

  test('Fatiha 2-4 -> matched, aralık 1:2-4, zaman çizelgesi monoton', () {
    final r = analyzeRecitation(segs(fatiha), matcher, names);
    expect(r.status, AyahFinderStatus.matched);
    expect(r.range?.surah, 1);
    expect(r.range?.fromAyah, 2);
    expect(r.range?.toAyah, 4);
    expect(r.range?.reference, 'Fâtiha, 2-4');
    expect([for (final m in r.matches) m.ayah], [2, 3, 4]);
    expect(r.matches.every((m) => m.arabic.isNotEmpty && m.meal.isNotEmpty), isTrue);
    expect([for (final t in r.timeline) t.ayah], [2, 3, 4]);
    expect(r.timeline.first.reference, 'Fâtiha, 2');
    expectMonotone(r.timeline);
    expect(r.extractedArabic, fatiha.join(' '));
  });

  test('besmele + Fatiha 2-4 -> besmele 1:1 olarak geri eklenir', () {
    final r = analyzeRecitation(
      segs(['بسم الله الرحمن الرحيم', ...fatiha]),
      matcher,
      names,
    );
    expect(r.status, AyahFinderStatus.matched);
    expect(r.range?.fromAyah, 1);
    expect(r.range?.toAyah, 4);
    expect([for (final t in r.timeline) t.ayah], [1, 2, 3, 4]);
    expectMonotone(r.timeline);
  });

  test("Âyetü'l-Kürsî 7 bölümü -> 2:255, tek kesintisiz çizelge girdisi", () {
    final s = segs([
      'الله لا اله الا هو الحي القيوم',
      'لا تاخذه سنه ولا نوم',
      'له ما في السماوات وما في الارض',
      'من ذا الذي يشفع عنده الا باذنه',
      'يعلم ما بين ايديهم وما خلفهم ولا يحيطون بشيء من علمه الا بما شاء',
      'وسع كرسيه السماوات والارض ولا يؤوده حفظهما',
      'وهو العلي العظيم',
    ]);
    final r = analyzeRecitation(s, matcher, names);
    expect(r.status, AyahFinderStatus.matched);
    expect(r.range?.surah, 2);
    expect(r.range?.fromAyah, 255);
    expect(r.range?.toAyah, 255);
    expect(r.range?.reference, 'Bakara, 255');
    expect([for (final m in r.matches) '${m.surah}:${m.ayah}'], ['2:255']);
    // Aynı ayete düşen ardışık bölümler birleşir: altyazı ilk bölümde bitmez.
    expect(r.timeline, hasLength(1));
    expect(r.timeline.single.startSec, s.first.start);
    expect(r.timeline.single.endSec, s.last.end);
  });

  test('istiaze + besmele + Yâsîn 58-61 -> 36:58-61 (istiaze düşer)', () {
    final r = analyzeRecitation(
      segs([
        'اعوذ بالله من الشيطان الرجيم',
        'بسم الله الرحمن الرحيم',
        'سلام قولا من رب رحيم',
        'وامتازوا اليوم ايها المجرمون',
        'الم اعهد اليكم يا بني ادم ان لا تعبدوا الشيطان انه لكم عدو مبين',
        'وان اعبدوني هذا صراط مستقيم',
      ]),
      matcher,
      names,
    );
    expect(r.status, AyahFinderStatus.matched);
    expect(r.range?.surah, 36);
    expect(r.range?.fromAyah, 58);
    expect(r.range?.toAyah, 61);
    expect(r.range?.reference, 'Yâsîn, 58-61');
    expect([for (final m in r.matches) m.ayah], [58, 59, 60, 61]);
    expect([for (final t in r.timeline) t.ayah], [58, 59, 60, 61]);
    expectMonotone(r.timeline);
    // İstiaze ve besmele zamanı çizelgeye girmez: ilk girdi 3. bölümde başlar.
    expect(r.timeline.first.startSec, greaterThan(5));
  });

  test('boş liste ve yalnız boş metinler -> notFound', () {
    expect(analyzeRecitation(const [], matcher, names).status, AyahFinderStatus.notFound);
    expect(
      analyzeRecitation(const [(start: 0, end: 1, text: '  ')], matcher, names).status,
      AyahFinderStatus.notFound,
    );
  });

  test('alakasız Arapça -> notFound ya da ambiguous, asla matched değil', () {
    final r = analyzeRecitation(
      segs([
        'ذهبت الى السوق واشتريت الخبز والحليب',
        'الطقس جميل جدا اليوم في المدينة',
        'شكرا لكم على المشاهدة',
      ]),
      matcher,
      names,
    );
    expect(r.status, anyOf(AyahFinderStatus.notFound, AyahFinderStatus.ambiguous));
    expect(r.range, isNull);
    expect(r.timeline, isEmpty);
  });

  test('sure adı bilinmiyorsa "Sure N" kullanılır', () {
    final r = analyzeRecitation(segs(fatiha), matcher, const {});
    expect(r.range?.reference, 'Sure 1, 2-4');
  });

  group('wordsToSegments (iOS kelime → bölüm)', () {
    SpeechSegment w(double s, double e, String t) => (start: s, end: e, text: t);

    test('boş liste boş döner', () {
      expect(wordsToSegments(const []), isEmpty);
    });

    test('duraklamasız kelimeler tek bölüm', () {
      final r = wordsToSegments([w(0.7, 1.2, 'الحمد'), w(1.3, 1.8, 'لله'), w(1.9, 2.4, 'رب')]);
      expect(r, hasLength(1));
      expect(r.single.text, 'الحمد لله رب');
      expect(r.single.start, 0.7);
      expect(r.single.end, 2.4);
    });

    test('0,6 sn üstü boşluk yeni bölüm açar', () {
      final r = wordsToSegments([
        w(0.7, 5.5, 'العالمين'),
        w(6.4, 7.0, 'الرحمن'),
        w(7.1, 10.0, 'الرحيم'),
      ]);
      expect(r.map((s) => s.text), ['العالمين', 'الرحمن الرحيم']);
      expect(r[1].start, 6.4);
    });

    test('iOS kelimeleri uçtan uca: Fatiha 2-4 → aralık 1:2-4', () {
      final words = [
        for (final (i, t) in 'الحمد لله رب العالمين'.split(' ').indexed) w(0.7 + i, 1.5 + i, t),
        for (final (i, t) in 'الرحمن الرحيم'.split(' ').indexed) w(6.4 + i, 7.2 + i, t),
        for (final (i, t) in 'مالك يوم الدين'.split(' ').indexed) w(10.9 + i, 11.7 + i, t),
      ];
      final r = analyzeRecitation(wordsToSegments(words), matcher, const {1: 'Fâtiha'});
      expect(r.status, AyahFinderStatus.matched);
      expect(r.range!.surah, 1);
      expect(r.range!.fromAyah, 2);
      expect(r.range!.toAyah, 4);
      expect(r.timeline.first.startSec, closeTo(0.7, 0.01));
    });

    test('kelime yoksa notFound', () {
      expect(analyzeRecitation(wordsToSegments(const []), matcher, const {}).status,
          AyahFinderStatus.notFound);
    });
  });
}
