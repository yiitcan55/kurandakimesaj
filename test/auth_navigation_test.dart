import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/services.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';

/// Regresyon: Google/e-posta girişi BAŞARILI olduğunda, `/auth`'a `go()` ile
/// gelinmiş (yığın değiştirilmiş, pop edilecek route yok) olsa bile UI hata
/// göstermemeli ve ana sekmeye gitmeli.
///
/// Hata öyküsü: `_afterAuthSuccess` öncesinde kod doğrudan `context.pop()`
/// çağırıyordu. Pop edilecek route olmadığında go_router "There is nothing to
/// pop" fırlatıyor, bu da genel `catch` tarafından yakalanıp "Google ile giriş
/// başarısız" diye YANLIŞ etiketleniyordu → başarılı giriş başarısız görünüyordu.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(SupabaseService(null));

  @override
  Future<void> signInWithGoogle() async {} // başarıyla tamamlanır
}

void main() {
  testWidgets(
    'pop edilemeyen yığında Google girişi başarılı olunca hata yok, /home\'a gider',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final router = GoRouter(
        initialLocation: '/auth', // go() benzeri: tek route, canPop=false
        routes: [
          GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME_OK')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Google ile devam et'));
      await tester.pumpAndSettle();

      // Düzeltme olmadan: context.pop() patlar → catch → "başarısız" gösterilir.
      expect(find.textContaining('başarısız'), findsNothing);
      // Düzeltme ile: pop edilemediği için /home'a yönlendirilir.
      expect(find.text('HOME_OK'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('iOS sürümünde Google girişi gösterilmez', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google ile devam et'), findsNothing);
    expect(find.text('veya'), findsNothing);
    expect(find.text('Giriş Yap'), findsWidgets);
    debugDefaultTargetPlatformOverride = null;
  });
}
