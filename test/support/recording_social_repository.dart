import 'dart:typed_data';

import 'package:kurandakimesaj/data/backend_repositories.dart';

/// `createPost`/`uploadPostMedia` çağrılarını kaydeden sahte repository.
class RecordingSocialRepository implements ISocialRepository {
  final List<bool> uploads = []; // isVideo değerleri
  Map<String, Object?>? lastPost;

  /// Son yüklenen baytlar. Yalnız `isVideo` kaydetmek PNG'nin BOŞ, şeffaf veya
  /// yanlış çözünürlükte olmasını testten kaçırıyordu — imza ve IHDR
  /// genişliğini doğrulayabilmek için baytları da tutuyoruz.
  Uint8List? lastBytes;

  @override
  bool get available => true;

  @override
  Future<String> uploadPostMedia(
    Uint8List bytes,
    {required bool isVideo}
  ) async {
    uploads.add(isVideo);
    lastBytes = bytes;
    return 'https://cdn.example.com/media.${isVideo ? 'mp4' : 'png'}';
  }

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
    lastPost = {
      'reference': reference,
      'arabic': arabic,
      'meal': meal,
      'caption': caption,
      'kind': kind,
      'mediaUrl': mediaUrl,
      'videoUrl': videoUrl,
      'templateId': templateId,
      'audioTrackId': audioTrackId,
    };
  }

  @override
  Future<List<FeedPost>> fetchReels() async => const [];

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
  Future<List<FeedPost>> fetchPendingPosts() async => const [];

  @override
  Future<void> setPostStatus(String postId, String status) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchReports() async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async => const [];
}
