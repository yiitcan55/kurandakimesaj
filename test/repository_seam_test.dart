import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';

/// Test seam kanıtı: provider-override ile sahte bir ISocialRepository
/// enjekte edilip metotların çağrılabildiğini doğrular. Bu, arayüz seam'inin
/// gerçekten backend olmadan test edilebilirliği sağladığını gösterir.

class _FakeSocialRepository implements ISocialRepository {
  final List<String> createdPosts = [];
  final List<String> reportedPosts = [];
  final List<String> reportedComments = [];
  final Set<String> blockedUsers = {};
  final Map<String, String> postStatuses = {};

  @override
  bool get available => true;

  @override
  Future<List<FeedPost>> fetchReels() async => const [];

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
  }) async {
    createdPosts.add(reference);
  }

  @override
  Future<void> toggleLike(String postId, bool currentlyLiked) async {}

  @override
  Future<void> follow(String userId) async {}

  @override
  Future<List<Comment>> fetchComments(String postId) async => const [];

  @override
  Future<void> addComment(String postId, String body) async {}

  @override
  Future<Set<String>> fetchBlockedUserIds() async => blockedUsers;

  @override
  Future<void> reportPost(String postId) async => reportedPosts.add(postId);

  @override
  Future<void> reportComment(String commentId) async =>
      reportedComments.add(commentId);

  @override
  Future<void> blockUser(String userId) async => blockedUsers.add(userId);

  @override
  Future<void> unblockUser(String userId) async => blockedUsers.remove(userId);

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> deleteComment(String commentId) async {}

  @override
  Future<List<FeedPost>> fetchPendingPosts() async => const [];

  @override
  Future<void> setPostStatus(String postId, String status) async =>
      postStatuses[postId] = status;

  @override
  Future<List<Map<String, dynamic>>> fetchReports() async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async => [
    for (final id in blockedUsers) {'blocked_id': id},
  ];
}

void main() {
  test(
    'ISocialRepository seam: createPost fake üzerinden çağrılabilir',
    () async {
      final fake = _FakeSocialRepository();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final repo = container.read(socialRepositoryProvider);
      await repo.createPost(
        reference: 'Bakara, 155',
        arabic: 'وَبَشِّرِ',
        meal: 'Sabredenleri müjdele',
      );

      expect(fake.createdPosts, ['Bakara, 155']);
    },
  );

  test(
    'UGC güvenliği: rapor/engelle seam ve engellenen yazar filtresi',
    () async {
      final fake = _FakeSocialRepository();
      await fake.reportPost('post-1');
      await fake.reportComment('comment-1');
      await fake.blockUser('blocked-user');

      final posts = [
        const FeedPost(
          id: 'visible-post',
          authorId: 'visible-user',
          authorName: 'Görünür',
          reference: '',
          arabic: '',
          meal: 'Görünür içerik',
          topic: '',
          likeCount: 0,
          likedByMe: false,
        ),
        const FeedPost(
          id: 'blocked-post',
          authorId: 'blocked-user',
          authorName: 'Engellenen',
          reference: '',
          arabic: '',
          meal: 'Gizlenmesi gereken içerik',
          topic: '',
          likeCount: 0,
          likedByMe: false,
        ),
      ];

      expect(fake.reportedPosts, ['post-1']);
      expect(fake.reportedComments, ['comment-1']);
      expect(
        filterBlockedFeedPosts(
          posts,
          await fake.fetchBlockedUserIds(),
        ).map((post) => post.id),
        ['visible-post'],
      );
    },
  );

  test('FeedPost media_url görsel önizlemesine eşlenir', () {
    final post = FeedPost.fromMap({
      'id': 'image-post',
      'author_id': 'author-1',
      'meal': 'Açıklama',
      'media_url': 'https://example.com/image.jpg',
    }, myId: null);

    expect(post.kind, 'still');
    expect(post.thumbnailUrl, 'https://example.com/image.jpg');
  });

  test('FeedPost.status: kolon yoksa approved, pending ise isPending', () {
    // Göç uygulanmamış/SELECT'te kolon yok → eski davranış korunur.
    final legacy = FeedPost.fromMap({'id': 'a', 'meal': ''}, myId: null);
    expect(legacy.status, 'approved');
    expect(legacy.isPending, isFalse);

    final queued = FeedPost.fromMap({
      'id': 'b',
      'meal': '',
      'status': 'pending',
    }, myId: null);
    expect(queued.isPending, isTrue);
  });

  // Gerçek `SocialRepository` (fake DEĞİL): sunucudaki `feed_posts_kind_check`
  // kısıtının istemci tarafı karşılığı — 23514 beklemeden burada patlamalı.
  group('SocialRepository.createPost sözleşmesi: kind yalnız video|still', () {
    test('kind: "ayah" gibi geçersiz bir değer ArgumentError fırlatır', () async {
      final repo = SocialRepository(null);

      await expectLater(
        repo.createPost(reference: '', arabic: '', meal: '', kind: 'ayah'),
        throwsArgumentError,
      );
    });

    test('geçerli kind ("video"/"still") ArgumentError fırlatmaz', () async {
      final repo = SocialRepository(null);

      // İstemci null → sonraki satırda sessizce döner, hata fırlatmaz.
      await expectLater(
        repo.createPost(reference: '', arabic: '', meal: '', kind: 'video'),
        completes,
      );
      await expectLater(
        repo.createPost(reference: '', arabic: '', meal: '', kind: 'still'),
        completes,
      );
    });
  });
}
