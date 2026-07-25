import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backend_repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Ayet kartı şablonu — arka plan teması. Gerçek video render'ı kapsam dışı;
/// şablon hem stüdyo önizlemesinde hem de Reels'teki 'still' kartta kullanılır.
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

  /// Önyüklenen ayetin referansı (ör. "Yasin, 58") — paylaşım altyazısı ve
  /// yayınlanan kartın ayet künyesi (`feed_posts.reference`) olarak kullanılır.
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

  // Dışa aktarım / yayınlama
  bool _exporting = false;
  bool _publishing = false;

  /// Telif/hak sahipliği beyanı (Guideline 5.2.3 + 1.2). Stüdyo arka planı
  /// kullanıcının galerisinden gelebildiği için bu ekran da CreatePostSheet
  /// ile AYNI kapıya tabi: iki yayın yolundan biri onaysız kalırsa kural
  /// fiilen uygulanmıyor demektir.
  bool _rightsAccepted = false;

  // Metin controller
  final _textController = TextEditingController();

  /// Ayet künyesi — "Videoya Aktar" ile gelindiyse dolu, aksi hâlde boş.
  String get _reference => widget.initialReference?.trim() ?? '';

  /// Paylaşım altyazısı: künye varsa onu kullan, yoksa genel metin.
  String get _shareText => _reference.isEmpty ? "Kur'an'dan bir mesaj" : _reference;

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
        ShareParams(files: [XFile(file.path)], text: _shareText),
      );
    } catch (e) {
      if (mounted) _snack('Dışa aktarma hatası: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Reels'e yayınla ('still' reel) ────────────────────────────────────────

  /// Stüdyo çıktısını onay kuyruğuna gönderir (`kind: 'still'`).
  ///
  /// ponytail: PNG'nin kendisi YÜKLENMİYOR — yayınlanan kart, şablon + metinden
  /// Reels tarafında yeniden kurulur. Depolamaya yükleyip URL dönen bir
  /// repository metodu yok (ör. `ISocialRepository.uploadPostMedia`) ve ekran
  /// mimari kural gereği doğrudan `client.storage` çağıramaz. O metot
  /// eklendiğinde `_previewKey` baytları yüklenip buraya `mediaUrl:` geçilecek;
  /// `FeedPost.thumbnailUrl` zaten `media_url`'e düşüyor.
  Future<void> _publish() async {
    final text = _overlayText.trim();
    if (text.isEmpty) {
      _snack('Yayınlamak için önce bir metin yazın.');
      return;
    }
    if (!ref.read(isSignedInProvider)) {
      _snack('Yayınlamak için giriş yapmanız gerekiyor.');
      return;
    }
    // Savunma amaçlı: buton zaten kilitli, ama kapı burada da dursun —
    // ileride biri butonun koşulunu değiştirirse kural sessizce kalkmasın.
    if (!_rightsAccepted) {
      _snack('Yayınlamak için telif onayını işaretlemen gerekiyor.');
      return;
    }
    setState(() => _publishing = true);
    try {
      await ref.read(socialRepositoryProvider).createPost(
            reference: _reference,
            arabic: '',
            meal: text,
            caption: text,
            kind: 'still',
            templateId: kTemplates[_selectedTemplate].id,
          );
      ref.invalidate(cloudReelsProvider);
      if (mounted) {
        _snack("İçeriğin incelemeye alındı. Onaylandığında Reels'te yayınlanacak.");
      }
    } catch (e) {
      if (mounted) _snack('Yayınlama hatası: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

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
            const AppHeader(title: 'Görsel Editör'),
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
                  // Telif beyanı — CreatePostSheet'teki kapının aynısı.
                  // CheckboxListTile bilerek seçildi: dokunma hedefi, metne
                  // dokunup değiştirme ve işaretli/işaretsiz durumunun ekran
                  // okuyucuya bildirilmesi native olarak geliyor.
                  CheckboxListTile(
                    key: const Key('studio_rights_checkbox'),
                    value: _rightsAccepted,
                    onChanged: _publishing
                        ? null
                        : (v) => setState(() => _rightsAccepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Bu içeriğin bana ait olduğunu veya paylaşma hakkım '
                      'olduğunu onaylıyorum.',
                      style: AppTypography.body(size: 13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _publishing || _exporting || !_rightsAccepted
                        ? null
                        : _publish,
                    icon: _publishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded, size: 18),
                    label: const Text("Reels'e Yayınla"),
                  ),
                  const SizedBox(height: 8),
                  if (!_rightsAccepted)
                    Padding(
                      key: const Key('studio_rights_hint'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Yayınlamak için önce telif onayını işaretle.',
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.cream2,
                        ),
                      ),
                    ),
                  Text(
                    'Yayınlanan kartta şablon ve metin kullanılır; galeri arka planı '
                    'ile metin biçimi yalnızca PNG çıktısına işlenir.',
                    style: AppTypography.body(size: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _exporting || _publishing ? null : _export,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('PNG Kaydet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldInk,
                      side: BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.smAll),
                    ),
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

