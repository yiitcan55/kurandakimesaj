import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';

/// Test seam kanıtı: provider-override ile sahte bir IRenderRepository (ve
/// ISocialRepository) enjekte edilip metotların çağrılabildiğini doğrular.
/// Bu, arayüz seam'inin gerçekten backend olmadan test edilebilirliği
/// sağladığını gösterir.

class _FakeRenderRepository implements IRenderRepository {
  String? lastTriggeredTemplate;
  RenderStatus statusToReturn = RenderStatus.ready;

  @override
  Future<String?> trigger({
    required String template,
    required String reciter,
    String? reference,
    String? arabic,
    String? meal,
  }) async {
    lastTriggeredTemplate = template;
    return 'fake-job-1';
  }

  @override
  Future<RenderStatus?> status(String jobId) async => statusToReturn;
}

class _FakeSocialRepository implements ISocialRepository {
  final List<String> createdPosts = [];
  final List<String> reportedPosts = [];
  final List<String> reportedComments = [];
  final Set<String> blockedUsers = {};

  @override
  bool get available => true;

  @override
  Future<List<FeedPost>> fetchFeed({String? kind}) async => const [];

  @override
  Future<void> createPost({
    required String reference,
    required String arabic,
    required String meal,
    String topic = '',
    String caption = '',
    String kind = 'ayah',
    String? mediaUrl,
    String? videoUrl,
    String? templateId,
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
}

void main() {
  test(
    'IRenderRepository seam: fake provider-override ile enjekte edilebilir',
    () async {
      final fake = _FakeRenderRepository();
      final container = ProviderContainer(
        overrides: [renderRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final repo = container.read(renderRepositoryProvider);
      final jobId = await repo.trigger(
        template: 'Zümrüt Huzur',
        reciter: 'Alafasy',
      );

      expect(jobId, 'fake-job-1');
      expect(fake.lastTriggeredTemplate, 'Zümrüt Huzur');
      expect(await repo.status(jobId!), RenderStatus.ready);
    },
  );

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

    expect(post.kind, 'ayah');
    expect(post.thumbnailUrl, 'https://example.com/image.jpg');
  });
}
