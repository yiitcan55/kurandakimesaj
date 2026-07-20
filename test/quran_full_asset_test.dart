import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `assets/quran/quran_full.json` offline seed kaynağıdır — Kur'an Okuma ekranı
/// internetsiz çalışsın diye 6236 ayetin tamamı uygulamayla paketlenir. Bu test
/// asset'in bütünlüğünü korur: ayet/sure adetleri ve şekil bozulursa kırılır.
void main() {
  test('quran_full.json tam Kur\'an verisini içerir (6236 ayet / 114 sure)', () {
    final file = File('assets/quran/quran_full.json');
    expect(file.existsSync(), isTrue,
        reason: 'asset eksik — `dart run tool/fetch_quran.dart` + üretici çalıştır');

    final list = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    expect(list.length, 6236, reason: 'Kur\'an 6236 ayettir');

    // Sure başına ayet sayıları (örnek doğrulama — bilinen referans değerler).
    final perSurah = <int, int>{};
    for (final a in list) {
      perSurah.update(a['s'] as int, (v) => v + 1, ifAbsent: () => 1);
    }
    expect(perSurah.length, 114, reason: '114 sure olmalı');
    expect(perSurah[1], 7); // Fâtiha
    expect(perSurah[2], 286); // Bakara
    expect(perSurah[36], 83); // Yâsîn
    expect(perSurah[112], 4); // İhlâs
    expect(perSurah[114], 6); // Nâs

    // Şekil: her kayıtta dolu Arapça + meal (boş ayet seed'i okuma ekranını bozar).
    final first = list.first;
    expect(first['s'], 1);
    expect(first['a'], 1);
    expect((first['ar'] as String).isNotEmpty, isTrue);
    expect((first['meal'] as String).isNotEmpty, isTrue);
    expect(list.every((a) => (a['ar'] as String).trim().isNotEmpty), isTrue);
    expect(list.every((a) => (a['meal'] as String).trim().isNotEmpty), isTrue);
  });
}
