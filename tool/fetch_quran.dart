// Tek seferlik geliştirme aracı — uygulamaya DAHİL DEĞİL.
//
// AlQuran Cloud'dan Osmanlı hattı Arapça (`quran-uthmani`) + Diyanet meali
// (`tr.diyanet`) editionlarını çekip, ayet-bul Edge Function'ının kullandığı
// `supabase/functions/ayah-finder/quran_data.ts` dosyasını üretir.
//
// Çalıştırma:  dart run tool/fetch_quran.dart
//
// Not: 6236 ayetin tamamı sunucuda (Edge Function bundle'ında) tutulur;
// istemciye ASLA paketlenmez (uygulama boyutu + tekrar-silme maliyeti düşük).
import 'dart:convert';
import 'dart:io';

const _base = 'https://api.alquran.cloud/v1/quran';
const _out = 'supabase/functions/ayah-finder/quran_data.ts';

Future<Map<String, dynamic>> _fetchEdition(HttpClient client, String edition) async {
  final req = await client.getUrl(Uri.parse('$_base/$edition'));
  final res = await req.close();
  if (res.statusCode != 200) {
    throw 'AlQuran Cloud $edition → HTTP ${res.statusCode}';
  }
  final body = await res.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

void main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  stdout.writeln('Arapça (quran-uthmani) cekiliyor...');
  final ar = await _fetchEdition(client, 'quran-uthmani');
  stdout.writeln('Meal (tr.diyanet) cekiliyor...');
  final meal = await _fetchEdition(client, 'tr.diyanet');
  client.close();

  // Her iki edition aynı sira: surahs[].ayahs[] → numberInSurah ile eslestir.
  final arSurahs = (ar['data']['surahs'] as List).cast<Map<String, dynamic>>();
  final mealSurahs = (meal['data']['surahs'] as List).cast<Map<String, dynamic>>();

  // ayetNo (1..6236) → meal metni
  final mealByGlobal = <int, String>{};
  for (final s in mealSurahs) {
    for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
      mealByGlobal[a['number'] as int] = (a['text'] as String).trim();
    }
  }

  final buf = StringBuffer()
    ..writeln('// OTOMATIK URETILDI — elle duzenleme. Kaynak: AlQuran Cloud')
    ..writeln('// quran-uthmani (Arapca) + tr.diyanet (Diyanet meali).')
    ..writeln('// Yeniden uret:  dart run tool/fetch_quran.dart')
    ..writeln('export interface QuranAyah { s: number; a: number; ar: string; meal: string; }')
    ..writeln('export const QURAN: QuranAyah[] = [');

  var count = 0;
  for (final s in arSurahs) {
    final sNo = s['number'] as int;
    for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
      final aNo = a['numberInSurah'] as int;
      final arText = (a['text'] as String).trim();
      final mealText = mealByGlobal[a['number'] as int] ?? '';
      buf.writeln('  {s:$sNo,a:$aNo,ar:${jsonEncode(arText)},meal:${jsonEncode(mealText)}},');
      count++;
    }
  }
  buf.writeln('];');

  final file = File(_out);
  await file.parent.create(recursive: true);
  await file.writeAsString(buf.toString());
  stdout.writeln('Yazildi: $_out  ($count ayet)');
  if (count != 6236) {
    stderr.writeln('UYARI: beklenen 6236, gelen $count');
  }
}
