import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../data/backend_repositories.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../quran/quran_screens.dart';
import '../studio/studio_screens.dart';

enum _ModerationAction { report, block, delete }

Future<bool> _confirmModeration(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

Future<void> _reportContent(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required bool isComment,
}) async {
  final confirmed = await _confirmModeration(
    context,
    title: 'İçeriği bildir',
    message:
        'Bu içeriği topluluk kurallarına aykırı olduğu için bildirmek istiyor musunuz?',
    confirmLabel: 'Bildir',
  );
  if (!confirmed || !context.mounted) return;
  try {
    final repo = ref.read(socialRepositoryProvider);
    if (isComment) {
      await repo.reportComment(targetId);
    } else {
      await repo.reportPost(targetId);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildiriminiz alındı. Teşekkür ederiz.')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim gönderilemedi. Lütfen tekrar deneyin.'),
      ),
    );
  }
}

Future<bool> _blockAuthor(
  BuildContext context,
  WidgetRef ref,
  String authorId,
) async {
  final confirmed = await _confirmModeration(
    context,
    title: 'Kullanıcıyı engelle',
    message:
        'Bu kullanıcının gönderileri ve yorumları artık size gösterilmeyecek.',
    confirmLabel: 'Engelle',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(socialRepositoryProvider).blockUser(authorId);
    ref.invalidate(cloudReelsProvider);
    if (!context.mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kullanıcı engellenemedi. Lütfen tekrar deneyin.'),
      ),
    );
    return false;
  }
}

/// İçerik seçenekleri menüsü. Başkasının içeriğinde Bildir/Engelle, kendi
/// içeriğinde Sil görünür — üçü de bağımsız opsiyoneldir; hiçbiri
/// verilmezse çağıran menüyü hiç çizmez.
class _ModerationMenuButton extends StatelessWidget {
  const _ModerationMenuButton({
    super.key,
    this.onReport,
    this.onBlock,
    this.onDelete,
  });

  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ModerationAction>(
      tooltip: 'İçerik seçenekleri',
      icon: Icon(Icons.more_vert_rounded, color: AppColors.muted),
      onSelected: (action) {
        switch (action) {
          case _ModerationAction.report:
            onReport?.call();
          case _ModerationAction.block:
            onBlock?.call();
          case _ModerationAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (_) => [
        if (onReport != null)
          const PopupMenuItem(
            value: _ModerationAction.report,
            child: ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Bildir'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onBlock != null)
          const PopupMenuItem(
            value: _ModerationAction.block,
            child: ListTile(
              leading: Icon(Icons.person_off_outlined),
              title: Text('Kullanıcıyı engelle'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: _ModerationAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline_rounded),
              title: Text('Sil'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

/// Reels ses durumu — Instagram gibi sessiz başlar; tüm reels'e uygulanır.
class ReelsMutedNotifier extends Notifier<bool> {
  @override
  bool build() => true; // varsayılan: sessiz
  void toggle() => state = !state;
}

final reelsMutedProvider = NotifierProvider<ReelsMutedNotifier, bool>(
  ReelsMutedNotifier.new,
);

/// Topluluk akışı içeriği — şu an seed ayetlerden derlenir. Supabase
/// yapılandırıldığında 'feed_posts' tablosu + Realtime ile beslenecek.
final feedProvider = FutureProvider<List<TopicalAyah>>((ref) async {
  final repo = ref.read(contentRepositoryProvider);
  final topics = await repo.topics();
  final all = <TopicalAyah>[];
  for (final t in topics) {
    all.addAll(await repo.topicalByTopic(t));
  }
  return all;
});

/// Akış ekranı — tek yüzey: tam ekran dikey Reels. Ayrı "Gönderiler" sekmesi
/// yoktur; 'video' (mp4) ve 'still' (stüdyo görseli) aynı akışta akar
/// (bkz. [FeedPost.kind]). Ekranın kendi mutable durumu yoktur.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseReady = ref.watch(supabaseGatewayProvider).isAvailable;
    final isSignedIn = ref.watch(isSignedInProvider);
    return Scaffold(
      // Reels tam ekran akar; zemin videonun letterbox rengiyle aynı olsun.
      backgroundColor: AppColors.onGold,
      floatingActionButton: isSignedIn
          ? FloatingActionButton(
              key: const Key('feed_create_fab'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.emerald850,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                builder: (_) => const CreatePostSheet(),
              ),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.onGold,
              tooltip: 'Reel paylaş',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: _ReelsView()),
          // Başlık şeridi yok (reels tam kanar); yalnız dürüst çevrimdışı işareti.
          if (!supabaseReady)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 18, top: 14),
                child: Tooltip(
                  message:
                      'Canlı topluluk akışı için Supabase bağlantısı gerekli',
                  child: Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.white70,
                    size: 20,
                    semanticLabel: 'Çevrimdışı: canlı akış kullanılamıyor',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reels (dikey video) ──────────────────────────────────────────────────────

/// Bir reel sayfasının görünüm modeli — bulut gönderisi ve küratörlük fallback'i
/// ortak tek tipe maplenir. Dürüstlük: küratörlükte yazar/sayı atfedilmez.
class _Reel {
  const _Reel({
    required this.id,
    required this.isCuration,
    required this.arabic,
    required this.meal,
    required this.reference,
    required this.topic,
    required this.template,
    this.videoUrl,
    this.thumbnailUrl,
    this.authorName,
    this.authorId,
    this.authorInitial,
    this.likeCount,
    this.liked = false,
    this.canModerate = false,
    this.isOwn = false,
    this.isPending = false,
  });

  final String id;
  final bool isCuration;
  final String arabic;
  final String meal;
  final String reference;
  final String topic;
  final VideoTemplate template; // gradyan fallback için (her zaman çözülür)
  final String? videoUrl; // null → 'still' görseli ya da gradyan kompozisyon
  /// Stüdyo görseli (kind='still') veya videonun poster karesi. Her ikisi de
  /// `thumbnail_url`/`media_url` kolonundan gelir.
  final String? thumbnailUrl;
  final String? authorName; // bulut
  final String? authorId; // bulut
  final String? authorInitial; // bulut
  final int? likeCount; // bulut: gerçek sayı; küratörlükte null
  final bool liked;

  /// Başkasının içeriği mi? (Bildir/Engelle yalnız burada anlamlı.)
  final bool canModerate;

  /// Kullanıcının kendi içeriği mi? (Sil yalnız burada anlamlı.)
  final bool isOwn;

  /// Yönetici onayı bekliyor mu? Yalnız yazarına görünür → "Onay bekliyor" rozeti.
  final bool isPending;

  /// Şablon kimliğinden kTemplates gradyanını çöz (yoksa ilk şablon).
  static VideoTemplate templateFor(String? id) =>
      kTemplates.firstWhere((t) => t.id == id, orElse: () => kTemplates.first);
}

/// Reels sekmesi — tam ekran dikey PageView. Oturum açıksa bulut (kind='video'),
/// değilse küratörlük ayetlerinden kompozisyon reels üretilir (sekme boş kalmaz).
class _ReelsView extends ConsumerStatefulWidget {
  const _ReelsView();

  @override
  ConsumerState<_ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends ConsumerState<_ReelsView> {
  // İşlenen beğeni istekleri (post id) — çift dokunma ikinci isteği başlatmasın.
  final _inFlight = <String>{};
  // Optimistik beğeni override'ı: post id → son niyet edilen durum.
  final _optimistic = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isSignedInProvider)) {
      final async = ref.watch(cloudReelsProvider);
      return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
        data: (posts) {
          if (posts.isEmpty) return const _ReelsEmpty();
          final myId = ref
              .read(supabaseGatewayProvider)
              .client
              ?.auth
              .currentUser
              ?.id;
          final reels = posts
              .map((p) {
                // Sunucu gerçeği optimistik niyetle uzlaştıysa override'ı bırak.
                if (_optimistic[p.id] == p.likedByMe) _optimistic.remove(p.id);
                return _Reel(
                  id: p.id,
                  isCuration: false,
                  arabic: p.arabic,
                  meal: p.meal,
                  reference: p.reference,
                  topic: p.topic,
                  template: _Reel.templateFor(p.templateId),
                  videoUrl: p.videoUrl,
                  thumbnailUrl: p.thumbnailUrl,
                  authorName: p.authorName,
                  authorId: p.authorId,
                  authorInitial: p.authorName.isNotEmpty
                      ? p.authorName.characters.first
                      : '?',
                  likeCount: p.likeCount,
                  liked: _optimistic[p.id] ?? p.likedByMe,
                  canModerate: p.authorId != myId,
                  isOwn: myId != null && p.authorId == myId,
                  isPending: p.isPending,
                );
              })
              .toList(growable: false);
          return _ReelsPager(
            reels: reels,
            onLike: (reel) => _toggleLike(reel.id, reel.liked),
            onComment: (reel) => _openComments(reel),
            onReport: (reel) => _reportContent(
              context,
              ref,
              targetId: reel.id,
              isComment: false,
            ),
            onBlock: (reel) {
              if (reel.authorId != null && reel.authorId != myId) {
                _blockAuthor(context, ref, reel.authorId!);
              }
            },
            onDelete: _deleteReel,
          );
        },
      );
    }

    // Oturum yok → küratörlük ayetlerinden kompozisyon reels (video yok).
    final async = ref.watch(feedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
      data: (items) {
        if (items.isEmpty) return const _ReelsEmpty();
        final reels = <_Reel>[
          for (var i = 0; i < items.length; i++)
            _Reel(
              id: 'curation-$i',
              isCuration: true,
              arabic: items[i].arabic,
              meal: items[i].meal,
              reference: items[i].reference,
              topic: items[i].topic,
              // Küratörlük: şablonu döngüsel ata (görsel çeşitlilik).
              template: kTemplates[i % kTemplates.length],
            ),
        ];
        return _ReelsPager(reels: reels);
      },
    );
  }

  /// Beğeni: in-flight guard (çift dokunma engellenir) + optimistik ikon.
  Future<void> _toggleLike(String postId, bool currentlyLiked) async {
    if (_inFlight.contains(postId)) return; // istek sürüyor → yok say.
    _inFlight.add(postId);
    setState(() => _optimistic[postId] = !currentlyLiked); // optimistik ikon.
    try {
      await ref
          .read(socialRepositoryProvider)
          .toggleLike(postId, currentlyLiked);
      if (!mounted) return;
      ref.invalidate(cloudReelsProvider);
    } catch (_) {
      if (mounted) setState(() => _optimistic.remove(postId));
    } finally {
      _inFlight.remove(postId);
    }
  }

  /// Kendi reel'ini sil — yıkıcı işlem, önce onay diyalogu.
  /// Hata yutulmaz: RLS reddi/ağ hatası kullanıcıya gösterilir.
  Future<void> _deleteReel(_Reel reel) async {
    final confirmed = await _confirmModeration(
      context,
      title: 'Reel’i sil',
      message:
          'Bu içerik kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(socialRepositoryProvider).deletePost(reel.id);
      if (!mounted) return;
      ref.invalidate(cloudReelsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Reel silindi.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
    }
  }

  /// Yorum sheet'ini aç (yalnız bulut reel'lerinde çağrılır).
  void _openComments(_Reel reel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.emerald850,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => CommentsSheet(postId: reel.id),
    );
  }
}

class _ReelsEmpty extends StatelessWidget {
  const _ReelsEmpty();
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.movie_creation_outlined,
      message: 'Henüz reel yok.\nStüdyoda ilk ayet görselini üreterek başla.',
      action: FilledButton.icon(
        key: const Key('reels_empty_studio_cta'),
        onPressed: () => context.push('/studio'),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('Stüdyoyu aç'),
      ),
    );
  }
}

/// Dikey sayfalayıcı. Yalnız görünür sayfanın videosu oynar; sayfa değişince
/// öncekinin oynatıcısı duraklatılır. Oynatıcı yaşam döngüsü tek tek sayfada
/// ([_ReelPage]) yönetilir → görünmeyen sayfalar bellek tutmaz (dispose edilir).
class _ReelsPager extends StatefulWidget {
  const _ReelsPager({
    required this.reels,
    this.onLike,
    this.onComment,
    this.onReport,
    this.onBlock,
    this.onDelete,
  });

  final List<_Reel> reels;
  final void Function(_Reel reel)? onLike;
  final void Function(_Reel reel)? onComment;
  final void Function(_Reel reel)? onReport;
  final void Function(_Reel reel)? onBlock;
  final void Function(_Reel reel)? onDelete;

  @override
  State<_ReelsPager> createState() => _ReelsPagerState();
}

class _ReelsPagerState extends State<_ReelsPager> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      itemCount: widget.reels.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (context, i) {
        final reel = widget.reels[i];
        return _ReelPage(
          // Anahtar: sayfa kimliği → controller'lar sayfaya bağlı yeniden kurulmaz.
          key: ValueKey(reel.id),
          reel: reel,
          isActive: i == _current,
          onLike: widget.onLike == null ? null : () => widget.onLike!(reel),
          onComment: widget.onComment == null
              ? null
              : () => widget.onComment!(reel),
          onReport: widget.onReport == null || !reel.canModerate
              ? null
              : () => widget.onReport!(reel),
          onBlock: widget.onBlock == null || !reel.canModerate
              ? null
              : () => widget.onBlock!(reel),
          onDelete: widget.onDelete == null || !reel.isOwn
              ? null
              : () => widget.onDelete!(reel),
          onShare: () => _shareReel(context, reel),
        );
      },
    );
  }

  void _shareReel(BuildContext context, _Reel reel) {
    // shareService ProviderScope üzerinden okunur; burada Builder ihtiyacı yok
    // çünkü _ReelPage zaten ref taşımıyor → en yakın ConsumerWidget _ReelsView.
    final reader = ProviderScope.containerOf(context, listen: false);
    reader
        .read(shareServiceProvider)
        .shareText('${reel.meal}\n(${reel.reference})');
  }
}

/// Tek bir reel sayfası. videoUrl varsa gerçek video, yoksa 'still' görseli
/// (Ken Burns), o da yoksa şablon gradyanı + Arapça + meal (dürüst fallback).
class _ReelPage extends ConsumerStatefulWidget {
  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onReport,
    this.onBlock,
    this.onDelete,
  });

  final _Reel reel;
  final bool isActive;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<_ReelPage> {
  VideoPlayerController? _video;
  bool _initialized = false;
  bool _userPaused = false;
  bool _disposed = false;
  bool _showHeart = false; // çift dokun beğeni kalp animasyonu

  bool get _hasVideo =>
      widget.reel.videoUrl != null && widget.reel.videoUrl!.isNotEmpty;

  String? get _poster {
    final url = widget.reel.thumbnailUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  @override
  void initState() {
    super.initState();
    // BELLEK: controller yalnız GÖRÜNÜR sayfada kurulur. PageView sürükleme
    // sırasında komşu sayfaları da inşa eder; koşulsuz kurulsaydı aynı anda
    // 2-3 video decoder canlı kalır, kare düşerdi. Aynı anda tek controller.
    if (_hasVideo && widget.isActive) _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.reel.videoUrl!;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    try {
      await c.initialize();
      // KİMLİK KONTROLÜ (her await sonrası): bu arada sayfa bırakılıp yerine
      // YENİ bir controller kurulmuş olabilir — hızlı ileri-geri kaydırma +
      // yavaş ağ, reels'te sık görülen bir birleşim. `_disposed`/`mounted`
      // bunu görmez, ikisi de hâlâ "canlı" der. Artık bizim değilsek kendi
      // kaynağımızı bırakıp sessizce çekiliyoruz (dispose idempotent).
      if (!identical(_video, c)) return await c.dispose();
      if (_disposed || !mounted) return;
      await c.setLooping(true);
      // Instagram gibi sessiz başlar; kullanıcı sessize-alma düğmesiyle açar.
      await c.setVolume(ref.read(reelsMutedProvider) ? 0 : 1);
      if (!identical(_video, c)) return await c.dispose();
      if (_disposed || !mounted) return;
      setState(() => _initialized = true);
      if (widget.isActive && !_userPaused) await c.play();
    } catch (_) {
      // Ağ/format hatası → dürüstçe poster/kompozisyon fallback'ine düş.
      // (Yutulan bir hata değil: kullanıcı fallback kompozisyonu görür.)
      //
      // Koşulsuz `_video = null` yazmak, o sırada _video'nun işaret ettiği
      // YENİ ve canlı controller'ın TEK referansını silerdi → native decoder
      // dispose edilmeden sızar (düşük RAM'li cihazda oturum başına birkaç
      // "hayalet" decoder = OOM riski). Bizim değilse dokunma.
      if (!identical(_video, c)) return await c.dispose();
      _video = null;
      await c.dispose();
      if (_disposed || !mounted) return;
      setState(() => _initialized = false);
    }
  }

  /// Controller'ı bırak — sayfa görünürlükten çıkınca ya da reel değişince.
  void _releaseVideo() {
    _video?.dispose();
    _video = null;
    _initialized = false;
    _userPaused = false;
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aynı slota farklı videoUrl'li reel gelirse (liste invalidate sonrası):
    // eski controller'ı dispose edip yeniden kur — orphan controller kalmaz.
    // NOT: burada setState yok — didUpdateWidget'ı build zaten izler.
    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _releaseVideo();
      if (_hasVideo && widget.isActive) _initVideo();
      return;
    }
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      // Sayfa görünür oldu → controller'ı şimdi kur (initState'te kurulmadı).
      if (_hasVideo && _video == null) _initVideo();
    } else {
      // Sayfa görünmez oldu → decoder'ı serbest bırak (pil + bellek).
      _releaseVideo();
    }
  }

  @override
  void dispose() {
    // Önce işaretle: devam eden _initVideo async'i disposed controller'a dokunmasın.
    _disposed = true;
    _video?.dispose();
    super.dispose();
  }

  /// "Yasin, 58" → ('Yasin', 58). Ayrıştırılamazsa null → künye tıklanamaz.
  static (String, int)? _parseReference(String reference) {
    final m = RegExp(r'^\s*(.+?)\s*,\s*(\d+)').firstMatch(reference);
    if (m == null) return null;
    return (m.group(1)!, int.parse(m.group(2)!));
  }

  /// Türkçe harf-duyarsız karşılaştırma (İ/I → i/ı; `toLowerCase` tek başına
  /// 'İ' için birleşik nokta üretip eşleşmeyi bozar).
  static String _fold(String s) =>
      s.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  /// Ayet künyesine dokunma → sureyi otoriter listeden çöz, okuyucuyu o ayete
  /// kaydırarak aç (Ayet Bulucu'daki `_openInReader` kalıbının aynısı).
  Future<void> _openReference() async {
    final parsed = _parseReference(widget.reel.reference);
    if (parsed == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final surahs = await ref.read(surahsProvider.future);
    final name = _fold(parsed.$1);
    final hits = surahs.where((s) => _fold(s.nameTr) == name);
    if (!mounted) return;
    if (hits.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bu sûre okuyucuda bulunamadı.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SurahReaderScreen(surah: hits.first, initialAyah: parsed.$2),
      ),
    );
  }

  void _togglePlay() {
    final c = _video;
    if (c == null || !_initialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
    });
  }

  /// Çift dokun → beğen + ortada kalp animasyonu (Instagram imza hareketi).
  void _onDoubleTap() {
    widget.onLike?.call();
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    // Sessize-alma durumu global; değişince oynayan videoya anında uygula.
    final muted = ref.watch(reelsMutedProvider);
    if (_video != null && _initialized) _video!.setVolume(muted ? 0 : 1);

    return GestureDetector(
      onTap: _hasVideo ? _togglePlay : null,
      onDoubleTap: widget.onLike == null ? null : _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan: gerçek video (hazır) veya şablon kompozisyonu.
          RepaintBoundary(child: _background()),
          // Okunurluk için alt scrim.
          const _BottomScrim(),
          // İlerleme çubuğu (yalnız gerçek video oynatılırken).
          if (_hasVideo && _initialized && _video != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _video!,
                allowScrubbing: false,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.gold,
                  bufferedColor: Color(0x33FFFFFF),
                  backgroundColor: Color(0x22FFFFFF),
                ),
              ),
            ),
          // Çift dokun beğeni kalbi.
          if (_showHeart)
            const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 110,
                    color: Colors.white,
                  ),
                )
                .animate()
                .scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 150.ms)
                .then(delay: 350.ms)
                .fadeOut(duration: 250.ms),
          // Alt-sol bilgi + sağ dikey aksiyonlar.
          _ReelOverlay(
            reel: reel,
            onLike: widget.onLike,
            onShare: widget.onShare,
            onComment: widget.onComment,
            onReport: widget.onReport,
            onBlock: widget.onBlock,
            onDelete: widget.onDelete,
            onOpenReference:
                _parseReference(reel.reference) == null ? null : _openReference,
            muted: muted,
            onToggleMute: () => ref.read(reelsMutedProvider.notifier).toggle(),
            showPlayIcon: _hasVideo && _initialized && _userPaused,
          ),
        ],
      ),
    );
  }

  Widget _background() {
    if (_hasVideo && _initialized && _video != null) {
      return ColoredBox(
        color: AppColors.onGold,
        child: Center(
          child: AspectRatio(
            aspectRatio: _video!.value.aspectRatio,
            child: VideoPlayer(_video!),
          ),
        ),
      );
    }
    final poster = _poster;
    if (poster != null) {
      // Video posteri (ilk kare gelene kadar) VEYA 'still' reel'in kendisi.
      // Ken Burns yalnız 'still'de ve yalnız sayfa görünürken çalışır: video
      // posteri saniyeler içinde kaybolacağı için animasyon boşa pil yakar.
      return _StillBackground(
        url: poster,
        animate: !_hasVideo && widget.isActive,
        fallback: _ReelComposition(reel: widget.reel),
      );
    }
    // Kompozisyon fallback (medya yok / yükleniyor / hata): şablon gradyanı.
    return _ReelComposition(
      reel: widget.reel,
      // videoUrl var ama henüz initialize değilse → "yükleniyor".
      loading: _hasVideo && !_initialized,
    );
  }
}

/// Tam ekran görsel arka plan (stüdyo 'still' reel'i veya video posteri).
///
/// Ken Burns: yavaş 1.0→1.08 ölçek, 12 sn, ileri-geri döngü. [animate] false
/// olduğunda animasyon sarmalayıcısı hiç kurulmaz → controller da yok
/// (görünmeyen sayfada sonsuz animasyon pil tüketmez). Görsel yüklenemezse
/// dürüstçe [fallback] kompozisyona düşer — boş siyah ekran gösterilmez.
class _StillBackground extends StatelessWidget {
  const _StillBackground({
    required this.url,
    required this.animate,
    required this.fallback,
  });

  final String url;
  final bool animate;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => fallback,
    );
    if (!animate || reduceMotion) return image;
    // ClipRect şart: Transform.scale kırpmaz, büyüyen görsel sayfa sınırlarının
    // dışına taşıp üstteki overlay'in altına sızardı.
    return ClipRect(
      child: image
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            duration: const Duration(seconds: 12),
            curve: Curves.easeInOut,
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
          ),
    );
  }
}

/// Video olmayan reel için tam ekran kompozisyon: gradyan + RTL Arapça + meal
/// + "Video hazırlanıyor" / "Yükleniyor" rozeti. Asla boş/bozuk görünmez.
class _ReelComposition extends StatelessWidget {
  const _ReelComposition({required this.reel, this.loading = false});
  final _Reel reel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: reel.template.colors,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (reel.arabic.isNotEmpty)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                reel.arabic,
                textAlign: TextAlign.center,
                style: arabicStyle(size: 30),
              ),
            ),
          if (reel.meal.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              reel.meal,
              textAlign: TextAlign.center,
              style: AppTypography.body(size: 17, color: AppColors.cream),
            ),
          ],
          // Rozet YALNIZ yüklenirken. Eskiden burada "Video hazırlanıyor"
          // yazıyordu; gerçek video render'ı kapsam dışı olduğu için bu artık
          // yanıltıcı bir vaat olurdu — kompozisyonun kendisi nihai içeriktir.
          if (loading) ...[
            const SizedBox(height: 22),
            const _ReelBadge(
              icon: Icons.hourglass_top_rounded,
              label: 'Yükleniyor',
            ),
          ],
        ],
      ),
    );
  }
}

/// Küçük altın rozet (dürüst durum etiketi).
class _ReelBadge extends StatelessWidget {
  const _ReelBadge({
    super.key,
    required this.icon,
    required this.label,
    this.semanticsLabel,
  });
  final IconData icon;
  final String label;

  /// Ekran okuyucuya bildirilen tam cümle (rozet metni kısaltılmış olabilir).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? label,
      excludeSemantics: semanticsLabel != null,
      child: _pill(),
    );
  }

  Widget _pill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.goldFaint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.body(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alt karartma gradyanı — overlay metnini okunur kılar.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();
  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [Color(0xCC08201A), Color(0x0008201A)],
          ),
        ),
      ),
    );
  }
}

/// Reel üstündeki bilgi + aksiyon katmanı (sol-alt + sağ dikey).
class _ReelOverlay extends StatelessWidget {
  const _ReelOverlay({
    required this.reel,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onReport,
    this.onBlock,
    this.onDelete,
    this.onOpenReference,
    this.muted = true,
    this.onToggleMute,
    this.showPlayIcon = false,
  });

  final _Reel reel;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;

  /// Ayet künyesine dokunulunca okuyucuyu açar. Künye ayrıştırılamıyorsa null
  /// → chip tıklanamaz görünür (yalnız renkle değil, etkileşimle de ayrışır).
  final VoidCallback? onOpenReference;
  final bool muted;
  final VoidCallback? onToggleMute;
  final bool showPlayIcon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Duraklatıldı işareti (ortada).
        if (showPlayIcon)
          const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 72,
              color: Colors.white70,
            ),
          ),
        // Sol üst: moderasyon şeffaflığı — bekleyen içerik yalnız yazarına görünür.
        if (reel.isPending)
          const Positioned(
            left: 14,
            top: 14,
            child: Tooltip(
              message: 'Onay bekliyor — yalnız sana görünür',
              child: _ReelBadge(
                key: Key('reel_pending_badge'),
                icon: Icons.hourglass_top_rounded,
                label: 'Onay bekliyor',
                semanticsLabel:
                    'Bu içerik onay bekliyor, yalnız sana görünür yayında değil',
              ),
            ),
          ),
        // Sağ üst: sessize alma (yalnız gerçek video reel'lerinde anlamlı).
        if (onToggleMute != null)
          Positioned(
            right: 14,
            top: 14,
            child: _MuteButton(muted: muted, onTap: onToggleMute!),
          ),
        // Sağ dikey aksiyonlar: beğeni + yorum + paylaş.
        Positioned(
          right: 14,
          bottom: 130,
          child: Column(
            children: [
              _ActionButton(
                icon: reel.liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: reel.liked ? AppColors.accent : Colors.white,
                // Bulut: gerçek sayı; küratörlük: sayı yok (dürüstlük).
                label: reel.likeCount?.toString(),
                onTap: onLike,
              ),
              // Yorum: yalnız gerçek (bulut) gönderilerde; küratörlükte yorumlanamaz.
              if (onComment != null) ...[
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  color: Colors.white,
                  onTap: onComment,
                ),
              ],
              const SizedBox(height: 18),
              _ActionButton(
                icon: Icons.share_rounded,
                color: AppColors.gold,
                tooltip: 'Paylaş',
                onTap: onShare,
              ),
              if (onReport != null) ...[
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.flag_outlined,
                  color: Colors.white,
                  label: 'Bildir',
                  tooltip: 'Bu içeriği bildir',
                  onTap: onReport,
                ),
              ],
              if (onBlock != null) ...[
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.person_off_outlined,
                  color: Colors.white,
                  label: 'Engelle',
                  tooltip: 'Kullanıcıyı engelle',
                  onTap: onBlock,
                ),
              ],
              // Kendi içeriği → Sil (yıkıcı; onay diyalogu çağıranda).
              if (onDelete != null) ...[
                const SizedBox(height: 12),
                _ActionButton(
                  key: const Key('reel_delete_action'),
                  icon: Icons.delete_outline_rounded,
                  color: Colors.white,
                  label: 'Sil',
                  tooltip: 'Bu reel’i sil',
                  onTap: onDelete,
                ),
              ],
            ],
          ),
        ),
        // Sol-alt: yazar + meal + referans.
        Positioned(
          left: 18,
          right: 84,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.goldFaint,
                    child: reel.isCuration
                        ? const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.gold,
                            size: 16,
                          )
                        : Text(
                            reel.authorInitial ?? '?',
                            style: AppTypography.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      reel.isCuration
                          ? 'Günün Seçkileri'
                          : (reel.authorName ?? 'Kullanıcı'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
              if (reel.meal.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reel.meal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(size: 14.5, color: AppColors.cream),
                ),
              ],
              // Ayet künyesi: dokununca sûreyi okuyucuda o ayete kaydırarak açar.
              // `selected: true` bilinçli — altın zemin + onGold metin tema
              // değişiminden ETKİLENMEZ; video/gradyan üstünde her iki temada
              // da okunur (cream/cream2 açık temada koyulaşıp kaybolurdu).
              if (reel.reference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Semantics(
                  button: onOpenReference != null,
                  label: onOpenReference == null
                      ? reel.reference
                      : '${reel.reference} — okuyucuda aç',
                  // ≥44px dokunma hedefi: chip'in kendi yüksekliği ~40, gelen
                  // minHeight kısıtı Container'a geçer → dokunma alanı da büyür.
                  // (Araya Align koymak kısıtı gevşetir; bilerek doğrudan sarılı.)
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: GoldChip(
                      key: const Key('reel_reference_chip'),
                      label: reel.reference,
                      selected: true,
                      onTap: onOpenReference,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.label,
    this.tooltip,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String? label;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          // ≥44px dokunma hedefi.
          iconSize: 30,
          icon: Icon(icon, color: color),
        ),
        if (label != null)
          Text(
            label!,
            style: AppTypography.body(size: 12, color: Colors.white),
          ),
      ],
    );
  }
}

/// Reels sessize-alma düğmesi — yarı saydam yuvarlak, hoparlör ikonu.
class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.muted, required this.onTap});
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x55000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Yorumlar Sheet ─────────────────────────────────────────────────────────────

/// Bir gönderinin/reel'in yorumları — liste + giriş alanı. Yorum tablosu deploy
/// edilmemişse boş liste döner (graceful), gönderim sessizce no-op olur.
class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  late Future<List<Comment>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(socialRepositoryProvider).fetchComments(widget.postId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = ref.read(socialRepositoryProvider).fetchComments(widget.postId);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(widget.postId, text);
      _controller.clear();
      if (!mounted) return;
      _reload();
      // Reels yorum sayacı güncellensin.
      ref.invalidate(cloudReelsProvider);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Kendi yorumunu sil — yıkıcı işlem, önce onay diyalogu. Hata yutulmaz.
  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await _confirmModeration(
      context,
      title: 'Yorumu sil',
      message: 'Bu yorum kalıcı olarak silinecek. Emin misiniz?',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(socialRepositoryProvider).deleteComment(comment.id);
      if (!mounted) return;
      _reload();
      ref.invalidate(cloudReelsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final myId = ref
        .watch(supabaseGatewayProvider)
        .client
        ?.auth
        .currentUser
        ?.id;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Yorumlar',
                      style: AppTypography.body(
                        size: 16,
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Comment>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snap.data ?? const <Comment>[];
                    if (comments.isEmpty) {
                      return const EmptyState(
                        icon: Icons.mode_comment_outlined,
                        message: 'Henüz yorum yok.\nİlk yorumu sen yaz.',
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final comment = comments[i];
                        final isOwn =
                            myId != null && comment.authorId == myId;
                        return _CommentTile(
                          comment: comment,
                          // Kendi yorumunda yalnız Sil; başkasında Bildir/Engelle.
                          onDelete: isOwn ? () => _deleteComment(comment) : null,
                          onReport: isOwn
                              ? null
                              : () => _reportContent(
                                  context,
                                  ref,
                                  targetId: comment.id,
                                  isComment: true,
                                ),
                          onBlock: isOwn
                              ? null
                              : () async {
                                  if (await _blockAuthor(
                                    context,
                                    ref,
                                    comment.authorId,
                                  )) {
                                    _reload();
                                  }
                                },
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: AppTypography.body(
                            size: 14,
                            color: AppColors.cream,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Yorum yaz…',
                            hintStyle: AppTypography.body(
                              size: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: AppColors.gold,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    this.onReport,
    this.onBlock,
    this.onDelete,
  });
  final Comment comment;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.goldFaint,
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName.characters.first
                  : '?',
              style: AppTypography.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: AppTypography.body(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: AppColors.cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: AppTypography.body(size: 14, color: AppColors.cream2),
                ),
              ],
            ),
          ),
          if (onReport != null || onBlock != null || onDelete != null)
            _ModerationMenuButton(
              key: const Key('comment_menu'),
              onReport: onReport,
              onBlock: onBlock,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

// ── Reel Paylaşma Sheet ───────────────────────────────────────────────────────

/// Yeni reel paylaşma sayfası — YALNIZ dikey medya: galeriden bir video (mp4)
/// veya stüdyoda üretilmiş bir görsel (PNG). Serbest fotoğraf yükleme yoktur;
/// akış tek biçimdir (bkz. [FeedPost.kind] = 'video' | 'still').
///
/// Supabase `post-media` bucket'ına yükler, `feed_posts` tablosuna repository
/// üzerinden kaydeder. Her yeni içerik sunucuda 'pending' başlar.
class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedMedia;

  /// Seçili medyanın türü — doğrudan `feed_posts.kind` değeridir.
  /// null → henüz medya seçilmedi (yayınlanamaz).
  String? _kind; // 'video' | 'still'

  /// Telif beyanı (App Store Guideline 5.2.3) — onaylanmadan yayın yapılamaz.
  bool _rightsAccepted = false;
  bool _uploading = false;

  /// Yayın sonrası onay kuyruğu bilgilendirmesi gösteriliyor mu?
  bool _published = false;

  static const _rightsLabel =
      'Bu içeriğin bana ait olduğunu veya paylaşma hakkım olduğunu onaylıyorum.';

  bool get _canPublish =>
      !_uploading && _selectedMedia != null && _rightsAccepted;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final picked = File(file.path);
    // BOYUT KAPISI — seçimin hemen ardından, kullanıcı başlık yazmadan önce.
    // `_publish` videoyu `readAsBytes()` ile TAMAMEN belleğe alıyor: birkaç
    // yüz MB'lık bir galeri videosu düşük RAM'li cihazda OOM ile uygulamayı
    // düşürür, mobil veride kullanıcı farkında olmadan yükleme yapar.
    // Ayet Bulucu video yolundaki (`backend_repositories.dart:902`) aynı
    // sınırı kullanıyoruz — iki yol farklı sınır uygularsa biri anlamsız olur.
    // `lengthSync` bilinçli: tek bir stat() çağrısı mikrosaniyeler sürer, ekstra
    // bir async sıçraması kadar bile maliyeti yok — ve kodu await'siz tutar.
    if (picked.lengthSync() > kAyahVideoMaxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video çok büyük (en fazla 20 MB). Daha kısa bir video seç.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedMedia = picked;
      _kind = 'video';
    });
  }

  /// Stüdyonun dışa aktardığı PNG'ler geçici dizine `ayet_<zaman>.png` adıyla
  /// yazılır (bkz. StudioScreen `_export`). Buradan seçtiriyoruz — böylece
  /// kullanıcı görselini galeriye kaydetmek zorunda kalmaz.
  Future<void> _pickFromStudio() async {
    final dir = await getTemporaryDirectory();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  f.uri.pathSegments.last.startsWith('ayet_') &&
                  f.path.toLowerCase().endsWith('.png'),
            )
            .toList()
          // Dosya adındaki zaman damgası artan → ters sırala: en yenisi başta.
          ..sort((a, b) => b.path.compareTo(a.path));
    if (!mounted) return;
    final picked = await showModalBottomSheet<File>(
      context: context,
      backgroundColor: AppColors.emerald850,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _StudioPickerSheet(files: files),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedMedia = picked;
      _kind = 'still';
    });
  }

  void _clearMedia() {
    setState(() {
      _selectedMedia = null;
      _kind = null;
    });
  }

  Future<void> _publish() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giriş yapmanız gerekiyor')));
      return;
    }
    final media = _selectedMedia;
    final kind = _kind;
    if (media == null || kind == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşmak için bir video veya stüdyo görseli seçin.'),
        ),
      );
      return;
    }
    // Savunma amaçlı ikinci kapı: seçim ile yayın arasında dosya değişebilir
    // ve ileride başka bir seçim yolu eklenirse sınır burada da tutsun.
    if (media.lengthSync() > kAyahVideoMaxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya çok büyük (en fazla 20 MB).')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final isVideo = kind == 'video';
      final ext = isVideo ? 'mp4' : 'png';
      final contentType = isVideo ? 'video/mp4' : 'image/png';
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage
          .from('post-media')
          .uploadBinary(
            path,
            await media.readAsBytes(),
            fileOptions: FileOptions(contentType: contentType),
          );
      final mediaUrl = client.storage.from('post-media').getPublicUrl(path);

      final caption = _captionController.text.trim();
      await ref
          .read(socialRepositoryProvider)
          .createPost(
            reference: '',
            arabic: '',
            meal: caption,
            caption: caption,
            kind: kind,
            // 'still' → poster/görsel; 'video' → oynatılabilir mp4.
            mediaUrl: isVideo ? null : mediaUrl,
            videoUrl: isVideo ? mediaUrl : null,
          );
      ref.invalidate(cloudReelsProvider);
      if (mounted) setState(() => _published = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: _published ? _reviewNotice() : _form(),
    );
  }

  /// Yayın sonrası onay kuyruğu şeffaflığı — kullanıcı içeriğini akışta hemen
  /// göremezse "kayboldu" sanmasın diye açıkça söylüyoruz.
  Widget _reviewNotice() {
    return Column(
      key: const Key('create_post_review_notice'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Icon(
          Icons.hourglass_top_rounded,
          size: 44,
          color: AppColors.gold,
          semanticLabel: 'İnceleme bekleniyor',
        ),
        const SizedBox(height: 14),
        Text(
          'İçeriğin incelemeye alındı. Onaylandığında Reels’te yayınlanacak.',
          textAlign: TextAlign.center,
          style: AppTypography.body(size: 15.5, color: AppColors.cream),
        ),
        const SizedBox(height: 8),
        Text(
          'O zamana kadar içeriğini “Onay bekliyor” rozetiyle yalnız sen görürsün.',
          textAlign: TextAlign.center,
          style: AppTypography.body(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.onGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Tamam',
            style: AppTypography.body(
              size: 16,
              weight: FontWeight.w600,
              color: AppColors.onGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Yeni Reel', style: AppTypography.display(size: 22)),
            const Spacer(),
            IconButton(
              tooltip: 'Kapat',
              icon: Icon(Icons.close_rounded, color: AppColors.muted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextField(
          key: const Key('create_post_caption'),
          controller: _captionController,
          maxLines: 3,
          style: AppTypography.body(size: 15, color: AppColors.cream),
          decoration: InputDecoration(
            hintText: 'Bir şeyler yaz (isteğe bağlı)…',
            hintStyle: AppTypography.body(size: 15, color: AppColors.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.emerald900,
          ),
        ),
        const SizedBox(height: 14),

        // Medya seçimi: yalnız dikey video veya stüdyo görseli.
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: const Key('create_post_pick_video'),
                icon: const Icon(Icons.videocam_rounded, color: AppColors.gold),
                label: Text(
                  'Video Seç',
                  style: AppTypography.body(size: 14, color: AppColors.gold),
                ),
                onPressed: _uploading ? null : _pickVideo,
              ),
            ),
            Expanded(
              child: TextButton.icon(
                key: const Key('create_post_pick_studio'),
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                ),
                label: Text(
                  'Stüdyodan Seç',
                  style: AppTypography.body(size: 14, color: AppColors.gold),
                ),
                onPressed: _uploading ? null : _pickFromStudio,
              ),
            ),
            if (_selectedMedia != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                tooltip: 'Seçimi kaldır',
                onPressed: _uploading ? null : _clearMedia,
              ),
          ],
        ),

        if (_selectedMedia != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _kind == 'still'
                ? Image.file(
                    _selectedMedia!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 48,
                        semanticLabel: 'Seçili video',
                      ),
                    ),
                  ),
          ),
        ],

        const SizedBox(height: 14),

        // Telif beyanı — onaylanmadan Yayınla devre dışı (Guideline 5.2.3).
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: _rightsLabel,
                child: Checkbox(
                  key: const Key('create_post_rights_checkbox'),
                  value: _rightsAccepted,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.onGold,
                  side: const BorderSide(color: AppColors.gold, width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: _uploading
                      ? null
                      : (v) => setState(() => _rightsAccepted = v ?? false),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const Key('create_post_rights_text'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _uploading
                      ? null
                      : () => setState(() => _rightsAccepted = !_rightsAccepted),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _rightsLabel,
                      style: AppTypography.body(
                        size: 13.5,
                        color: AppColors.cream2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Devre dışı olma nedeni metinle de bildirilir (yalnız renkle ayırma yok).
        if (!_canPublish && !_uploading) ...[
          const SizedBox(height: 4),
          Text(
            _selectedMedia == null
                ? 'Yayınlamak için bir video veya stüdyo görseli seçin.'
                : 'Yayınlamak için telif beyanını onaylayın.',
            key: const Key('create_post_publish_hint'),
            style: AppTypography.body(size: 12.5, color: AppColors.muted),
          ),
        ],

        const SizedBox(height: 14),

        ElevatedButton(
          key: const Key('create_post_publish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.onGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _canPublish ? _publish : null,
          child: _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onGold,
                  ),
                )
              : Text(
                  'Yayınla',
                  style: AppTypography.body(
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.onGold,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Stüdyoda üretilmiş PNG'leri seçtiren küçük sheet (en yenisi başta).
/// Geçici dizin işletim sistemince temizlenebilir → boşsa dürüst yönlendirme.
class _StudioPickerSheet extends StatelessWidget {
  const _StudioPickerSheet({required this.files});
  final List<File> files;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stüdyo Görsellerin',
              style: AppTypography.body(
                size: 16,
                weight: FontWeight.w600,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  message:
                      'Henüz kayıtlı stüdyo görseli yok.\nÖnce stüdyoda bir ayet görseli üret.',
                  action: FilledButton.icon(
                    key: const Key('studio_picker_open_studio'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/studio');
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Stüdyoyu aç'),
                  ),
                ),
              )
            else
              SizedBox(
                height: 190,
                child: ListView.separated(
                  key: const Key('studio_picker_list'),
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => Navigator.of(context).pop(files[i]),
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        files[i],
                        width: 110,
                        height: 190,
                        fit: BoxFit.cover,
                        semanticLabel: 'Stüdyo görseli ${i + 1}',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mesajlar ────────────────────────────────────────────────────────────────

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(messagesRepositoryProvider).myConversations();
});

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Mesajlar', style: AppTypography.display(size: 30)),
            ),
            if (!isSignedIn)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mesajlar için giriş yapın',
                        style: AppTypography.body(
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.push('/auth'),
                        child: const Text('Giriş Yap'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ref
                    .watch(conversationsProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Sohbetler yüklenemedi.',
                          style: AppTypography.body(
                            size: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      data: (convs) {
                        if (convs.isEmpty) {
                          return EmptyState(
                            icon: Icons.mail_outline_rounded,
                            message: 'Henüz sohbet yok.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: convs.length,
                          itemBuilder: (context, i) {
                            final conv = convs[i];
                            final title =
                                conv['conversations']?['title'] as String? ??
                                'Sohbet';
                            final isGroup =
                                conv['conversations']?['is_group'] as bool? ??
                                false;
                            final convId = conv['conversation_id'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(
                                      title: title,
                                      conversationId: convId,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.goldFaint,
                                      child: Icon(
                                        isGroup
                                            ? Icons.groups_rounded
                                            : Icons.person_rounded,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: AppTypography.body(
                                          size: 16,
                                          weight: FontWeight.w600,
                                          color: AppColors.cream,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.title, this.conversationId});
  final String title;
  final String? conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

// ── Kullanıcı Profil ────────────────────────────────────────────────────────

class UserProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null = kendi profili
  const UserProfileScreen({super.key, this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _effectiveUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    _effectiveUserId = widget.userId ?? client?.auth.currentUser?.id;
    if (_effectiveUserId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    final results = await Future.wait([
      repo.getUserProfile(_effectiveUserId!),
      repo.getFollowerCount(_effectiveUserId!),
      repo.getFollowingCount(_effectiveUserId!),
      repo.getUserPosts(_effectiveUserId!),
    ]);
    bool following = false;
    final myId = client?.auth.currentUser?.id;
    if (myId != null && myId != _effectiveUserId) {
      following = await repo.isFollowing(myId, _effectiveUserId!);
    }
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _followerCount = results[1] as int;
      _followingCount = results[2] as int;
      _posts = results[3] as List<Map<String, dynamic>>;
      _isFollowing = following;
      _loading = false;
    });
  }

  Future<void> _showEditNameDialog() async {
    // Controller, dialog'un kendi State'inde yaşar ve orada dispose edilir —
    // async helper'da `await showDialog` sonrası manuel dispose, EditableText
    // hâlâ teardown olurken controller'ı erken yok edip InheritedElement
    // deactivation sırasını bozuyordu (aralıklı `_dependents.isEmpty` çökmesi).
    final current = _profile?['display_name'] as String? ?? '';
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: current),
    );
    if (newName == null || newName.isEmpty || newName == current) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(newName);
      if (mounted) await _load();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İsim güncellenemedi. Tekrar deneyin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = ref.watch(supabaseClientProvider);
    final myId = client?.auth.currentUser?.id;
    final isOwnProfile = widget.userId == null || widget.userId == myId;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_effectiveUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Profilinizi görmek için giriş yapın'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _profile?['display_name'] as String? ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Profilim' : displayName),
        actions: [
          if (isOwnProfile)
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (isOwnProfile) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'İsmi düzenle',
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: _showEditNameDialog,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBadge('$_followerCount', 'Takipçi'),
                      const SizedBox(width: 32),
                      _StatBadge('$_followingCount', 'Takip'),
                      const SizedBox(width: 32),
                      _StatBadge('${_posts.length}', 'Gönderi'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isOwnProfile && myId != null)
                    FilledButton.tonal(
                      onPressed: () async {
                        final repo = ref.read(profileRepositoryProvider);
                        if (_isFollowing) {
                          await repo.unfollow(_effectiveUserId!);
                        } else {
                          await repo.follow(_effectiveUserId!);
                        }
                        setState(() {
                          _isFollowing = !_isFollowing;
                          _followerCount += _isFollowing ? 1 : -1;
                        });
                      },
                      child: Text(_isFollowing ? 'Takibi Bırak' : 'Takip Et'),
                    ),
                ],
              ),
            ),
            const Divider(),
            if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Henüz gönderi yok'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _posts.length,
                itemBuilder: (ctx, i) {
                  final post = _posts[i];
                  final thumb = post['thumbnail_url'] as String?;
                  return thumb != null
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) =>
                              Container(color: Colors.grey.shade200),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.article_rounded),
                        );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// İsim düzenleme dialog'u. Controller'ı State'inde sahiplenir; `dispose()`
/// element tam deactive olduktan sonra çalıştığı için teardown yarışı yaşanmaz.
class _EditNameDialog extends StatefulWidget {
  final String initial;
  const _EditNameDialog({required this.initial});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İsmi düzenle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Görünen adınız'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Sohbet ────────────────────────────────────────────────────────────────────

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _offlineMessages = <(bool, String)>[
    (false, 'Selamünaleyküm, hoş geldin! 🌙'),
  ];
  bool _sending = false;
  Stream<List<ChatMessage>>? _messageStream;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _messageStream = ref
          .read(messagesRepositoryProvider)
          .watchMessages(widget.conversationId!);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _sendOffline() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _offlineMessages.add((true, t));
      _input.clear();
    });
  }

  Future<void> _sendOnline() async {
    final t = _input.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .send(widget.conversationId!, t);
      _input.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.conversationId != null;
    final myId = ref.read(supabaseClientProvider)?.auth.currentUser?.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: widget.title),
            Expanded(
              child: isOnline
                  ? StreamBuilder<List<ChatMessage>>(
                      stream: _messageStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final messages = snap.data ?? const [];
                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              'Henüz mesaj yok.',
                              style: AppTypography.body(
                                size: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: messages.length,
                          itemBuilder: (context, i) {
                            final msg = messages[i];
                            final mine = msg.senderId == myId;
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? AppColors.gold
                                      : AppColors.emerald900,
                                  borderRadius: AppRadii.chatBubble(mine: mine),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Text(
                                  msg.body,
                                  style: AppTypography.body(
                                    size: 15,
                                    color: mine
                                        ? AppColors.onGold
                                        : AppColors.cream,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _offlineMessages.length,
                      itemBuilder: (context, i) {
                        final (mine, text) = _offlineMessages[i];
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.gold
                                  : AppColors.emerald900,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text(
                              text,
                              style: AppTypography.body(
                                size: 15,
                                color: mine
                                    ? AppColors.onGold
                                    : AppColors.cream,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) =>
                          isOnline ? _sendOnline() : _sendOffline(),
                      decoration: const InputDecoration(hintText: 'Mesaj yaz…'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending
                        ? null
                        : (isOnline ? _sendOnline : _sendOffline),
                    child: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
