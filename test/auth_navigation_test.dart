import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kurandakimesaj/app/app_config.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/services.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

/// Regresyon: sosyal giriş BAŞARILI olduğunda, `/auth`'a `go()` ile gelinmiş
/// (yığın değiştirilmiş, pop edilecek route yok) olsa bile UI hata
/// göstermemeli ve ana sekmeye gitmeli.
///
/// Hata öyküsü: `_afterAuthSuccess` öncesinde kod doğrudan `context.pop()`
/// çağırıyordu. Pop edilecek route olmadığında go_router "There is nothing to
/// pop" fırlatıyor, bu da genel `catch` tarafından yakalanıp "giriş
/// başarısız" diye YANLIŞ etiketleniyordu → başarılı giriş başarısız görünüyordu.
///
/// GÜNCELLENDİ (Faz 1): bu regresyon eskiden Google butonuyla tetikleniyordu;
/// artık Apple butonuyla tetikleniyor. Sebep: `AppConfig.hasGoogleSignIn`
/// derleme zamanı sabiti (`String.fromEnvironment`) olduğundan
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` verilmeden çalışan bu suite'te
/// Google butonu HİÇ render edilmez (bkz. dosya sonundaki notlar). Apple
/// butonu yalnız platforma bağlı (`debugDefaultTargetPlatformOverride`) ve bu
/// suite'te runtime'da kontrol edilebiliyor — aynı regresyonu daha az kırılgan
/// doğrular.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(SupabaseService(null));

  @override
  Future<void> signInWithApple() async {} // başarıyla tamamlanır
}

/// [isSignedInProvider] reaktivite testi için: canlı `isSignedIn` değeri
/// dışarıdan değiştirilebilen sahte kapı.
class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  bool signedIn = false;
  @override
  bool get isSignedIn => signedIn;
}

void main() {
  testWidgets(
    'pop edilemeyen yığında Apple girişi başarılı olunca hata yok, /home\'a gider',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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

      // EULA kapısı (Faz 2): onay verilmeden Apple butonu disabled'dır.
      await tester.tap(find.byKey(const Key('auth_terms_checkbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('auth_apple_button')));
      await tester.pumpAndSettle();

      // Düzeltme olmadan: context.pop() patlar → catch → "başarısız" gösterilir.
      expect(find.textContaining('başarısız'), findsNothing);
      // Düzeltme ile: pop edilemediği için /home'a yönlendirilir.
      expect(find.text('HOME_OK'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  // GÜNCELLENDİ (Faz 1): Apple girişi eklendiğinden beri sosyal giriş bloğu
  // (ve "veya" ayracı) artık `showApple || showGoogle` koşuluna bağlı; iOS'ta
  // Apple butonu göründüğü için ayraç da iOS'ta artık GÖRÜNÜR. Eski test
  // "veya" ayracının iOS'ta tamamen gizli olduğunu varsayıyordu — bu artık
  // yanlış, güncellendi (silinmedi).
  //
  // Not: `AppConfig.hasGoogleSignIn` derleme zamanı sabiti
  // (`String.fromEnvironment`) olduğu için bu test suite'i normal
  // `flutter test` ile (--dart-define=GOOGLE_WEB_CLIENT_ID=... VERİLMEDEN)
  // çalıştığında her zaman false'tur — yani aşağıdaki "Google görünmüyor"
  // beklentisi define'sız koşuda platformdan bağımsız olarak sağlanır.
  // Google'ın iOS'taki GERÇEK koşulu ayrıca iOS client ID'sinin de dolu
  // olmasıdır (aşağıdaki asimetri testi). Uçtan uca doğrulama:
  // `flutter test test/auth_navigation_test.dart --dart-define=GOOGLE_WEB_CLIENT_ID=test`
  testWidgets(
    'iOS\'ta Apple butonu (ve "veya" ayracı) görünür; Google client ID yokken gizli',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuthScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_apple_button')), findsOneWidget);
      // Apple butonu gösterildiği için ayraç artık iOS'ta da var (eski
      // davranışta tüm sosyal blok "if (platform != iOS)" ile gizliydi).
      expect(find.text('veya'), findsOneWidget);
      // dart-define verilmediği için derleme zamanında false; iOS'a özel
      // bir gizleme DEĞİL (bkz. üstteki not).
      expect(find.text('Google ile devam et'), findsNothing);
      expect(find.text('Giriş Yap'), findsWidgets);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('Apple butonu yalnızca iOS platformunda görünür', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_apple_button')), findsOneWidget);
    expect(find.text('Apple ile devam et'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Apple butonu Android platformunda görünmez', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_apple_button')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'AppConfig.hasGoogleSignIn false iken (derleme zamanı sabiti, --dart-define verilmedi) Google butonu görünmez',
    (tester) async {
      // Bu bayrak platformdan bağımsızdır; Android'de de aynen false kalır —
      // gösterip göstermemeyi belirleyen artık platform değil bu bayraktır.
      expect(AppConfig.hasGoogleSignIn, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuthScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_google_button')), findsNothing);
      expect(find.text('Google ile devam et'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  // REGRESYON KİLİDİ (1.0.1): Faz 1d Google butonunu iOS'ta da görünür yaptı,
  // ama iOS'ta `GoogleSignIn.initialize` WEB client ID'ye ek olarak İOS client
  // ID de ister — GOOGLE_IOS_CLIENT_ID tanımsız derlenirse buton görünür ve
  // her dokunuşta hata verirdi. Beklenen asimetri: web ID varken Android
  // gösterir, iOS gizler.
  //
  // Bu test yalnız `--dart-define=GOOGLE_WEB_CLIENT_ID=test` ile koşulduğunda
  // AYIRT EDİCİDİR (define'sız iki platform da gizler, test yine geçer ama
  // hiçbir şey kanıtlamaz). Kasıtlı: define'ı zorunlu kılmak tüm suite'i
  // define'a bağımlı hale getirirdi.
  testWidgets(
    'iOS\'ta Google butonu iOS client ID olmadan gizli, Android\'de web ID yeterli',
    (tester) async {
      Future<bool> googleVisible(TargetPlatform platform) async {
        debugDefaultTargetPlatformOverride = platform;
        // UniqueKey ŞART: aynı `const` widget'la ikinci kez pumpWidget çağrılırsa
        // Flutter ağacı identical görüp alt ağacı hiç yeniden inşa etmez; ikinci
        // platform ölçümü birincinin sonucunu okurdu (bu test tam da bu yüzden
        // ilk yazılışında yanlış "başarısız" verdi).
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: AuthScreen(key: UniqueKey()))),
        );
        await tester.pumpAndSettle();
        return find.byKey(const Key('auth_google_button')).evaluate().isNotEmpty;
      }

      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      // GOOGLE_IOS_CLIENT_ID hiçbir koşuda verilmiyor → iOS her zaman gizli.
      expect(await googleVisible(TargetPlatform.iOS), isFalse);
      expect(
        await googleVisible(TargetPlatform.android),
        AppConfig.hasGoogleSignIn,
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  // REAKTİVİTE TESTİ — kök nedenin (isSignedInProvider'ın çıkış/girişte
  // yeniden hesaplanmaması) geri gelmesini engeller. authChangesProvider'ı
  // sahte bir stream'le, supabaseGatewayProvider'ı canlı değeri elden
  // değiştirebildiğimiz sahte bir kapıyla override ediyoruz; gerçek ağ
  // çağrısı YOK.
  testWidgets(
    'auth durumu "çıkış" -> "giriş" olarak değişince isSignedInProvider\'ı izleyen widget yeniden inşa edilir',
    (tester) async {
      final gateway = _FakeGateway();
      final events = StreamController<AuthState>();
      addTearDown(events.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseGatewayProvider.overrideWithValue(gateway),
            authChangesProvider.overrideWith((ref) => events.stream),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final signedIn = ref.watch(isSignedInProvider);
                return Text(signedIn ? 'GIRIS_YAPILDI' : 'MISAFIR');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Başlangıç: çıkış yapılmış.
      expect(find.text('MISAFIR'), findsOneWidget);
      expect(find.text('GIRIS_YAPILDI'), findsNothing);

      // Giriş olayı yayınla: canlı değer değişti + tetikleyici stream olay yaydı.
      gateway.signedIn = true;
      events.add(AuthState(AuthChangeEvent.signedIn, null));
      // Stream olayı bir sonraki event-loop turunda dağıtılır; pumpAndSettle
      // ile birlikte ek bir bekleme veriyoruz (yalnızca pump yetmeyebiliyor).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('GIRIS_YAPILDI'), findsOneWidget);
      expect(find.text('MISAFIR'), findsNothing);
    },
  );
}
