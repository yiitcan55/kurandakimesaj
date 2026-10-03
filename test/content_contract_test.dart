import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/seed/seed_data.dart';

/// İçerik sözleşmesi: seed verisindeki her ayet atfı, Arapça metin ve meal
/// paketli Kur'an verisiyle (`assets/quran/quran_full.json`, Diyanet meali)
/// KODLA doğrulanır; imla ve tekrar kontrolleri otomatiktir. Hedef hacimler de
/// burada kilitlidir (sürüm 1.0.x içerik genişletmesi).

String _fold(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase()
    .replaceAll(RegExp(r"[âÂ]"), 'a')
    .replaceAll(RegExp(r"[îÎ]"), 'i')
    .replaceAll(RegExp(r"[ûÛ]"), 'u')
    .replaceAll(RegExp(r"[\s'’‘`´\-]"), '');

/// Harekeleri, Kur'an işaretlerini ve alef/ya biçimlerini eşitle.
String _arabic(String s) => s
    .replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ࣓-ࣿ]'), '')
    .replaceAll(RegExp('[ٱآأإ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _ws(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

class _Quran {
  _Quran(List<dynamic> raw) {
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      byKey[(m['s'] as int, m['a'] as int)] = (m['ar'] as String, m['meal'] as String);
    }
  }
  final byKey = <(int, int), (String, String)>{};
}

late _Quran _quran;
final surahNo = <String, int>{};
final ayahCount = <int, int>{};

/// "Bakara, 153" / "Bakara, 285-286" → (sure, ilk, son); çözülemezse null.
(int, int, int)? parseRef(String ref) {
  final m = RegExp(r'^\s*(.+?)\s*,\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*$').firstMatch(ref);
  if (m == null) return null;
  final s = surahNo[_fold(m.group(1)!)];
  if (s == null) return null;
  final a = int.parse(m.group(2)!);
  final b = m.group(3) == null ? a : int.parse(m.group(3)!);
  return (s, a, b);
}

/// Aralığın Arapça ve meal metni; aralık Kur'an'da yoksa null.
(String, String)? ayahText((int, int, int) r) {
  final ar = <String>[];
  final meal = <String>[];
  for (var a = r.$2; a <= r.$3; a++) {
    final t = _quran.byKey[(r.$1, a)];
    if (t == null) return null;
    ar.add(t.$1);
    meal.add(t.$2);
  }
  return (_arabic(ar.join(' ')), _ws(meal.join(' ')));
}

/// ASCII'ye düşmüş yaygın Türkçe kelimeler (gerçek kelimeyle karışmayanlar).
final _asciiFallback = RegExp(
  r'\b(icin|cunku|gunes|guzel|soyle|yagmur|dusunmek|ogrenmek|ogretmek|'
  r'sukur|sabir|gunah|gorev|dusunce|insanlar?in|iman etmis|kuran|Kuran|'
  r'allah\x27in|peygamberimiz\s+hz)\b',
);

void _checkText(String where, String text, List<String> errors) {
  if (text.trim().isEmpty) errors.add('$where: boş alan');
  if (text.contains('  ')) errors.add('$where: çift boşluk');
  if (text != text.trim()) errors.add('$where: baş/son boşluk');
  if (_asciiFallback.hasMatch(text)) {
    errors.add('$where: ASCII\'ye düşmüş Türkçe olabilir → '
        '${_asciiFallback.firstMatch(text)!.group(0)}');
  }
  if (text.contains('Kur\'an\'ı Kerim') || text.contains('Kuran-ı')) {
    errors.add('$where: "Kur\'ân-ı Kerîm"/"Kur\'an" yazımı tutarsız');
  }
}

void main() {
  setUpAll(() {
    final raw = jsonDecode(File('assets/quran/quran_full.json').readAsStringSync());
    _quran = _Quran(raw as List<dynamic>);
    for (final s in kSurahSeed) {
      surahNo[_fold(s.$2)] = s.$1;
      ayahCount[s.$1] = s.$5;
    }
  });

  test('Kur\'an verisi ve sure tablosu tutarlı (6236 ayet, 114 sure)', () {
    expect(_quran.byKey.length, 6236);
    expect(kSurahSeed.length, 114);
    for (final e in ayahCount.entries) {
      expect(_quran.byKey.containsKey((e.key, e.value)), isTrue, reason: 'sure ${e.key}');
    }
  });

  test('Konuya göre ayet: atıf çözülür, Arapça ve meal Kur\'an verisiyle aynı', () {
    final errors = <String>[];
    final seen = <String>{};
    for (final t in kTopicalSeed) {
      final (topic, ref, ar, meal) = t;
      final where = 'konu "$topic" / $ref';
      if (!seen.add('$topic|$ref')) errors.add('$where: tekrar');
      final r = parseRef(ref);
      final txt = r == null ? null : ayahText(r);
      if (txt == null) {
        errors.add('$where: atıf çözülemedi veya ayet yok');
        continue;
      }
      if (!txt.$1.contains(_arabic(ar))) errors.add('$where: Arapça Kur\'an metniyle eşleşmiyor');
      if (!txt.$2.contains(_ws(meal))) errors.add('$where: meal Diyanet meali değil (birebir alınmalı)');
      _checkText(where, meal, errors);
    }
    expect(errors, isEmpty, reason: '\n${errors.join('\n')}');
  });

  test('Konuya göre ayet: her konuda en az 4 ayet', () {
    final perTopic = <String, int>{};
    for (final t in kTopicalSeed) {
      perTopic[t.$1] = (perTopic[t.$1] ?? 0) + 1;
    }
    expect(perTopic.length, greaterThanOrEqualTo(7));
    final thin = perTopic.entries.where((e) => e.value < 4).map((e) => '${e.key}=${e.value}');
    expect(thin, isEmpty, reason: 'yetersiz konular: ${thin.join(', ')}');
  });

  test('Dua: Kur\'an kaynaklı dualar ayetle doğrulanır; her dua kaynaklı', () {
    final errors = <String>[];
    final seen = <String>{};
    for (final d in kDuaSeed) {
      final (title, cat, ar, latin, body, source) = d;
      final where = 'dua "$title"';
      if (!seen.add(_fold(title))) errors.add('$where: başlık tekrarı');
      if (source.trim().isEmpty) errors.add('$where: kaynak yok');
      if (ar.trim().isEmpty) errors.add('$where: Arapça yok');
      if (latin.trim().isEmpty) errors.add('$where: okunuş yok');
      for (final f in [title, cat, latin, body, source]) {
        _checkText(where, f, errors);
      }
      // "Bakara, 201" gibi sure atfı: Arapça ayetin içinde geçmeli.
      final r = parseRef(source);
      if (r != null) {
        final txt = ayahText(r);
        if (txt == null) {
          errors.add('$where: ayet yok ($source)');
        } else if (!txt.$1.contains(_arabic(ar))) {
          errors.add('$where: Arapça $source ile eşleşmiyor');
        }
      }
    }
    expect(errors, isEmpty, reason: '\n${errors.join('\n')}');
  });

  test('Kıssa, mucize, tecvid, rüya: imla, boş alan ve tekrar', () {
    final errors = <String>[];
    void dupes(String name, Iterable<String> keys) {
      final seen = <String>{};
      for (final k in keys) {
        if (!seen.add(_fold(k))) errors.add('$name: tekrar "$k"');
      }
    }

    dupes('kıssa', kStorySeed.map((e) => e.$2));
    dupes('mucize', kMiracleSeed.map((e) => e.$2));
    dupes('tecvid', kTajweedSeed.map((e) => e.$2));
    dupes('rüya', kDreamSeed.map((e) => e.$1));
    for (final s in kStorySeed) {
      for (final f in [s.$2, s.$3, s.$5, s.$6]) {
        _checkText('kıssa "${s.$2}"', f, errors);
      }
    }
    for (final m in kMiracleSeed) {
      for (final f in [m.$1, m.$2, m.$3]) {
        _checkText('mucize "${m.$2}"', f, errors);
      }
    }
    for (final t in kTajweedSeed) {
      for (final f in [t.$2, t.$3, t.$5]) {
        _checkText('tecvid "${t.$2}"', f, errors);
      }
      if (t.$4.trim().isEmpty) errors.add('tecvid "${t.$2}": örnek yok');
    }
    for (final d in kDreamSeed) {
      for (final f in [d.$1, d.$2, d.$3, d.$4]) {
        _checkText('rüya "${d.$1}"', f, errors);
      }
    }
    expect(errors, isEmpty, reason: '\n${errors.join('\n')}');
  });

  test('Kıssalar: Kur\'an\'da adı geçen 25 peygamberin hepsi, her birine en az 2 kıssa', () {
    const prophets = [
      'Âdem', 'İdrîs', 'Nûh', 'Hûd', 'Sâlih', 'İbrâhîm', 'Lût', 'İsmâîl', 'İshâk',
      'Yâkub', 'Yûsuf', 'Eyyûb', 'Şuayb', 'Mûsâ', 'Hârûn', 'Zülkifl', 'Dâvûd',
      'Süleyman', 'İlyâs', 'Elyesâ', 'Yûnus', 'Zekeriyyâ', 'Yahyâ', 'Îsâ', 'Muhammed',
    ];
    final titles = kStorySeed.map((e) => _fold(e.$2)).toList();
    final missing = <String>[];
    for (final p in prophets) {
      final key = _fold(p).replaceAll('â', 'a');
      final n = titles.where((t) => t.contains(key.substring(0, key.length > 4 ? 4 : key.length))).length;
      if (n < 2) missing.add('$p ($n)');
    }
    expect(missing, isEmpty, reason: 'eksik/yetersiz: ${missing.join(', ')}');
  });

  test('Hacim hedefleri (orta): dua≥38, mucize≥40, tecvid≥18, rüya≥140', () {
    expect(kDuaSeed.length, greaterThanOrEqualTo(38), reason: 'dua');
    expect(kMiracleSeed.length, greaterThanOrEqualTo(40), reason: 'mucize');
    expect(kTajweedSeed.length, greaterThanOrEqualTo(18), reason: 'tecvid');
    expect(kDreamSeed.length, greaterThanOrEqualTo(140), reason: 'rüya');
  });
}
