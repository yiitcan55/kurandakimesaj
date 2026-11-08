import 'dart:convert';
import 'dart:math' as math;

/// Arapça metni karşılaştırılabilir forma indirir.
///
/// Korpus uthmani hattında (harekeli, Kur'an işaretli); cihazın ses tanıyıcısı
/// ise harekesiz MODERN imla üretir. İki taraf da aynı kurallarla sadeleşir.
/// Aynı kurallar sunucudaki `supabase/functions/_shared/quran/matcher.ts`
/// ile uyumludur.
class ArabicNormalizer {
  ArabicNormalizer._();

  // Harekeler, tenvin, şedde, sükun, hançerli elif, Kur'an durak/işaretleri, tatweel.
  static final RegExp _marks =
      RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static final RegExp _alefVariants = RegExp('[آأإٱ]');
  // Temel Arap harfleri (ء .. ي) dışındaki her şey boşluğa çevrilir.
  static final RegExp _nonArabic = RegExp('[^ء-ي\\s]');
  static final RegExp _spaces = RegExp(r'\s+');

  // Uthmani ↔ modern imla farkı: `ٱلصَّلَوٰة` harekesiz `الصلوه` olur, modern
  // `الصلاة` ise `الصلاه`. Alt-dizgi kuralı önek/ek almış biçimleri de kapsar.
  static const Map<String, String> _uthmaniVariants = {
    'صلوه': 'صلاه',
    'زكوه': 'زكاه',
    'حيوه': 'حياه',
    'مشكوه': 'مشكاه',
    'منوه': 'مناه',
    'الربوا': 'الربا',
  };

  static String normalize(String input) {
    var s = input
        .replaceAll(_marks, '')
        .replaceAll(_alefVariants, 'ا') // أ إ آ ٱ -> ا
        .replaceAll('ى', 'ي') // ى -> ي
        .replaceAll('ة', 'ه') // ة -> ه
        .replaceAll('ؤ', 'و') // ؤ -> و
        .replaceAll('ئ', 'ي') // ئ -> ي
        .replaceAll('ء', '') // tek başına hemze atılır
        .replaceAll(_nonArabic, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
    _uthmaniVariants.forEach((from, to) => s = s.replaceAll(from, to));
    return s;
  }

  static List<String> tokenize(String input) {
    final n = normalize(input);
    return n.isEmpty ? const [] : n.split(' ');
  }
}

/// Kur'an'daki tek bir ayet (gösterim metni + eşleştirme kelimeleri).
class QuranVerse {
  QuranVerse({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.meal,
  }) : tokens = ArabicNormalizer.tokenize(arabic);

  final int surah;
  final int ayah;
  final String arabic;
  final String meal;

  /// Normalize edilmiş kelimeler (eşleştirme için).
  final List<String> tokens;
}

/// Bir eşleşme sonucu. Okuma iki ayete taşıyorsa fromAyah != toAyah olur.
class QuranHit {
  const QuranHit({
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.score,
  });

  final int surah;
  final int fromAyah;
  final int toAyah;

  /// 0..1 arası güven skoru.
  final double score;

  String get label =>
      fromAyah == toAyah ? '$surah:$fromAyah' : '$surah:$fromAyah-$toAyah';

  @override
  String toString() => 'QuranHit($label, ${score.toStringAsFixed(2)})';
}

/// Tanınan Arapça metni Kur'an ayetleriyle eşleştirir. Yapay zekâ yok:
/// ters indeks + IDF + bulanık (Levenshtein) kelime eşleşmesi + kelime sırasına
/// duyarlı hizalama (ağırlıklı LCS) + komşu ayetle birleşik aralık.
class QuranMatcher {
  QuranMatcher(List<QuranVerse> verses) : _verses = verses {
    _buildIndex();
  }

  /// Asset şekli: `[{"s":1,"a":1,"ar":"...","meal":"..."}]`.
  factory QuranMatcher.fromJson(String rawJson) {
    final list = jsonDecode(rawJson) as List;
    return QuranMatcher([
      for (final e in list.cast<Map<String, dynamic>>())
        QuranVerse(
          surah: e['s'] as int,
          ayah: e['a'] as int,
          arabic: e['ar'] as String,
          meal: e['meal'] as String,
        ),
    ]);
  }

  final List<QuranVerse> _verses;

  /// sure*1000+ayet -> _verses indeksi
  final Map<int, int> _position = {};

  /// kelime -> bu kelimenin geçtiği ayetlerin indeksleri
  final Map<String, List<int>> _index = {};

  /// kelime -> IDF ağırlığı (nadir kelime = daha ayırt edici)
  final Map<String, double> _idf = {};

  /// uzunluk -> o uzunluktaki kelimeler (bulanık arama için)
  final Map<int, List<String>> _vocabByLength = {};

  final Map<String, List<_Similar>> _similarCache = {};

  int get verseCount => _verses.length;

  void _buildIndex() {
    for (var i = 0; i < _verses.length; i++) {
      _position[_verses[i].surah * 1000 + _verses[i].ayah] = i;
      for (final t in _verses[i].tokens.toSet()) {
        (_index[t] ??= []).add(i);
      }
    }
    final n = _verses.length.toDouble();
    _index.forEach((word, list) {
      _idf[word] = math.log(n / list.length) + 1.0;
      (_vocabByLength[word.length] ??= []).add(word);
    });
  }

  /// [hit]'in kapsadığı ayetler (sırayla). Gösterim için Arapça/meal buradan.
  List<QuranVerse> versesOf(QuranHit hit) => [
        for (var a = hit.fromAyah; a <= hit.toAyah; a++)
          if (_position[hit.surah * 1000 + a] case final i?) _verses[i],
      ];

  /// [recognized]: ses tanıyıcıdan gelen metin.
  /// [alternates]: tanıyıcının diğer tahminleri (varsa) — isabeti artırır.
  List<QuranHit> match(
    String recognized, {
    List<String> alternates = const [],
    int limit = 5,
    double minScore = 0.35,
  }) {
    final best = <String, QuranHit>{};
    for (final text in {recognized, ...alternates}) {
      for (final m in _matchSingle(text, limit: limit * 2)) {
        final prev = best[m.label];
        if (prev == null || m.score > prev.score) best[m.label] = m;
      }
    }
    final sorted = best.values.where((m) => m.score >= minScore).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // "1:2" en iyiyse "1:2-3" gibi çakışan varyasyonları listeye koyma.
    final results = <QuranHit>[];
    for (final m in sorted) {
      final overlaps = results.any((r) =>
          r.surah == m.surah &&
          r.fromAyah <= m.toAyah &&
          m.fromAyah <= r.toAyah);
      if (!overlaps) results.add(m);
      if (results.length == limit) break;
    }
    return results;
  }

  List<QuranHit> _matchSingle(String text, {required int limit}) {
    final query = ArabicNormalizer.tokenize(text);
    if (query.isEmpty) return const [];

    // 1) Aday üretimi: her sorgu kelimesine benzeyen kelimelerin geçtiği ayetler.
    final candidateScore = <int, double>{};
    final queryWeights = <double>[];
    for (final q in query) {
      final similars = _similarWords(q);
      queryWeights.add(similars.isEmpty
          ? _unknownWordWeight
          : similars.map((s) => _idf[s.word]! * s.sim).reduce(math.max));
      final seen = <int>{};
      for (final s in similars) {
        final w = _idf[s.word]! * s.sim;
        for (final idx in _index[s.word]!) {
          if (seen.add(idx)) {
            candidateScore[idx] = (candidateScore[idx] ?? 0) + w;
          }
        }
      }
    }
    if (candidateScore.isEmpty) return const [];

    final candidates = candidateScore.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = candidates.take(60).map((e) => e.key);
    final totalWeight = queryWeights.fold<double>(0, (a, b) => a + b);

    // 2) Yeniden sıralama: kelime sırasına duyarlı hizalama. Okuma ayet
    // sınırını aşmış olabileceği için komşu ayetle birleşik hali de denenir.
    final dedup = <String, QuranHit>{};
    for (final i in top) {
      QuranHit? bestHere;
      for (final span in _spansAround(i, query.length)) {
        final m = _scoreSpan(query, queryWeights, totalWeight, span);
        if (bestHere == null || m.score > bestHere.score) bestHere = m;
      }
      final prev = dedup[bestHere!.label];
      if (prev == null || bestHere.score > prev.score) {
        dedup[bestHere.label] = bestHere;
      }
    }
    final out = dedup.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return out.take(limit).toList();
  }

  double get _unknownWordWeight => math.log(_verses.length.toDouble()) * 0.5;

  /// [i]'yi içeren ardışık ayet aralıkları (aynı surede). Komşu ayet her
  /// zaman denenir; daha geniş aralık yalnız toplam kelime sayısı sorgunun
  /// 1,5 katını aşmıyorsa (en çok [_maxSpan] ayet) — kısa okumada maliyet ve
  /// davranış değişmez, birkaç ayetlik okuma tam aralık olarak döner.
  Iterable<List<int>> _spansAround(int i, int queryLen) sync* {
    final s = _verses[i].surah;
    bool inSurah(int k) => k >= 0 && k < _verses.length && _verses[k].surah == s;
    final budget = queryLen * 3 ~/ 2;
    var prefix = 0; // [a, i) aralığının kelime sayısı
    for (var a = i; a > i - _maxSpan && inSurah(a); a--) {
      if (a < i) prefix += _verses[a].tokens.length;
      var len = prefix;
      for (var b = i; b - a < _maxSpan && inSurah(b); b++) {
        len += _verses[b].tokens.length;
        if (b - a >= 2 && len > budget) break;
        yield [for (var k = a; k <= b; k++) k];
      }
      if (i - a >= 1 && prefix + _verses[i].tokens.length > budget) break;
    }
  }

  static const _maxSpan = 8;

  QuranHit _scoreSpan(
    List<String> query,
    List<double> weights,
    double totalWeight,
    List<int> span,
  ) {
    final target = <String>[for (final i in span) ..._verses[i].tokens];
    final m = query.length, n = target.length;

    // Ağırlıklı LCS: kelimeler aynı sırada ve benzer olmalı.
    var prev = List<double>.filled(n + 1, 0);
    var prevCount = List<int>.filled(n + 1, 0);
    for (var a = 1; a <= m; a++) {
      final cur = List<double>.filled(n + 1, 0);
      final curCount = List<int>.filled(n + 1, 0);
      for (var b = 1; b <= n; b++) {
        var v = prev[b];
        var c = prevCount[b];
        if (cur[b - 1] > v) {
          v = cur[b - 1];
          c = curCount[b - 1];
        }
        final sim = _wordSim(query[a - 1], target[b - 1]);
        if (sim > 0) {
          final d = prev[b - 1] + sim * weights[a - 1];
          if (d > v) {
            v = d;
            c = prevCount[b - 1] + 1;
          }
        }
        cur[b] = v;
        curCount[b] = c;
      }
      prev = cur;
      prevCount = curCount;
    }

    final coverage = totalWeight == 0 ? 0.0 : prev[n] / totalWeight;
    final completeness = n == 0 ? 0.0 : prevCount[n] / n;
    // Kapsama (okunanın ne kadarı ayette var) esas; tamlık eşitlikleri bozar.
    // Birleşik aralık hafifçe cezalandırılır ki gereksiz yere seçilmesin.
    var score = 0.85 * coverage + 0.15 * completeness;
    if (span.length > 1) score -= 0.03;

    return QuranHit(
      surah: _verses[span.first].surah,
      fromAyah: _verses[span.first].ayah,
      toAyah: _verses[span.last].ayah,
      score: score.clamp(0.0, 1.0),
    );
  }

  /// Sorgu kelimesine Kur'an sözlüğünde benzeyen kelimeler.
  List<_Similar> _similarWords(String q) {
    final cached = _similarCache[q];
    if (cached != null) return cached;
    final maxDist = _maxDistance(q.length);
    final out = <_Similar>[];
    for (var len = q.length - maxDist; len <= q.length + maxDist; len++) {
      for (final w in _vocabByLength[len] ?? const <String>[]) {
        final d = _levenshtein(q, w, maxDist);
        if (d <= maxDist) out.add(_Similar(w, _simOf(d)));
      }
    }
    if (_similarCache.length > 5000) _similarCache.clear();
    return _similarCache[q] = out;
  }

  /// Sorgu kelimesi [q] ile ayet kelimesi [t] arasındaki benzerlik. Tolerans
  /// SORGU kelimesinin uzunluğundan alınır (aday aşamasıyla aynı): kısa
  /// ayet kelimesi `ملك`, sorgudaki `مالك` ile eşleşebilsin.
  double _wordSim(String q, String t) {
    if (q == t) return 1.0;
    final maxDist = _maxDistance(q.length);
    if ((q.length - t.length).abs() > maxDist) return 0;
    final d = _levenshtein(q, t, maxDist);
    return d <= maxDist ? _simOf(d) : 0;
  }

  static double _simOf(int distance) =>
      distance == 0 ? 1.0 : 0.7 - 0.1 * (distance - 1);

  static int _maxDistance(int len) => len <= 3 ? 0 : (len <= 6 ? 1 : 2);

  /// Sınırlı Levenshtein: mesafe [max]'ı aşınca erken çıkar.
  static int _levenshtein(String a, String b, int max) {
    if (a == b) return 0;
    if ((a.length - b.length).abs() > max) return max + 1;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(
            math.min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost);
        if (cur[j] < rowMin) rowMin = cur[j];
      }
      if (rowMin > max) return max + 1;
      prev = cur;
    }
    return prev[b.length];
  }
}

class _Similar {
  _Similar(this.word, this.sim);
  final String word;
  final double sim;
}
