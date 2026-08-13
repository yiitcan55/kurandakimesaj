import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';
import 'package:kurandakimesaj/features/onboarding/onboarding_screens.dart';

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
      ],
    );

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
}
