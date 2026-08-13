import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

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

/// Gelişmiş görsel editörün yapılandırması.
///
/// Sınıf dışında ve `@visibleForTesting`: iki ayarı da testten doğrulanabilir
/// olmalı, çünkü ikisi de sessizce kırılıp geç fark edilecek türden.
@visibleForTesting
const ProImageEditorConfigs kStudioEditorConfigs = ProImageEditorConfigs(
  // KRİTİK: paket varsayılanı JPG. `uploadPostMedia` dosyayı `.png` adıyla ve
  // `image/png` content-type'ıyla yazıyor — varsayılan bırakılsaydı hem dosya
  // adı hem MIME yalan söylerdi.
  imageGeneration: ImageGenerationConfigs(outputFormat: OutputFormat.png),
  // sticker/emoji/audio BİLEREK YOK:
  // * sticker + emoji → moderasyondan geçmeyen YENİ bir UGC yüzeyi açar
  //   (Guideline 1.2); kapı `feed_posts` satırını korur, kullanıcının kartın
  //   üstüne yapıştırdığı rastgele görseli değil.
  // * audio → madde 5'in küratörlü (FK ile kilitli) müzik kütüphanesiyle
  //   çakışır; iki ses kaynağı olursa telif güvencesi anlamını yitirir.
  mainEditor: MainEditorConfigs(
    tools: [
      SubEditorMode.paint,
      SubEditorMode.text,
      SubEditorMode.cropRotate,
      SubEditorMode.tune,
      SubEditorMode.filter,
      SubEditorMode.blur,
    ],
  ),
);

// ── Canva benzeri görsel editör ─────────────────────────────────────────────

/// Metin konumu
enum _TextPosition { top, center, bottom }

/// StudioScreen — Canva benzeri gerçek editör.
/// Arka plan seç (şablon / görsel / video) → Ayet/Metin yaz → Özelleştir →
/// Önizle → PNG paylaş veya Reels'e yayınla.
class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({
    super.key,
    this.template,
    this.initialArabic,
    this.initialText,
    this.initialReference,
  });
  final VideoTemplate? template;

  /// Ayet Bulucu ile gelindiğinde önyüklenen Arapça metin. Düzenlenemez:
  /// yayınlanan kartın `feed_posts.arabic` alanına AYRI gider (Reels oynatıcısı
  /// RTL bloğu buradan çizer) ve önizlemede Amiri Quran ile RTL render edilir.
  final String? initialArabic;

  /// Önyüklenen ayetin meali — düzenlenebilir metin alanına düşer.
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

  // Arka plan: şablon gradyanı (varsayılan) VEYA galeriden seçilen tek bir
  // dosya. Dosya görsel de video da olabilir; hangisi olduğunu [_bgIsVideo]
  // söyler (iki ayrı alan tutmak "ikisi de dolu" gibi imkânsız bir durumu
  // temsil edilebilir kılardı).
  late int _selectedTemplate;
  File? _bgFile;
  bool _bgIsVideo = false;

  /// Video arka planın önizleme oynatıcısı — yalnız [_bgIsVideo] iken canlı.
  /// Yeni seçimde ve `dispose`ta MUTLAKA bırakılır (decoder sızıntısı).
  VideoPlayerController? _bgVideo;

  // Metin
  String _overlayText = '';
  double _fontSize = 22.0;
  Color _textColor = Colors.white;
  _TextPosition _textPosition = _TextPosition.center;

  // Boyut modu: true = Story (9:16), false = Kare (1:1)
  bool _storyMode = true;

  /// Seçili küratörlü müzik parçası (`feed_audio_tracks.id`). Kullanıcı keyfi
  /// bir ses URL'i veremez — yalnız kütüphaneden seçebilir; telif güvencesi
  /// yabancı anahtarda durur.
  String? _audioTrackId;

  /// "Gelişmiş Düzenle" sonrası dönen görsel. Doluysa yayınlanan/paylaşılan
  /// şey ARTIK marka bestecisinin çıktısı değil, kullanıcının düzenlediği
  /// bayttır. `null` → normal akış.
  Uint8List? _editedBytes;

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

  /// Ayetin Arapça metni — "Videoya Aktar" ile gelindiyse dolu, aksi hâlde boş
  /// (kullanıcının kendi yazdığı serbest metinde Arapça blok yoktur).
  String get _arabic => widget.initialArabic?.trim() ?? '';

  /// Paylaşım altyazısı: künye varsa onu kullan, yoksa genel metin.
  String get _shareText => _reference.isEmpty ? "Kur'an'dan bir mesaj" : _reference;

  @override
  void initState() {
    super.initState();
    final tpl = widget.template;
    _selectedTemplate = tpl != null
        ? kTemplates.indexWhere((t) => t.id == tpl.id).clamp(0, kTemplates.length - 1)
        : 0;
    // "Videoya Aktar" ile gelen ayet mealini önyükle.
    final text = widget.initialText;
    if (text != null && text.isNotEmpty) {
      _overlayText = text;
      _textController.text = text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _bgVideo?.dispose();
    super.dispose();
  }

  // ── Galeri'den arka plan seç ──────────────────────────────────────────────

  /// Video önizleyiciyi bırak — yeni arka plan seçilince ve şablona dönünce.
  void _releaseVideo() {
    _bgVideo?.dispose();
    _bgVideo = null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() {
      _releaseVideo();
      _bgFile = File(file.path);
      _bgIsVideo = false;
    });
  }

  /// Galeriden video arka planı seç. Boyut kapısı `CreatePostSheet._pickVideo`
  /// ile AYNI: `_publish` videoyu `readAsBytes()` ile tamamen belleğe alır,
  /// sınırsız bırakılırsa büyük bir galeri videosu düşük RAM'li cihazda OOM
  /// yapar. İki yayın yolu farklı sınır uygularsa biri anlamsızlaşır.
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final picked = File(file.path);
    if (picked.lengthSync() > kAyahVideoMaxBytes) {
      _snack('Video çok büyük (en fazla 20 MB). Daha kısa bir video seç.');
      return;
    }
    // Seçim ÖNCE kesinleşir. Yayınlanan şey dosyanın kendisidir, önizleme
    // değil — oynatıcı kurulamazsa (codec/platform) kullanıcının seçimini
    // sessizce çöpe atmak yanlış olurdu; sabit bir yer tutucu gösteririz.
    setState(() {
      _releaseVideo();
      _bgFile = picked;
      _bgIsVideo = true;
    });
    final controller = VideoPlayerController.file(picked);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // önizleme sessiz başlar
      // Bu arada başka bir arka plan seçilmiş olabilir → kendi kaynağımızı
      // bırak (aksi hâlde controller sahipsiz kalır, decoder sızar).
      if (!mounted || _bgFile != picked) return await controller.dispose();
      await controller.play();
      setState(() => _bgVideo = controller);
    } catch (_) {
      await controller.dispose();
    }
  }

  // ── PNG dışa aktarım → paylaş ────────────────────────────────────────────

  /// Önizlemeyi PNG baytlarına çevirir. Video arka planda çağrılmaz —
  /// tek kareye indirgemek kullanıcıyı yanıltır (bkz. "PNG Kaydet" gizleme).
  Future<Uint8List?> _renderPng() async {
    // Çağıranlar (`_export`, `_publish`) hemen öncesinde `setState` yapıyor;
    // `setState` yalnız kare PLANLAR. Bekleyen kare koşmadan `toImage()`
    // çağrılırsa boundary hâlâ `needsPaint` olur → assert / bayat kare.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final boundary =
        _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _bytesToPublish();
      if (bytes == null) return;
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

  /// Yayınlanacak/paylaşılacak baytlar — tek kaynak.
  ///
  /// Kullanıcı gelişmiş editörden geçtiyse ONUN çıktısı gider; aksi hâlde
  /// marka kartı canlı render edilir. İki yayın yolunun (`_export`,
  /// `_publish`) ayrışmaması için tek fonksiyondan geçiyorlar.
  Future<Uint8List?> _bytesToPublish() async =>
      _editedBytes ?? await _renderPng();

  /// Gelişmiş görsel editör. Marka bestecisi BİRİNCİL kalır: editör mevcut
  /// kartın PNG'siyle AÇILIR, yani zümrüt/altın kimlik ve RTL Arapça dizgi
  /// korunur; kullanıcı onun üstünde çalışır.
  Future<void> _openEditor() async {
    final bytes = await _bytesToPublish();
    if (!mounted) return;
    if (bytes == null) {
      _snack('Önizleme hazırlanamadı. Tekrar dene.');
      return;
    }
    final navigator = Navigator.of(context);
    final edited = await navigator.push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (_) => ProImageEditor.memory(
          bytes,
          configs: kStudioEditorConfigs,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (result) async => navigator.pop(result),
          ),
        ),
      ),
    );
    if (edited != null && mounted) {
      setState(() => _editedBytes = edited);
    }
  }

  // ── Reels'e yayınla ───────────────────────────────────────────────────────

  /// Stüdyo çıktısını onay kuyruğuna gönderir (sunucuda `status='pending'`).
  ///
  /// Medya GERÇEKTEN yüklenir ([ISocialRepository.uploadPostMedia] — iki yayın
  /// yolunun ortak yolu):
  /// * video arka plan → mp4 yüklenir, `kind: 'video'`, `videoUrl`
  /// * şablon/görsel  → önizlemenin PNG'si yüklenir, `kind: 'still'`, `mediaUrl`
  ///
  /// Arapça / meal / künye AYRI alanlar olarak gider: Reels oynatıcısı metni
  /// arka planın ÜSTÜNE kendi çizer (`_ReelComposition` RTL Arapça bloğu +
  /// `_ReelOverlay` meal/künye), bu yüzden hepsini `meal` içine gömmek
  /// oynatıcının Arapça bloğunu boş bırakırdı.
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
      final repo = ref.read(socialRepositoryProvider);
      final video = _bgIsVideo ? _bgFile : null;
      final bytes =
          video != null ? await video.readAsBytes() : await _bytesToPublish();
      if (bytes == null) {
        _snack('Önizleme hazırlanamadı. Tekrar dene.');
        return;
      }
      final url = await repo.uploadPostMedia(bytes, isVideo: video != null);
      await repo.createPost(
        reference: _reference,
        arabic: _arabic,
        meal: text,
        caption: text,
        kind: video != null ? 'video' : 'still',
        // 'still' → poster/görsel; 'video' → oynatılabilir mp4.
        mediaUrl: video != null ? null : url,
        videoUrl: video != null ? url : null,
        templateId: kTemplates[_selectedTemplate].id,
        audioTrackId: _audioTrackId,
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

    final video = _bgVideo;
    Widget backgroundWidget;
    if (_bgIsVideo && video != null && video.value.isInitialized) {
      // FittedBox+SizedBox = BoxFit.cover'ın video karşılığı: dikey kartta
      // videonun kendi en-boyu korunur, taşan kısım kırpılır.
      backgroundWidget = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    } else if (_bgIsVideo) {
      // Oynatıcı henüz hazır değil ya da kurulamadı — seçim yine de geçerli.
      backgroundWidget = ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.videocam_rounded,
            size: 44,
            color: AppColors.gold,
            semanticLabel: 'Seçili video arka planı',
          ),
        ),
      );
    } else if (_bgFile != null) {
      backgroundWidget = Image.file(
        _bgFile!,
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

    // Düzenlenen görselde metin ZATEN var; marka katmanını üstüne yeniden
    // çizmek metni ÇİFT gösterirdi.
    if (_editedBytes != null) {
      return RepaintBoundary(
        key: _previewKey,
        child: ClipRRect(
          borderRadius: AppRadii.lgAll,
          child: Image.memory(_editedBytes!, fit: BoxFit.cover),
        ),
      );
    }

    // Boyutu artık çağıran veriyor (sabit 360×640 / 360×360 tuval), bu yüzden
    // buradaki `AspectRatio` kaldırıldı — çıktı çözünürlüğü deterministik.
    return RepaintBoundary(
      key: _previewKey,
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
            // Metin katmanı — Arapça varsa üstte, RTL + Amiri Quran
            // (domain kuralı 2). Meal düzenlenebilir metin alanından gelir.
            Align(
              alignment: textAlignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_arabic.isNotEmpty) ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          _arabic,
                          textAlign: TextAlign.center,
                          style: arabicStyle(
                            size: _fontSize * 1.35,
                            color: _textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    textWidget,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Şablon thumbnail'i ────────────────────────────────────────────────────

  Widget _buildTemplateThumbnail(int index) {
    final t = kTemplates[index];
    final selected = index == _selectedTemplate && _bgFile == null;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTemplate = index;
        _releaseVideo();
        _bgFile = null;
        _bgIsVideo = false;
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

            // ── Önizleme — KAYDIRILAN LİSTENİN DIŞINDA ───────────────────
            // Daha önce `ListView`in ilk çocuğuydu. `ListView` tembeldir:
            // kullanıcı "Reels'e Yayınla"ya ulaşmak için kaydırınca önizleme
            // görünür alanı terk eder, `RenderSliverMultiBoxAdaptor` onu
            // layout eder ama BOYAMAZ → `_previewKey`in RepaintBoundary'si
            // `needsPaint` kalır ve `toImage()` `!debugNeedsPaint` assert'iyle
            // patlar (release'de `layer! as OffsetLayer` cast'i / bayat kare).
            //
            // Sabit 360×640 tuval + `FittedBox`: tuval boyutu ekrandan
            // BAĞIMSIZ olduğu için `pixelRatio: 3.0` her cihazda tam
            // 1080×1920 (Story) / 1080×1080 (Kare) üretir — önceden çıktı
            // ekran genişliğine göre değişiyordu. `FittedBox` yalnız gösterimi
            // ölçekler; boundary katmanı 360×640'ta kaydedilir.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: FittedBox(
                  child: SizedBox(
                    // Test bu anahtarla "önizleme kaydırılan listenin İÇİNDE
                    // değil" değişmezini kilitliyor.
                    key: const Key('studio_preview_canvas'),
                    width: 360,
                    height: _storyMode ? 640 : 360,
                    child: _buildPreview(),
                  ),
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

                  // ── 1. Arka plan seçici ──────────────────────────────────
                  const SectionLabel(
                    title: 'Arka Plan',
                    eyebrow: 'Tema / Görsel / Video',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Galeri düğmeleri ŞERİDİN BAŞINDA: sonda dursalardı
                        // dar telefonlarda (ve testte) altı şablonun ardında
                        // görünmez kalıp kaydırmadan bulunamazlardı.
                        _MediaPickButton(
                          key: const Key('studio_pick_image'),
                          icon: Icons.image_rounded,
                          tooltip: 'Galeriden görsel seç',
                          selected: _bgFile != null && !_bgIsVideo,
                          onTap: _pickImage,
                        ),
                        const SizedBox(width: 8),
                        // Video arka plan: oynatıcı üstüne ayet metnini çizer.
                        _MediaPickButton(
                          key: const Key('studio_pick_video'),
                          icon: Icons.videocam_rounded,
                          tooltip: 'Galeriden video seç',
                          selected: _bgIsVideo,
                          onTap: _pickVideo,
                        ),
                        const SizedBox(width: 12),
                        for (int i = 0; i < kTemplates.length; i++)
                          _buildTemplateThumbnail(i),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Metin girişi ──────────────────────────────────────
                  // ── Müzik (küratörlü) ───────────────────────────────────
                  // Kütüphane boşsa ya da göç uygulanmamışsa şerit HİÇ
                  // görünmez: kullanıcıya çalışmayan bir kontrol göstermeyiz.
                  ref
                      .watch(reelAudioTracksProvider)
                      .maybeWhen(
                        data: (tracks) => tracks.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SectionLabel(
                                    title: 'Müzik',
                                    eyebrow: 'Küratörlü Kütüphane',
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 52,
                                    child: ListView.separated(
                                      key: const Key('studio_music_rail'),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: tracks.length + 1,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, i) {
                                        if (i == 0) {
                                          return ChoiceChip(
                                            label: const Text('Sessiz'),
                                            selected: _audioTrackId == null,
                                            onSelected: (_) => setState(
                                              () => _audioTrackId = null,
                                            ),
                                          );
                                        }
                                        final t = tracks[i - 1];
                                        return ChoiceChip(
                                          label: Text(
                                            t.artist.isEmpty
                                                ? t.title
                                                : '${t.title} · ${t.artist}',
                                          ),
                                          selected: _audioTrackId == t.id,
                                          onSelected: (_) => setState(
                                            () => _audioTrackId = t.id,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),

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
                        style: AppTypography.body(size: 13, color: AppColors.goldInk),
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
                    _bgIsVideo
                        ? 'Videon arka plan olarak yüklenir; ayet metnini Reels '
                              'oynatıcısı üstüne çizer.'
                        : 'Gördüğün kartın kendisi yüklenir; yayına yönetici '
                              'onayından sonra girer.',
                    style: AppTypography.body(size: 12, color: AppColors.muted),
                  ),
                  // Gelişmiş editör yalnız durağan kartta anlamlı: video arka
                  // planda yayınlanan şey mp4'ün kendisidir, tek kare değil.
                  if (!_bgIsVideo) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('studio_advanced_edit'),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Gelişmiş Düzenle'),
                      onPressed: _exporting || _publishing ? null : _openEditor,
                    ),
                    if (_editedBytes != null)
                      TextButton.icon(
                        key: const Key('studio_revert_edit'),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Düzenlemeyi geri al'),
                        // Kullanıcı kapana kısılmasın: düzenleme sonrası marka
                        // kartına dönebilmeli.
                        onPressed: () => setState(() => _editedBytes = null),
                      ),
                  ],
                  // Video arka planda PNG çıktısı YOK: hareketli içeriği tek
                  // kareye indirip "kaydettin" demek kullanıcıyı yanıltır.
                  if (!_bgIsVideo) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('studio_export_png'),
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
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.smAll,
                        ),
                      ),
                    ),
                  ],
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

/// Arka plan seçici şeridindeki galeri düğmesi (görsel / video).
class _MediaPickButton extends StatelessWidget {
  const _MediaPickButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? AppColors.goldInk : AppColors.muted,
            size: 22,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}

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
            Icon(icon, color: selected ? AppColors.goldInk : AppColors.muted, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.body(
                size: 12,
                color: selected ? AppColors.goldInk : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

