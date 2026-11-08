import 'dart:math' as math;

import 'models.dart';
import 'quran_matcher.dart';

/// Cihazın ses tanıyıcısından gelen bir bölüm: videodaki konum (sn) + metin.
typedef SpeechSegment = ({double start, double end, String text});

// Eşikler — `test/recitation_timeline_test.dart` gerçek korpusla sınar.
const _candidateLimit = 8; // tekrar eden ayetler için geniş aday listesi
const _minScore = 0.35;
const _dominantShare = 0.6; // baskın sure / (baskın + ikinci)
const _gapFill = 2; // atanmış ayetler arası en çok 2 ayetlik boşluk doldurulur
const _maxRange = 30; // bundan geniş aralık güvenilmez
const _matchedMean = 0.6; // atanan skorların ortalaması
const _tie = 1e-9;

// Tilavet öncesi söylenen, ayet OLMAYAN kalıplar. İstiaze `الشيطان` yüzünden
// Yâsîn 36:60'a oturup sıralı atamada 58-59'u düşürürdü.
final _istiaze = ArabicNormalizer.tokenize('أعوذ بالله من الشيطان الرجيم').toSet();
final _basmala = ArabicNormalizer.tokenize('بسم الله الرحمن الرحيم').toSet();

enum _Ritual { none, istiaze, basmala }

/// Kelimelerin tamamı istiaze/besmele kümesindeyse ritüeldir. Ayırt edici kelime
/// (`بسم` / `اعوذ`) şart: yoksa Fatiha 3 `الرحمن الرحيم` de besmele sayılırdı.
_Ritual _ritualOf(List<String> tokens) {
  if (tokens.isEmpty ||
      !tokens.every((t) => _istiaze.contains(t) || _basmala.contains(t))) {
    return _Ritual.none;
  }
  if (tokens.contains('بسم')) return _Ritual.basmala;
  if (tokens.contains('اعوذ')) return _Ritual.istiaze;
  return _Ritual.none;
}

class _Part {
  _Part(this.seg, this.tokens, this.ritual, this.hits);
  final SpeechSegment seg;
  final List<String> tokens;
  final _Ritual ritual;
  final List<QuranHit> hits;
}

typedef _Pick = ({SpeechSegment seg, QuranHit hit});

/// iOS `SFSpeechRecognizer` kelime düzeyinde zaman verir; Android bölüm verir.
/// Kelimeleri, aralarındaki boşluk [gap] saniyeyi aşınca yeni bölüme ayırır
/// (tilavetteki vakıf duraklamaları ≈ Android tanıyıcısının bölümleri).
List<SpeechSegment> wordsToSegments(List<SpeechSegment> words, {double gap = 0.6}) {
  final out = <SpeechSegment>[];
  final buf = StringBuffer();
  var start = 0.0, end = 0.0;
  for (final w in words) {
    final t = w.text.trim();
    if (t.isEmpty) continue;
    if (buf.isNotEmpty && w.start - end > gap) {
      out.add((start: start, end: end, text: buf.toString()));
      buf.clear();
    }
    if (buf.isEmpty) {
      start = w.start;
    } else {
      buf.write(' ');
    }
    buf.write(t);
    end = w.end;
  }
  if (buf.isNotEmpty) out.add((start: start, end: end, text: buf.toString()));
  return out;
}

/// Tanıyıcı bölümleri -> ayet aralığı + "hangi saniyede hangi ayet".
/// Eski sunucu `ayah-finder-audio/segments.ts`'in (Groq, 2026-11-08'de
/// kaldırıldı) fikri, cihaz eşleştiricisiyle.
/// Sure/ayet ve meal HER ZAMAN korpustan gelir; tanıyıcı yalnız metin verir.
AyahFinderResult analyzeRecitation(
  List<SpeechSegment> segments,
  QuranMatcher matcher,
  Map<int, String> surahNames,
) {
  String name(int surah) => surahNames[surah] ?? 'Sure $surah';
  final spoken = [for (final s in segments) if (s.text.trim().isNotEmpty) s];
  final fullText = [for (final s in spoken) s.text.trim()].join(' ');

  final parts = <_Part>[];
  for (final s in spoken) {
    final tokens = ArabicNormalizer.tokenize(s.text);
    final ritual = _ritualOf(tokens);
    parts.add(_Part(
      s,
      tokens,
      ritual,
      ritual == _Ritual.none
          ? matcher.match(s.text, limit: _candidateLimit, minScore: _minScore)
          : const [],
    ));
  }
  if (parts.every((p) => p.hits.isEmpty)) {
    return AyahFinderResult(status: AyahFinderStatus.notFound, extractedArabic: fullText);
  }

  AyahFinderResult ambiguous() => AyahFinderResult(
        status: AyahFinderStatus.ambiguous,
        extractedArabic: fullText,
        matches: [
          for (final h in matcher.match(fullText)) _wholeHit(matcher, h, name(h.surah)),
        ],
      );

  // ── Baskın sure: her bölümün sure başına en iyi skoru toplanır ────────────
  // Pay, ikinci sureye göre ölçülür: `الرحمن الرحيم` gibi ortak kalıplar onlarca
  // surede ~0.9 skor alır; tüm surelerin toplamı payda olsa Fatiha bile ~%16'da
  // kalırdı (gerçek korpusla ölçüldü).
  final totals = <int, double>{};
  for (final p in parts) {
    final best = <int, double>{};
    for (final h in p.hits) {
      best[h.surah] = math.max(best[h.surah] ?? 0, h.score);
    }
    best.forEach((s, v) => totals[s] = (totals[s] ?? 0) + v);
  }
  final ranked = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final dominant = ranked.first.key;
  final top = ranked.first.value;
  final second = ranked.length > 1 ? ranked[1].value : 0.0;
  if (top / (top + second) < _dominantShare) return ambiguous();

  // ── Sıralı atama: tilavet ilerledikçe ayet numarası azalmaz ─────────────
  final picks = <_Pick>[];
  var prevTo = 0;
  for (final p in parts) {
    QuranHit? pick;
    if (p.ritual == _Ritual.basmala) {
      // Besmele yalnız Fatiha'da ayettir (1:1).
      if (dominant == 1 && prevTo <= 1) {
        final words = p.tokens.where(_basmala.contains).toSet().length;
        pick = QuranHit(surah: 1, fromAyah: 1, toAyah: 1, score: words / _basmala.length);
      }
    } else {
      for (final h in p.hits) {
        if (h.surah != dominant || h.fromAyah < prevTo) continue;
        // Eşitlikte öncekine en yakın (tekrar eden ayetlerde sıradaki kopya).
        if (pick == null ||
            h.score > pick.score + _tie ||
            (h.score > pick.score - _tie && h.fromAyah < pick.fromAyah)) {
          pick = h;
        }
      }
    }
    if (pick != null) {
      picks.add((seg: p.seg, hit: pick));
      prevTo = pick.toAyah;
    }
  }
  if (picks.isEmpty) return ambiguous();

  // ── Aralık: ≤2 ayetlik boşluklar doldurulur; daha büyük boşluk kümeyi böler,
  // en yüksek skor toplamlı küme kalır (sıçrayan tek yanlış atama aralığı şişirmez).
  final clusters = <List<_Pick>>[[picks.first]];
  for (final pk in picks.skip(1)) {
    if (pk.hit.fromAyah - clusters.last.last.hit.toAyah - 1 > _gapFill) {
      clusters.add([pk]);
    } else {
      clusters.last.add(pk);
    }
  }
  double sum(List<_Pick> c) => c.fold(0.0, (a, pk) => a + pk.hit.score);
  final chosen = clusters.reduce((a, b) => sum(b) > sum(a) ? b : a);
  // Atama monoton olduğundan ilk/son seçim aralığın uçlarıdır.
  final from = chosen.first.hit.fromAyah;
  final to = chosen.last.hit.toAyah;
  if (to - from + 1 > _maxRange) return ambiguous();
  if (sum(chosen) / chosen.length < _matchedMean) return ambiguous();

  // ── Zaman çizelgesi: bölümün süresi kapsadığı ayetlere kelime sayısıyla
  // bölünür; aynı ayete düşen ardışık bölümler tek girdide birleşir.
  final timeline = <AyahTimelineEntry>[];
  for (final (:seg, :hit) in chosen) {
    final verses = matcher.versesOf(hit);
    final total = verses.fold(0, (a, v) => a + math.max(1, v.tokens.length));
    final span = math.max(0.0, seg.end - seg.start);
    var acc = 0;
    for (final v in verses) {
      final start = seg.start + span * acc / total;
      acc += math.max(1, v.tokens.length);
      final end = seg.start + span * acc / total;
      final last = timeline.isEmpty ? null : timeline.last;
      if (last != null && last.surah == v.surah && last.ayah == v.ayah) {
        timeline.last = AyahTimelineEntry(
          startSec: last.startSec,
          endSec: end,
          surah: v.surah,
          ayah: v.ayah,
          reference: last.reference,
          confidence: math.max(last.confidence, hit.score),
        );
      } else {
        timeline.add(AyahTimelineEntry(
          startSec: start,
          endSec: end,
          surah: v.surah,
          ayah: v.ayah,
          reference: '${name(v.surah)}, ${v.ayah}',
          confidence: hit.score,
        ));
      }
    }
  }

  // ── Aralıktaki HER ayet (boşluklar korpustan doldurulur) ─────────────────
  final conf = <int, double>{};
  for (final (seg: _, :hit) in chosen) {
    for (var a = hit.fromAyah; a <= hit.toAyah; a++) {
      conf[a] = math.max(conf[a] ?? 0, hit.score);
    }
  }
  final n = name(dominant);
  return AyahFinderResult(
    status: AyahFinderStatus.matched,
    extractedArabic: fullText,
    matches: [
      for (final v in matcher.versesOf(
          QuranHit(surah: dominant, fromAyah: from, toAyah: to, score: 0)))
        AyahMatch(
          reference: '$n, ${v.ayah}',
          surah: v.surah,
          ayah: v.ayah,
          arabic: v.arabic,
          meal: v.meal,
          confidence: conf[v.ayah] ?? 0,
        ),
    ],
    range: AyahRange(
      surah: dominant,
      fromAyah: from,
      toAyah: to,
      reference: from == to ? '$n, $from' : '$n, $from-$to',
    ),
    timeline: timeline,
  );
}

/// Tüm metnin eşleşmesi (ambiguous adayları) — Okuyarak Bul kartıyla aynı şekil.
AyahMatch _wholeHit(QuranMatcher matcher, QuranHit hit, String name) {
  final verses = matcher.versesOf(hit);
  return AyahMatch(
    reference: hit.fromAyah == hit.toAyah
        ? '$name, ${hit.fromAyah}'
        : '$name, ${hit.fromAyah}-${hit.toAyah}',
    surah: hit.surah,
    ayah: hit.fromAyah,
    arabic: verses.map((v) => v.arabic).join(' '),
    meal: verses.map((v) => v.meal).join(' '),
    confidence: hit.score,
  );
}
