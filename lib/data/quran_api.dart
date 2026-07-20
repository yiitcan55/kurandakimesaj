import 'package:dio/dio.dart';

/// API'den dönen tek bir ayet: (sure içi numara, Arapça metin, meal).
typedef RemoteAyah = ({int numberInSurah, String arabic, String meal});

/// Kur'an metni uzak veri kaynağı sözleşmesi — test edilebilirlik seam'i.
/// ContentRepository bu tipi alır; testte fake enjekte edilebilir.
abstract interface class IQuranApi {
  /// [surahNumber] (1..114) için Arapça (Osmanlı resm-i hattı) + Diyanet
  /// mealini birlikte çeker. Ağ hatasında [DioException]/Exception fırlatır.
  Future<List<RemoteAyah>> fetchSurah(int surahNumber);
}

/// AlQuran Cloud (https://alquran.cloud) tabanlı Kur'an metni istemcisi.
///
/// Tek istekte iki "edition" birden alınır:
///   - `quran-uthmani`  → Osmanlı resm-i hattıyla Arapça metin
///   - `tr.diyanet`     → Diyanet İşleri Başkanlığı Türkçe meali (onaylı kaynak)
///
/// Çevrimdışı öncelikli mimaride bu istemci yalnızca DB cache'i eksik olduğunda
/// devreye girer; çekilen ayetler Drift'e yazılıp bir daha indirilmez.
class QuranApi implements IQuranApi {
  QuranApi(this._dio);

  final Dio _dio;

  static const _base = 'https://api.alquran.cloud/v1';
  static const _arabicEdition = 'quran-uthmani';
  static const _mealEdition = 'tr.diyanet';

  @override
  Future<List<RemoteAyah>> fetchSurah(int surahNumber) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/surah/$surahNumber/editions/$_arabicEdition,$_mealEdition',
    );

    final body = res.data;
    final editions = body?['data'];
    if (editions is! List || editions.length < 2) {
      throw const FormatException('Beklenmeyen Kur\'an API yanıtı.');
    }

    // editions[0] = Arapça, editions[1] = meal (sorgudaki sıraya göre).
    final arabicAyahs = _ayahList(editions[0]);
    final mealAyahs = _ayahList(editions[1]);

    // numberInSurah → metin eşlemesi (paralel indeks yerine güvenli eşleme).
    final mealByNumber = <int, String>{
      for (final a in mealAyahs) a.$1: a.$2,
    };

    return [
      for (final a in arabicAyahs)
        (
          numberInSurah: a.$1,
          arabic: a.$2,
          meal: mealByNumber[a.$1] ?? '',
        ),
    ];
  }

  /// Bir edition map'inden (numberInSurah, text) çiftlerini çıkarır.
  List<(int, String)> _ayahList(Object? edition) {
    final ayahs = (edition is Map ? edition['ayahs'] : null);
    if (ayahs is! List) return const [];
    return [
      for (final a in ayahs)
        if (a is Map)
          (
            (a['numberInSurah'] as num?)?.toInt() ?? 0,
            (a['text'] as String?) ?? '',
          ),
    ];
  }
}
