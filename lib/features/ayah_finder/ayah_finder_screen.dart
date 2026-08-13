import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Paylaş menüsünden metin/URL (X, blog, haber — og:image yayınlayan siteler).
      // Aynı yol ekrandaki "Bağlantı Yapıştır" alanıyla ortaktır; doğrulama
      // controller'daki `normalizeAyahUrl` ile tek yerde yapılır.
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
                    'Elindeki tilavet videosunu, bir gönderinin ekran görüntüsünü '
                    'ya da bağlantısını ver; okunan ayetleri ve mealini bulalım.',
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
                  const SizedBox(height: 12),
                  _LinkField(
                    key: const Key('ayahLinkCard'),
                    onSubmit: (url) => _search(() => notifier.fromUrl(url)),
                  ),
                  const SizedBox(height: 22),
                  result.when(
                    loading: () => _LoadingView(video: _videoPending),
                    // Repo tüm hataları sonuç nesnesine çevirir; buraya düşen
                    // istisna beklenmedik olandır (ör. dosya okunamadı) — kodla
                    // birlikte istisnanın kendisi de loglansın (Faz 1 dersi).
                    error: (e, _) => _ErrorView(code: 'unexpected', detail: '$e'),
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
          CircularProgressIndicator(color: AppColors.goldInk),
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
            child: Icon(icon, color: AppColors.goldInk),
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

/// "Bağlantı Yapıştır" kartı — gönderi bağlantısından ayet bulma girişi.
///
/// Pano SESSİZCE OKUNMAZ: açılışta yalnız `Clipboard.hasStrings()` sorulur
/// (içeriği vermez, iOS'ta yapıştır uyarısı çıkarmaz) ve panoda metin varsa
/// bir ÖNERİ butonu gösterilir. Gerçek okuma kullanıcı o butona dokununca olur.
class _LinkField extends StatefulWidget {
  const _LinkField({super.key, required this.onSubmit});

  /// Doğrulanmış (normalize edilmiş) bağlantı ile çağrılır.
  final ValueChanged<String> onSubmit;

  @override
  State<_LinkField> createState() => _LinkFieldState();
}

class _LinkFieldState extends State<_LinkField> {
  final _controller = TextEditingController();
  String? _error;
  bool _clipboardHasText = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    final has = await Clipboard.hasStrings();
    if (!mounted || !has) return;
    setState(() => _clipboardHasText = true);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final url = normalizeAyahUrl(data?.text ?? '');
    setState(() {
      if (url == null) {
        _error = 'Panoda bir bağlantı bulunamadı. Gönderinin bağlantısını '
            'kopyalayıp tekrar dene.';
      } else {
        _controller.text = url;
        _error = null;
      }
    });
  }

  void _submit() {
    final url = normalizeAyahUrl(_controller.text);
    if (url == null) {
      setState(() => _error = _controller.text.trim().isEmpty
          ? 'Önce bir gönderi bağlantısı yapıştır.'
          : 'Bu bir bağlantı gibi görünmüyor. "https://" ile başlayan bir '
              'gönderi bağlantısı yapıştır.');
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    widget.onSubmit(url);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.goldFaint, borderRadius: AppRadii.smAll),
                child: Icon(Icons.link_rounded, color: AppColors.goldInk),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bağlantı Yapıştır',
                        style: AppTypography.body(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.cream)),
                    Text('Gönderi bağlantısındaki görselden ayeti bul',
                        style:
                            AppTypography.body(size: 13, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('ayahLinkInput'),
            controller: _controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            onSubmitted: (_) => _submit(),
            style: AppTypography.body(size: 15, color: AppColors.cream),
            decoration: InputDecoration(
              labelText: 'Gönderi bağlantısı',
              labelStyle: AppTypography.body(size: 14, color: AppColors.muted),
              floatingLabelStyle:
                  AppTypography.body(size: 14, color: AppColors.goldInk),
              hintText: 'https://…',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            // Uyarı yalnız renkle değil, ikon + metinle de ayrışır.
            Semantics(
              key: const Key('ayahLinkError'),
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: AppTypography.body(
                            size: 13, color: AppColors.accent)),
                  ),
                ],
              ),
            ),
          ],
          if (_clipboardHasText) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ayahLinkPaste'),
                onPressed: _paste,
                icon: Icon(Icons.content_paste_rounded,
                    size: 18, color: AppColors.goldInk),
                label: Text('Panodaki bağlantıyı yapıştır',
                    style:
                        AppTypography.body(size: 13.5, color: AppColors.cream)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('ayahLinkSubmit'),
            onPressed: _submit,
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text('Bağlantıdan Ayet Bul'),
          ),
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
            child: Icon(Icons.graphic_eq_rounded, color: AppColors.goldInk),
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
                      style: AppTypography.body(size: 13.5, color: AppColors.goldInk)
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
                    style: AppTypography.body(size: 16, weight: FontWeight.w600, color: AppColors.goldInk)),
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
                key: const Key('ayahStudioButton'),
                icon: Icons.movie_creation_rounded,
                label: 'Videoya Aktar',
                onTap: () => _openStudio(context),
              ),
              _ActionButton(
                key: const Key('ayahReelsButton'),
                icon: Icons.auto_awesome_motion_rounded,
                label: "Reels'te Paylaş",
                onTap: () => _openStudio(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stüdyoyu ayet önyüklü açar; kullanıcı arka planı seçip yayınlar
  /// (`createPost(kind: 'still')`, moderasyon için `status: 'pending'`).
  ///
  /// ÜÇÜNCÜ TARAF VİDEOSU KOPYALANMAZ: paylaşılan şey bizim ürettiğimiz
  /// ayet kartıdır, kaynak gönderinin videosu/görseli değil (App Store 5.2.3).
  /// "Videoya Aktar" ile aynı kapı — ikisi de aynı stüdyo akışına girer,
  /// tek fark kullanıcının niyetini karşılayan etikettir.
  void _openStudio(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudioScreen(
          // Arapça ve meal AYRI: stüdyo Arapça'yı RTL/Amiri render eder ve
          // yayınlarken `feed_posts.arabic` alanına ayrı gönderir.
          initialArabic: match.arabic,
          initialText: match.meal,
          initialReference: match.reference,
        ),
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
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.goldInk),
      label: Text(label, style: AppTypography.body(size: 13.5, color: AppColors.cream)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.line)),
    );
  }
}

/// Hata kodunu eyleme dönük Türkçe mesaja çevirir.
///
/// Kod listesi sözleşmenin bir parçası: `ayah-finder` + `ayah-finder-audio`
/// Edge Function'ları ve `AyahFinderRepository` bu kodları üretir. Yeni kod
/// eklenirse burası da güncellenmeli — ele alınmayan kod `debugPrint` ile
/// loglanır ki hata bilgisi hiçbir yerde kaybolmasın.
class _ErrorView extends StatelessWidget {
  const _ErrorView({this.code, this.detail});
  final String? code;

  /// Yalnız log için: AsyncError'un asıl istisna metni.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final known = _messageFor(code);
    if (known == null) {
      debugPrint('AyahFinder hata: kod="$code" detay=${detail ?? '-'}');
    }
    final (icon, message) = known ??
        (
          Icons.help_outline_rounded,
          'Beklenmedik bir hata oluştu. Tekrar dene; sorun sürerse '
              'uygulamayı kapatıp yeniden açmayı dene.'
        );
    return EmptyState(icon: icon, message: message);
  }

  static (IconData, String)? _messageFor(String? code) {
    return switch (code) {
      'link_unresolved' => (
          Icons.link_off_rounded,
          'Bu bağlantıdan görsel alınamadı (ör. Instagram giriş duvarı).\n'
              'Gönderinin ekran görüntüsünü alıp "Galeriden Seç" ile ya da '
              'videoyu cihazına kaydedip "Video Seç" ile dene.'
        ),
      'blocked_host' => (
          Icons.shield_outlined,
          'Bu bağlantı güvenlik nedeniyle açılamıyor.\n'
              'Gönderinin herkese açık bağlantısını kullan ya da ekran '
              'görüntüsünü alıp "Galeriden Seç" ile dene.'
        ),
      'invalid_url' => (
          Icons.edit_note_rounded,
          'Bu bir bağlantı gibi görünmüyor.\n'
              '"https://" ile başlayan bir gönderi bağlantısı yapıştırıp '
              'tekrar dene.'
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
      'no_video' => (
          Icons.upload_file_rounded,
          'Video isteği eksik gönderildi.\n'
              'Videoyu yeniden seçip tekrar dene.'
        ),
      'no_image' => (
          Icons.image_not_supported_rounded,
          'Bu içerikte okunabilecek bir görsel bulunamadı.\n'
              'Ayetin net göründüğü bir ekran görüntüsü seçip tekrar dene.'
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
          'Ayet bulma servisi şu an yapılandırılmamış.\n'
              'Bu bizden kaynaklı; kısa süre içinde tekrar dene.'
        ),
      'network' => (
          Icons.wifi_off_rounded,
          'İnternete ulaşılamadı.\n'
              'Wi-Fi ya da mobil veri bağlantını kontrol edip tekrar dene.'
        ),
      'server_error' => (
          Icons.warning_amber_rounded,
          'Sunucuda beklenmedik bir sorun oluştu.\n'
              'Birkaç dakika sonra tekrar dene.'
        ),
      'bad_response' => (
          Icons.sync_problem_rounded,
          'Sunucudan anlaşılmayan bir yanıt geldi.\n'
              'Uygulamanın güncel olduğundan emin olup tekrar dene.'
        ),
      _ => null,
    };
  }
}
