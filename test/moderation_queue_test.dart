import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/app/app_config.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';
import 'package:kurandakimesaj/features/moderation/moderation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 2: EULA onay kapısı (App Store Guideline 1.2) + moderasyon kuyruğu
/// regresyon testleri.

/// [isSignedInProvider] reaktivitesi için: `auth_navigation_test.dart`'taki
/// `_FakeGateway` ile birebir aynı kalıp (dosyalar arası paylaşılan yeni bir
/// altyapı KURULMADI — her dosya kendi küçük kopyasını tutar).
class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  bool signedIn = false;
  @override
  bool get isSignedIn => signedIn;
}

/// `repository_seam_test.dart`'taki `_FakeSocialRepository` ile aynı seam
/// kalıbı; bu dosyaya özgü senaryolar (akış listesi, bekleyen kuyruk,
/// `setPostStatus` hatası) için genişletildi.
class _FakeSocialRepository implements ISocialRepository {
  _FakeSocialRepository({
    this.feedPosts = const [],
    this.pendingPosts = const [],
    this.setPostStatusError,
  });

  final List<FeedPost> feedPosts;
  final List<FeedPost> pendingPosts;
  final Object? setPostStatusError;
  final List<String> statusChanges = [];

  @override
  bool get available => true;

  @override
  Future<List<FeedPost>> fetchReels() async =>
      // Gerçek RLS (`feed_select_visible`, bkz.
      // supabase/migrations/20260725120000_moderation_queue.sql) başka
      // kullanıcılar için akışı yalnız onaylı + gizlenmemiş içerikle sınırlar;
      // kullanıcının kendi bekleyen içeriği bilerek akışta kalır (ekran
      // ayrımı `FeedPost.isPending` ile yapılır). Fake bu sözleşmeyi taklit
      // eder — repo artık istemci tarafında ek `status` filtresi UYGULAMAZ,
      // fake da uygulamamalı (bkz. backend_repositories.dart fetchReels doc).
      feedPosts;

  @override
  Future<void> createPost({
    required String reference,
    required String arabic,
    required String meal,
    String topic = '',
    String caption = '',
    String kind = 'still',
    String? mediaUrl,
    String? videoUrl,
    String? templateId,
  }) async {}

  @override
  Future<void> toggleLike(String postId, bool currentlyLiked) async {}

  @override
  Future<void> follow(String userId) async {}

  @override
  Future<List<Comment>> fetchComments(String postId) async => const [];

  @override
  Future<void> addComment(String postId, String body) async {}

  @override
  Future<Set<String>> fetchBlockedUserIds() async => const {};

  @override
  Future<void> reportPost(String postId) async {}

  @override
  Future<void> reportComment(String commentId) async {}

  @override
  Future<void> blockUser(String userId) async {}

  @override
  Future<void> unblockUser(String userId) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> deleteComment(String commentId) async {}

  @override
  Future<List<FeedPost>> fetchPendingPosts() async => pendingPosts;

  @override
  Future<void> setPostStatus(String postId, String status) async {
    final err = setPostStatusError;
    if (err != null) throw err;
    statusChanges.add('$postId:$status');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReports() async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async => const [];
}

void main() {
  group('EULA kapısı (App Store Guideline 1.2) — auth_terms_checkbox', () {
    testWidgets(
      'onay kutusu işaretsizken gönder ve Apple butonu devre dışı; '
      'işaretlenince ikisi de etkin (Google aynı _socialButton kod yolunu '
      'paylaştığı için yapısal olarak aynı davranışa tabidir)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: AuthScreen())),
        );
        await tester.pumpAndSettle();

        // dart-define verilmeden (`flutter test`) AppConfig.hasGoogleSignIn
        // derleme zamanında false'tur → Google butonu hiç render edilmez (bkz.
        // auth_navigation_test.dart). Apple ile TAM AYNI `_socialButton()`
        // gövdesini (`onPressed: _canSubmit ? onPressed : null`) paylaştığı
        // için buradaki Apple sonucu Google için de yapısal kanıttır.
        expect(AppConfig.hasGoogleSignIn, isFalse);
        expect(find.byKey(const Key('auth_google_button')), findsNothing);

        FilledButton submitButton() => tester.widget<FilledButton>(
          find.byKey(const Key('auth_submit_button')),
        );
        OutlinedButton appleButton() => tester.widget<OutlinedButton>(
          find.byKey(const Key('auth_apple_button')),
        );

        // Onaysız: gönder VE Apple butonu devre dışı.
        expect(submitButton().onPressed, isNull);
        expect(appleButton().onPressed, isNull);
        expect(find.byKey(const Key('auth_terms_hint')), findsOneWidget);

        await tester.tap(find.byKey(const Key('auth_terms_checkbox')));
        await tester.pumpAndSettle();

        // Onaylı: ikisi de etkin.
        expect(submitButton().onPressed, isNotNull);
        expect(appleButton().onPressed, isNotNull);
        expect(find.byKey(const Key('auth_terms_hint')), findsNothing);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'terms_accepted_version güncel sürümle kayıtlıysa onay kutusu önceden '
      'işaretli gelir ve gönder butonu baştan etkindir',
      (tester) async {
        SharedPreferences.setMockInitialValues({'terms_accepted_version': 1});
        addTearDown(() => SharedPreferences.setMockInitialValues({}));

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: AuthScreen())),
        );
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(
          find.byKey(const Key('auth_terms_checkbox')),
        );
        expect(checkbox.value, isTrue);
        expect(find.byKey(const Key('auth_terms_hint')), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('auth_submit_button')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  // Karar (bkz. ISocialRepository.fetchReels doc, backend_repositories.dart):
  // istemci artık status=='approved' filtresi UYGULAMAZ — RLS başkalarının
  // pending'ini zaten sunucuda kapatır, kullanıcının kendi bekleyen içeriği
  // bilerek akışta kalır ve "Onay bekliyor" rozetiyle (reel_pending_badge)
  // ayrışır. Bu grup eskiden ("içerik gizlenir") test ediyordu; yeni
  // sözleşmeye göre güncellendi ("içerik rozetle işaretlenir, gizlenmez").
  group('Onay kuyruğu — akıştaki içerik durumuna göre rozetle ayrışır', () {
    testWidgets('status=approved gönderi rozetsiz gösterilir', (
      tester,
    ) async {
      final gateway = _FakeGateway()..signedIn = true;
      final fake = _FakeSocialRepository(
        feedPosts: const [
          FeedPost(
            id: 'approved-post',
            authorId: 'author-2',
            authorName: 'Onaylı Yazar',
            reference: '',
            arabic: '',
            meal: 'Onaylı içerik akışta GÖRÜNMELİ',
            topic: '',
            likeCount: 0,
            likedByMe: false,
            status: 'approved',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseGatewayProvider.overrideWithValue(gateway),
            socialRepositoryProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // meal iki katmanda render edilir (bkz. _ReelComposition arka plan +
      // _ReelOverlay altyazı) — kasıtlı tasarım, findsWidgets (>=1) yeterli.
      expect(find.text('Onaylı içerik akışta GÖRÜNMELİ'), findsWidgets);
      expect(find.byKey(const Key('reel_pending_badge')), findsNothing);
    });

    testWidgets(
      'status=pending gönderi akıştan gizlenmez, "Onay bekliyor" '
      'rozetiyle birlikte gösterilir',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          feedPosts: const [
            FeedPost(
              id: 'pending-post',
              authorId: 'author-1',
              authorName: 'Bekleyen Yazar',
              reference: '',
              arabic: '',
              meal: 'Bekleyen içerik rozetle birlikte GÖRÜNMELİ',
              topic: '',
              likeCount: 0,
              likedByMe: false,
              status: 'pending',
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseGatewayProvider.overrideWithValue(gateway),
              socialRepositoryProvider.overrideWithValue(fake),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Bekleyen içerik rozetle birlikte GÖRÜNMELİ'),
          findsWidgets,
        );
        expect(find.byKey(const Key('reel_pending_badge')), findsOneWidget);
      },
    );
  });

  group(
    'setPostStatus hata yolu — yönetici değilse anlamlı Türkçe hata gösterilir',
    () {
      testWidgets(
        '403 (StateError) fırlatılırsa moderasyon ekranında SnackBar ile '
        'Türkçe hata görünür, sessizce yutulmaz',
        (tester) async {
          final gateway = _FakeGateway()..signedIn = true;
          final fake = _FakeSocialRepository(
            pendingPosts: const [
              FeedPost(
                id: 'pending-1',
                authorId: 'author-1',
                authorName: 'Yazar',
                reference: 'Bakara, 1',
                arabic: '',
                meal: 'Kuyruktaki içerik',
                topic: '',
                likeCount: 0,
                likedByMe: false,
                status: 'pending',
              ),
            ],
            setPostStatusError: StateError(
              'İçerik durumunu yalnızca yönetici değiştirebilir.',
            ),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                supabaseGatewayProvider.overrideWithValue(gateway),
                socialRepositoryProvider.overrideWithValue(fake),
              ],
              child: const MaterialApp(home: ModerationScreen()),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('moderation-approve-pending-1')),
          );
          await tester.pump(); // SnackBar animasyonu tetiklenir.
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            find.text('İçerik durumunu yalnızca yönetici değiştirebilir.'),
            findsOneWidget,
          );
          // Hata fırlatıldığı için durum GERÇEKTEN değişmedi.
          expect(fake.statusChanges, isEmpty);
        },
      );
    },
  );
}
