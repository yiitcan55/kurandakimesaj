import 'models.dart';

/// Bir videoya yazılabilecek en fazla altyazı (cue) sayısı — sunucudaki
/// `is_valid_meal_cues` sınırıyla aynı.
const int kMealCueMax = 60;

/// Reels'te altyazının çizilme biçimi. `db` kolon değeridir (`meal_cue_style`).
enum MealCueStyle {
  standard('default', 'Varsayılan'),
  large('large', 'Büyük'),
  arabic('arabic', 'Arapça + Meal');

  const MealCueStyle(this.db, this.label);
  final String db;
  final String label;

  /// Bilinmeyen/boş değer [standard]'a düşer — eski ya da bozuk satır akışı düşürmez.
  static MealCueStyle fromDb(String? v) =>
      values.firstWhere((s) => s.db == v, orElse: () => standard);
}

/// Bir ayetin videodaki gösterim aralığı. Meal metni TAŞINMAZ; ekranlar
/// `(surah, ayah)` ile yerel otoriter veriden çözer.
class MealCue {
  const MealCue({
    required this.startSec,
    required this.endSec,
    required this.surah,
    required this.ayah,
    this.approx = false,
  });

  final double startSec;
  final double endSec;
  final int surah;
  final int ayah;

  /// Zamanlama sesten değil, ağırlıkla tahmin edildi. Sunucuya yazılmaz.
  final bool approx;

  static double _r2(double v) => (v * 100).round() / 100;

  /// Yalnız s,e,su,a — sunucudaki CHECK tam bu dört anahtarı ister.
  Map<String, Object> toJson() => {
    's': _r2(startSec),
    'e': _r2(endSec),
    'su': surah,
    'a': ayah,
  };

  /// Girdi liste değilse ya da herhangi bir öğe bozuksa `[]`; asla fırlatmaz.
  static List<MealCue> listFromJson(Object? j) {
    if (j is! List) return const [];
    final out = <MealCue>[];
    for (final m in j) {
      if (m is! Map) return const [];
      final s = m['s'], e = m['e'], su = m['su'], a = m['a'];
      if (s is! num || e is! num || su is! int || a is! int) return const [];
      if (su < 1 || su > 114 || a < 1 || a > 286 || e <= s) return const [];
      out.add(
        MealCue(
          startSec: s.toDouble(),
          endSec: e.toDouble(),
          surah: su,
          ayah: a,
        ),
      );
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is MealCue &&
      other.startSec == startSec &&
      other.endSec == endSec &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.approx == approx;

  @override
  int get hashCode => Object.hash(startSec, endSec, surah, ayah, approx);
}

/// `weight` = Arapça metin uzunluğu (çapasız ayetlerin süre payı).
typedef CueAyah = ({int surah, int ayah, int weight});

/// [ayahs] sıralı aralıktır. Ayet başına ilk geçerli çapa alınır; çıktı ayet
/// sırasına göre zaman-monotondur (geri dönen çapa → çapasız). Çapasız ayetler
/// komşu çapalar arasına weight ile orantılı dağılır ve `approx` olur.
List<MealCue> buildCues({
  required List<CueAyah> ayahs,
  List<AyahTimelineEntry> timeline = const [],
  required double durationSec,
}) {
  final n = ayahs.length;
  if (n == 0) return const [];

  final first = <(int, int), AyahTimelineEntry>{};
  for (final t in timeline) {
    if (t.startSec >= 0 && t.endSec > t.startSec) {
      first.putIfAbsent((t.surah, t.ayah), () => t);
    }
  }
  // Monotonlaştırma: önceki çapanın başlangıcından büyük olmayan çapa düşer.
  final a = List<AyahTimelineEntry?>.filled(n, null);
  var lastStart = -1.0;
  for (var i = 0; i < n; i++) {
    final e = first[(ayahs[i].surah, ayahs[i].ayah)];
    if (e != null && e.startSec > lastStart) {
      a[i] = e;
      lastStart = e.startSec;
    }
  }

  var dur = durationSec;
  if (dur <= 0) {
    final last = a.whereType<AyahTimelineEntry>().lastOrNull;
    if (last == null) return const [];
    dur = last.endSec;
  }
  for (var i = 0; i < n; i++) {
    if (a[i] != null && a[i]!.startSec >= dur) a[i] = null;
  }
  // Baştaki çapasız ayetlere 0'dan yer kalması için 0'da başlayan çapa düşer.
  final f = a.indexWhere((e) => e != null);
  if (f > 0 && a[f]!.startSec <= 0) a[f] = null;

  final starts = List<double>.filled(n, 0);
  final approx = List<bool>.filled(n, false);
  for (var i = 0; i < n;) {
    final anchor = a[i];
    if (anchor != null) {
      starts[i++] = anchor.startSec;
      continue;
    }
    var j = i;
    while (j < n && a[j] == null) {
      j++;
    }
    // [i, j) çapasız koşu; i > 0 ise a[i - 1] çapalıdır.
    final hi = j < n ? a[j]!.startSec : dur;
    final prev = i > 0 ? a[i - 1] : null;
    final lo = prev == null
        ? 0.0
        : (prev.endSec < hi ? prev.endSec : (prev.startSec + hi) / 2);
    var total = 0;
    for (var k = i; k < j; k++) {
      total += ayahs[k].weight < 1 ? 1 : ayahs[k].weight;
    }
    var acc = 0;
    for (var k = i; k < j; k++) {
      starts[k] = lo + (hi - lo) * acc / total;
      approx[k] = true;
      acc += ayahs[k].weight < 1 ? 1 : ayahs[k].weight;
    }
    i = j;
  }

  return [
    for (var k = 0; k < n; k++)
      MealCue(
        startSec: starts[k],
        endSec: k < n - 1
            ? starts[k + 1]
            : (a[k] != null && a[k]!.endSec < dur ? a[k]!.endSec : dur),
        surah: ayahs[k].surah,
        ayah: ayahs[k].ayah,
        approx: approx[k],
      ),
  ];
}

/// [sec] anında görünen cue; start dahil, end hariç.
MealCue? cueAt(List<MealCue> cues, double sec) {
  for (final c in cues) {
    if (sec >= c.startSec && sec < c.endSec) return c;
  }
  return null;
}

/// Meali kelime sınırlarından [maxChars]'ı aşmayan sayfalara böler. Kırpma yok;
/// [maxChars]'tan uzun tek kelime kendi sayfasında bütün kalır.
List<String> splitMealPages(String meal, {int maxChars = 140}) {
  final pages = <String>[];
  var cur = '';
  for (final w in meal.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    if (cur.isEmpty) {
      cur = w;
    } else if (cur.length + 1 + w.length <= maxChars) {
      cur = '$cur $w';
    } else {
      pages.add(cur);
      cur = w;
    }
  }
  if (cur.isNotEmpty) pages.add(cur);
  return pages;
}
