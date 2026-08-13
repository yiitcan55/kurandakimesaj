import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

/// Auth olay akışı — bu akış SADECE bir TETİKLEYİCİDİR, değer kaynağı değildir.
/// `onAuthStateChange` token yenileme ağ hatalarını da olay olarak yayar; bool'u
/// `AsyncValue`'dan türetseydik ilk frame'de `AsyncLoading` (yanlış `false`) ve
/// yenileme hatasında `AsyncError` kullanıcıyı bir anlık "çıkış yapmış"
/// gösterirdi. Supabase yoksa boş akış → provider error state'e düşmez.
///
/// `BehaviorSubject` tabanlı olduğu için geç abone olan son olayı (startup'ta
/// `initialSession`) replay eder; kaçırılan olay penceresi yoktur.
final authChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();
});

/// Oturum açık mı? (backend'e bağlı özellikler bunu kontrol eder)
///
/// Değer HER ZAMAN canlı `currentUser`'dan okunur; [authChangesProvider]
/// yalnızca yeniden hesaplamayı tetiklemek için izlenir. Bu izleme olmadan
/// `Provider<bool>` ilk okumadaki sonucu (çıkışta `false`) süreç boyunca
/// cache'lerdi — `IndexedStack` içindeki sekmeler yeniden kurulmadığı için
/// giriş yapıldığı halde ekranların "Misafir" kalmasının kök nedeni buydu.
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authChangesProvider);
  return ref.watch(supabaseGatewayProvider).isSignedIn;
});

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
    this.kind = 'still',
    this.videoUrl,
    this.thumbnailUrl,
    this.templateId,
    this.commentCount = 0,
    this.status = 'approved',
    this.caption = '',
    this.audioUrl,
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

  /// Medya türü: 'video' (kullanıcının mp4'ü) | 'still' (stüdyo üretimi PNG).
  /// Reels tek akış olduğu için bu artık sekme değil, yalnız oynatma biçimidir.
  /// (Göç: 20260725130000_reels_kind.sql — eski 'ayah' kayıtları 'still' oldu.)
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

  /// Moderasyon durumu: 'pending' | 'approved' | 'rejected'.
  /// Kolon moderasyon göçüyle gelir; SELECT'te yoksa 'approved' (eski davranış).
  final String status;

  /// Kullanıcının yazdığı açıklama. `createPost` bunu HER ZAMAN yazıyordu ama
  /// `fromMap` hiç okumuyordu — ekranda görünen aslında `meal` idi. Bugün iki
  /// yayın yolu da aynı metni ikisine birden yazdığı için **davranış
  /// değişmiyor**; ayrıştıkları an doğru alan gösterilmiş olacak.
  final String caption;

  /// Küratörlü arka plan sesinin URL'i (`feed_audio_tracks` embed'inden).
  /// Kolon/göç yoksa null — istemci göçten bağımsız çalışır.
  final String? audioUrl;

  /// Oynatılabilir mp4 mü? Değilse 'still' — stüdyo görseli olarak render edilir.
  bool get isVideo => kind == 'video';

  /// Yönetici onayı bekliyor mu? (yalnız yazarına görünür — RLS böyle kısıtlar)
  bool get isPending => status == 'pending';

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
      kind: m['kind'] as String? ?? 'still',
      // Defansif: bu kolonlar göç uygulanmadan SELECT'te bulunmayabilir → null.
      videoUrl: m['video_url'] as String?,
      thumbnailUrl: m['thumbnail_url'] as String? ?? m['media_url'] as String?,
      templateId: m['template_id'] as String?,
      commentCount: m['comment_count'] as int? ?? 0,
      status: m['status'] as String? ?? 'approved',
      caption: m['caption'] as String? ?? '',
      // `feed_audio_tracks(url, title)` embed'i; göç uygulanmamışsa yok.
      audioUrl: (m['feed_audio_tracks'] as Map?)?['url'] as String?,
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

  /// Profil ızgarasındaki gönderiler — en yeni önce.
  ///
  /// `select('*')` + [FeedPost.fromMap]: `thumbnail_url` kolonu HİÇ yazılmıyor
  /// ([SupabaseSocialRepository.createPost] payload'ı yalnız `media_url` /
  /// `video_url` yazar), poster URL'i `media_url`'de duruyor. Fallback'i burada
  /// tekrarlamak yerine [FeedPost.fromMap]'ten geçiyoruz — Reels tarafı da aynı
  /// fonksiyondan besleniyor, düzeltme tek yerde kalıyor.
  ///
  /// Hata YUTULMAZ (moderasyon dörtlüsüyle aynı sözleşme): RLS reddi veya ağ
  /// hatası "Henüz gönderi yok" diye görünmemeli — çağıran ekran hatayı
  /// ayırt edip "Tekrar dene" gösterebilmeli.
  Future<List<FeedPost>> getUserPosts(String userId) async {
    final c = _client;
    if (c == null) return const [];
    final rows = await c
        .from('feed_posts')
        .select('*')
        .eq('author_id', userId)
        .order('created_at', ascending: false)
        .limit(30);
    // myId: null — ızgarada beğeni durumu gösterilmiyor, `likes` embed'i de
    // çekilmiyor; `fromMap` ikisinin yokluğunda defansif.
    return (rows as List)
        .map((r) => FeedPost.fromMap(r as Map<String, dynamic>, myId: null))
        .toList(growable: false);
  }
}

// ── Sosyal (akış + beğeni + takip) ──────────────────────────────────────────

/// Sosyal akış sözleşmesi — test edilebilirlik seam'i (fake enjekte edilebilir).
abstract interface class ISocialRepository {
  bool get available;

  /// Tek akış: Reels. 'video' de 'still' de aynı listede döner — `kind` artık
  /// sekme değil oynatma biçimi olduğu için tür filtresi YOK.
  ///
  /// Durum filtresi de YOK: RLS zaten başkalarının 'pending' içeriğini kapatır;
  /// kullanıcının KENDİ bekleyen gönderisi bilerek akışta kalır ("inceleniyor"
  /// rozetiyle) — aksi hâlde paylaştığı içerik kaybolmuş sanılırdı.
  /// Ayrımı ekran [FeedPost.isPending] üzerinden yapar.
  Future<List<FeedPost>> fetchReels();

  /// Gönderi medyasını `post-media` bucket'ına yükler ve genel URL'ini döner.
  ///
  /// İKİ yayın yolu da (CreatePostSheet + StudioScreen) buradan geçer: yükleme
  /// mantığı ekranlarda kopyalanırsa boyut kapısı/yol şeması/içerik tipi
  /// zamanla ayrışır. [isVideo] yalnız uzantı + content-type seçer; `kind`
  /// kararını çağıran verir.
  ///
  /// Hata YUTMAZ — çağıran kullanıcıya mesaj gösterebilsin diye [StateError]
  /// veya depolama istisnası yayılır.
  Future<String> uploadPostMedia(Uint8List bytes, {required bool isVideo});

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
    String? audioTrackId,
  });
  Future<void> toggleLike(String postId, bool currentlyLiked);
  Future<void> follow(String userId);

  /// Bir gönderinin yorumları (eski→yeni). Tablo yoksa boş liste (graceful).
  Future<List<Comment>> fetchComments(String postId);

  /// Yorum ekle. Tablo yoksa/oturum yoksa sessizce no-op (graceful).
  Future<void> addComment(String postId, String body);

  /// Kullanıcının KENDİ gönderisini siler (RLS: `feed_delete_own`).
  /// Hata YUTMAZ — başkasının içeriğinde RLS reddi çağırana yayılır.
  Future<void> deletePost(String postId);

  /// Yorum siler. Yetki kararı sunucudadır: kendi yorumu için
  /// `comments_delete_own`, yöneticinin BAŞKASININ yorumu için
  /// `comments_delete_admin` (App Store Guideline 1.2 — şikâyet edilen yoruma
  /// aksiyon alınabilmeli). Hata YUTMAZ: yetkisiz/bulunamayan silme çağırana
  /// gösterilebilir bir [StateError] olarak yayılır.
  Future<void> deleteComment(String commentId);

  Future<Set<String>> fetchBlockedUserIds();
  Future<void> reportPost(String postId);
  Future<void> reportComment(String commentId);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);

  // ── Moderasyon (yönetici) ─────────────────────────────────────────────────
  // Bu dörtlü hata YUTMAZ: RLS/trigger reddi veya ağ hatası çağırana yayılır ki
  // ekran anlamlı bir mesaj gösterebilsin (bkz. `_report` kalıbı).

  /// Onay bekleyen gönderiler — en eski önce (kuyruk mantığı).
  /// Yalnız yönetici satır görür; yetkisiz çağrıda liste boş döner.
  Future<List<FeedPost>> fetchPendingPosts();

  /// Gönderinin moderasyon durumunu değiştirir ('approved' | 'rejected' |
  /// 'pending'). Yönetici olmayan çağrıda sunucu tetikleyicisi reddeder.
  Future<void> setPostStatus(String postId, String status);

  /// Şikâyet kuyruğu — raporlanan gönderi/yorum ve şikâyetçi adıyla birlikte.
  Future<List<Map<String, dynamic>>> fetchReports();

  /// Kullanıcının engellediği kişiler — görüntülenebilir ad/avatarla birlikte.
  /// (`fetchBlockedUserIds` yalnız filtreleme için id döner.)
  Future<List<Map<String, dynamic>>> fetchBlockedUsers();
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
  Future<List<FeedPost>> fetchReels() async {
    final c = _client;
    if (c == null) return const [];
    final myId = c.auth.currentUser?.id;
    final rows = await c
        .from('feed_posts')
        .select(
          '*, profiles!feed_posts_author_id_fkey(display_name), '
          'likes(user_id), feed_audio_tracks(url, title)',
        )
        .eq('is_hidden', false)
        .order('created_at', ascending: false)
        .limit(50);
    final posts = (rows as List)
        .map((r) => FeedPost.fromMap(r as Map<String, dynamic>, myId: myId))
        .toList();
    return filterBlockedFeedPosts(posts, await fetchBlockedUserIds());
  }

  static const _postMediaBucket = 'post-media';

  @override
  Future<String> uploadPostMedia(
    Uint8List bytes, {
    required bool isVideo,
  }) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Yüklemek için giriş yapmanız gerekiyor.');
    }
    // Boyut kapısı: seçim ekranındaki kontrolün son savunması. Yükleme
    // yolları çoğaldıkça (video seçimi, stüdyo PNG'si) kural TEK yerde
    // dursun — yoksa yeni bir çağıran sınırı sessizce atlar.
    if (bytes.lengthInBytes > kAyahVideoMaxBytes) {
      throw StateError('Dosya çok büyük (en fazla 20 MB).');
    }
    // Yol '<uid>/...' olmalı: bucket RLS'i sahiplik için bunu şart koşar.
    final path =
        '$uid/${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'png'}';
    await c.storage
        .from(_postMediaBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: isVideo ? 'video/mp4' : 'image/png',
          ),
        );
    return c.storage.from(_postMediaBucket).getPublicUrl(path);
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
    // Sunucudaki feed_posts_kind_check'in istemci karşılığı. Sessizce
    // düzeltmiyoruz: geçersiz değer çağıranın hatasıdır, 23514'ü beklemeden
    // burada patlasın.
    if (kind != 'video' && kind != 'still') {
      throw ArgumentError.value(kind, 'kind', "'video' veya 'still' olmalı");
    }
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
    // Mevcut opsiyonel-kolon kalıbı: göç uygulanmamışsa insert'e HİÇ ekleme
    // (yoksa "column does not exist" ile patlar).
    if (audioTrackId != null) payload['audio_track_id'] = audioTrackId;
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
  Future<void> deletePost(String postId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Silmek için giriş yapmanız gerekiyor.');
    }
    // `author_id` eşleşmesi RLS'in istemci karşılığı: yanlış id ile çağrıldığında
    // sessizce 0 satır silmek yerine sunucu politikası devrede kalsın diye
    // filtreyi biz de koyuyoruz (savunma derinliği).
    await c.from('feed_posts').delete().match({'id': postId, 'author_id': uid});
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Silmek için giriş yapmanız gerekiyor.');
    }
    // `user_id` filtresi BİLEREK yok: yetkiyi RLS verir (`comments_delete_own`
    // VEYA `comments_delete_admin`). İstemci filtresi yöneticinin şikâyet
    // edilen yorumu kaldırmasını engellerdi.
    // `select()` ile silinen satırı geri istiyoruz: RLS reddi hata değil "0
    // satır"dır — dönüş boşsa sessiz başarı yerine dürüst hata fırlatırız.
    final deleted = await c
        .from('comments')
        .delete()
        .eq('id', commentId)
        .select('id');
    if (deleted.isEmpty) {
      throw StateError(
        'Yorum silinemedi: yalnızca kendi yorumunuzu, yönetici olarak da '
        'başkasının yorumunu silebilirsiniz.',
      );
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
    if (c == null || uid == null) {
      // Artık kullanıcı eylemi (engellenenler listesindeki "Engeli kaldır") →
      // sessiz no-op yerine dürüst hata; ekran mesaj gösterebilsin.
      throw StateError('Engeli kaldırmak için giriş yapmanız gerekiyor.');
    }
    await c.from('user_blocks').delete().match({
      'blocker_id': uid,
      'blocked_id': userId,
    });
  }

  // ── Moderasyon ─────────────────────────────────────────────────────────────

  @override
  Future<List<FeedPost>> fetchPendingPosts() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Moderasyon kuyruğu için giriş yapmanız gerekiyor.');
    }
    final rows = await c
        .from('feed_posts')
        .select(
          '*, profiles!feed_posts_author_id_fkey(display_name), likes(user_id)',
        )
        .eq('status', 'pending')
        // Kuyruk: en uzun bekleyen önce.
        .order('created_at', ascending: true)
        .limit(50);
    return (rows as List)
        .map((r) => FeedPost.fromMap(r as Map<String, dynamic>, myId: uid))
        .toList(growable: false);
  }

  @override
  Future<void> setPostStatus(String postId, String status) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Bu işlem için giriş yapmanız gerekiyor.');
    }
    if (status != 'approved' && status != 'rejected' && status != 'pending') {
      throw ArgumentError('Geçersiz içerik durumu: $status');
    }
    try {
      await c.from('feed_posts').update({'status': status}).eq('id', postId);
    } on PostgrestException catch (e) {
      // feed_posts_moderation_guard tetikleyicisi 42501 (→ HTTP 403) atar.
      // Yutmuyoruz; yalnız kullanıcıya gösterilebilir Türkçeye çeviriyoruz.
      if (e.code == '42501') {
        throw StateError('İçerik durumunu yalnızca yönetici değiştirebilir.');
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReports() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Şikâyet kuyruğu için giriş yapmanız gerekiyor.');
    }
    final rows = await c
        .from('reports')
        .select(
          '*, profiles!reports_reporter_id_fkey(display_name), '
          'feed_posts(id, kind, reference, meal, caption, thumbnail_url, '
          'status, author_id), '
          // Yorum yazarı da gömülü gelir: yönetici kimin yazdığını görmeden
          // silme kararı veremez.
          'comments(id, body, user_id, '
          'profiles!comments_user_id_fkey(display_name))',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) {
      throw StateError('Engellenenler listesi için giriş yapmanız gerekiyor.');
    }
    final rows = await c
        .from('user_blocks')
        .select(
          'blocked_id, created_at, '
          'profiles!user_blocks_blocked_id_fkey(display_name, avatar_url)',
        )
        .eq('blocker_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

// ── Mesajlaşma (Realtime) ────────────────────────────────────────────────────

class MessagesRepository {
  MessagesRepository(this._client);
  final SupabaseClient? _client;

  /// Sohbet listesi. 1:1 sohbetlerde başlık KARŞI TARAFIN adıdır.
  ///
  /// `conversations.title` 1:1'de kullanılamaz: tek kolon, iki taraf — her
  /// ikisine de aynı başlığı gösterirdi. `.eq('user_id', uid)` filtresi
  /// BİLEREK yok: `cmembers_select_self_conv` politikası zaten yalnız benim
  /// üye olduğum sohbetlerin satırlarını görünür kılıyor, dolayısıyla
  /// filtresiz sorgu tam olarak O sohbetlerin tüm üyelerini verir.
  Future<List<Map<String, dynamic>>> myConversations() async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null) return const [];
    final rows = await c
        .from('conversation_members')
        .select(
          'conversation_id, user_id, '
          'conversations(id, title, is_group), '
          'profiles(display_name, avatar_url)',
        );
    return resolveConversationTitles(
      (rows as List).cast<Map<String, dynamic>>(),
      uid,
    );
  }

  /// Profilden 1:1 sohbet aç — varsa mevcudu döndürür, yoksa oluşturur.
  ///
  /// **RPC YAZILMADI**: mevcut politikalar bunu zaten mümkün kılıyor
  /// (`conv_insert_own` + `cmembers_insert`). İki tuzak var:
  ///
  /// 1. **Sıra zorunlu.** `cmembers_insert` iki kollu:
  ///    `auth.uid() = user_id OR is_conversation_member(conversation_id, auth.uid())`.
  ///    Önce KENDİ üyeliğimi eklerim (birinci kol), ancak ondan sonra ikinci
  ///    kol karşı tarafı eklememe izin verir. Tek çağrıda çok satırlı insert
  ///    yapılmaz: ikinci satırın kontrolü birinciyi aynı komut içinde görür mü
  ///    garanti değil.
  /// 2. **Id istemcide üretilir.** Insert'ten sonra satırı `.select()` ile geri
  ///    okumak İMKÂNSIZ: `conv_select_member` henüz üye olmadığım için 0 satır
  ///    döner — hata değil, sessiz boş sonuç.
  Future<String?> openDirectConversation(String otherId) async {
    final c = _client;
    final uid = c?.auth.currentUser?.id;
    if (c == null || uid == null || otherId.isEmpty || otherId == uid) {
      return null;
    }

    // Tekilleştirme tek sorguyla: `cmembers_select_self_conv` "yalnız benim
    // üye olduğum sohbetler" diyor → karşı tarafın üyeliklerini sorgulamak tam
    // olarak İKİMİZİN de üye olduğu sohbetleri verir.
    final existing = await c
        .from('conversation_members')
        .select('conversation_id, conversations(is_group)')
        .eq('user_id', otherId);
    for (final r in (existing as List).cast<Map<String, dynamic>>()) {
      final conv = r['conversations'];
      if (conv is Map && conv['is_group'] == false) {
        return r['conversation_id'] as String;
      }
    }

    final convId = const Uuid().v4();
    await c.from('conversations').insert({
      'id': convId,
      'is_group': false,
      'created_by': uid,
    });
    await c.from('conversation_members').insert({
      'conversation_id': convId,
      'user_id': uid,
    });
    await c.from('conversation_members').insert({
      'conversation_id': convId,
      'user_id': otherId,
    });
    return convId;
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

/// Üyelik satırlarını sohbet başına tekilleştirir ve 1:1 sohbetlerde başlığı
/// KARŞI TARAFIN adıyla değiştirir.
///
/// Ayrı ve saf bir fonksiyon: kural ("benim olmayan üyelik satırındaki profil
/// adı başlıktır") sessizce yanlış olabilecek tek yer burası ve Supabase
/// istemcisi olmadan doğrulanabilmesi gerekiyor.
@visibleForTesting
List<Map<String, dynamic>> resolveConversationTitles(
  List<Map<String, dynamic>> rows,
  String myId,
) {
  final byConv = <String, Map<String, dynamic>>{};
  for (final r in rows) {
    final convId = r['conversation_id'] as String?;
    final conv = (r['conversations'] as Map?)?.cast<String, dynamic>();
    if (convId == null || conv == null) continue;
    final entry = byConv.putIfAbsent(
      convId,
      () => <String, dynamic>{
        'conversation_id': convId,
        'conversations': Map<String, dynamic>.from(conv),
      },
    );
    // Grup sohbetinde `conversations.title` zaten anlamlı — dokunma.
    if (r['user_id'] == myId || conv['is_group'] == true) continue;
    final p = (r['profiles'] as Map?)?.cast<String, dynamic>();
    final name = p?['display_name'] as String?;
    if (name != null && name.isNotEmpty) {
      (entry['conversations'] as Map)['title'] = name;
    }
    entry['avatar_url'] = p?['avatar_url'];
  }
  return byConv.values.toList(growable: false);
}

/// Küratörlü arka plan müziği parçası. Kullanıcı YAZAMAZ — tabloya yalnız
/// service_role ekler (20260803120000_reel_audio.sql), telif güvencesi
/// uygulamada değil yabancı anahtarda durur.
class ReelAudioTrack {
  const ReelAudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
  });

  final String id;
  final String title;
  final String artist;
  final String url;

  factory ReelAudioTrack.fromMap(Map<String, dynamic> m) => ReelAudioTrack(
    id: m['id'] as String,
    title: m['title'] as String? ?? '',
    artist: m['artist'] as String? ?? '',
    url: m['url'] as String? ?? '',
  );
}

/// Küratörlü müzik listesi. Göç uygulanmamışsa boş döner — stüdyodaki "Müzik"
/// şeridi sessizce gizlenir, ekran çökmez.
final reelAudioTracksProvider = FutureProvider<List<ReelAudioTrack>>((ref) async {
  final c = ref.watch(supabaseClientProvider);
  if (c == null) return const [];
  try {
    final rows = await c
        .from('feed_audio_tracks')
        .select('id, title, artist, url')
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => ReelAudioTrack.fromMap(r as Map<String, dynamic>))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
});

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

/// Görsel hattı kapsamı. `supabase/functions/ayah-finder/link_resolver.ts`
/// içindeki `_MAX_IMAGE_BYTES` ile AYNI olmalı (10 MB) — farklı olurlarsa biri
/// diğerini boşa çıkarır: küçük olan sınır zaten devreye girer, büyük olan
/// yalnızca kullanıcıyı boşuna bekletir.
const int kAyahImageMaxBytes = 10 * 1024 * 1024;

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
    // Boyut ön kontrolü — base64'e ÇEVİRMEDEN önce: kodlama baytları ~1.33x
    // şişirir, sonra bakmak belleği zaten harcamış olur.
    if (bytes.lengthInBytes > kAyahImageMaxBytes) {
      return Future.value(
        const AyahFinderResult(
          status: AyahFinderStatus.error,
          errorCode: 'file_too_large',
        ),
      );
    }
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
final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(supabaseClientProvider)),
);
final ayahFinderRepositoryProvider = Provider<IAyahFinderRepository>(
  (ref) => AyahFinderRepository(ref.watch(supabaseClientProvider)),
);

/// Bulut Reels akışı — topluluğun TEK akışı ('video' + 'still' birlikte).
/// Oturum açıksa Supabase, değilse boş → istemci yerel küratörlük içeriğine düşer.
///
/// autoDispose DEĞİL: sekme değişiminde dinleyici kalmıyor; autoDispose olsa
/// provider yok edilip geri dönüşte sıfırdan fetch + spinner olurdu. Önbellek
/// korunur; `ref.invalidate(...)` (pull-to-refresh + beğeni sonrası) hâlâ
/// yeniden fetch tetikler.
/// [isSignedInProvider] izlenir: `repo.available` canlı `currentUser`'a bakar
/// ama bu provider autoDispose değil — izleme olmadan çıkışta üretilen boş liste
/// (veya girişte üretilen akış) sonsuza dek cache'de kalırdı.
final cloudReelsProvider = FutureProvider<List<FeedPost>>((ref) async {
  ref.watch(isSignedInProvider);
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchReels();
});

/// Onay bekleyen gönderiler (yönetici moderasyon kuyruğu).
/// [isSignedInProvider] izlenir — bkz. [cloudReelsProvider] açıklaması.
final pendingPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  ref.watch(isSignedInProvider);
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchPendingPosts();
});

/// Şikâyet kuyruğu (yönetici). Satırlar ham map — raporlanan gönderi/yorum
/// `feed_posts` / `comments` anahtarlarında gömülü gelir.
final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(isSignedInProvider);
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchReports();
});

/// Kullanıcının engellediği kişiler (Ayarlar → Engellenen Kullanıcılar).
final blockedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(isSignedInProvider);
  final repo = ref.watch(socialRepositoryProvider);
  if (!repo.available) return const [];
  return repo.fetchBlockedUsers();
});
