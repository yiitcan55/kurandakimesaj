import 'package:drift/drift.dart';

import 'backend_repositories.dart';
import 'local/app_database.dart';
import 'quran_api.dart';

/// Salt-okunur dini içerik sözleşmesi — test edilebilirlik seam'i.
/// Çağrı yerlerinde kullanılan tüm public metotları bildirir; provider bu tipi
/// döndürdüğü için call site'lar değişmeden fake enjekte edilebilir.
abstract interface class IContentRepository {
  Future<List<EsmaName>> esma();
  Future<List<Dua>> duas();
  Future<List<String>> duaCategories();
  Future<List<Surah>> surahs();
  Future<Surah?> surah(int number);
  Future<List<Ayah>> ayahsForSurah(int surahNumber);
  Future<Ayah?> ayahOfDay(DateTime day);
  Future<List<String>> topics();
  Future<List<TopicalAyah>> topicalByTopic(String topic);
  Future<List<Story>> stories();
  Future<List<Miracle>> miracles();
  Future<List<String>> miracleCategories();
  Future<List<TajweedLesson>> tajweed();
  Future<List<DreamSymbol>> searchDreams(String query);
}

/// Salt-okunur dini içerik erişimi (seed'lenmiş tablolar üzerinden).
/// Tüm sorgular drift'e gider — çevrimdışı çalışır.
class ContentRepository implements IContentRepository {
  ContentRepository(this._db, this._api);

  final AppDatabase _db;
  final IQuranApi _api;

  // ── Esma ──
  @override
  Future<List<EsmaName>> esma() =>
      (_db.select(_db.esmaNames)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();

  // ── Dua ──
  @override
  Future<List<Dua>> duas() => _db.select(_db.duas).get();
  @override
  Future<List<String>> duaCategories() async {
    final all = await duas();
    final set = <String>{for (final d in all) d.category};
    return set.toList();
  }

  // ── Sure / Ayet ──
  @override
  Future<List<Surah>> surahs() =>
      (_db.select(_db.surahs)..orderBy([(t) => OrderingTerm(expression: t.number)])).get();
  @override
  Future<Surah?> surah(int number) =>
      (_db.select(_db.surahs)..where((t) => t.number.equals(number))).getSingleOrNull();
  Future<List<Ayah>> _selectAyahs(int surahNumber) =>
      (_db.select(_db.ayahs)
            ..where((t) => t.surahNumber.equals(surahNumber))
            ..orderBy([(t) => OrderingTerm(expression: t.numberInSurah)]))
          .get();

  /// Bir surenin ayetleri. Çevrimdışı öncelikli: önce yerel cache (seed veya
  /// önceki indirme) okunur. Cache surenin tam ayet sayısını içermiyorsa metin
  /// API'den çekilip Drift'e yazılır ve bir daha indirilmez. Ağ hatasında eldeki
  /// (kısmi de olsa) cache döndürülür — uygulama çevrimdışı çökmez.
  @override
  Future<List<Ayah>> ayahsForSurah(int surahNumber) async {
    final cached = await _selectAyahs(surahNumber);
    final expected = (await surah(surahNumber))?.ayahCount ?? 0;
    if (expected > 0 && cached.length >= expected) return cached;

    try {
      final remote = await _api.fetchSurah(surahNumber);
      if (remote.isNotEmpty) {
        await _cacheAyahs(surahNumber, remote);
        return _selectAyahs(surahNumber);
      }
    } catch (_) {
      // Ağ yok / API hatası. Elde (kısmi de olsa) cache varsa onu döndür
      // (çevrimdışı dostu). Hiç cache yoksa hatayı yukarı ilet — yoksa ekran
      // yanıltıcı "bu sürümde paketlenmedi" mesajı gösterir; oysa sorun ağ.
      if (cached.isEmpty) rethrow;
    }
    return cached;
  }

  /// Bir sureye ait ayetleri atomik olarak değiştirir: eski (kısmi seed)
  /// satırları silinir, indirilen tam set yazılır → tekrar/eksik kalmaz.
  Future<void> _cacheAyahs(int surahNumber, List<RemoteAyah> ayahs) =>
      _db.transaction(() async {
        await (_db.delete(_db.ayahs)
              ..where((t) => t.surahNumber.equals(surahNumber)))
            .go();
        await _db.batch((b) {
          b.insertAll(_db.ayahs, [
            for (final a in ayahs)
              AyahsCompanion.insert(
                surahNumber: surahNumber,
                numberInSurah: a.numberInSurah,
                arabic: a.arabic,
                meal: a.meal,
              ),
          ]);
        });
      });

  /// Günün ayeti — gün sırasına göre deterministik seçim (her gün aynı ayet).
  @override
  Future<Ayah?> ayahOfDay(DateTime day) async {
    final all = await _db.select(_db.ayahs).get();
    if (all.isEmpty) return null;
    final index = (day.year * 1000 + day.month * 50 + day.day) % all.length;
    return all[index];
  }

  // ── Konuya göre ──
  @override
  Future<List<String>> topics() async {
    final all = await _db.select(_db.topicalAyahs).get();
    return <String>{for (final t in all) t.topic}.toList();
  }

  @override
  Future<List<TopicalAyah>> topicalByTopic(String topic) =>
      (_db.select(_db.topicalAyahs)..where((t) => t.topic.equals(topic))).get();

  // ── Kıssalar ──
  @override
  Future<List<Story>> stories() =>
      (_db.select(_db.stories)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();

  // ── Mucizeler ──
  @override
  Future<List<Miracle>> miracles() => _db.select(_db.miracles).get();
  @override
  Future<List<String>> miracleCategories() async {
    final all = await miracles();
    return <String>{for (final m in all) m.category}.toList();
  }

  // ── Tecvid ──
  @override
  Future<List<TajweedLesson>> tajweed() =>
      (_db.select(_db.tajweedLessons)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();

  // ── Rüya sözlüğü ──
  @override
  Future<List<DreamSymbol>> searchDreams(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _db.select(_db.dreamSymbols).get();
    return (_db.select(_db.dreamSymbols)
          ..where((t) => t.term.lower().contains(q)))
        .get();
  }
}

/// Zikir sayaçları — günlük, çevrimdışı öncelikli.
class DhikrRepository {
  DhikrRepository(this._db);
  final AppDatabase _db;

  Future<int> count(String key, String dateIso) async {
    final row = await (_db.select(_db.dhikrCounters)
          ..where((t) => t.dhikrKey.equals(key) & t.dateIso.equals(dateIso)))
        .getSingleOrNull();
    return row?.count ?? 0;
  }

  Future<void> setCount(String key, String dateIso, int value) async {
    final existing = await (_db.select(_db.dhikrCounters)
          ..where((t) => t.dhikrKey.equals(key) & t.dateIso.equals(dateIso)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.dhikrCounters).insert(
            DhikrCountersCompanion.insert(
              dateIso: dateIso,
              dhikrKey: key,
              count: Value(value),
            ),
          );
    } else {
      await (_db.update(_db.dhikrCounters)..where((t) => t.id.equals(existing.id)))
          .write(DhikrCountersCompanion(count: Value(value)));
    }
  }

  /// Bir günün tüm zikir toplamı (canlı).
  Stream<int> watchDayTotal(String dateIso) {
    final query = _db.select(_db.dhikrCounters)
      ..where((t) => t.dateIso.equals(dateIso));
    return query.watch().map((rows) => rows.fold<int>(0, (s, r) => s + r.count));
  }
}

/// Kullanıcının kaydettiği ayetler (Koleksiyonlar).
class CollectionsRepository {
  CollectionsRepository(this._db, [this._sync]);
  final AppDatabase _db;
  final SyncRepository? _sync; // null-safe: sync yoksa sadece yerel

  Stream<List<Collection>> watch() =>
      (_db.select(_db.collections)..orderBy([(t) => OrderingTerm.desc(t.id)])).watch();

  Future<void> add({
    required String reference,
    required String arabic,
    required String meal,
    String? note,
  }) async {
    await _db.into(_db.collections).insert(
          CollectionsCompanion.insert(
            reference: reference,
            arabic: arabic,
            meal: meal,
            note: Value(note),
            createdIso: DateTime.now().toIso8601String(),
          ),
        );
    // Bulut senkronu — hata yutulur, offline çalışmayı engellemez.
    _sync
        ?.pushCollection(reference: reference, arabic: arabic, meal: meal, note: note)
        .catchError((_) {});
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.collections)..where((t) => t.id.equals(id))).go();
}

/// Sure ezber takibi.
class MemorizationRepository {
  MemorizationRepository(this._db);
  final AppDatabase _db;

  Stream<List<Memorization>> watch() =>
      (_db.select(_db.memorizations)
            ..orderBy([(t) => OrderingTerm(expression: t.surahNumber)]))
          .watch();

  Future<void> setMemorized(int id, int memorized) =>
      (_db.update(_db.memorizations)..where((t) => t.id.equals(id))).write(
        MemorizationsCompanion(
          memorizedAyahs: Value(memorized),
          lastReviewIso: Value(DateTime.now().toIso8601String()),
        ),
      );
}

/// 30 cüz okuma ilerlemesi.
class JuzRepository {
  JuzRepository(this._db);
  final AppDatabase _db;

  Stream<List<JuzProgressData>> watch() =>
      (_db.select(_db.juzProgress)
            ..orderBy([(t) => OrderingTerm(expression: t.juzNumber)]))
          .watch();

  Future<void> setCompleted(int juz, bool completed) =>
      (_db.update(_db.juzProgress)..where((t) => t.juzNumber.equals(juz))).write(
        JuzProgressCompanion(
          completed: Value(completed),
          updatedIso: Value(DateTime.now().toIso8601String()),
        ),
      );
}
