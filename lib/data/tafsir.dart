import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi (QuranEnc.com,
/// `turkish_mokhtasar`) — uygulamayla paketli `assets/quran/tafsir_muhtasar_tr.json`.
///
/// Metin DEĞİŞTİRİLMEZ (yeniden yayın koşulu); gösterilen her yerde
/// [sourceLine] ile kaynak anılır. Üretim: `dart run tool/fetch_tafsir.dart`.
class Tafsir {
  const Tafsir({
    required this.byAyah,
    required this.title,
    required this.source,
    required this.fetched,
  });

  factory Tafsir.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map;
    return Tafsir(
      byAyah: (json['tafsir'] as Map).cast<String, String>(),
      title: meta['title'] as String,
      source: meta['source'] as String,
      fetched: meta['fetched'] as String,
    );
  }

  /// "sure:ayet" → tefsir metni.
  final Map<String, String> byAyah;
  final String title;
  final String source;

  /// API'de sürüm numarası yok; verinin çekildiği gün (YYYY-AA-GG).
  final String fetched;

  String? of(int surah, int ayah) => byAyah['$surah:$ayah'];

  String get sourceLine => 'Kaynak: $title — $source';
}

/// Asset okunamaz/çözülemezse hata loglanır ve yeniden fırlatılır; tüketiciler
/// (AyahNote) hatada tefsir bölümünü çizmez, uygulama çökmez.
final tafsirProvider = FutureProvider<Tafsir>(
  (ref) async {
    try {
      final raw = await rootBundle.loadString('assets/quran/tafsir_muhtasar_tr.json');
      return Tafsir.fromJson(await Isolate.run(() => jsonDecode(raw) as Map<String, dynamic>));
    } catch (e, st) {
      debugPrint('Muhtasar tefsir yüklenemedi: $e\n$st');
      rethrow;
    }
  },
  // Paketli varlık: yeniden denemek hatayı düzeltmez, yalnız log/zamanlayıcı biriktirir.
  retry: (_, _) => null,
);
