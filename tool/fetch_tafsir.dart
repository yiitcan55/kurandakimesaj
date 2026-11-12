// Tek seferlik geliştirme aracı — uygulamaya DAHİL DEĞİL.
//
// QuranEnc.com'dan "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi"ni
// (`turkish_mokhtasar`) çekip `assets/quran/tafsir_muhtasar_tr.json` üretir.
//
// Çalıştırma:  dart run tool/fetch_tafsir.dart
//
// Yeniden yayın koşulu: metin DEĞİŞTİRİLMEZ, eklenmez, silinmez. Bu yüzden
// `translation` ve `footnotes` olduğu gibi yazılır (trim bile yok). 6236 ayet
// gelmezse betik hata verir. Sürüm numarası API'de yok; `fetched` tarihi tutulur.
import 'dart:convert';
import 'dart:io';

const _key = 'turkish_mokhtasar';
const _base = 'https://quranenc.com/api/v1/translation/sura/$_key';
const _out = 'assets/quran/tafsir_muhtasar_tr.json';
const _title = "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi";

Future<List<Map<String, dynamic>>> _fetchSura(HttpClient client, int sura) async {
  Object? last;
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final req = await client.getUrl(Uri.parse('$_base/$sura'));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      return ((jsonDecode(body) as Map)['result'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      last = e;
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw 'QuranEnc sure $sura → $last';
}

Future<void> main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  final tafsir = <String, String>{};
  final footnotes = <String, String>{};

  for (var s = 1; s <= 114; s++) {
    final ayahs = await _fetchSura(client, s);
    for (final (i, a) in ayahs.indexed) {
      final no = int.parse(a['aya'] as String);
      if (int.parse(a['sura'] as String) != s || no != i + 1) {
        throw 'Sıra bozuk: sure $s, kayıt ${a['sura']}:${a['aya']}';
      }
      final text = a['translation'] as String?;
      if (text == null || text.trim().isEmpty) throw 'Boş tefsir: $s:$no';
      tafsir['$s:$no'] = text; // AYNEN — trim yok.
      final fn = a['footnotes'];
      if (fn != null && (fn as String).isNotEmpty) footnotes['$s:$no'] = fn;
    }
    stdout.writeln('sure $s: ${ayahs.length} ayet');
    await Future<void>.delayed(const Duration(milliseconds: 400)); // sunucuyu yorma
  }
  client.close();

  if (tafsir.length != 6236) {
    throw 'Beklenen 6236 ayet, gelen ${tafsir.length}';
  }

  final now = DateTime.now();
  final fetched =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final json = <String, Object>{
    'meta': {'title': _title, 'source': 'QuranEnc.com', 'key': _key, 'fetched': fetched},
    'tafsir': tafsir,
    if (footnotes.isNotEmpty) 'footnotes': footnotes,
  };
  final file = File(_out);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
  stdout.writeln('Yazıldı: $_out  (${tafsir.length} ayet, ${footnotes.length} dipnot, '
      '${file.lengthSync()} bayt)');
}
