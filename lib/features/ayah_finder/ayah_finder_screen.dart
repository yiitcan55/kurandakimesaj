import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../quran/quran_screens.dart';
import '../studio/studio_screens.dart';
import 'ayah_finder_controller.dart';

/// Ayet Bulucu — bir gönderinin ekran görüntüsünden/bağlantısından ya da
/// elindeki bir tilavet **videosundan** hangi Kur'an ayetlerinin geçtiğini bulur.
///
/// Video kullanıcının KENDİ cihazından gelir (galeri, paylaş menüsü — WhatsApp/
/// Telegram videosu, kaydedilmiş klip). Uygulama hiçbir platformdan video
/// indirmez — bkz. Karar Günlüğü (App Store 5.2.3).
class AyahFinderScreen extends ConsumerStatefulWidget {
  const AyahFinderScreen({super.key, this.initialImagePath});

  /// Paylaş menüsünden gelen görsel yolu (Faz 3).
  final String? initialImagePath;

  @override
  ConsumerState<AyahFinderScreen> createState() => _AyahFinderScreenState();
}

class _AyahFinderScreenState extends ConsumerState<AyahFinderScreen> {
  /// Ses hattı görsel hattından belirgin şekilde yavaştır (yükleme + ASR).
  /// Kullanıcı bekleyeceğini bilsin diye yükleme metni buna göre değişir.
  bool _videoPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeInitialInput());
  }

  /// Paylaş menüsünden (sharedAyahInputProvider) veya constructor'dan gelen
  /// girdiyi bir kez işle.
  void _consumeInitialInput() {
    final notifier = ref.read(ayahFinderProvider.notifier);
    final shared = ref.read(sharedAyahInputProvider);
    if (shared != null) {
      ref.read(sharedAyahInputProvider.notifier).clear(); // bir kez tüket
      if (shared.videoPath != null && shared.videoPath!.isNotEmpty) {
        _startVideo(() => notifier.fromVideo(shared.videoPath!));
        return;
      }
      if (shared.imagePath != null && shared.imagePath!.isNotEmpty) {
        notifier.fromSharedImage(shared.imagePath!);
        return;
      }
      // Paylaş menüsünden metin/URL (X, blog, haber — og:image yayınlayan siteler):
      // manuel URL alanı kaldırıldı ama paylaş-intent yolu korunur.
      if (shared.url != null && shared.url!.isNotEmpty) {
        notifier.fromUrl(shared.url!);
        return;
      }
    }
    final path = widget.initialImagePath;
    if (path != null && path.isNotEmpty) {
      notifier.fromSharedImage(path);
    }
  }

  /// Video aramasını başlat + yükleme metnini "video" moduna al.
  Future<void> _startVideo(Future<void> Function() run) async {
    setState(() => _videoPending = true);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _videoPending = false);
    }
  }

  void _search(VoidCallback run) {
    setState(() => _videoPending = false);
    run();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(ayahFinderProvider);
    final notifier = ref.read(ayahFinderProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Ayet Bul'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Text(
                    'Elindeki tilavet videosunu ya da bir gönderinin ekran görüntüsünü '
                    'seç; okunan ayetleri ve mealini bulalım.',
                    style: AppTypography.body(size: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  _SourceButton(
                    icon: Icons.movie_filter_rounded,
                    title: 'Video Seç',
                    subtitle: 'Tilavet videosu — okunan ayetleri bul',
                    onTap: () => _startVideo(notifier.fromVideoGallery),
                  ),
                  const SizedBox(height: 12),
                  _SourceButton(
                    icon: Icons.image_search_rounded,
                    title: 'Galeriden Seç',
                    subtitle: 'Ekran görüntüsü / görsel',
                    onTap: () => _search(notifier.fromGallery),
                  ),
                  const SizedBox(height: 22),
                  result.when(
                    loading: () => _LoadingView(video: _videoPending),
                    error: (_, _) => _ErrorView(code: 'network'),
                    data: (r) => r == null
                        ? const SizedBox.shrink()
                        : _ResultView(result: r),
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

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.video});
  final bool video;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            video
                ? 'Video analiz ediliyor…\nBu birkaç saniye sürebilir.'
                : 'Aranıyor…',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 13.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.goldFaint, borderRadius: AppRadii.smAll),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body(size: 16, weight: FontWeight.w600, color: AppColors.cream)),
                Text(subtitle,
                    style: AppTypography.body(size: 13, color: AppColors.muted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final AyahFinderResult result;

  @override
  Widget build(BuildContext context) {
    switch (result.status) {
      case AyahFinderStatus.matched:
        if (result.matches.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            message: 'Bir ayet tanındı ama içeriği getirilemedi. Tekrar dene.',
          );
        }
        // Video hattı: birden çok ayet + aralık + zaman çizelgesi.
        final range = result.range;
        if (range != null && !range.isSingle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RangeHeader(range: range, ayahCount: result.matches.length),
              const SizedBox(height: 14),
              for (final m in result.matches) ...[
                _MatchCard(match: m, primary: true),
                const SizedBox(height: 12),
              ],
              if (result.timeline.isNotEmpty) _TimelineCard(timeline: result.timeline),
            ],
          );
        }
        return _MatchCard(match: result.matches.first, primary: true);
      case AyahFinderStatus.ambiguous:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Birden çok olası ayet bulundu — doğru olanı seç:',
                style: AppTypography.body(size: 14, color: AppColors.cream2)),
            const SizedBox(height: 12),
            for (final m in result.matches) ...[
              _MatchCard(match: m, primary: false),
              const SizedBox(height: 12),
            ],
          ],
        );
      case AyahFinderStatus.notFound:
        return const EmptyState(
          icon: Icons.search_off_rounded,
          message: 'Tanıyabildiğimiz bir ayet bulunamadı.\n'
              'Videoda tilavetin net duyulduğundan ya da görselde ayetin net '
              'göründüğünden emin olup tekrar dene.',
        );
      case AyahFinderStatus.error:
        return _ErrorView(code: result.errorCode);
    }
  }
}

/// "Yasin, 58-61 · 4 ayet" — video sonucunun başlığı.
class _RangeHeader extends StatelessWidget {
  const _RangeHeader({required this.range, required this.ayahCount});
  final AyahRange range;
  final int ayahCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.goldFaint, borderRadius: AppRadii.smAll),
            child: const Icon(Icons.graphic_eq_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Videoda okunan ayetler',
                    style: AppTypography.body(size: 13, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(range.reference,
                    style: AppTypography.body(
                        size: 18, weight: FontWeight.w600, color: AppColors.goldInk)),
              ],
            ),
          ),
          GoldChip(label: '$ayahCount ayet'),
        ],
      ),
    );
  }
}

/// "00:12 · Yasin 58" — hangi saniyede hangi ayet okunuyor.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.timeline});
  final List<AyahTimelineEntry> timeline;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Zaman çizelgesi',
              style: AppTypography.body(
                  size: 15, weight: FontWeight.w600, color: AppColors.cream)),
          const SizedBox(height: 4),
          Text('Videonun hangi anında hangi ayetin okunduğu',
              style: AppTypography.body(size: 12.5, color: AppColors.muted)),
          const SizedBox(height: 12),
          for (final t in timeline)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      t.startLabel,
                      // Tabular rakam: saat sütunu kaymasın.
                      style: AppTypography.body(size: 13.5, color: AppColors.gold)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  Expanded(
                    child: Text(t.reference,
                        style: AppTypography.body(size: 14, color: AppColors.cream)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match, required this.primary});
  final AyahMatch match;
  final bool primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(match.reference,
                    style: AppTypography.body(size: 16, weight: FontWeight.w600, color: AppColors.gold)),
              ),
              GoldChip(label: '%${(match.confidence * 100).round()} eşleşme'),
            ],
          ),
          const SizedBox(height: 14),
          AyetFrame(arabic: match.arabic),
          const SizedBox(height: 14),
          Text(match.meal, style: AppTypography.body(size: 15, color: AppColors.cream)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.bookmark_add_rounded,
                label: 'Kaydet',
                onTap: () async {
                  await ref.read(collectionsRepositoryProvider).add(
                        reference: match.reference,
                        arabic: match.arabic,
                        meal: match.meal,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Koleksiyonlara kaydedildi')),
                    );
                  }
                },
              ),
              _ActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Paylaş',
                onTap: () => ref.read(shareServiceProvider).shareText(
                      '${match.arabic}\n\n${match.meal}\n\n— ${match.reference}',
                      subject: match.reference,
                    ),
              ),
              _ActionButton(
                icon: Icons.menu_book_rounded,
                label: 'Okuyucuda Aç',
                onTap: () => _openInReader(context, ref),
              ),
              _ActionButton(
                icon: Icons.movie_creation_rounded,
                label: 'Videoya Aktar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudioScreen(
                      initialText: '${match.arabic}\n\n${match.meal}',
                      initialReference: match.reference,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Eşleşen sureyi otoriter listeden çözüp okuyucuyu o ayete kaydırarak açar.
  Future<void> _openInReader(BuildContext context, WidgetRef ref) async {
    final surahs = await ref.read(surahsProvider.future);
    final hits = surahs.where((s) => s.number == match.surah);
    if (hits.isEmpty || !context.mounted) return;
    final surah = hits.first;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SurahReaderScreen(surah: surah, initialAyah: match.ayah),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.gold),
      label: Text(label, style: AppTypography.body(size: 13.5, color: AppColors.cream)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.line)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.code});
  final String? code;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (code) {
      'link_unresolved' => (
          Icons.link_off_rounded,
          'Bu bağlantıdan görsel alınamadı (ör. Instagram giriş duvarı).\n'
              'Gönderinin ekran görüntüsünü alıp "Galeriden Seç" ile ya da '
              'videoyu cihazına kaydedip "Video Seç" ile dene.'
        ),
      'file_too_large' => (
          Icons.video_settings_rounded,
          'Video çok büyük (en fazla 20 MB).\n'
              'Kısa bir tilavet klibi (yaklaşık 3 dakikaya kadar) ile dene.'
        ),
      'video_missing' => (
          Icons.videocam_off_rounded,
          'Video okunamadı. Dosyayı tekrar seçip dene.'
        ),
      'upload_failed' => (
          Icons.cloud_upload_outlined,
          'Video yüklenemedi. İnternetini kontrol edip tekrar dene.'
        ),
      'asr_failed' => (
          Icons.hearing_disabled_rounded,
          'Videodaki ses çözümlenemedi.\n'
              'Tilavetin net duyulduğu bir klip ile tekrar dene.'
        ),
      'rate_limited' => (
          Icons.hourglass_bottom_rounded,
          'Şu an çok fazla istek var. Birkaç dakika sonra tekrar dene.'
        ),
      'forbidden_path' => (
          Icons.lock_outline_rounded,
          'Bu videoya erişim yetkin yok. Videoyu tekrar seçip dene.'
        ),
      'auth_required' => (
          Icons.login_rounded,
          'Bu özellik için giriş yapman gerekir.'
        ),
      'no_api_key' => (
          Icons.cloud_off_rounded,
          'Ayet bulma servisi şu an yapılandırılmamış.'
        ),
      _ => (
          Icons.wifi_off_rounded,
          'Bağlantı sorunu oluştu. İnternetini kontrol edip tekrar dene.'
        ),
    };
    return EmptyState(icon: icon, message: message);
  }
}
