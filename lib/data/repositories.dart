import 'package:flutter/material.dart' show ThemeMode, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show User, AuthState, AuthResponse, AuthException;

import 'package:dio/dio.dart';

import '../domain/models.dart';
import 'backend_repositories.dart';
import 'content_repository.dart';
import 'device_services.dart';
import 'local/app_database.dart';
import 'quran_api.dart';
import 'seed/seed_service.dart';
import 'services.dart';
import 'widget_sync_service.dart';
export 'services.dart' show GoldPriceService, TtsService, StatsService, FavoritesService;

// ── Altyapı provider'ları (DI konteyneri = Riverpod provider grafiği) ──────

/// main()'de gerçek örnekle override edilir.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider override edilmeli'),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Supabase erişimi tek doğru kaynaktan (supabaseClientProvider) gelir; başlatma
/// guard'ı orada toplanır. Env verilmeden açılan uygulamada client null kalır,
/// SupabaseService null-guard'lı olduğu için bağlı ekranlar (ör. Profil) çökmez.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(ref.watch(supabaseClientProvider)),
);

final prefsServiceProvider = Provider<PrefsService>(
  (ref) => PrefsService(ref.watch(prefsProvider)),
);

final permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());

final seedServiceProvider =
    Provider<SeedService>((ref) => SeedService(ref.watch(appDatabaseProvider)));

// ── Ayarlar (ViewModel = Riverpod Notifier) ────────────────────────────────

/// Uygulama tercihleri ViewModel'ı. Mimari skill'in "ViewModel" rolü =
/// Riverpod Notifier (immutable state + command metotları).
class SettingsController extends Notifier<AppSettings> {
  late final PrefsService _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(prefsServiceProvider);
    return _prefs.load();
  }

  Future<void> setMeal(MealOption m) async {
    state = state.copyWith(mealOption: m);
    await _prefs.save(state);
  }

  Future<void> toggleInterest(AppInterest i) async {
    final next = Set<AppInterest>.from(state.interests);
    next.contains(i) ? next.remove(i) : next.add(i);
    state = state.copyWith(interests: next);
    await _prefs.save(state);
  }

  Future<void> setNotifications(bool granted) async {
    state = state.copyWith(notificationsGranted: granted);
    await _prefs.save(state);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.save(state);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await _prefs.save(state);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// ── Auth ────────────────────────────────────────────────────────────────────

/// Supabase auth'u soyutlayan repository.
class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseService _supabase;

  bool get isSignedIn => _supabase.isSignedIn;
  User? get currentUser => _supabase.currentUser;
  Stream<AuthState> get changes => _supabase.authChanges;

  Future<void> signIn(String email, String password) =>
      _supabase.signInWithEmail(email, password);

  /// Kayıt sonucu aynen döner: `res.session == null` ise e-posta doğrulaması
  /// bekleniyor demektir, oturum AÇILMAMIŞTIR.
  Future<AuthResponse> signUp(String email, String password) =>
      _supabase.signUpWithEmail(email, password);
  Future<void> resetPassword(String email) =>
      _supabase.resetPasswordForEmail(email);
  Future<void> signInWithGoogle() => _supabase.signInWithGoogle();
  Future<void> signInWithApple() => _supabase.signInWithApple();
  Future<void> signOut() => _supabase.signOut();
  Future<void> deleteAccount() => _supabase.deleteAccount();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseServiceProvider)),
);

/// Auth durum akışı. Tek kaynak [authChangesProvider]
/// (backend_repositories.dart) — burada yalnızca eski ad korunuyor, böylece
/// akışa iki ayrı abonelik açılmaz.
final authStateProvider = authChangesProvider;

/// Supabase auth hatasını kullanıcıya gösterilecek Türkçe metne çevirir.
///
/// Hata YUTULMAZ: servis ve repository katmanları `AuthException`'ı aynen
/// yukarı yayar; bu saf fonksiyon sadece gösterilecek metni üretir. Bilinmeyen
/// kodlarda orijinal kod+mesaj hata ayıklama günlüğüne yazılır — bilgi kaybı
/// olmaz, kullanıcı da İngilizce sunucu metni görmez.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-posta veya parola hatalı.';
      case 'email_not_confirmed':
        return 'E-postanı doğrula. Doğrulama bağlantısı gelen kutunda.';
      case 'weak_password':
        return 'Parola en az 6 karakter olmalı.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Çok fazla deneme yapıldı, biraz sonra tekrar dene.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Bu e-posta zaten kayıtlı.';
      case 'validation_failed':
        return 'E-posta veya parola geçersiz.';
      case 'signup_disabled':
        return 'Yeni kayıtlar şu an kapalı.';
    }
    debugPrint('AuthException (kod: ${error.code}): ${error.message}');
    return 'İşlem tamamlanamadı, lütfen tekrar dene.';
  }
  // "Supabase yapılandırılmamış." gibi mesajlar zaten Türkçe.
  if (error is StateError) return error.message;
  debugPrint('Auth hatası: $error');
  return 'Bir sorun oluştu, lütfen tekrar dene.';
}

// ── Cihaz / özellik servisleri (Sprint 1+) ─────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final prayerServiceProvider = Provider<PrayerService>((ref) => PrayerService());
final widgetSyncServiceProvider =
    Provider<WidgetSyncService>((ref) => WidgetSyncService());
final qiblaServiceProvider = Provider<QiblaService>((ref) => QiblaService());
final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final svc = NotificationService(FlutterLocalNotificationsPlugin());
  svc.init();
  return svc;
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final s = AudioService();
  ref.onDispose(s.dispose);
  return s;
});

/// Reels arka plan müziği için AYRI oynatıcı örneği.
///
/// Tilavetle (`audioServiceProvider`) aynı oynatıcıyı paylaşmaz: akışı
/// kaydırmak kullanıcının süren tilavetini ÖLDÜRMEMELİ. İki ayrı `AudioPlayer`
/// olduğu için ikisi de kendi yaşam döngüsünü sürdürür.
final reelAudioServiceProvider = Provider<AudioService>((ref) {
  final s = AudioService();
  ref.onDispose(s.dispose);
  return s;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  // Tilavet artık arka planda da çalıyor → TTS ile üst üste binme olasılığı
  // eskisinden çok yüksek. Konuşma başlamadan tilaveti duraklat.
  final svc = TtsService(
    onSpeakStart: () => ref.read(audioServiceProvider).pause(),
  );
  svc.init();
  ref.onDispose(svc.stop);
  return svc;
});

// ── İçerik & kullanıcı verisi repository'leri ───────────────────────────────

/// Kur'an metni HTTP istemcisi (AlQuran Cloud). Cache eksikse devreye girer.
final quranApiProvider = Provider<IQuranApi>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));
  ref.onDispose(dio.close);
  return QuranApi(dio);
});

final contentRepositoryProvider = Provider<IContentRepository>(
  (ref) => ContentRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(quranApiProvider),
  ),
);
final dhikrRepositoryProvider = Provider<DhikrRepository>(
  (ref) => DhikrRepository(ref.watch(appDatabaseProvider)),
);
final collectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => CollectionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  ),
);
final memorizationRepositoryProvider = Provider<MemorizationRepository>(
  (ref) => MemorizationRepository(ref.watch(appDatabaseProvider)),
);
final juzRepositoryProvider = Provider<JuzRepository>(
  (ref) => JuzRepository(ref.watch(appDatabaseProvider)),
);

// ── Zekât — Altın/Gümüş fiyatı ─────────────────────────────────────────────

final goldPriceServiceProvider =
    Provider<GoldPriceService>((ref) => GoldPriceService());

/// Son 24 saat içinde kaydedilen gram altın fiyatını yükler.
/// Kayıt yoksa varsayılan değer ([GoldPriceService.defaultGoldPrice]) döner.
final goldPriceProvider = FutureProvider<double>((ref) async {
  final cached = await ref.watch(goldPriceServiceProvider).getCachedGoldPrice();
  return cached ?? GoldPriceService.defaultGoldPrice;
});

/// Son 24 saat içinde kaydedilen gram gümüş fiyatını yükler.
/// Kayıt yoksa varsayılan değer ([GoldPriceService.defaultSilverPrice]) döner.
final silverPriceProvider = FutureProvider<double>((ref) async {
  final cached =
      await ref.watch(goldPriceServiceProvider).getCachedSilverPrice();
  return cached ?? GoldPriceService.defaultSilverPrice;
});

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref.watch(appDatabaseProvider));
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService(ref.watch(appDatabaseProvider));
});

