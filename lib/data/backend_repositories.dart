import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

/// Supabase istemcisi — başlatılmamışsa null (uygulama backend'siz de çalışır).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

/// Supabase erişimini tek yerde toplayan kapı (dağınık try-catch'i ortadan
/// kaldırır). Tüm ekranlar/servisler ham `Supabase.instance` yerine bunu okur.
class SupabaseGateway {
  const SupabaseGateway(this.client);
  final SupabaseClient? client;

  /// Supabase yapılandırılmış ve başlatılmış mı?
  bool get isAvailable => client != null;

  /// Kullanıcı oturumu açık mı?
  bool get isSignedIn => client?.auth.currentUser != null;
}

final supabaseGatewayProvider = Provider<SupabaseGateway>(
  (ref) => SupabaseGateway(ref.watch(supabaseClientProvider)),
);

/// Oturum açık mı? (backend'e bağlı özellikler bunu kontrol eder)
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(supabaseGatewayProvider).isSignedIn,
);

// ── Modeller ────────────────────────────────────────────────────────────────

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.reference,
    required this.arabic,
    required this.meal,
    required this.topic,
    required this.likeCount,
    required this.likedByMe,
    this.kind = 'ayah',
    this.videoUrl,
    this.thumbnailUrl,
    this.templateId,
    this.commentCount = 0,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String reference;
  final String arabic;
  final String meal;
  final String topic;
  final int likeCount;
  final bool likedByMe;

  /// 'ayah' (ayet kartı / Gönderiler) | 'video' (Reels). Kolon init göçünde var.
  final String kind;

  /// Oynatılabilir video URL'i. Render hattı backend'de hazır olunca dolar;
  /// kolon SELECT'te yoksa null kalır (defansif okuma → çökme yok).
  final String? videoUrl;

  /// Önizleme (poster) görseli URL'i — video başlamadan gösterilebilir.
  final String? thumbnailUrl;

  /// Şablon kimliği (kTemplates id) — videosu olmayan reel'de gradyan fallback.
  final String? templateId;

  /// Yorum sayısı — `comment_count` kolonu göç uygulanmadan SELECT'te yoksa 0.
  final int commentCount;

  /// Reels sekmesi mi? (kind == 'video')
  bool get isVideo => kind == 'video';

  factory FeedPost.fromMap(Map<String, dynamic> m, {required String? myId}) {
    final profile = m['profiles'];
    final likes = (m['likes'] as List?) ?? const [];
    return FeedPost(
      id: m['id'] as String,
      authorId: m['author_id'] as String? ?? '',
      authorName:
          (profile is Map ? profile['display_name'] as String? : null) ??
          'Kullanıcı',
      reference: m['reference'] as String? ?? '',
      arabic: m['arabic'] as String? ?? '',
      meal: m['meal'] as String? ?? '',
      topic: m['topic'] as String? ?? '',
      likeCount: m['like_count'] as int? ?? 0,
      likedByMe:
          myId != null && likes.any((l) => (l as Map)['user_id'] == myId),
      kind: m['kind'] as String? ?? 'ayah',
      // Defansif: bu kolonlar göç uygulanmadan SELECT'te bulunmayabilir → null.
      videoUrl: m['video_url'] as String?,
      thumbnailUrl: m['thumbnail_url'] as String? ?? m['media_url'] as String?,
      templateId: m['template_id'] as String?,
      commentCount: m['comment_count'] as int? ?? 0,
    );
  }
}

/// Bir gönderi/reel yorumu.
class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  factory Comment.fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'];
    return Comment(
      id: m['id'] as String,
      authorId: m['user_id'] as String? ?? '',
      authorName:
          (profile is Map ? profile['display_name'] as String? : null) ??
          'Kullanıcı',
      body: m['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id: m['id'] as String,
    senderId: m['sender_id'] as String? ?? '',
    body: m['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

// ── Profil ──────────────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient? _client;

  Future<Map<String, dynamic>?> myProfile() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return null;
    return await c.from('profiles').select().eq('id', uid).maybeSingle();
  }

  Future<bool> isPro() async =>
      (await myProfile())?['is_pro'] as bool? ?? false;

  Future<void> updateDisplayName(String name) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    await c.from('profiles').update({'display_name': name}).eq('id', uid);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final c = _client;
    if (c == null) return null;
    try {
      return await c
          .from('profiles')
          .select('id, display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<int> getFollowerCount(String userId) async {
    final c = _client;
    if (c == null) return 0;
    try {
      final res = await c
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    final c = _client;
    if (c == null) return 0;
    try {
      final res = await c
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final c = _client;
    if (c == null) return false;
    try {
      final res = await c
          .from('follows')
          .select('follower_id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> follow(String followingId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    try {
      await c.from('follows').insert({
        'follower_id': uid,
        'following_id': followingId,
      });
    } catch (_) {}
  }

  Future<void> unfollow(String followingId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    try {
      await c
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', followingId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final c = _client;
    if (c == null) return [];
    try {
      final res = await c
          .from('feed_posts')
          .select('id, kind, thumbnail_url, caption, created_at')
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}

// ── Sosyal (akış + beğeni + takip) ──────────────────────────────────────────

/// Sosyal akış sözleşmesi — test edilebilirlik seam'i (fake enjekte edilebilir).
abstract interface class ISocialRepository {
  bool get available;

  /// Akışı çeker. [kind] verilirse ('ayah' | 'video') yalnız o tür döner;
  /// null ise tümü (geriye dönük uyum).
  Future<List<FeedPost>> fetchFeed({String? kind});
  Future<void> createPost({
    required String reference,
    required String arabic,
    required String meal,
    String topic,
    String caption,
    String kind,
    String? mediaUrl,
    String? videoUrl,
    String? templateId,
  });
  Future<void> toggleLike(String postId, bool currentlyLiked);
  Future<void> follow(String userId);

  /// Bir gönderinin yorumları (eski→yeni). Tablo yoksa boş liste (graceful).
  Future<List<Comment>> fetchComments(String postId);

  /// Yorum ekle. Tablo yoksa/oturum yoksa sessizce no-op (graceful).
  Future<void> addComment(String postId, String body);

  Future<Set<String>> fetchBlockedUserIds();
  Future<void> reportPost(String postId);
  Future<void> reportComment(String commentId);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
}

/// Sunucudan gelen akışın son güvenlik kapısı. RLS görünürlüğünden bağımsız
/// olarak kullanıcının engellediği yazarlar istemcide gösterilmez.
List<FeedPost> filterBlockedFeedPosts(
  Iterable<FeedPost> posts,
  Set<String> blockedUserIds,
) => posts
    .where((post) => !blockedUserIds.contains(post.authorId))
    .toList(growable: false);

class SocialRepository implements ISocialRepository {
  SocialRepository(this._client);
  final SupabaseClient? _client;

  @override
  bool get available => _client != null && _client.auth.currentUser != null;

  @override
  Future<List<FeedPost>> fetchFeed({String? kind}) async {
    final c = _client;
    if (c == null) return const [];
    final myId = c.auth.currentUser?.id;
    final base = c
        .from('feed_posts')
        .select(
          '*, profiles!feed_posts_author_id_fkey(display_name), likes(user_id)',
        )
        .eq('is_hidden', false);
    // kind verilirse süz; her hâlde sıralı + limitli.
    final filtered = kind == null ? base : base.eq('kind', kind);
    final rows = await filtered.order('created_at', ascending: false).limit(50);
    final posts = (rows as List)
        .map((r) => FeedPost.fromMap(r as Map<String, dynamic>, myId: myId))
        .toList();
    return filterBlockedFeedPosts(posts, await fetchBlockedUserIds());
  }

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
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    // `kind` kolonu init göçünde garanti var. video_url/thumbnail_url/template_id
    // kolonları ek göçle gelir; göç uygulanmamışsa insert'e EKLEME (yoksa hata
    // verir) — yalnız dolu olduklarında ekle. Böylece kod göçten bağımsız çalışır.
    final payload = <String, dynamic>{
      'author_id': uid,
      'kind': kind,
      'reference': reference,
      'arabic': arabic,
      'meal': meal,
      'topic': topic,
      'caption': caption,
    };
    if (mediaUrl != null) payload['media_url'] = mediaUrl;
    if (videoUrl != null) payload['video_url'] = videoUrl;
    if (templateId != null) payload['template_id'] = templateId;
    await c.from('feed_posts').insert(payload);
  }

  @override
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    if (currentlyLiked) {
      // delete idempotent: zaten silinmişse no-op.
      await c.from('likes').delete().match({'post_id': postId, 'user_id': uid});
    } else {
      // upsert: çift dokunmada aynı (post_id,user_id) yeniden eklenince
      // unique-violation çökmez — mevcut satıra düşer (idempotent).
      await c.from('likes').upsert({
        'post_id': postId,
        'user_id': uid,
      }, onConflict: 'post_id,user_id');
    }
  }

  @override
  Future<void> follow(String userId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null || uid == userId) return;
    await c.from('follows').insert({
      'follower_id': uid,
      'following_id': userId,
    });
  }

  @override
  Future<List<Comment>> fetchComments(String postId) async {
    final c = _client;
    if (c == null) return const [];
    try {
      final rows = await c
          .from('comments')
          .select('*, profiles!comments_user_id_fkey(display_name)')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(200);
      final blocked = await fetchBlockedUserIds();
      return (rows as List)
          .map((r) => Comment.fromMap(r as Map<String, dynamic>))
          .where((comment) => !blocked.contains(comment.authorId))
          .toList();
    } catch (_) {
      // Tablo henüz deploy edilmemiş → graceful (follows kalıbı).
      return const [];
    }
  }

  @override
  Future<void> addComment(String postId, String body) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    final text = body.trim();
    if (c == null || uid == null || text.isEmpty) return;
    try {
      await c.from('comments').insert({
        'post_id': postId,
        'user_id': uid,
        'body': text,
      });
    } catch (_) {
      // Tablo yoksa sessizce yut (graceful degradation).
    }
  }

  @override
  Future<Set<String>> fetchBlockedUserIds() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return const {};
    try {
      final rows = await c
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', uid);
      return (rows as List)
          .map((row) => (row as Map<String, dynamic>)['blocked_id'] as String)
          .toSet();
    } catch (_) {
      // Migration deploy edilene kadar akış çalışmaya devam eder.
      return const {};
    }
  }

  @override
  Future<void> reportPost(String postId) => _report('post_id', postId);

  @override
  Future<void> reportComment(String commentId) =>
      _report('comment_id', commentId);

  Future<void> _report(String targetColumn, String targetId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Rapor göndermek için giriş yapmanız gerekiyor.');
    }
    await c.from('reports').insert({
      'reporter_id': uid,
      targetColumn: targetId,
      'reason': 'Topluluk kurallarına aykırı içerik',
    });
  }

  @override
  Future<void> blockUser(String userId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Kullanıcı engellemek için giriş yapmanız gerekiyor.');
    }
    if (uid == userId) throw ArgumentError('Kendinizi engelleyemezsiniz.');
    await c.from('user_blocks').upsert({
      'blocker_id': uid,
      'blocked_id': userId,
    }, onConflict: 'blocker_id,blocked_id');
  }

  @override
  Future<void> unblockUser(String userId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    await c.from('user_blocks').delete().match({
      'blocker_id': uid,
      'blocked_id': userId,
    });
  }
}

// ── Mesajlaşma (Realtime) ────────────────────────────────────────────────────

class MessagesRepository {
  MessagesRepository(this._client);
  final SupabaseClient? _client;

  Future<List<Map<String, dynamic>>> myConversations() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return const [];
    final rows = await c
        .from('conversation_members')
        .select('conversation_id, conversations(id, title, is_group)')
        .eq('user_id', uid);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Bir sohbetin mesaj akışı (Realtime).
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final c = _client;
    if (c == null) return const Stream.empty();
    return c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(ChatMessage.fromMap).toList());
  }

  Future<void> send(String conversationId, String body) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null || body.trim().isEmpty) return;
    await c.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body.trim(),
    });
  }
}

// ── Hatim Halkaları ──────────────────────────────────────────────────────────

class KhatmRepository {
  KhatmRepository(this._client);
  final SupabaseClient? _client;

  Future<List<Map<String, dynamic>>> publicCircles() async {
    final c = _client;
    if (c == null) return const [];
    final rows = await c
        .from('khatm_circles')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Stream<List<Map<String, dynamic>>> watchClaims(String circleId) {
    final c = _client;
    if (c == null) return const Stream.empty();
    return c
        .from('khatm_claims')
        .stream(primaryKey: ['circle_id', 'juz_number'])
        .eq('circle_id', circleId);
  }

  Future<void> claim(String circleId, int juz) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    await c.from('khatm_claims').upsert({
      'circle_id': circleId,
      'juz_number': juz,
      'user_id': uid,
    });
  }
}

// ── Render (Edge Function) ───────────────────────────────────────────────────

/// Sunucu tarafı render işinin durum sözleşmesi. İstemci yalnızca bu durumları
/// bilir; backend `render-status` Edge Function'ı bunları döndürür.
enum RenderStatus { queued, processing, ready, failed }

/// Render sözleşmesi — test edilebilirlik seam'i (fake enjekte edilebilir).
abstract interface class IRenderRepository {
  Future<String?> trigger({
    required String template,
    required String reciter,
    String? reference,
    String? arabic,
    String? meal,
  });
  Future<RenderStatus?> status(String jobId);
}

class RenderRepository implements IRenderRepository {
  RenderRepository(this._client);
  final SupabaseClient? _client;

  /// render-trigger Edge Function'ı çağırır; jobId döner (yoksa null).
  @override
  Future<String?> trigger({
    required String template,
    required String reciter,
    String? reference,
    String? arabic,
    String? meal,
  }) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) return null;
    final res = await c.functions.invoke(
      'render-trigger',
      body: {
        'template': template,
        'reciter': reciter,
        'reference': reference,
        'arabic': arabic,
        'meal': meal,
      },
    );
    final data = res.data;
    if (data is Map && data['jobId'] != null) return data['jobId'].toString();
    return null;
  }

  /// Bir render işinin güncel durumu. `render-status` Edge Function'ını dener;
  /// backend yoksa/erişilemezse `null` döner — dürüst "henüz bilinmiyor".
  // TODO(backend): render-status Edge Function + renders tablosu deploy edilince status() canlanır
  @override
  Future<RenderStatus?> status(String jobId) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) return null;
    try {
      final res = await c.functions.invoke(
        'render-status',
        body: {'jobId': jobId},
      );
      final data = res.data;
      final raw = data is Map ? data['status']?.toString() : null;
      if (raw == null) return null;
      return RenderStatus.values.where((s) => s.name == raw).firstOrNull;
    } catch (_) {
      return null; // backend yok/erişilemez → durum bilinmiyor
    }
  }
}

// ── Ayet Bulucu (Edge Function) ──────────────────────────────────────────────

/// Görsel/bağlantı/videodan ayet tanıma sözleşmesi — test seam'i (fake enjekte edilir).
abstract interface class IAyahFinderRepository {
  Future<AyahFinderResult> findFromImage(Uint8List bytes, {String mime});
  Future<AyahFinderResult> findFromUrl(String url);

  /// Cihazdaki bir Kur'an videosundan okunan ayetleri bulur (ses hattı).
  ///
  /// Video kullanıcının KENDİ cihazından gelir (galeri / paylaş menüsü);
  /// uygulama hiçbir platformdan video indirmez (App Store 5.2.3).
  Future<AyahFinderResult> findFromVideo(String filePath);
}

/// Ses hattı kapsamı: kısa video. Bundan büyüğü sunucuya HİÇ yüklenmez —
/// Groq'un free tier dosya limiti (25 MB) altında güvenli pay bırakır ve
/// mobil veriyle boşuna yükleme yapılmasını engeller. `ayah-audio` bucket'ında
/// da aynı sınır zorlanır (savunma derinliği).
const int kAyahVideoMaxBytes = 20 * 1024 * 1024;

class AyahFinderRepository implements IAyahFinderRepository {
  AyahFinderRepository(this._client);
  final SupabaseClient? _client;

  static const _bucket = 'ayah-audio';

  Future<AyahFinderResult> _invoke(
    String function,
    Map<String, dynamic> body,
  ) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) {
      // Bu özellik oturum + internet gerektirir — dürüst hata.
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'auth_required',
      );
    }
    try {
      final res = await c.functions.invoke(function, body: body);
      final data = res.data;
      if (data is Map) {
        return AyahFinderResult.fromJson(data.cast<String, dynamic>());
      }
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'bad_response',
      );
    } on FunctionException catch (e) {
      // Edge Function hata gövdesi de sözleşmeye uyar (errorCode taşır) →
      // "rate_limited"/"asr_failed" gibi kodlar kullanıcıya doğru mesajla döner.
      final details = e.details;
      if (details is Map) {
        return AyahFinderResult.fromJson(details.cast<String, dynamic>());
      }
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'network',
      );
    } catch (_) {
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'network',
      );
    }
  }

  @override
  Future<AyahFinderResult> findFromImage(
    Uint8List bytes, {
    String mime = 'image/jpeg',
  }) {
    return _invoke('ayah-finder', {
      'imageBase64': 'data:$mime;base64,${base64Encode(bytes)}',
    });
  }

  @override
  Future<AyahFinderResult> findFromUrl(String url) {
    return _invoke('ayah-finder', {'postUrl': url.trim()});
  }

  @override
  Future<AyahFinderResult> findFromVideo(String filePath) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'auth_required',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'video_missing',
      );
    }
    // Boyut ön kontrolü — sınırı aşan video YÜKLENMEZ (kota + veri israfı).
    if (await file.length() > kAyahVideoMaxBytes) {
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'file_too_large',
      );
    }

    // Yol '<uid>/...' olmalı: bucket RLS'i ve Edge Function'daki sahiplik
    // doğrulaması bunu şart koşar.
    final ext = _extOf(filePath);
    final objectPath =
        '$uid/${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}$ext';
    try {
      await c.storage.from(_bucket).upload(objectPath, file);
    } catch (_) {
      return const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'upload_failed',
      );
    }

    // Edge Function işi bitince objeyi kendisi siler (gizlilik).
    return _invoke('ayah-finder-audio', {'path': objectPath});
  }

  String _extOf(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i == path.length - 1) return '.mp4';
    final ext = path.substring(i).toLowerCase();
    return ext.length <= 5 ? ext : '.mp4';
  }
}

// ── Bulut senkronu (offline→online) ──────────────────────────────────────────

class SyncRepository {
  SyncRepository(this._client);
  final SupabaseClient? _client;

  Future<void> pushDhikr(String dateIso, String key, int count) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    await c.from('cloud_dhikr').upsert({
      'user_id': uid,
      'date_iso': dateIso,
      'dhikr_key': key,
      'count': count,
    });
  }

  Future<void> pushCollection({
    required String reference,
    required String arabic,
    required String meal,
    String? note,
  }) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return;
    await c.from('cloud_collections').insert({
      'user_id': uid,
      'reference': reference,
      'arabic': arabic,
      'meal': meal,
      'note': note,
    });
  }
}

// ── Provider'lar ──────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);
final socialRepositoryProvider = Provider<ISocialRepository>(
  (ref) => SocialRepository(ref.watch(supabaseClientProvider)),
);
final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(ref.watch(supabaseClientProvider)),
);
final khatmRepositoryProvider = Provider<KhatmRepository>(
  (ref) => KhatmRepository(ref.watch(supabaseClientProvider)),
);
final renderRepositoryProvider = Provider<IRenderRepository>(
  (ref) => RenderRepository(ref.watch(supabaseClientProvider)),
);
final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(supabaseClientProvider)),
);
final ayahFinderRepositoryProvider = Provider<IAyahFinderRepository>(
  (ref) => AyahFinderRepository(ref.watch(supabaseClientProvider)),
);

/// Bulut "Gönderiler" akışı (kind='ayah'). Oturum açıksa Supabase, değilse boş
/// → istemci yerel küratörlük içeriğine düşer.
///
/// autoDispose DEĞİL: pill toggle ile Gönderiler↔Reels arasında geçince sekme
/// dinleyicisi kalmıyor; autoDispose olsa provider yok edilip geri dönüşte
/// sıfırdan fetch + spinner olurdu. Önbellek korunur; `ref.invalidate(...)`
/// (pull-to-refresh + beğeni sonrası) hâlâ yeniden fetch tetikler.
final cloudPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchFeed(kind: 'ayah');
});

/// Bulut "Reels" akışı (kind='video'). Dikey video gönderileri.
/// autoDispose DEĞİL — bkz. [cloudPostsProvider] açıklaması.
final cloudReelsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchFeed(kind: 'video');
});

/// Geriye dönük uyum: eski `cloudFeedProvider` artık "Gönderiler"e yönlenir.
@Deprecated(
  'cloudPostsProvider (Gönderiler) veya cloudReelsProvider (Reels) kullan',
)
final cloudFeedProvider = cloudPostsProvider;
