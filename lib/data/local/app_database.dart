import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Salt-okunur dini içerik (uygulamayla paketli seed, offline-first) ────────
// Bu tablolar kullanıcı tarafından değiştirilmez; dini bütünlük tasarım gereği
// korunur (Supabase'de yazılabilir tabloda DURMAZ).

/// Esmaü'l-Hüsna — Allah'ın 99 ismi.
class EsmaNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get order => integer()();
  TextColumn get name => text()();
  TextColumn get arabic => text()();
  TextColumn get meaning => text()();
}

/// Dua kütüphanesi (sebebine göre).
class Duas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get arabic => text()();
  TextColumn get latin => text().withDefault(const Constant(''))();
  TextColumn get body => text()();
  TextColumn get source => text().withDefault(const Constant(''))();
}

/// Sure üst verisi (114 sure — referans veri).
class Surahs extends Table {
  IntColumn get number => integer()();
  TextColumn get nameTr => text()();
  TextColumn get nameArabic => text()();
  TextColumn get meaning => text()();
  IntColumn get ayahCount => integer()();
  TextColumn get revelation => text()(); // Mekki | Medeni
  IntColumn get juzStart => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {number};
}

/// Ayet metni (Arapça + meal) — küratörlü altküme (kısa/meşhur sureler).
class Ayahs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surahNumber => integer()();
  IntColumn get numberInSurah => integer()();
  TextColumn get arabic => text()();
  TextColumn get meal => text()();
  TextColumn get tafsir => text().nullable()();
}

/// Konuya/ruh haline göre ayet önerileri (Sabır, Huzur, Umut…).
class TopicalAyahs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text()();
  TextColumn get reference => text()();
  TextColumn get arabic => text()();
  TextColumn get meal => text()();
}

/// Peygamber kıssaları.
class Stories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get order => integer()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get readMinutes => integer()();
  TextColumn get summary => text()();
  TextColumn get body => text()();
}

/// Kuran mucizeleri (kategorili).
class Miracles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
}

/// Tecvid dersleri.
class TajweedLessons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get order => integer()();
  TextColumn get title => text()();
  TextColumn get rule => text()();
  TextColumn get example => text()();
  TextColumn get body => text()();
}

/// Rüya tabiri sözlüğü (klasik kaynaklara dayalı sembol araması).
class DreamSymbols extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get term => text()();
  TextColumn get category => text()();
  TextColumn get meaning => text()();
  TextColumn get source => text().withDefault(const Constant(''))();
}

// ── Kullanıcı durumu (offline-first; online iken Supabase'e senkron) ─────────

/// Zikir sayaçları — günlük (last-write-wins upsert ile senkron).
class DhikrCounters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateIso => text()(); // YYYY-MM-DD
  TextColumn get dhikrKey => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
}

/// Kullanıcının kaydettiği ayetler (Koleksiyonlar).
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reference => text()();
  TextColumn get arabic => text()();
  TextColumn get meal => text()();
  TextColumn get note => text().nullable()();
  TextColumn get createdIso => text()();
}

/// Sure ezber takibi (hıfz ilerlemesi).
class Memorizations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surahNumber => integer()();
  TextColumn get surahName => text()();
  IntColumn get totalAyahs => integer()();
  IntColumn get memorizedAyahs => integer().withDefault(const Constant(0))();
  TextColumn get lastReviewIso => text().nullable()();
}

/// 30 cüz okuma ilerlemesi.
class JuzProgress extends Table {
  IntColumn get juzNumber => integer()(); // 1..30
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get updatedIso => text().nullable()();

  @override
  Set<Column> get primaryKey => {juzNumber};
}

/// Kur'an okuma istatistikleri — her okuma seansı bir kayıt üretir.
class ReadingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surahId => integer()();
  IntColumn get ayahCount => integer()();
  IntColumn get durationSeconds => integer()();
  DateTimeColumn get readAt => dateTime()();
}

/// Favori sureler — kullanıcının yıldızladığı sureler.
class FavoriteSurahs extends Table {
  IntColumn get surahId => integer()();
  DateTimeColumn get savedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahId};
}

@DriftDatabase(
  tables: [
    EsmaNames,
    Duas,
    Surahs,
    Ayahs,
    TopicalAyahs,
    Stories,
    Miracles,
    TajweedLessons,
    DreamSymbols,
    DhikrCounters,
    Collections,
    Memorizations,
    JuzProgress,
    ReadingEvents,
    FavoriteSurahs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kuran_db'));

  @override
  int get schemaVersion => 6;

  /// Kullanıcının asla geri gelmeyen verisi — şema yükseltmede KORUNUR.
  /// (Seed dini içerikten ayrı tutulur; içerik güncellemesi ezber/koleksiyon
  /// ilerlemesini silmemeli.)
  Set<String> get _userTables => {
        dhikrCounters.actualTableName,
        collections.actualTableName,
        memorizations.actualTableName,
        juzProgress.actualTableName,
        readingEvents.actualTableName,
        favoriteSurahs.actualTableName,
      };

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Seed tabloları (dini içerik — yeniden üretilebilir) yükseltmede
        // sıfırlanıp yeniden seed edilir; KULLANICI tabloları korunur.
        // createTable IF NOT EXISTS üretir → var olan kullanıcı tablosuna
        // dokunmaz, yalnız yeni eklenen tabloları oluşturur.
        // NOT: bir kullanıcı tablosuna SÜTUN eklersen burada açık `m.addColumn`
        // ile migrate et — IF NOT EXISTS eski tabloyu olduğu gibi bırakır.
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.createTable(readingEvents);
            await m.createTable(favoriteSurahs);
          }
          // v5: AI ayet-tanıma kaldırıldı → tam Kur'an seed tablosu düşürülür.
          if (from < 5) {
            await m.deleteTable('quran_full_ayahs');
          }
          for (final table in allTables) {
            if (_userTables.contains(table.actualTableName)) {
              await m.createTable(table); // koru; yoksa oluştur
            } else {
              await m.deleteTable(table.actualTableName); // seed: sıfırla
              await m.createTable(table);
            }
          }
        },
      );

  // ── Seed gerekli mi? kontrolleri ──
  Future<int> esmaCount() async => (await select(esmaNames).get()).length;
  Future<int> duaCount() async => (await select(duas).get()).length;
  Future<int> surahCount() async => (await select(surahs).get()).length;
  Future<int> ayahCount() async => (await select(ayahs).get()).length;
  Future<int> topicalCount() async => (await select(topicalAyahs).get()).length;
  Future<int> storyCount() async => (await select(stories).get()).length;
  Future<int> miracleCount() async => (await select(miracles).get()).length;
  Future<int> tajweedCount() async =>
      (await select(tajweedLessons).get()).length;
  Future<int> dreamCount() async => (await select(dreamSymbols).get()).length;
  Future<int> memorizationCount() async =>
      (await select(memorizations).get()).length;
  Future<int> juzCount() async => (await select(juzProgress).get()).length;
}
