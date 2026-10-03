import 'story_seed_a.dart';
import 'story_seed_b.dart';

/// (sıra, başlık, kategori, dakika, özet, gövde) — peygamber kıssaları.
/// 25 peygamber × 2-4 bölüm; iki dosyada yazılır, burada birleşir.
const List<(int, String, String, int, String, String)> kStorySeed = [
  ...kStorySeedA,
  ...kStorySeedB,
];
