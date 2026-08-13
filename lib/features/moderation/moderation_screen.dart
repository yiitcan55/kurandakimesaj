import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Moderasyon yüzeyleri:
/// * [ModerationScreen] — yönetici kuyruğu (bekleyen içerik + şikâyetler).
///   App Store UGC şartı: bildirilen içeriğe 24 saat içinde aksiyon alınabilmeli.
/// * [BlockedUsersScreen] — kullanıcının kendi engel listesi; engel geri alınabilir.
///
/// İkisi de repository'yi provider üzerinden çağırır; doğrudan Supabase erişimi yok.

String _errorText(Object e) =>
    e is StateError ? e.message : 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';

/// Supabase gömülü satırı (`feed_posts`, `comments`, `profiles`) güvenli okuma.
Map<String, dynamic>? _embedded(Map<String, dynamic> row, String key) {
  final value = row[key];
  return value is Map ? value.cast<String, dynamic>() : null;
}

/// Yıkıcı işlem onayı — yanlışlıkla dokunmayı engeller.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Yükleniyor / hata / boş üçlüsü — üç listede de aynı davranış.
Widget _asyncList<T>(
  AsyncValue<List<T>> async, {
  required IconData emptyIcon,
  required String emptyMessage,
  required Widget Function(List<T> items) builder,
}) => async.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) =>
      EmptyState(icon: Icons.error_outline_rounded, message: _errorText(e)),
  data: (items) => items.isEmpty
      ? EmptyState(icon: emptyIcon, message: emptyMessage)
      : builder(items),
);

Future<void> _setStatus(
  BuildContext context,
  WidgetRef ref,
  String postId,
  String status,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(socialRepositoryProvider).setPostStatus(postId, status);
    ref
      ..invalidate(pendingPostsProvider)
      ..invalidate(reportsProvider)
      ..invalidate(cloudReelsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          status == 'approved'
              ? 'İçerik onaylandı ve yayına alındı.'
              : 'İçerik yayından kaldırıldı.',
        ),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(_errorText(e))));
  }
}

/// Şikâyet edilen yorumu kaldırır (RLS: `comments_delete_admin`).
/// `_setStatus` ile aynı akış: onay → repository → liste tazeleme → SnackBar.
/// Yetkisiz çağrıda repository dürüst hata fırlatır, sessizce yutulmaz.
Future<void> _deleteComment(
  BuildContext context,
  WidgetRef ref,
  String commentId,
) async {
  final ok = await _confirm(
    context,
    title: 'Yorumu sil',
    message:
        'Bu yorum kalıcı olarak silinecek ve kimseye görünmeyecek. '
        'İşlemi onaylıyor musunuz?',
    confirmLabel: 'Sil',
  );
  if (!ok || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(socialRepositoryProvider).deleteComment(commentId);
    ref
      ..invalidate(reportsProvider)
      // Yorum sayacı gönderide tutuluyor → akış da tazelensin.
      ..invalidate(cloudReelsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Yorum silindi.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(_errorText(e))));
  }
}

/// Yönetici moderasyon kuyruğu. `DefaultTabController` controller'ı kendi
/// State'inde tutar → ayrıca dispose edilecek bir TabController kalmaz.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(title: 'İçerik moderasyonu'),
              TabBar(
                labelColor: AppColors.goldInk,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.gold,
                tabs: const [
                  Tab(
                    key: Key('moderation-tab-pending'),
                    icon: Icon(Icons.hourglass_bottom_rounded),
                    text: 'Bekleyenler',
                  ),
                  Tab(
                    key: Key('moderation-tab-reports'),
                    icon: Icon(Icons.flag_outlined),
                    text: 'Şikâyetler',
                  ),
                ],
              ),
              const Expanded(
                child: TabBarView(children: [_PendingTab(), _ReportsTab()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<FeedPost>(
      ref.watch(pendingPostsProvider),
      emptyIcon: Icons.verified_rounded,
      emptyMessage: 'Bekleyen içerik yok.\nKuyruk temiz.',
      builder: (posts) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingPostsProvider),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final post = posts[i];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContentPreview(
                    thumbnailUrl: post.thumbnailUrl,
                    title: post.authorName,
                    subtitle: post.reference.isNotEmpty
                        ? post.reference
                        : (post.isVideo ? 'Video gönderisi' : 'Görsel reel'),
                    body: post.meal,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: Key('moderation-approve-${post.id}'),
                          onPressed: () =>
                              _setStatus(context, ref, post.id, 'approved'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Onayla'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.onGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: Key('moderation-reject-${post.id}'),
                          onPressed: () async {
                            final ok = await _confirm(
                              context,
                              title: 'İçeriği reddet',
                              message:
                                  'Bu içerik yayına alınmayacak ve yazarı dışında '
                                  'kimseye görünmeyecek. İşlemi onaylıyor musunuz?',
                              confirmLabel: 'Reddet',
                            );
                            if (!ok || !context.mounted) return;
                            await _setStatus(context, ref, post.id, 'rejected');
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          label: Text(
                            'Reddet',
                            style: AppTypography.body(
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            side: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<Map<String, dynamic>>(
      ref.watch(reportsProvider),
      emptyIcon: Icons.shield_moon_rounded,
      emptyMessage: 'Bekleyen şikâyet yok.',
      builder: (rows) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportsProvider),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final row = rows[i];
            final post = _embedded(row, 'feed_posts');
            final comment = _embedded(row, 'comments');
            final reporter =
                _embedded(row, 'profiles')?['display_name'] as String? ??
                'Kullanıcı';
            final removed = post?['status'] == 'rejected';
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row['reason'] as String? ?? 'Şikâyet',
                          style: AppTypography.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bildiren: $reporter',
                    style: AppTypography.body(size: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (post != null)
                    _ContentPreview(
                      thumbnailUrl: post['thumbnail_url'] as String?,
                      title: post['kind'] == 'video'
                          ? 'Video gönderisi'
                          : 'Görsel reel',
                      subtitle: post['reference'] as String? ?? '',
                      body:
                          (post['caption'] as String?)?.isNotEmpty == true
                          ? post['caption'] as String
                          : post['meal'] as String? ?? '',
                    )
                  else if (comment != null) ...[
                    // Yazar + tam metin: yönetici kararını görerek versin.
                    // `maxLines` YOK — kırpılan kısım tam da şikâyet edilen
                    // bölüm olabilir.
                    Text(
                      _embedded(comment, 'profiles')?['display_name']
                              as String? ??
                          'Kullanıcı',
                      style: AppTypography.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${comment['body'] as String? ?? ''}”',
                      style: AppTypography.body(
                        size: 14,
                        color: AppColors.cream2,
                      ),
                    ),
                  ] else
                    Text(
                      'Raporlanan içerik bulunamadı (silinmiş olabilir).',
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (post != null && !removed)
                    OutlinedButton.icon(
                      key: Key('report-remove-${row['id']}'),
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          title: 'İçeriği kaldır',
                          message:
                              'Bu içerik akıştan kaldırılacak. İşlemi onaylıyor musunuz?',
                          confirmLabel: 'Kaldır',
                        );
                        if (!ok || !context.mounted) return;
                        await _setStatus(
                          context,
                          ref,
                          post['id'] as String,
                          'rejected',
                        );
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        'İçeriği kaldır',
                        style: AppTypography.body(
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  else if (removed)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bu içerik kaldırıldı.',
                          style: AppTypography.body(
                            size: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    )
                  else if (comment != null)
                    OutlinedButton.icon(
                      key: Key('report-delete-comment-${row['id']}'),
                      onPressed: () =>
                          _deleteComment(context, ref, comment['id'] as String),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        'Yorumu sil',
                        style: AppTypography.body(
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  else
                    // Hedef içerik zaten silinmiş — yukarıda bilgilendirildi,
                    // alınacak bir aksiyon kalmadı.
                    const SizedBox.shrink(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Küçük görsel + başlık/alt başlık + metin önizlemesi — kuyrukta ve şikâyette ortak.
class _ContentPreview extends StatelessWidget {
  const _ContentPreview({
    required this.title,
    required this.subtitle,
    required this.body,
    this.thumbnailUrl,
  });

  final String title;
  final String subtitle;
  final String body;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnailUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  thumbnailUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.cream,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.goldInk,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(size: 14, color: AppColors.cream2),
          ),
        ],
      ],
    );
  }
}

/// Kullanıcının engellediği hesaplar — engel buradan geri alınabilir.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Engellenen kullanıcılar'),
            Expanded(
              child: _asyncList<Map<String, dynamic>>(
                ref.watch(blockedUsersProvider),
                emptyIcon: Icons.person_off_outlined,
                emptyMessage:
                    'Engellediğiniz kullanıcı yok.\n'
                    'Bir gönderinin sağ üstündeki menüden kullanıcı engelleyebilirsiniz.',
                builder: (rows) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    final userId = row['blocked_id'] as String;
                    final profile = _embedded(row, 'profiles');
                    final name =
                        profile?['display_name'] as String? ?? 'Kullanıcı';
                    final avatar = profile?['avatar_url'] as String?;
                    return AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.goldFaint,
                            backgroundImage: avatar != null
                                ? NetworkImage(avatar)
                                : null,
                            child: avatar == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: AppColors.goldInk,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.body(
                                size: 15,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            key: Key('unblock-$userId'),
                            onPressed: () =>
                                _unblock(context, ref, userId, name),
                            icon: const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text('Engeli kaldır'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: AppColors.goldInk,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String name,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Engeli kaldır',
      message:
          '$name adlı kullanıcının gönderileri akışınızda yeniden görünecek. '
          'İşlemi onaylıyor musunuz?',
      confirmLabel: 'Engeli kaldır',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(socialRepositoryProvider).unblockUser(userId);
      ref
        ..invalidate(blockedUsersProvider)
        ..invalidate(cloudReelsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Engel kaldırıldı.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_errorText(e))));
    }
  }
}
