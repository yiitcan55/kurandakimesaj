import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/repositories.dart' show prefsProvider;
import 'package:kurandakimesaj/features/community/community_screens.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart'
    show myProfileProvider;
import 'package:kurandakimesaj/features/moderation/moderation_screen.dart';
import 'package:kurandakimesaj/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store Guideline 1.2 (UGC) — Bildir / Engelle / Engeli kaldır / yönetici
/// yetkisi mekanizmalarının regresyon testleri. Fake repository + fake gateway
/// kalıbı `moderation_queue_test.dart` ve `repository_seam_test.dart` ile
/// BİREBİR aynıdır — paylaşılan yeni bir altyapı KURULMADI, bu dosya kendi
/// küçük kopyasını tutar.

/// [isSignedInProvider] reaktivitesi için canlı değeri elden değiştirilebilen
/// sahte kapı — `moderation_queue_test.dart`'taki `_FakeGateway` ile aynı kalıp.
class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  bool signedIn = false;
  @override
  bool get isSignedIn => signedIn;

  // `client == null` yapar `isAvailable == false` → FeedScreen o zaman
  // Stack'e Positioned OLMAYAN küçük "çevrimdışı" ikon çocuğu ekler
  // (bkz. community_screens.dart FeedScreen.build). Stack fit:loose
  // olduğundan boyutunu o küçük non-positioned çocuğa göre belirler ve
  // `Positioned.fill(_ReelsView())` koca ekran yerine o minik alana
  // sıkışır — reel aksiyon düğmeleri hit-test edilemez hale gelir. Testte
  // "backend bağlı" simüle etmek için burada true'ya sabitliyoruz.
  @override
  bool get isAvailable => true;
}

/// Çağrıları kaydeden sahte `ISocialRepository`. Gerçek ağ çağrısı YOK.
class _FakeSocialRepository implements ISocialRepository {
  _FakeSocialRepository({
    this.feedPosts = const [],
    this.comments = const [],
    this.blockedUserRows = const [],
  });

  final List<FeedPost> feedPosts;
  final List<Comment> comments;
  final List<Map<String, dynamic>> blockedUserRows;

  final List<String> reportedPosts = [];
  final List<String> reportedComments = [];
  final List<String> blockedUserIds = [];
  final List<String> unblockedUserIds = [];

  @override
  bool get available => true;

  @override
  Future<List<FeedPost>> fetchReels() async => feedPosts;

  @override
  Future<String> uploadPostMedia(Uint8List bytes, {required bool isVideo}) async =>
      'https://example.com/media.${isVideo ? 'mp4' : 'png'}';

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
    String? audioTrackId,
  }) async {}

  @override
  Future<void> toggleLike(String postId, bool currentlyLiked) async {}

  @override
  Future<void> follow(String userId) async {}

  @override
  Future<List<Comment>> fetchComments(String postId) async => comments;

  @override
  Future<void> addComment(String postId, String body) async {}

  @override
  Future<Set<String>> fetchBlockedUserIds() async => blockedUserIds.toSet();

  @override
  Future<void> reportPost(String postId) async => reportedPosts.add(postId);

  @override
  Future<void> reportComment(String commentId) async =>
      reportedComments.add(commentId);

  @override
  Future<void> blockUser(String userId) async => blockedUserIds.add(userId);

  @override
  Future<void> unblockUser(String userId) async =>
      unblockedUserIds.add(userId);

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> deleteComment(String commentId) async {}

  @override
  Future<List<FeedPost>> fetchPendingPosts() async => const [];

  @override
  Future<void> setPostStatus(String postId, String status) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchReports() async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async =>
      blockedUserRows;
}

void main() {
  group('Reel akışı — Bildir/Engelle (Apple Guideline 1.2, madde 3-4)', () {
    // BULGU: `_ReelOverlay`'de ayrı bir "⋯" popup menüsü YOK — Bildir/Engelle
    // dikey aksiyon rayında DOĞRUDAN ikon düğmeleri olarak render ediliyor
    // (görevde varsayılan "⋯ menüsü" yalnız yorumlarda gerçek — bkz. aşağıdaki
    // `_CommentTile` grubu). Burada gerçek davranışı test ediyoruz: aksiyon
    // ULAŞILABİLİR mi ve doğru argümanla repository'yi çağırıyor mu?
    testWidgets(
      'reel aksiyon rayında "Bildir" ulaşılabilir ve onaylanınca '
      'repository.reportPost DOĞRU postId ile çağrılır',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          feedPosts: const [
            FeedPost(
              id: 'reel-1',
              authorId: 'author-x',
              authorName: 'Başka Yazar',
              reference: '',
              arabic: '',
              meal: 'Bildirilecek içerik',
              topic: '',
              likeCount: 0,
              likedByMe: false,
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

        expect(find.text('Bildir'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.flag_outlined));
        // NOT: `pumpAndSettle()` burada YETERSİZ — reel sayfasındaki sürekli
        // dönen arka plan animasyonu (Ken Burns / mute ikonu) `pumpAndSettle`ın
        // "artık bekleyen kare yok" sinyalini yanlış okumasına yol açıyor ve
        // IconButton'ın InkResponse gecikmesi dolmadan diyalog kontrolüne
        // geçiliyor (bugün düşülen tuzak — bkz. moderation_queue_test.dart'taki
        // SnackBar notu, aynı desen). Sabit küçük pump'lar güvenilir.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Onay diyalogu — yanlışlıkla bildirmeyi engeller.
        expect(find.text('İçeriği bildir'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Bildir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(fake.reportedPosts, ['reel-1']);
      },
    );

    testWidgets(
      'reel aksiyon rayında "Engelle" ulaşılabilir ve onaylanınca '
      'repository.blockUser DOĞRU authorId ile çağrılır',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          feedPosts: const [
            FeedPost(
              id: 'reel-2',
              authorId: 'author-x',
              authorName: 'Başka Yazar',
              reference: '',
              arabic: '',
              meal: 'Engellenecek yazarın içeriği',
              topic: '',
              likeCount: 0,
              likedByMe: false,
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

        expect(find.text('Engelle'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.person_off_outlined));
        // Bkz. yukarıdaki "Bildir" testindeki `pumpAndSettle` notu.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Kullanıcıyı engelle'), findsWidgets);
        await tester.tap(find.widgetWithText(FilledButton, 'Engelle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(fake.blockedUserIds, ['author-x']);
      },
    );
  });

  group('Yorumda Bildir/Engelle — `_CommentTile` "⋯" menüsü', () {
    testWidgets(
      '"⋯" yorum menüsünden Bildir ulaşılabilir ve repository.reportComment '
      'DOĞRU commentId ile çağrılır',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          comments: [
            Comment(
              id: 'comment-1',
              authorId: 'author-y',
              authorName: 'Yorumcu',
              body: 'Bildirilecek yorum',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseGatewayProvider.overrideWithValue(gateway),
              socialRepositoryProvider.overrideWithValue(fake),
            ],
            child: MaterialApp(
              home: Scaffold(body: CommentsSheet(postId: 'post-1')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('comment_menu')), findsOneWidget);
        await tester.tap(find.byKey(const Key('comment_menu')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bildir'));
        await tester.pumpAndSettle();

        expect(find.text('İçeriği bildir'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Bildir'));
        await tester.pumpAndSettle();

        expect(fake.reportedComments, ['comment-1']);
      },
    );

    testWidgets(
      '"⋯" yorum menüsünden "Kullanıcıyı engelle" ulaşılabilir ve '
      'repository.blockUser DOĞRU authorId ile çağrılır',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          comments: [
            Comment(
              id: 'comment-2',
              authorId: 'author-y',
              authorName: 'Yorumcu',
              body: 'Yazarı engellenecek yorum',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseGatewayProvider.overrideWithValue(gateway),
              socialRepositoryProvider.overrideWithValue(fake),
            ],
            child: MaterialApp(
              home: Scaffold(body: CommentsSheet(postId: 'post-1')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('comment_menu')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Kullanıcıyı engelle'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Engelle'));
        await tester.pumpAndSettle();

        expect(fake.blockedUserIds, ['author-y']);
      },
    );
  });

  group(
    'filterBlockedFeedPosts — engellenen yazarın içeriği akıştan GERÇEKTEN elenir',
    () {
      test(
        'engellenen authorId\'ye ait gönderi listeden çıkarılır, diğerleri kalır',
        () {
          const posts = [
            FeedPost(
              id: 'blocked-post',
              authorId: 'blocked-author',
              authorName: 'Engellenen',
              reference: '',
              arabic: '',
              meal: 'Görünmemeli',
              topic: '',
              likeCount: 0,
              likedByMe: false,
            ),
            FeedPost(
              id: 'visible-post',
              authorId: 'ok-author',
              authorName: 'Görünür',
              reference: '',
              arabic: '',
              meal: 'Görünmeli',
              topic: '',
              likeCount: 0,
              likedByMe: false,
            ),
          ];

          final result = filterBlockedFeedPosts(posts, {'blocked-author'});

          expect(result.map((p) => p.id), ['visible-post']);
        },
      );

      testWidgets(
        'engellenen yazarın reel\'i FeedScreen akışında GÖSTERİLMEZ '
        '(repository zaten filtrelenmiş listeyi döndürdüğünde)',
        (tester) async {
          final gateway = _FakeGateway()..signedIn = true;
          // Gerçek `SocialRepository.fetchReels` sunucudan gelen listeyi
          // `filterBlockedFeedPosts` ile süzer (bkz. backend_repositories.dart);
          // burada fake bu SÖZLEŞMEYİ taklit ediyor — yalnız süzülmüş sonucu
          // döndürür, engellenen yazarın içeriği hiç fetchReels() listesinde yok.
          final fake = _FakeSocialRepository(
            feedPosts: filterBlockedFeedPosts(const [
              FeedPost(
                id: 'blocked-post',
                authorId: 'blocked-author',
                authorName: 'Engellenen',
                reference: '',
                arabic: '',
                meal: 'AKIŞTA GÖRÜNMEMELİ',
                topic: '',
                likeCount: 0,
                likedByMe: false,
              ),
              FeedPost(
                id: 'visible-post',
                authorId: 'ok-author',
                authorName: 'Görünür',
                reference: '',
                arabic: '',
                meal: 'Akışta görünmeli',
                topic: '',
                likeCount: 0,
                likedByMe: false,
              ),
            ], {'blocked-author'}),
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

          expect(find.text('Akışta görünmeli'), findsWidgets);
          expect(find.text('AKIŞTA GÖRÜNMEMELİ'), findsNothing);
        },
      );
    },
  );

  group('/blocked-users — liste + Engeli kaldır (Apple Guideline 1.2, madde 4)', () {
    testWidgets(
      'engellenen kullanıcı listelenir ve "Engeli kaldır" onaylanınca '
      'repository.unblockUser DOĞRU userId ile çağrılır',
      (tester) async {
        final gateway = _FakeGateway()..signedIn = true;
        final fake = _FakeSocialRepository(
          blockedUserRows: const [
            {
              'blocked_id': 'u1',
              'profiles': {'display_name': 'Ali Veli'},
            },
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseGatewayProvider.overrideWithValue(gateway),
              socialRepositoryProvider.overrideWithValue(fake),
            ],
            child: const MaterialApp(home: BlockedUsersScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ali Veli'), findsOneWidget);
        await tester.tap(find.byKey(const Key('unblock-u1')));
        await tester.pumpAndSettle();

        // Onay diyalogu — yanlışlıkla engeli kaldırmayı engeller.
        await tester.tap(find.widgetWithText(FilledButton, 'Engeli kaldır'));
        await tester.pumpAndSettle();

        expect(fake.unblockedUserIds, ['u1']);
      },
    );
  });

  group(
    'Ayarlar — "İçerik moderasyonu" satırı yalnız is_admin=true iken görünür',
    () {
      testWidgets(
        'is_admin=false (veya yok) iken "İçerik moderasyonu" satırı '
        'GÖRÜNMEZ; "Engellenen kullanıcılar" satırı her zaman görünür',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();

          // SettingsScreen'in `ListView(children:)`si de (StudioScreen ile
          // aynı sebep — bkz. rights_gate_test.dart notu) viewport'a göre
          // TEMBEL mount olur; "Güvenlik" bölümü listenin epey aşağısında.
          // Yüzeyi tüm içeriği kapsayacak kadar büyütüyoruz.
          await tester.binding.setSurfaceSize(const Size(400, 3000));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                prefsProvider.overrideWithValue(prefs),
                myProfileProvider.overrideWith(
                  (ref) async => {'is_admin': false},
                ),
              ],
              child: const MaterialApp(home: SettingsScreen()),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('İçerik moderasyonu'), findsNothing);
          expect(find.text('Engellenen kullanıcılar'), findsOneWidget);
        },
      );

      testWidgets(
        'is_admin=true iken "İçerik moderasyonu" satırı GÖRÜNÜR',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();

          await tester.binding.setSurfaceSize(const Size(400, 3000));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                prefsProvider.overrideWithValue(prefs),
                myProfileProvider.overrideWith(
                  (ref) async => {'is_admin': true},
                ),
              ],
              child: const MaterialApp(home: SettingsScreen()),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('İçerik moderasyonu'), findsOneWidget);
        },
      );
    },
  );
}
