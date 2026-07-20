import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/backend_repositories.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Video şablonu — arka plan teması (ayet → reels/TikTok render'ı için).
class VideoTemplate {
  const VideoTemplate(this.id, this.name, this.colors, this.vibe);
  final String id;
  final String name;
  final List<Color> colors;
  final String vibe;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      );
}

const List<VideoTemplate> kTemplates = [
  VideoTemplate('emerald', 'Zümrüt Huzur', [Color(0xFF0D2A20), Color(0xFF08201A)], 'Sakin'),
  VideoTemplate('gold', 'Altın Şafak', [Color(0xFF3A2E12), Color(0xFF1A1407)], 'Zarif'),
  VideoTemplate('night', 'Gece Mavisi', [Color(0xFF101A3A), Color(0xFF070B1A)], 'Huşû'),
  VideoTemplate('rose', 'Gül Bahçesi', [Color(0xFF3A1320), Color(0xFF1A070D)], 'Sıcak'),
  VideoTemplate('sand', 'Çöl Sükûneti', [Color(0xFF3A3012), Color(0xFF1A1607)], 'Dingin'),
  VideoTemplate('teal', 'Okyanus', [Color(0xFF0A2E32), Color(0xFF05171A)], 'Ferah'),
];

const List<String> kReciters = ['Mishary Alafasy', 'Abdulbasit', 'Sudais', 'Hüzzam (TR)'];

/// Bir render işinin durum sözleşmesi — backend ile eşleşmeli.
// RenderStatus enum'u backend_repositories.dart'ta tanımlıdır.

/// Tek bir video üretim işi — Videolarım yüzeyini besler.
class RenderJob {
  const RenderJob({
    required this.id,
    required this.template,
    required this.reciter,
    required this.reference,
    required this.arabic,
    required this.meal,
    required this.queued,
    required this.status,
  });

  /// prefs'ten okunan kayıt → şablon id ile kTemplates'e çözülür.
  factory RenderJob.fromJson(Map<String, dynamic> j) {
    final queued = j['queued'] as bool? ?? false;
    return RenderJob(
      id: j['id'] as String? ?? '',
      template: kTemplates.firstWhere(
        (t) => t.id == j['template'],
        orElse: () => kTemplates.first,
      ),
      reciter: j['reciter'] as String? ?? kReciters.first,
      reference: j['reference'] as String? ?? '',
      arabic: j['arabic'] as String? ?? '',
      meal: j['meal'] as String? ?? '',
      queued: queued,
      status: RenderStatus.values
              .where((s) => s.name == j['status'])
              .firstOrNull ??
          (queued ? RenderStatus.queued : RenderStatus.processing),
    );
  }

  final String id;
  final VideoTemplate template;
  final String reciter;
  final String reference;
  final String arabic;
  final String meal;
  final bool queued;
  final RenderStatus status;

  RenderJob copyWith({RenderStatus? status}) => RenderJob(
        id: id,
        template: template,
        reciter: reciter,
        reference: reference,
        arabic: arabic,
        meal: meal,
        queued: queued,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'template': template.id,
        'reciter': reciter,
        'reference': reference,
        'arabic': arabic,
        'meal': meal,
        'queued': queued,
        'status': status.name,
      };
}

/// Render işleri notifier'ı (SharedPreferences'a kalıcı yazar).
class RenderJobsNotifier extends Notifier<List<RenderJob>> {
  static const _k = 'render_jobs';

  @override
  List<RenderJob> build() {
    final raw = ref.watch(prefsProvider).getString(_k);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RenderJob.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(RenderJob job) async {
    state = [job, ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((j) => j.id != id).toList(growable: false);
    await _persist();
  }

  Future<void> _persist() async {
    final raw = jsonEncode(state.map((j) => j.toJson()).toList());
    await ref.read(prefsProvider).setString(_k, raw);
  }
}

final renderJobsProvider =
    NotifierProvider<RenderJobsNotifier, List<RenderJob>>(RenderJobsNotifier.new);

// ── Canva benzeri görsel editör ─────────────────────────────────────────────

/// Metin konumu
enum _TextPosition { top, center, bottom }

/// StudioScreen — Canva benzeri gerçek editör.
/// Arka plan seç → Ayet/Metin yaz → Özelleştir → Önizle → Paylaş/Yükle.
class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key, this.template, this.initialText, this.initialReference});
  final VideoTemplate? template;

  /// Ayet Bulucu "Videoya Aktar" ile gelindiğinde önyüklenen ayet metni (Arapça+meal).
  final String? initialText;

  /// Önyüklenen ayetin referansı (ör. "Yasin, 58") — paylaşım altyazısı için.
  final String? initialReference;

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  // Preview alanı
  final GlobalKey _previewKey = GlobalKey();

  // Arka plan
  late int _selectedTemplate;
  File? _bgImage;

  // Metin
  String _overlayText = '';
  double _fontSize = 22.0;
  Color _textColor = Colors.white;
  _TextPosition _textPosition = _TextPosition.center;

  // Boyut modu: true = Story (9:16), false = Kare (1:1)
  bool _storyMode = true;

  // Dışa aktarım
  bool _exporting = false;

  // Metin controller
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tpl = widget.template;
    _selectedTemplate = tpl != null
        ? kTemplates.indexWhere((t) => t.id == tpl.id).clamp(0, kTemplates.length - 1)
        : 0;
    // "Videoya Aktar" ile gelen ayet metnini önyükle.
    final text = widget.initialText;
    if (text != null && text.isNotEmpty) {
      _overlayText = text;
      _textController.text = text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Galeri'den arka plan seç ──────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _bgImage = File(file.path);
      });
    }
  }

  // ── PNG dışa aktarım → paylaş ────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ayet_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: "Kur'an'dan bir mesaj"),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Supabase'e yükle ──────────────────────────────────────────────────────

  Future<void> _uploadToSupabase() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null || client.auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmanız gerekiyor')),
        );
      }
      return;
    }
    setState(() => _exporting = true);
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final userId = client.auth.currentUser!.id;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.png';

      await client.storage.from('post-media').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      final url = client.storage.from('post-media').getPublicUrl(path);

      await client.from('feed_posts').insert({
        'user_id': userId,
        'kind': 'image',
        'thumbnail_url': url,
        'caption': _overlayText,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşıldı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Önizleme widget'ı ─────────────────────────────────────────────────────

  Widget _buildPreview() {
    final template = kTemplates[_selectedTemplate];

    // Metin hizalama
    final Alignment textAlignment = switch (_textPosition) {
      _TextPosition.top => Alignment.topCenter,
      _TextPosition.center => Alignment.center,
      _TextPosition.bottom => Alignment.bottomCenter,
    };

    Widget backgroundWidget;
    if (_bgImage != null) {
      backgroundWidget = Image.file(
        _bgImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      backgroundWidget = Container(
        decoration: BoxDecoration(
          gradient: template.gradient,
        ),
      );
    }

    Widget textWidget = _overlayText.isEmpty
        ? Text(
            'Metin buraya gelecek…',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: _fontSize, color: AppColors.muted),
          )
        : Text(
            _overlayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _fontSize,
              color: _textColor,
              fontWeight: FontWeight.w600,
              height: 1.4,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
          );

    return RepaintBoundary(
      key: _previewKey,
      child: AspectRatio(
        aspectRatio: _storyMode ? 9 / 16 : 1,
        child: ClipRRect(
          borderRadius: AppRadii.lgAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              backgroundWidget,
              // Hafif karartma katmanı — metin okunabilirliği
              Container(color: Colors.black.withValues(alpha: 0.25)),
              // Altın kenarlık
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.lgAll,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
              ),
              // Metin katmanı
              Align(
                alignment: textAlignment,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: textWidget,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Şablon thumbnail'i ────────────────────────────────────────────────────

  Widget _buildTemplateThumbnail(int index) {
    final t = kTemplates[index];
    final selected = index == _selectedTemplate && _bgImage == null;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTemplate = index;
        _bgImage = null;
      }),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        margin: const EdgeInsets.only(right: 8),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: t.gradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.line,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }

  // ── Ana build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'Görsel Editör',
              trailing: IconButton(
                tooltip: 'Videolarım',
                icon: const Icon(Icons.video_library_rounded, color: AppColors.gold),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MyVideosScreen()),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── 0. Boyut seçici ──────────────────────────────────────
                  Center(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Story (9:16)'),
                          icon: Icon(Icons.crop_portrait_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Kare (1:1)'),
                          icon: Icon(Icons.crop_square_rounded, size: 16),
                        ),
                      ],
                      selected: {_storyMode},
                      onSelectionChanged: (v) =>
                          setState(() => _storyMode = v.first),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 1. Önizleme ──────────────────────────────────────────
                  Center(child: _buildPreview())
                      .animate()
                      .fadeIn(duration: AppDurations.normal),
                  const SizedBox(height: 20),

                  // ── 2. Arka plan seçici ──────────────────────────────────
                  const SectionLabel(title: 'Arka Plan', eyebrow: 'Tema / Galeri'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (int i = 0; i < kTemplates.length; i++)
                          _buildTemplateThumbnail(i),
                        // Galeri butonu
                        GestureDetector(
                          onTap: _pickImage,
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _bgImage != null
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _bgImage != null ? AppColors.gold : AppColors.line,
                                width: _bgImage != null ? 2.5 : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.image_rounded,
                              color: _bgImage != null ? AppColors.gold : AppColors.muted,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Metin girişi ──────────────────────────────────────
                  const SectionLabel(title: 'Metin', eyebrow: 'Ayet Meali / Özel Metin'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    style: AppTypography.body(color: AppColors.cream),
                    decoration: const InputDecoration(
                      labelText: 'Metin / Ayet meali',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (v) => setState(() => _overlayText = v),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Font boyutu ───────────────────────────────────────
                  Row(
                    children: [
                      Text('Font', style: AppTypography.eyebrow()),
                      const SizedBox(width: 8),
                      Text(
                        _fontSize.round().toString(),
                        style: AppTypography.body(size: 13, color: AppColors.gold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12,
                    max: 40,
                    divisions: 28,
                    activeColor: AppColors.gold,
                    inactiveColor: AppColors.line,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                  const SizedBox(height: 12),

                  // ── 5. Renk seçici ───────────────────────────────────────
                  const SectionLabel(title: 'Metin Rengi', eyebrow: 'Renk'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ColorCircle(
                        color: Colors.white,
                        selected: _textColor == Colors.white,
                        onTap: () => setState(() => _textColor = Colors.white),
                      ),
                      const SizedBox(width: 12),
                      _ColorCircle(
                        color: const Color(0xFFD4AF37),
                        selected: _textColor == const Color(0xFFD4AF37),
                        onTap: () => setState(() => _textColor = const Color(0xFFD4AF37)),
                        label: 'Altın',
                      ),
                      const SizedBox(width: 12),
                      _ColorCircle(
                        color: const Color(0xFFFFF8E7),
                        selected: _textColor == const Color(0xFFFFF8E7),
                        onTap: () => setState(() => _textColor = const Color(0xFFFFF8E7)),
                        label: 'Krem',
                      ),
                      const SizedBox(width: 12),
                      _ColorCircle(
                        color: Colors.black,
                        selected: _textColor == Colors.black,
                        onTap: () => setState(() => _textColor = Colors.black),
                        label: 'Siyah',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── 6. Pozisyon toggle ───────────────────────────────────
                  const SectionLabel(title: 'Konum', eyebrow: 'Metin Pozisyonu'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PositionButton(
                          label: 'Üst',
                          icon: Icons.vertical_align_top_rounded,
                          selected: _textPosition == _TextPosition.top,
                          onTap: () => setState(() => _textPosition = _TextPosition.top),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PositionButton(
                          label: 'Orta',
                          icon: Icons.vertical_align_center_rounded,
                          selected: _textPosition == _TextPosition.center,
                          onTap: () => setState(() => _textPosition = _TextPosition.center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PositionButton(
                          label: 'Alt',
                          icon: Icons.vertical_align_bottom_rounded,
                          selected: _textPosition == _TextPosition.bottom,
                          onTap: () => setState(() => _textPosition = _TextPosition.bottom),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 7. Alt eylem butonları ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: const Text('PNG Kaydet'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting ? null : _uploadToSupabase,
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: const Text("Akışa Yükle"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.gold),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            shape: const RoundedRectangleBorder(borderRadius: AppRadii.smAll),
                          ),
                        ),
                      ),
                    ],
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

// ── Yardımcı widget'lar ──────────────────────────────────────────────────────

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.line,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

class _PositionButton extends StatelessWidget {
  const _PositionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.gold : AppColors.muted, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.body(
                size: 12,
                color: selected ? AppColors.gold : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ortak yardımcılar ────────────────────────────────────────────────────────

/// Bir render işini topluluk akışına paylaşır.
Future<void> shareJobToFeed(BuildContext context, WidgetRef ref, RenderJob job) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!ref.read(supabaseGatewayProvider).isSignedIn) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Paylaşmak için giriş yap.')),
    );
    return;
  }
  await ref.read(socialRepositoryProvider).createPost(
        reference: job.reference,
        arabic: job.arabic,
        meal: job.meal,
        topic: job.template.vibe,
        kind: 'video',
        templateId: job.template.id,
        videoUrl: null,
      );
  messenger.showSnackBar(
    const SnackBar(content: Text('Akışa paylaşıldı.')),
  );
}

String _statusLabel(RenderJob job) {
  if (!job.queued) return 'Bağlanınca işlenecek';
  return switch (job.status) {
    RenderStatus.ready => 'Hazır',
    RenderStatus.failed => 'Başarısız',
    RenderStatus.queued || RenderStatus.processing => 'İşleniyor (sunucuda)',
  };
}

IconData _statusIcon(RenderJob job) {
  if (!job.queued) return Icons.hourglass_empty_rounded;
  return switch (job.status) {
    RenderStatus.ready => Icons.check_circle_rounded,
    RenderStatus.failed => Icons.error_outline_rounded,
    RenderStatus.queued || RenderStatus.processing => Icons.cloud_sync_rounded,
  };
}

/// Stüdyo önizlemesinin küçük (thumbnail) hâli — şablon gradyanı + ayet.
class _RenderPreview extends StatelessWidget {
  const _RenderPreview({required this.job});
  final RenderJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: job.template.colors,
        ),
        borderRadius: AppRadii.smAll,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(job.arabic, textAlign: TextAlign.center, style: arabicStyle(size: 16)),
        ),
      ),
    );
  }
}

/// Üretilen videoların indiği yüzey.
class MyVideosScreen extends ConsumerWidget {
  const MyVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(renderJobsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Videolarım'),
            Expanded(
              child: jobs.isEmpty
                  ? EmptyState(
                      icon: Icons.video_library_outlined,
                      message: 'Henüz video üretmedin.\nBir ayet seç, ilk videonu oluştur.',
                      action: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const StudioScreen()),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Video oluştur'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: jobs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final job = jobs[i];
                        return Dismissible(
                          key: ValueKey(job.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref.read(renderJobsProvider.notifier).remove(job.id);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Video taslağı silindi')),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              borderRadius: AppRadii.mdAll,
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.accent),
                          ),
                          child: AppCard(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: AspectRatio(
                                      aspectRatio: 9 / 16, child: _RenderPreview(job: job)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(job.template.name,
                                          style: AppTypography.body(
                                              size: 15,
                                              weight: FontWeight.w600,
                                              color: AppColors.cream)),
                                      const SizedBox(height: 2),
                                      Text(job.reference,
                                          style: AppTypography.body(
                                              size: 12.5, color: AppColors.muted)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            _statusIcon(job),
                                            size: 13,
                                            color: AppColors.gold,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _statusLabel(job),
                                            style: AppTypography.body(
                                                size: 12, color: AppColors.gold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Akışa paylaş',
                                  icon: const Icon(Icons.dynamic_feed_rounded,
                                      color: AppColors.gold, size: 20),
                                  onPressed: () => shareJobToFeed(context, ref, job),
                                ),
                                IconButton(
                                  tooltip: job.status == RenderStatus.ready
                                      ? 'Dışa aktar'
                                      : 'Video hazır olunca dışa aktarılır',
                                  icon: Icon(
                                    Icons.ios_share_rounded,
                                    color: job.status == RenderStatus.ready
                                        ? AppColors.gold
                                        : AppColors.muted,
                                    size: 20,
                                  ),
                                  onPressed: job.status == RenderStatus.ready
                                      ? () => ref
                                          .read(shareServiceProvider)
                                          .shareText('${job.meal}\n(${job.reference})')
                                      : null,
                                ),
                              ],
                            ),
                          ),
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
