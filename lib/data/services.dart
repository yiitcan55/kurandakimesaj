import 'package:flutter/material.dart' show ThemeMode;
import 'package:drift/drift.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_config.dart';
import '../domain/models.dart';
import 'local/app_database.dart';

/// Günlük namaz takibi — SharedPreferences tabanlı, sıfır bağımlılık.
class PrayerTracker {
  static const _key = 'prayer_log';

  /// Bugünün tarihini "2026-06-20" formatında döndürür.
  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Bugün kılınan namazları döndürür.
  static Future<Set<String>> getTodayPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final list = prefs.getStringList('${_key}_$key') ?? [];
    return list.toSet();
  }

  /// Namaz kıldı/kılmadı toggle — yeni seti döndürür.
  static Future<Set<String>> togglePrayer(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final prefKey = '${_key}_$key';
    final list = prefs.getStringList(prefKey) ?? [];
    if (list.contains(prayer)) {
      list.remove(prayer);
    } else {
      list.add(prayer);
    }
    await prefs.setStringList(prefKey, list);
    return list.toSet();
  }

  /// Bu hafta kaç namaz kılındı (7 günlük özet, max 35).
  static Future<int> weeklyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final list = prefs.getStringList('${_key}_$key') ?? [];
      total += list.length;
    }
    return total;
  }
}

/// Günlük Kur'an okuma hedefi + streak takibi.
class ReadingGoalService {
  static const _goalKey = 'reading_goal_pages';
  static const _streakKey = 'reading_streak';
  static const _lastReadKey = 'reading_last_read_date';
  static const _todayReadKey = 'reading_today_read';

  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 2; // varsayılan: 2 sayfa/gün
  }

  static Future<void> setDailyGoal(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, pages);
  }

  static Future<int> getTodayRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayReadKey) ?? 0;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  /// Sayfa okunduğunda çağır — streak ve bugünkü sayacı günceller.
  static Future<void> markPagesRead(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastRead = prefs.getString(_lastReadKey);

    if (lastRead != todayStr) {
      // Streak hesapla
      if (lastRead != null) {
        final lastDate = DateTime.tryParse(lastRead);
        if (lastDate != null && today.difference(lastDate).inDays == 1) {
          final streak = prefs.getInt(_streakKey) ?? 0;
          await prefs.setInt(_streakKey, streak + 1);
        } else {
          await prefs.setInt(_streakKey, 1);
        }
      } else {
        await prefs.setInt(_streakKey, 1);
      }
      await prefs.setInt(_todayReadKey, pages);
      await prefs.setString(_lastReadKey, todayStr);
    } else {
      final current = prefs.getInt(_todayReadKey) ?? 0;
      await prefs.setInt(_todayReadKey, current + pages);
    }
  }
}

/// Supabase istemci sarmalayıcısı. Yalnızca anon key taşır; tüm erişim RLS'e
/// tabidir. service_role asla burada/istemcide bulunmaz (güvenlik kuralı).
///
/// Supabase başlatılmadıysa [_client] null olur; uygulama backend'siz de
/// açılabilmeli (mimari kural). Tüm erişimler null-guard'lıdır.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient? _client;

  /// Supabase yapılandırılmış ve başlatılmış mı?
  bool get isAvailable => _client != null;

  SupabaseClient? get client => _client;
  User? get currentUser => _client?.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Supabase yoksa hiçbir olay yaymayan boş akış döner (Stream.empty),
  /// böylece [authChanges]'i dinleyen StreamProvider error state'e düşmez.
  Stream<AuthState> get authChanges =>
      _client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<void> signInWithEmail(String email, String password) async {
    final c = _client;
    if (c == null) throw StateError('Supabase yapılandırılmamış.');
    await c.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final c = _client;
    if (c == null) throw StateError('Supabase yapılandırılmamış.');
    await c.auth.signUp(email: email, password: password);
  }

  /// `GoogleSignIn.instance.initialize()` süreç başına yalnızca bir kez
  /// çağrılmalı; tekrar çağrılırsa hata verir. Bu guard ile koruruz.
  bool _googleInitialized = false;

  /// Native Google girişi: yerel hesap seçici → idToken → Supabase
  /// `signInWithIdToken`. Tarayıcı açılmaz (en iyi mobil UX). Ayet adı/meal
  /// gibi yetkili veriler değil, yalnızca kimlik akışıdır.
  ///
  /// Kullanıcı seçiciyi kapatırsa `GoogleSignInException` (code: canceled)
  /// fırlar; çağıran taraf bunu sessizce yutmalıdır.
  Future<void> signInWithGoogle() async {
    final c = _client;
    if (c == null) throw StateError('Supabase yapılandırılmamış.');
    if (AppConfig.googleWebClientId.isEmpty) {
      throw StateError(
        'Google girişi yapılandırılmamış (GOOGLE_WEB_CLIENT_ID eksik).',
      );
    }

    final googleSignIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await googleSignIn.initialize(
        serverClientId: AppConfig.googleWebClientId,
        clientId: AppConfig.googleIosClientId.isEmpty
            ? null
            : AppConfig.googleIosClientId,
      );
      _googleInitialized = true;
    }

    final googleUser = await googleSignIn.authenticate();

    const scopes = <String>['email', 'profile'];
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google kimlik anahtarı (ID token) alınamadı.');
    }

    await c.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
    if (_googleInitialized) {
      // Google oturumunu da kapat ki sonraki girişte hesap yeniden seçilebilsin.
      await GoogleSignIn.instance.signOut();
    }
  }

  /// Hesabı kalıcı siler. `delete-account` Edge Function'ı `service_role` ile
  /// auth user'ı siler; cascade FK'ler (profiles/messages/follows…) tüm
  /// kullanıcı verisini otomatik temizler. Ardından yerel oturum kapatılır.
  /// Not: `service_role` ASLA istemcide değil — silme sunucuda yapılır.
  Future<void> deleteAccount() async {
    final c = _client;
    if (c == null) throw StateError('Supabase yapılandırılmamış.');
    final res = await c.functions.invoke('delete-account');
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    await signOut();
  }
}

/// shared_preferences sarmalayıcısı — AppSettings kalıcılığı.
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboarding = 'onboarding_complete';
  static const _kMeal = 'meal_option';
  static const _kInterests = 'interests';
  static const _kNotif = 'notifications_granted';
  static const _kThemeMode = 'theme_mode';

  AppSettings load() {
    final mealName = _prefs.getString(_kMeal);
    final interestNames = _prefs.getStringList(_kInterests) ?? const [];
    final themeName = _prefs.getString(_kThemeMode);
    return AppSettings(
      onboardingComplete: _prefs.getBool(_kOnboarding) ?? false,
      mealOption: MealOption.values.firstWhere(
        (m) => m.name == mealName,
        orElse: () => MealOption.diyanet,
      ),
      interests: interestNames
          .map((n) => AppInterest.values.where((i) => i.name == n))
          .expand((e) => e)
          .toSet(),
      notificationsGranted: _prefs.getBool(_kNotif) ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setBool(_kOnboarding, s.onboardingComplete);
    await _prefs.setString(_kMeal, s.mealOption.name);
    await _prefs.setStringList(
      _kInterests,
      s.interests.map((i) => i.name).toList(),
    );
    await _prefs.setBool(_kNotif, s.notificationsGranted);
    await _prefs.setString(_kThemeMode, s.themeMode.name);
  }
}

/// Cihaz izinleri — bildirim (ezan/ayet/kandil) ve ileride konum.
class PermissionService {
  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}

/// Gram altın ve gümüş fiyatlarını SharedPreferences'e kaydeder ve yükler.
///
/// Ücretsiz ve güvenilir bir gerçek zamanlı altın fiyatı API'si olmadığından
/// kullanıcı fiyatı manuel girer; son girilen değer 24 saat geçerlilikte cache'lenir.
class GoldPriceService {
  static const String _goldPriceKey = 'gold_price_gram_tl';
  static const String _goldDateKey = 'gold_price_date';
  static const String _silverPriceKey = 'silver_price_gram_tl';
  static const String _silverDateKey = 'silver_price_date';

  static const double defaultGoldPrice = 4000.0;
  static const double defaultSilverPrice = 45.0;

  /// Son 24 saat içinde kaydedilen gram altın fiyatını (TL) döndürür.
  /// Kayıt yoksa veya süresi dolmuşsa null döner.
  Future<double?> getCachedGoldPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_goldDateKey);
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null && DateTime.now().difference(date).inHours < 24) {
        return prefs.getDouble(_goldPriceKey);
      }
    }
    return null;
  }

  /// Gram altın fiyatını (TL) kaydeder.
  Future<void> saveGoldPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goldPriceKey, price);
    await prefs.setString(_goldDateKey, DateTime.now().toIso8601String());
  }

  /// Son 24 saat içinde kaydedilen gram gümüş fiyatını (TL) döndürür.
  Future<double?> getCachedSilverPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_silverDateKey);
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null && DateTime.now().difference(date).inHours < 24) {
        return prefs.getDouble(_silverPriceKey);
      }
    }
    return null;
  }

  /// Gram gümüş fiyatını (TL) kaydeder.
  Future<void> saveSilverPrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_silverPriceKey, price);
    await prefs.setString(_silverDateKey, DateTime.now().toIso8601String());
  }
}

class StatsService {
  final AppDatabase _db;
  StatsService(this._db);

  Future<void> recordReading({
    required int surahId,
    required int ayahCount,
    required int durationSeconds,
  }) async {
    if (durationSeconds < 10) return; // 10 saniyeden az → kaydetme
    await _db.into(_db.readingEvents).insert(
      ReadingEventsCompanion.insert(
        surahId: surahId,
        ayahCount: ayahCount,
        durationSeconds: durationSeconds,
        readAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, int>> getLifetimeStats() async {
    final events = await _db.select(_db.readingEvents).get();
    return {
      'surahCount': events.map((e) => e.surahId).toSet().length,
      'ayahCount': events.fold(0, (s, e) => s + e.ayahCount),
      'minutes': events.fold(0, (s, e) => s + e.durationSeconds) ~/ 60,
    };
  }

  // Son 7 günün günlük ayet sayıları [Bugün-6, Bugün-5, ..., Bugün]
  Future<List<int>> getWeeklyAyahCounts() async {
    final now = DateTime.now();
    final result = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));
      final events = await (_db.select(_db.readingEvents)
        ..where((t) => t.readAt.isBiggerOrEqualValue(day) &
                       t.readAt.isSmallerThanValue(nextDay)))
        .get();
      result.add(events.fold(0, (s, e) => s + e.ayahCount));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopSurahs({int limit = 3}) async {
    final events = await _db.select(_db.readingEvents).get();
    final counts = <int, int>{};
    for (final e in events) {
      counts[e.surahId] = (counts[e.surahId] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => {'surahId': e.key, 'count': e.value}).toList();
  }
}

/// Favori sureler — kullanıcının yıldızladığı sureleri takip eder.
class FavoritesService {
  final AppDatabase _db;
  FavoritesService(this._db);

  Stream<bool> watchIsFavorite(int surahId) {
    return (_db.select(_db.favoriteSurahs)
      ..where((t) => t.surahId.equals(surahId)))
      .watchSingleOrNull()
      .map((row) => row != null);
  }

  Future<void> toggleFavorite(int surahId) async {
    final existing = await (_db.select(_db.favoriteSurahs)
      ..where((t) => t.surahId.equals(surahId)))
      .getSingleOrNull();

    if (existing != null) {
      await (_db.delete(_db.favoriteSurahs)
        ..where((t) => t.surahId.equals(surahId)))
        .go();
    } else {
      await _db.into(_db.favoriteSurahs).insert(
        FavoriteSurahsCompanion.insert(surahId: Value(surahId)),
      );
    }
  }

  Stream<List<int>> watchFavoriteIds() {
    return _db.select(_db.favoriteSurahs).watch().map(
      (rows) => rows.map((r) => r.surahId).toList(),
    );
  }
}

/// Türkçe metin okuma servisi — flutter_tts sarmalayıcısı.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  Future<void> init() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = false);
  }

  Future<void> speak(String text) async {
    if (_speaking) await stop();
    _speaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }

  bool get isSpeaking => _speaking;
}
