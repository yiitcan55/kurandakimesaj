import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/services.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthResponse;

/// Faz 1: e-posta/parola auth akışının Türkçe hata eşlemesi, form doğrulaması
/// ve "doğrulama e-postası gönderildi" akışı için regresyon testleri.

/// Kayıt sırasında Supabase `session == null` döndürdüğünde (e-posta
/// doğrulaması bekleniyor) kullanılan sahte repository.
class _FakeAuthRepositoryUnconfirmedSignUp extends AuthRepository {
  _FakeAuthRepositoryUnconfirmedSignUp() : super(SupabaseService(null));

  @override
  Future<AuthResponse> signUp(String email, String password) async =>
      AuthResponse(); // session == null -> oturum AÇILMADI
}

Future<void> _pumpAuthScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: AuthScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('authErrorMessage — AuthException kod -> Türkçe mesaj eşlemesi', () {
    test('invalid_credentials -> "E-posta veya parola hatalı."', () {
      const e = AuthException('Invalid login credentials', code: 'invalid_credentials');
      expect(authErrorMessage(e), 'E-posta veya parola hatalı.');
    });

    test('email_not_confirmed -> doğrulama iste mesajı', () {
      const e = AuthException('Email not confirmed', code: 'email_not_confirmed');
      expect(
        authErrorMessage(e),
        'E-postanı doğrula. Doğrulama bağlantısı gelen kutunda.',
      );
    });

    test('weak_password -> parola uzunluk mesajı', () {
      const e = AuthException('Password too weak', code: 'weak_password');
      expect(authErrorMessage(e), 'Parola en az 6 karakter olmalı.');
    });

    test('over_email_send_rate_limit -> "biraz sonra tekrar dene" mesajı', () {
      const e = AuthException(
        'Email rate limit exceeded',
        code: 'over_email_send_rate_limit',
      );
      expect(
        authErrorMessage(e),
        'Çok fazla deneme yapıldı, biraz sonra tekrar dene.',
      );
    });

    test(
      'bilinmeyen kod -> genel Türkçe mesaja düşer, orijinal İngilizce metin kullanıcıya sızmaz',
      () {
        const original = 'Some obscure english server message';
        const e = AuthException(original, code: 'totally_unknown_code_xyz');
        final result = authErrorMessage(e);
        expect(result, 'İşlem tamamlanamadı, lütfen tekrar dene.');
        // Bilgi kaybı yok (debugPrint'e gider) ama kullanıcıya asla İngilizce
        // sunucu metni gösterilmez.
        expect(result.contains(original), isFalse);
      },
    );

    test('StateError (ör. "Supabase yapılandırılmamış.") aynen döner', () {
      final e = StateError('Supabase yapılandırılmamış.');
      expect(authErrorMessage(e), 'Supabase yapılandırılmamış.');
    });

    test('bilinmeyen genel hata -> "Bir sorun oluştu" mesajı', () {
      final e = Exception('network down');
      expect(authErrorMessage(e), 'Bir sorun oluştu, lütfen tekrar dene.');
    });
  });

  group('AuthScreen form doğrulaması — Türkçe hatalar', () {
    testWidgets('boş e-posta ve boş parola ile gönderilince Türkçe hatalar gösterilir', (
      tester,
    ) async {
      await _pumpAuthScreen(tester);

      // EULA kapısı (Faz 2): onay verilmeden gönder butonu disabled'dır, bu
      // yüzden form validasyonunun tetiklenmesi için önce koşulları onaylamak
      // gerekir — aksi halde tap no-op olur ve hiç hata gösterilmez.
      await tester.tap(find.byKey(const Key('auth_terms_checkbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('E-posta adresini gir.'), findsOneWidget);
      expect(find.text('Parolanı gir.'), findsOneWidget);
    });

    testWidgets('geçersiz e-posta biçimi Türkçe hata gösterir', (tester) async {
      await _pumpAuthScreen(tester);

      await tester.enterText(
        find.byKey(const Key('auth_email_field')),
        'gecersiz-adres',
      );
      await tester.enterText(
        find.byKey(const Key('auth_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);
      expect(find.text('Parolanı gir.'), findsNothing);
    });

    testWidgets('6 karakterden kısa parola Türkçe hata gösterir', (tester) async {
      await _pumpAuthScreen(tester);

      await tester.enterText(
        find.byKey(const Key('auth_email_field')),
        'test@example.com',
      );
      await tester.enterText(find.byKey(const Key('auth_password_field')), '123');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Parola en az 6 karakter olmalı.'), findsOneWidget);
      expect(find.text('Geçerli bir e-posta adresi gir.'), findsNothing);
    });
  });

  group('Kayıt — session == null (e-posta doğrulaması bekleniyor)', () {
    testWidgets(
      'signUp session döndürmezse doğrulama bilgisi gösterilir ve /home\'a GİDİLMEZ',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/auth',
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
              authRepositoryProvider.overrideWithValue(
                _FakeAuthRepositoryUnconfirmedSignUp(),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Kayıt moduna geç.
        await tester.tap(find.byKey(const Key('auth_toggle_mode')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('auth_email_field')),
          'yeni@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('auth_password_field')),
          '123456',
        );
        // EULA kapısı (Faz 2): onay verilmeden gönder butonu disabled'dır.
        await tester.tap(find.byKey(const Key('auth_terms_checkbox')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('auth_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Doğrulama e-postası gönderildi. Gelen kutunu kontrol et.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('auth_info_text')), findsOneWidget);
        expect(find.byKey(const Key('auth_error_text')), findsNothing);
        // _afterAuthSuccess ÇAĞRILMADI: /home'a geçilmedi, hâlâ /auth'tayız.
        expect(find.text('HOME_OK'), findsNothing);
      },
    );
  });
}
