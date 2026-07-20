import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../local/app_database.dart';
import 'seed_data.dart';

/// İlk açılışta uygulamayla paketli statik dini içeriği drift'e yazar
/// (offline-first). İçerik kullanıcı tarafından değiştirilemez (Supabase'de
/// yazılabilir tabloda DURMAZ) — dini bütünlük tasarım gereği korunur.
class SeedService {
  SeedService(this._db);

  final AppDatabase _db;

  Future<void> seedIfNeeded() async {
    if (await _db.esmaCount() == 0) await _seedEsma();
    if (await _db.duaCount() == 0) await _seedDuas();
    if (await _db.surahCount() == 0) await _seedSurahs();
    if (await _db.ayahCount() == 0) await _seedAyahs();
    if (await _db.topicalCount() == 0) await _seedTopical();
    if (await _db.storyCount() == 0) await _seedStories();
    if (await _db.miracleCount() == 0) await _seedMiracles();
    if (await _db.tajweedCount() == 0) await _seedTajweed();
    if (await _db.dreamCount() == 0) await _seedDreams();
    if (await _db.memorizationCount() == 0) await _seedMemorizations();
    if (await _db.juzCount() == 0) await _seedJuz();
  }

  Future<void> _seedEsma() => _db.batch((b) {
        b.insertAll(_db.esmaNames, [
          for (final e in kEsmaSeed)
            EsmaNamesCompanion.insert(
              order: e.$1,
              name: e.$2,
              arabic: e.$3,
              meaning: e.$4,
            ),
        ]);
      });

  Future<void> _seedDuas() => _db.batch((b) {
        b.insertAll(_db.duas, [
          for (final d in kDuaSeed)
            DuasCompanion.insert(
              title: d.$1,
              category: d.$2,
              arabic: d.$3,
              latin: Value(d.$4),
              body: d.$5,
              source: Value(d.$6),
            ),
        ]);
      });

  Future<void> _seedSurahs() => _db.batch((b) {
        b.insertAll(_db.surahs, [
          for (final s in kSurahSeed)
            SurahsCompanion.insert(
              number: Value(s.$1),
              nameTr: s.$2,
              nameArabic: s.$3,
              meaning: s.$4,
              ayahCount: s.$5,
              revelation: s.$6,
            ),
        ]);
      });

  /// Tam Kur'an'ı (6236 ayet) uygulamayla paketli `quran_full.json` asset'inden
  /// Drift'e yazar — offline-first: tüm sureler internetsiz açılır. Asset
  /// `tool/fetch_quran.dart`'ın ürettiği AlQuran Cloud verisinden üretilir
  /// (Osmanlı hattı Arapça + Diyanet meali).
  Future<void> _seedAyahs() async {
    final raw = await rootBundle.loadString('assets/quran/quran_full.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    await _db.batch((b) {
      b.insertAll(_db.ayahs, [
        for (final a in list)
          AyahsCompanion.insert(
            surahNumber: a['s'] as int,
            numberInSurah: a['a'] as int,
            arabic: a['ar'] as String,
            meal: a['meal'] as String,
          ),
      ]);
    });
  }

  Future<void> _seedTopical() => _db.batch((b) {
        b.insertAll(_db.topicalAyahs, [
          for (final t in kTopicalSeed)
            TopicalAyahsCompanion.insert(
              topic: t.$1,
              reference: t.$2,
              arabic: t.$3,
              meal: t.$4,
            ),
        ]);
      });

  Future<void> _seedStories() => _db.batch((b) {
        b.insertAll(_db.stories, [
          for (final s in kStorySeed)
            StoriesCompanion.insert(
              order: s.$1,
              title: s.$2,
              category: s.$3,
              readMinutes: s.$4,
              summary: s.$5,
              body: s.$6,
            ),
        ]);
      });

  Future<void> _seedMiracles() => _db.batch((b) {
        b.insertAll(_db.miracles, [
          for (final m in kMiracleSeed)
            MiraclesCompanion.insert(
              category: m.$1,
              title: m.$2,
              body: m.$3,
            ),
        ]);
      });

  Future<void> _seedTajweed() => _db.batch((b) {
        b.insertAll(_db.tajweedLessons, [
          for (final t in kTajweedSeed)
            TajweedLessonsCompanion.insert(
              order: t.$1,
              title: t.$2,
              rule: t.$3,
              example: t.$4,
              body: t.$5,
            ),
        ]);
      });

  Future<void> _seedDreams() => _db.batch((b) {
        b.insertAll(_db.dreamSymbols, [
          for (final d in kDreamSeed)
            DreamSymbolsCompanion.insert(
              term: d.$1,
              category: d.$2,
              meaning: d.$3,
              source: Value(d.$4),
            ),
        ]);
      });

  Future<void> _seedMemorizations() => _db.batch((b) {
        b.insertAll(_db.memorizations, [
          for (final m in kMemorizationSeed)
            MemorizationsCompanion.insert(
              surahNumber: m.$1,
              surahName: m.$2,
              totalAyahs: m.$3,
            ),
        ]);
      });

  Future<void> _seedJuz() => _db.batch((b) {
        b.insertAll(_db.juzProgress, [
          for (var i = 1; i <= 30; i++)
            JuzProgressCompanion.insert(juzNumber: Value(i)),
        ]);
      });
}
