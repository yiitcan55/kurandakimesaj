import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/domain/quran_matcher.dart';

/// Okuyarak Bul eşleştiricisi — GERÇEK paketli Kur'an'a (6236 ayet, uthmani)
/// karşı, cihaz ses tanıyıcısının ürettiği biçimde (harekesiz, MODERN imla)
/// sorgularla sınanır. Sahte korpus bu uyumsuzluğu göstermezdi.
void main() {
  late QuranMatcher matcher;

  setUpAll(() {
    matcher = QuranMatcher.fromJson(
      File('assets/quran/quran_full.json').readAsStringSync(),
    );
  });

  List<String> labels(List<QuranHit> hits) => [for (final h in hits) h.label];

  group('ArabicNormalizer', () {
    test('harekeli uthmani metni harekesiz kelimelere indirir', () {
      expect(
        ArabicNormalizer.normalize('ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
        'الحمد لله رب العلمين',
      );
    });

    test('uthmani ٱلصَّلَوٰةَ ile modern الصلاة aynı kelimeye iner', () {
      expect(ArabicNormalizer.normalize('ٱلصَّلَوٰةَ'), 'الصلاه');
      expect(ArabicNormalizer.normalize('الصلاة'), 'الصلاه');
      expect(ArabicNormalizer.normalize('وَٱلزَّكَوٰةَ'), 'والزكاه');
    });

    test('hemze biçimleri, ى/ي ve Arapça olmayan karakterler', () {
      expect(ArabicNormalizer.normalize('ٱلْقُرْءَانَ'), 'القران');
      expect(ArabicNormalizer.normalize('القرآن'), 'القران');
      expect(ArabicNormalizer.tokenize('الحمد، lillah 123 لله'), ['الحمد', 'لله']);
      expect(ArabicNormalizer.tokenize('  ۞  '), isEmpty);
    });
  });

  group('QuranMatcher (gerçek korpus, modern imla sorgu)', () {
    test('tam ayet: الحمد لله رب العالمين -> 1:2', () {
      final hits = matcher.match('الحمد لله رب العالمين');
      expect(hits.first.label, '1:2');
      expect(hits.first.score, greaterThan(0.8));
    });

    test('tam ayet: مالك يوم الدين -> 1:4 (مالك/ملك uthmani farkı)', () {
      expect(matcher.match('مالك يوم الدين').first.label, '1:4');
    });

    test('kısmi okuma: Ayetü\'l-Kürsi\'nin ortası -> 2:255', () {
      final hits = matcher.match(
        'له ما في السماوات وما في الأرض من ذا الذي يشفع عنده إلا بإذنه',
      );
      expect(hits.first.label, '2:255');
    });

    test('Ayetü\'l-Kürsi\'nin ilk kelimeleri 3:2 ile ortaktır; 2:255 yine de listede', () {
      // "الله لا إله إلا هو الحي القيوم" 3:2'nin TAMAMIDIR; ilk sıra 3:2 olabilir.
      final hits = matcher.match('الله لا إله إلا هو الحي');
      expect(labels(hits).take(3), contains('2:255'));
    });

    test('eksik kelimeli okuma (وآتوا الزكاة atlanmış) -> 2:43', () {
      expect(
        matcher.match('وأقيموا الصلاة واركعوا مع الراكعين').first.label,
        '2:43',
      );
    });

    test('iki ayete taşan okuma (1:4 sonu + 1:5 başı) -> aralık 1:4-5', () {
      final hits = matcher.match('مالك يوم الدين إياك نعبد');
      expect(hits.first.label, '1:4-5');
      expect(hits.first.fromAyah, 4);
      expect(hits.first.toAyah, 5);
    });

    // Emülatörde Husarî Fatiha 2-4: tanıyıcı bölümleri birikince 3 ayetlik
    // okuma geldi; yalnız 2 ayetlik aralık denendiği için "1:2-3" %65 çıktı.
    test('üç ayete yayılan okuma -> aralık 1:2-4', () {
      final hits = matcher.match('الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين');
      expect(hits.first.label, '1:2-4');
      expect(hits.first.score, greaterThan(0.85));
    });

    test('tek ayet okuması geniş aralığa kaymaz', () {
      expect(matcher.match('الرحمن الرحيم مالك يوم الدين').first.label, '1:3-4');
      expect(matcher.match('مالك يوم الدين').first.label, '1:4');
    });

    test('1-2 harf hatalı tanıma doğru ayeti bulur', () {
      expect(matcher.match('الحمد لله رب العالمن').first.label, '1:2');
      expect(
        matcher.match('وأقيموا الصلاه وآتوا الزكاه واركعوا مع الراكعن').first.label,
        '2:43',
      );
    });

    test('الصلاة içeren ayet: وأقيموا الصلاة وآتوا الزكاة واركعوا مع الراكعين -> 2:43', () {
      final hits = matcher.match('وأقيموا الصلاة وآتوا الزكاة واركعوا مع الراكعين');
      expect(hits.first.label, '2:43');
      expect(hits.first.score, greaterThan(0.9));
    });

    test('alternatif tahmin isabeti kurtarır', () {
      final hits = matcher.match(
        'ذهبت إلى السوق',
        alternates: const ['الحمد لله رب العالمين'],
      );
      expect(hits.first.label, '1:2');
    });

    test('alakasız Arapça cümle: sonuç yok ya da düşük skor', () {
      final hits = matcher.match('ذهبت إلى السوق لشراء الخبز والحليب');
      expect(hits.isEmpty || hits.first.score < 0.5, isTrue, reason: '$hits');
    });

    test('Arapça olmayan / boş metin sonuç vermez', () {
      expect(matcher.match(''), isEmpty);
      expect(matcher.match('hello world 123'), isEmpty);
    });

    test('versesOf: aralık sırayla Arapça + meal döndürür', () {
      final hit = matcher.match('مالك يوم الدين إياك نعبد').first;
      final verses = matcher.versesOf(hit);
      expect(verses.map((v) => '${v.surah}:${v.ayah}'), ['1:4', '1:5']);
      expect(verses.every((v) => v.arabic.isNotEmpty && v.meal.isNotEmpty), isTrue);
    });
  });
}
