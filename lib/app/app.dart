import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show JustAudioBackground;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/app_database.dart';
import '../data/seed/seed_service.dart';
import '../data/repositories.dart';
import '../data/widget_background.dart';
import '../features/ayah_finder/ayah_finder_controller.dart';
import '../ui/core/theme/app_colors.dart';
import '../ui/core/theme/app_theme.dart';
import 'app_config.dart';
import 'router.dart';

/// main()'in ProviderScope override'larını kurması için gereken hazır kaynaklar.
typedef BootstrapResult = (SharedPreferences prefs, AppDatabase db);

/// Uygulama başlatma sırası: prefs → Supabase (varsa) → drift open + seed.
Future<BootstrapResult> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih biçimlendirme (intl) — Dini Günler vb. ekranlar için.
  await initializeDateFormatting('tr', null);

  // Tilavetin arka planda sürmesi + bildirim/kilit ekranı medya çubuğu.
  // `runApp` ÖNCESİ çağrılmalı: paket, ilk oynatıcı kurulmadan servisi
  // bağlamak zorunda. `androidNotificationOngoing: true` → çalarken bildirim
  // kaydırılıp kapatılamaz (yanlışlıkla sesi öldürmeyi engeller).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.kurandakimesaj.app.channel.audio',
    androidNotificationChannelName: 'Tilavet',
    androidNotificationOngoing: true,
  );

  final prefs = await SharedPreferences.getInstance();

  if (AppConfig.hasSupabase) {
    // anon key hâlâ geçerli; publishable key'e geçiş Supabase yapılandırması
    // netleşince yapılacak.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  final db = AppDatabase();
  await SeedService(db).seedIfNeeded();

  // Ana ekran ezan widget'ı için periyodik arka plan yenilemesi (fire-and-forget).
  unawaited(WidgetBackground.init());

  return (prefs, db);
}

/// Kök uygulama — MaterialApp.router + zümrüt/altın tema.
/// Ana ekran widget'ı tıklamalarını dinleyip ilgili ekrana yönlendirir.
class KuranApp extends ConsumerStatefulWidget {
  const KuranApp({super.key});

  @override
  ConsumerState<KuranApp> createState() => _KuranAppState();
}

class _KuranAppState extends ConsumerState<KuranApp> {
  StreamSubscription<Uri?>? _widgetClickSub;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  @override
  void initState() {
    super.initState();
    _widgetClickSub = HomeWidget.widgetClicked.listen(_onWidgetClick);
    // Uygulama widget tıklamasıyla soğuk başlatıldıysa.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_onWidgetClick);

    // Paylaş menüsünden gelen görsel/bağlantı → Ayet Bul (Faz 3).
    _shareSub =
        ReceiveSharingIntent.instance.getMediaStream().listen(_onShared);
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _onShared(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  /// homeWidget://prayer → /prayer, homeWidget://ayah → /daily-ayah.
  void _onWidgetClick(Uri? uri) {
    if (uri == null || !mounted) return;
    final route = uri.host == 'ayah' ? '/daily-ayah' : '/prayer';
    ref.read(routerProvider).go(route);
  }

  /// Paylaşılan ilk görsel/video/metni Ayet Bul ekranına aktar.
  ///
  /// Video: kullanıcının kendi cihazındaki dosya (WhatsApp/Telegram'dan gelen
  /// tilavet videosu, galeriye kaydedilmiş klip, ekran kaydı). Uygulama hiçbir
  /// platformdan video İNDİRMEZ — bkz. Karar Günlüğü (App Store 5.2.3).
  void _onShared(List<SharedMediaFile> files) {
    if (files.isEmpty || !mounted) return;
    final f = files.first;
    final SharedAyahInput? input = switch (f.type) {
      SharedMediaType.image => (imagePath: f.path, videoPath: null, url: null),
      SharedMediaType.video => (imagePath: null, videoPath: f.path, url: null),
      SharedMediaType.text ||
      SharedMediaType.url =>
        (imagePath: null, videoPath: null, url: f.path),
      _ => null,
    };
    if (input == null) return;
    ref.read(sharedAyahInputProvider.notifier).set(input);
    final router = ref.read(routerProvider);
    // Soğuk başlatma: `getInitialMedia` burayı t≈0'da çağırır, ama ekranda
    // hâlâ `/splash` var ve `SplashScreen._go` 2400 ms sonra `go('/home')` ile
    // yığını TAMAMEN değiştiriyor — buradan push edilen rota silinirdi.
    // Üstelik push edilen AyahFinderScreen bir frame sonra provider'ı
    // `clear()` ettiği için silinen rotayla birlikte paylaşım da kaybolurdu.
    // Splash'teysek rotayı ona bırakıyoruz: provider dolu kalır, splash
    // `/home`'a geçtikten sonra `/ayah-finder`'ı kendisi push eder.
    if (router.state.uri.path == '/splash') return;
    router.push('/ayah-finder');
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Kur\'an\'da ki Mesaj',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      builder: (context, child) {
        // Aktif brightness'ı themeMode + platformdan hesapla ve global palete
        // yaz; AppColors getter'ları widget-build anında doğru (koyu/açık)
        // renkleri döndürür. (Theme.of(builder-context) güvenilir değil.)
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        AppColors.brightness = isDark ? Brightness.dark : Brightness.light;
        // brightness'a bağlı key: tema değişince tüm alt ağaç yeniden build
        // olur, böylece AppColors okuyan `const` widget'lar da güncel paleti
        // alır (go_router delegate mevcut route'u koruduğundan navigasyon
        // kaybolmaz). İsim-düzenleme çökmesiyle ilgisiz olduğu doğrulandı.
        //
        // Yazı ölçeği kelepçesi: Android "Yazı tipi boyutu" 2.0×'e, iOS
        // Dynamic Type AX5 ≈3.1×'e kadar çıkıyor ve her sabit-piksel kabı
        // taşırıyor. 1.3 tavanı erişilebilirliği tamamen kesmeden kapları
        // korur (yapısal düzeltmeler bunun ÜSTÜNE gelir — tek başına yetmez).
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
          child: KeyedSubtree(key: ValueKey(isDark), child: child!),
        );
      },
      routerConfig: router,
    );
  }
}
