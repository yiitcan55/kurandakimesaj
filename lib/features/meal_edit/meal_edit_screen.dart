import 'dart:io';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../data/backend_repositories.dart';
import '../../domain/meal_cues.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../ayah_finder/ayah_error_messages.dart';
import '../ayah_finder/ayah_finder_controller.dart';
import 'ayah_range_sheet.dart';
import 'meal_edit_controller.dart';
import 'meal_publish_sheet.dart';
import 'meal_subtitle_overlay.dart';
import 'meal_timeline.dart';

/// Meal Düzenle: videoyu seç, ayetleri algıla, meal altyazısını ayarla, yayınla.
/// Ekran YALNIZ [VideoPlayerController]'ı sahiplenir; iş mantığı controller'da.
class MealEditScreen extends ConsumerStatefulWidget {
  const MealEditScreen({super.key});

  @override
  ConsumerState<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends ConsumerState<MealEditScreen> {
  // Video yokken zaman çizelgesi/altyazı için boş konum kaynağı.
  final _idle = ValueNotifier(const VideoPlayerValue.uninitialized());
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;

  MealEditController get _notifier => ref.read(mealEditProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumeShared(ref.read(sharedAyahInputProvider));
      final path = ref.read(mealEditProvider).videoPath;
      if (path != null && _video == null) _onPath(path);
    });
  }

  @override
  void dispose() {
    _video?.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Paylaşım girdisini tüketir; görsel girdiye (Ayet Bul'un) dokunmaz.
  void _consumeShared(SharedAyahInput? input) {
    if (input == null || (input.imagePath ?? '').isNotEmpty) return;
    final shared = ref.read(sharedAyahInputProvider.notifier);
    if ((input.videoPath ?? '').isNotEmpty) {
      shared.clear();
      _notifier.loadVideo(input.videoPath!);
    } else if ((input.url ?? '').isNotEmpty) {
      shared.clear();
      _notifier.showLinkHint();
    }
  }

  Future<void> _onPath(String? path) async {
    final old = _video;
    _video = null;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }
    // Eski controller bir kare boyunca hâlâ ağaçta olabilir; kareden sonra bırak.
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    if (path == null) return;

    final c = VideoPlayerController.file(File(path));
    _video = c;
    try {
      await c.initialize();
      if (!identical(_video, c)) return await c.dispose();
      if (!mounted) return;
      await c.setLooping(true);
      if (!identical(_video, c)) return await c.dispose();
      if (!mounted) return;
      setState(() => _ready = true);
      _notifier.setDuration(c.value.duration.inMilliseconds / 1000);
    } catch (e) {
      // Oynatılamayan video ekranı düşürmez; analiz/elle seçim sürer.
      debugPrint('meal video init failed: $e');
      if (!identical(_video, c)) return await c.dispose();
      _video = null;
      await c.dispose();
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _togglePlay() {
    final c = _video;
    if (c == null || !_ready) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  void _openFullscreen() {
    final c = _video;
    if (c == null || !_ready) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MealFullscreen(controller: c),
      ),
    );
  }

  Future<void> _pickRange(MealEditState s) async {
    final pick = await showAyahRangeSheet(
      context,
      maxAyahs: kMealCueMax,
      initialSurah: s.range?.surah,
    );
    if (pick == null || !mounted) return;
    await _notifier.setManualRange(
      surah: pick.surah,
      from: pick.from,
      to: pick.to,
    );
  }

  void _publish(MealEditState s) {
    final reason = !ref.read(isSignedInProvider)
        ? 'Yayınlamak için giriş yapmalısın.'
        : s.tooLarge
        ? "Video 20 MB'tan büyük olduğu için Reels'e yayınlanamaz."
        : null;
    showMealPublishSheet(
      context,
      onPublish: (caption) => _notifier.publish(caption: caption),
      disabledReason: reason,
    );
  }

  void _showInfo() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Nasıl çalışır?', style: AppTypography.display(size: 22)),
      content: SingleChildScrollView(
        child: Text(
          "Bir video seç; videodaki Kur'an tilaveti analiz edilir, "
          'ayetler bulunur ve meal altyazısı zamanlanır. Sonucu düzenleyip '
          "Reels'e yayınlayabilirsin.\n\n"
          'Sonuçlar yapay zekâ ile bulunur ve yanılabilir; meal metni '
          'Diyanet mealinden gelir.\n\n'
          'Videon yalnızca analiz için kullanılır; yayınlamadan çıkarsan '
          'uygulamadan silinir.',
          style: AppTypography.body(),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(mealEditProvider.select((s) => s.videoPath), (_, p) => _onPath(p));
    ref.listen(sharedAyahInputProvider, (_, n) => _consumeShared(n));
    final s = ref.watch(mealEditProvider);

    return PopScope(
      canPop: !s.publishing,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _brandRow(s),
                    const SizedBox(height: 16),
                    _titleBlock(),
                    const SizedBox(height: 16),
                    if (s.linkShared && s.videoPath == null) ...[
                      _linkHint(),
                      const SizedBox(height: 12),
                    ],
                    _videoCard(s),
                    const SizedBox(height: 14),
                    _analysisCard(s),
                    const SizedBox(height: 14),
                    MealTimeline(
                      position: _video ?? _idle,
                      cues: s.cues,
                      onSeek: (d) => _video?.seekTo(d),
                    ),
                    const SizedBox(height: 14),
                    _manualRow(s),
                    const SizedBox(height: 14),
                    _styleRow(s),
                    const SizedBox(height: 18),
                    Text(
                      'Seçilen Ayet Aralığı',
                      style: AppTypography.body(
                        weight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _rangeBox(s),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('mealEditCta'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.successSurface,
                      foregroundColor: AppColors.onSuccess,
                    ),
                    onPressed: s.cues.isEmpty || s.publishing || s.published
                        ? null
                        : () => _publish(s),
                    child: const Text('Meal Edit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandRow(MealEditState s) => Row(
    children: [
      IconButton(
        tooltip: 'Geri',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: s.publishing ? null : () => context.pop(),
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.goldInk),
      ),
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: AppRadii.smAll,
          border: Border.all(color: AppColors.gold, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.emerald700, AppColors.emerald950],
          ),
        ),
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text('إقرأ', style: arabicStyle(size: 15)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kur'an'da ki Mesaj", style: AppTypography.display(size: 20)),
            Text(
              "Kur'an'ı daha iyi anlamak için",
              style: AppTypography.body(size: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      IconButton(
        key: const Key('mealInfoButton'),
        tooltip: 'Bilgi',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: _showInfo,
        icon: Icon(Icons.info_outline_rounded, color: AppColors.goldInk),
      ),
    ],
  );

  Widget _titleBlock() => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.16),
          borderRadius: AppRadii.smAll,
        ),
        child: Icon(Icons.subtitles_rounded, color: AppColors.success),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meal Düzenle', style: AppTypography.display(size: 28)),
            Text(
              'Videodaki ayetleri algıla ve mealini ekle',
              style: AppTypography.body(size: 13.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _linkHint() => AppCard(
    key: const Key('mealLinkHint'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.link_rounded, color: AppColors.goldInk),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Bu uygulama videoyu değil yalnızca bağlantısını paylaştı. '
            'Videoyu telefonuna kaydet, sonra aşağıdan Video Seç ile '
            'galeriden seç.',
            style: AppTypography.body(size: 14),
          ),
        ),
      ],
    ),
  );

  Widget _videoCard(MealEditState s) {
    final c = _video;
    final playable = c != null && _ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: AppRadii.mdAll,
            child: ColoredBox(
              color: AppColors.mediaLetterbox,
              child: playable ? _player(c, s) : _videoPlaceholder(s),
            ),
          ),
        ),
        if (s.videoPath == null) ...[
          const SizedBox(height: 10),
          Text(
            "Başka bir uygulamada Paylaş menüsünden Kur'an'da ki Mesaj'ı "
            'seçerek de video gönderebilirsin.',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 12.5, color: AppColors.muted),
          ),
        ],
      ],
    );
  }

  Widget _videoPlaceholder(MealEditState s) {
    if (s.videoPath != null) {
      return Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Video oynatılamıyor',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.onMedia),
                ),
              )
            : const CircularProgressIndicator(),
      );
    }
    return Center(
      child: FilledButton.icon(
        key: const Key('mealPickVideo'),
        style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
        onPressed: s.publishing ? null : _notifier.pickVideo,
        icon: const Icon(Icons.video_library_rounded),
        label: const Text('Video Seç'),
      ),
    );
  }

  Widget _player(VideoPlayerController c, MealEditState s) {
    final chip = AppTypography.body(size: 12, color: AppColors.onMedia);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover-fit: videonun en-boyu korunur, taşan kısım kırpılır.
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _togglePlay,
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'Video Yüklendi',
                style: AppTypography.body(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: AppColors.onSuccess,
                ),
              ),
            ),
          ),
        ),
        // Altyazı kartın ortasını kapladığı için ortadaki büyük düğme yalnız
        // altyazı yokken görünür; cue varken düğme alt satıra iner.
        if (s.cues.isEmpty) Center(child: _playButton(c, compact: false)),
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          bottom: 44,
          child: FittedMealSubtitle(position: c, cues: s.cues, style: s.style),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.cues.isEmpty)
                const SizedBox(width: 12)
              else
                _playButton(c, compact: true),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: c,
                builder: (_, v, _) => Text(
                  '${formatClock(v.position)} / ${formatClock(v.duration)}',
                  style: chip,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: IconButton(
            tooltip: 'Tam ekran',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            color: AppColors.onMedia,
            onPressed: _openFullscreen,
            icon: const Icon(Icons.fullscreen_rounded),
          ),
        ),
      ],
    );
  }

  Widget _playButton(VideoPlayerController c, {required bool compact}) =>
      ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (_, v, _) => IconButton.filled(
          tooltip: v.isPlaying ? 'Duraklat' : 'Oynat',
          style: IconButton.styleFrom(
            minimumSize: Size.square(compact ? 44 : 56),
            backgroundColor:
                AppColors.mediaLetterbox.withValues(alpha: compact ? 0 : 0.6),
            foregroundColor: AppColors.onMedia,
          ),
          onPressed: _togglePlay,
          icon: Icon(
            v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: compact ? 24 : 32,
          ),
        ),
      );

  Widget _analysisCard(MealEditState s) {
    final code = s.errorCode;
    final msg = code == null
        ? null
        : (ayahErrorMessage(code)?.$2 ?? 'Beklenmeyen bir sorun oluştu. Tekrar dene.');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.goldInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yapay Zeka Analizi',
                  style: AppTypography.body(
                    weight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _pill(s),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Videodaki ses analiz ediliyor. Sadece Kur'an tilaveti algılanır, "
            'diğer sesler dikkate alınmaz.',
            style: AppTypography.body(size: 13, color: AppColors.muted),
          ),
          if (msg != null) ...[
            const SizedBox(height: 10),
            Text(
              msg,
              key: const Key('mealErrorText'),
              style: AppTypography.body(size: 13.5, color: AppColors.danger),
            ),
          ],
          if (code == 'auth_required')
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: () => context.push('/auth'),
              child: const Text('Giriş Yap'),
            ),
        ],
      ),
    );
  }

  Widget _pill(MealEditState s) {
    final retry = s.phase == MealEditPhase.needsManual && !s.tooLarge;
    final label = switch (s.phase) {
      MealEditPhase.analyzing => 'Analiz Ediliyor…',
      // Hap yapay zekânın yapmadığı işi sahiplenmez: 20 MB üstünde analiz hiç
      // çalışmadı; tüm cue'lar yaklaşıksa aralık elle seçildi (çapa yok).
      MealEditPhase.ready =>
        s.tooLarge
            ? 'Analiz Yok'
            : s.cues.isNotEmpty && s.cues.every((c) => c.approx)
            ? 'Elle Seçildi'
            : 'Tamamlandı',
      MealEditPhase.needsManual => s.tooLarge ? 'Analiz Yok' : 'Tekrar Dene',
      MealEditPhase.idle => 'Bekliyor',
    };
    final lit = s.phase == MealEditPhase.ready || s.phase == MealEditPhase.analyzing;
    final color = lit ? AppColors.success : AppColors.muted;
    return InkWell(
      key: const Key('mealAnalysisPill'),
      borderRadius: BorderRadius.circular(99),
      onTap: retry ? _notifier.analyze : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.phase == MealEditPhase.analyzing) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTypography.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _manualRow(MealEditState s) => AppCard(
    key: const Key('mealManualRange'),
    onTap: () => _pickRange(s),
    child: Row(
      children: [
        Icon(Icons.tune_rounded, color: AppColors.goldInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayet Aralığını Manuel Seç',
                style: AppTypography.body(
                  weight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
              Text(
                'Eğer yapay zeka doğru algılayamazsa, ayet aralığını kendin '
                'seçebilirsin.',
                style: AppTypography.body(size: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    ),
  );

  Widget _styleRow(MealEditState s) => AppCard(
    child: Row(
      children: [
        Icon(Icons.text_fields_rounded, color: AppColors.goldInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Altyazı Tipi',
                style: AppTypography.body(
                  weight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
              Text(
                'Meal metninin görünümünü özelleştir.',
                style: AppTypography.body(size: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        PopupMenuButton<MealCueStyle>(
          key: const Key('mealStylePicker'),
          tooltip: 'Altyazı tipi',
          initialValue: s.style,
          onSelected: _notifier.setStyle,
          itemBuilder: (_) => [
            for (final v in MealCueStyle.values)
              PopupMenuItem(value: v, height: 48, child: Text(v.label)),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.style.label,
                  style: AppTypography.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: AppColors.success),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _rangeBox(MealEditState s) {
    final r = s.range;
    final approx = s.cues.any((c) => c.approx);
    return CustomPaint(
      key: const Key('mealRangeBox'),
      painter: _DashedBorderPainter(color: AppColors.muted.withValues(alpha: 0.6)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: r == null
              ? Column(
                  children: [
                    Text(
                      'Henüz ayet aralığı seçilmedi.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yapay zeka tamamlandığında otomatik seçilecektir.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(size: 13, color: AppColors.muted),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      r.reference,
                      textAlign: TextAlign.center,
                      style: AppTypography.display(size: 22),
                    ),
                    Text(
                      '${r.toAyah - r.fromAyah + 1} ayet',
                      style: AppTypography.body(size: 13, color: AppColors.muted),
                    ),
                    if (s.cues.isEmpty)
                      Padding(
                        key: const Key('mealNoDurationHint'),
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Video süresi okunamadı; meal zamanlanamıyor.',
                          style: AppTypography.body(size: 12, color: AppColors.danger),
                        ),
                      ),
                    if (approx)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Yaklaşık zamanlama',
                          style: AppTypography.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.goldInk,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Kesikli yuvarlak köşeli çerçeve (paket yok).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadii.md)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// Aynı controller ile tam ekran sayfa; controller'ı BURADA dispose ETME.
@visibleForTesting
class MealFullscreen extends ConsumerWidget {
  const MealFullscreen({super.key, required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Yeni video gelince _onPath bu controller'ı dispose eder; önce kapan.
    ref.listen(mealEditProvider.select((s) => s.videoPath), (_, _) => Navigator.of(context).maybePop());
    final s = ref.watch(mealEditProvider);
    return Scaffold(
      backgroundColor: AppColors.mediaLetterbox,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.value.isPlaying
                ? controller.pause()
                : controller.play(),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SafeArea(
              child: MealSubtitleOverlay(
                position: controller,
                cues: s.cues,
                style: s.style,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Kapat',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                color: AppColors.onMedia,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
