import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/app/app.dart';
import 'package:kurandakimesaj/app/feature_catalog.dart';
import 'package:kurandakimesaj/app/router.dart';
import 'package:kurandakimesaj/data/meal_video_store.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';
import 'package:kurandakimesaj/features/onboarding/onboarding_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regresyon: Instagram/TikTok'tan paylaşım yapıldığında uygulama KAPALIYSA
/// (soğuk başlatma), `getInitialMedia` sonucu `sharedAyahInputProvider`'a
/// `initState` sırasında (t≈0) yazılır ve `_onShared` `/ayah-finder`'ı hemen
/// `push` eder. Ancak `SplashScreen._go`, 2400 ms sonra `context.go(...)`
/// çağırıyordu; go_router'da `go` navigasyon yığınını TAMAMEN değiştirir, bu
/// yüzden erken push edilen `/ayah-finder` sessizce silinip kullanıcı ana
/// sayfada kalıyordu. Düzeltme: `_go` kendi sonunda provider'ı tekrar kontrol
/// edip gerekiyorsa `/ayah-finder`'ı yeniden `push` ediyor.
///
/// Gerçek uygulama router'ı yerine 3 rotalı (gerçek [SplashScreen] +
/// [Placeholder] stub'ları) minimal bir [GoRouter] kuruyoruz — testin konusu
/// yönlendirme sırası, ekranların gerçek içeriği değil.
class _TamamlanmisAyarlarController extends SettingsController {
  @override
  AppSettings build() => const AppSettings(onboardingComplete: true);
}

GoRouter _routerKur() => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Placeholder(key: Key('stub_home')),
        ),
        GoRoute(
          path: '/ayah-finder',
          builder: (_, _) => const Placeholder(key: Key('stub_ayah_finder')),
        ),
        GoRoute(
          path: '/meal-edit',
          builder: (_, _) => const Placeholder(key: Key('stub_meal_edit')),
        ),
      ],
    );

class _RecStore extends MealVideoStore {
  _RecStore(SharedPreferences prefs) : super(prefs: prefs);
  bool swept = false;
  String? except;
  @override
  Future<void> sweepOrphan({String? except}) async {
    swept = true;
    this.except = except;
  }
}

void main() {
  // google_fonts test ortamında fontu ne asset'ten ne ağdan çözebiliyor ve
  // bu, testin konusu olmayan bir async hataya yol açabiliyor (bkz.
  // tasks/lessons.md ders 11). Ağ bacağını kapatmak yeterli — bu testler
  // widget pump zone'unda koşuyor, `buildAppTheme`'i doğrudan çağırmıyor.
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'soğuk başlatmada paylaşılan ayet girdisi varsa, splash süresi dolunca '
    'Ayet Bul ekranı açılır (go navigasyon yığınını silse bile)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_TamamlanmisAyarlarController.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _routerKur()),
        ),
      );

      // pumpWidget'tan SONRA ama 2400 ms geçmeden yaz: soğuk başlatmada
      // `getInitialMedia` sonucu tam olarak böyle, `initState` sırasında
      // (splash animasyonu daha bitmeden) provider'a düşer.
      container
          .read(sharedAyahInputProvider.notifier)
          .set((imagePath: '/tmp/a.png', videoPath: null, url: null));

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byKey(const Key('stub_ayah_finder')), findsOneWidget);
    },
  );

  testWidgets(
    'paylaşım girdisi yokken soğuk başlatma normal şekilde ana sayfaya gider',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_TamamlanmisAyarlarController.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _routerKur()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byKey(const Key('stub_home')), findsOneWidget);
      expect(find.byKey(const Key('stub_ayah_finder')), findsNothing);
    },
  );

  Future<void> sogukPaylasim(
    WidgetTester tester,
    SharedAyahInput input,
    String stubKey,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(_TamamlanmisAyarlarController.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _routerKur()),
      ),
    );
    container.read(sharedAyahInputProvider.notifier).set(input);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(find.byKey(Key(stubKey)), findsOneWidget);
  }

  testWidgets('soğuk başlatmada video paylaşımı Meal Düzenle yolunu açar',
      (tester) => sogukPaylasim(
          tester,
          (imagePath: null, videoPath: '/tmp/v.mp4', url: null),
          'stub_meal_edit'));

  testWidgets('soğuk başlatmada bağlantı paylaşımı Meal Düzenle yolunu açar',
      (tester) => sogukPaylasim(
          tester,
          (imagePath: null, videoPath: null, url: 'https://example.com/v'),
          'stub_meal_edit'));

  testWidgets('soğuk başlatmada görsel paylaşımı Ayet Bul yolunu açar',
      (tester) => sogukPaylasim(
          tester,
          (imagePath: '/tmp/a.png', videoPath: null, url: null),
          'stub_ayah_finder'));

  // app.dart _onShared / sweepOrphan bağlantısı: platform kanalları sahte.
  Future<(_RecStore, GoRouter, void Function(String json))> appKur(
    WidgetTester tester, {
    required String initial,
    String? initialJson,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final store = _RecStore(await SharedPreferences.getInstance());
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Placeholder(key: Key('stub_home'))),
        GoRoute(path: '/meal-edit', builder: (_, _) => const Placeholder(key: Key('stub_meal_edit'))),
        GoRoute(path: '/ayah-finder', builder: (_, _) => const Placeholder()),
      ],
    );
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (_) async => null);
    messenger.setMockStreamHandler(
      const EventChannel('home_widget/updates'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('receive_sharing_intent/messages'),
      (c) async => c.method == 'getInitialMedia' ? initialJson : null,
    );
    MockStreamHandlerEventSink? sink;
    messenger.setMockStreamHandler(
      const EventChannel('receive_sharing_intent/events-media'),
      MockStreamHandler.inline(onListen: (_, s) {
          sink = s;
        },),
    );
    addTearDown(() {
      messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), null);
      messenger.setMockMethodCallHandler(
        const MethodChannel('receive_sharing_intent/messages'),
        null,
      );
      messenger.setMockStreamHandler(const EventChannel('home_widget/updates'), null);
      messenger.setMockStreamHandler(
        const EventChannel('receive_sharing_intent/events-media'),
        null,
      );
    });
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(_TamamlanmisAyarlarController.new),
        routerProvider.overrideWithValue(router),
        mealVideoStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KuranApp()),
    );
    await tester.pump();
    await tester.pump();
    return (store, router, (json) => sink!.success(json));
  }

  String video(String path) => jsonEncode([
    {'path': path, 'type': 'video'},
  ]);

  testWidgets('soğuk başlatmada sweepOrphan paylaşılan ilk yolu except olarak alır', (
    tester,
  ) async {
    final (store, _, _) = await appKur(
      tester,
      initial: '/home',
      initialJson: video('/tmp/paylasilan.mp4'),
    );
    expect(store.swept, isTrue);
    expect(store.except, '/tmp/paylasilan.mp4');
  });

  testWidgets('zaten Meal Düzenle açıkken yeni video paylaşımı ikinci ekran yığmaz', (
    tester,
  ) async {
    final (_, router, emit) = await appKur(tester, initial: '/meal-edit');
    emit(video('/tmp/ikinci.mp4'));
    await tester.pump();
    await tester.pump();
    expect(router.canPop(), isFalse);
    expect(find.byKey(const Key('stub_meal_edit')), findsOneWidget);
  });

  testWidgets('başka ekrandayken video paylaşımı Meal Düzenle rotasını push eder', (
    tester,
  ) async {
    final (_, router, emit) = await appKur(tester, initial: '/home');
    emit(video('/tmp/ikinci.mp4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(router.canPop(), isTrue);
    expect(find.byKey(const Key('stub_meal_edit')), findsOneWidget);
  });

  test('katalogda /meal-edit var ve rotalar tekil', () {
    final routes = kFeatures.map((f) => f.route).toList();
    expect(routes, contains('/meal-edit'));
    expect(routes.toSet().length, routes.length);
  });
}
