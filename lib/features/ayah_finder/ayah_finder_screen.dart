import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../quran/quran_screens.dart';
import '../studio/studio_screens.dart';
import 'ayah_error_messages.dart';
import 'ayah_finder_controller.dart';

/// Ayet Bulucu — bir gönderinin ekran görüntüsünden/görselinden hangi Kur'an
/// ayetinin geçtiğini bulur (yalnız görsel OCR). Video yolu Meal Düzenle'dedir;
/// uygulama hiçbir platformdan içerik indirmez — bkz. Karar Günlüğü (App Store 5.2.3).
class AyahFinderScreen extends ConsumerStatefulWidget {
  const AyahFinderScreen({super.key, this.initialImagePath});

  /// Paylaş menüsünden gelen görsel yolu (Faz 3).
  final String? initialImagePath;

  @override
  ConsumerState<AyahFinderScreen> createState() => _AyahFinderScreenState();
}

class _AyahFinderScreenState extends ConsumerState<AyahFinderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeInitialInput());
  }

  /// Paylaş menüsünden gelen görseli bir kez tüketir; görsel yoksa false.
  /// Video/bağlantı girdisine DOKUNULMAZ: onu Meal Düzenle tüketir; burada
  /// temizlenirse soğuk başlatmada paylaşım kaybolur.
  bool _consumeSharedImage() {
    final image = ref.read(sharedAyahInputProvider)?.imagePath;
    if (image == null || image.isEmpty) return false;
    ref.read(sharedAyahInputProvider.notifier).clear(); // bir kez tüket
    ref.read(ayahFinderProvider.notifier).fromSharedImage(image);
    return true;
  }

  /// Açılışta: paylaşılan görsel, yoksa constructor'dan gelen görsel.
  void _consumeInitialInput() {
    if (_consumeSharedImage()) return;
    final path = widget.initialImagePath;
    if (path != null && path.isNotEmpty) {
      ref.read(ayahFinderProvider.notifier).fromSharedImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran AÇIKKEN gelen görsel paylaşımı: `app.dart` hedef rota zaten
    // açıksa yeni ekran push etmez; girdiyi açık ekranın tüketmesi gerekir.
    ref.listen(sharedAyahInputProvider, (_, _) => _consumeSharedImage());
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
                    'Bir gönderinin ekran görüntüsünü ya da görselini ver; '
                    'içindeki ayeti ve mealini bulalım.',
                    style: AppTypography.body(size: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  _SourceButton(
                    key: const Key('ayahVideoTile'),
                    icon: Icons.movie_filter_rounded,
                    title: 'Videodan Meal',
                    subtitle: 'Tilavet videosundaki ayetleri Meal Düzenle ile bul',
                    onTap: () => context.push('/meal-edit'),
                  ),
                  const SizedBox(height: 12),
                  _SourceButton(
                    icon: Icons.image_search_rounded,
                    title: 'Galeriden Seç',
                    subtitle: 'Ekran görüntüsü / görsel',
                    onTap: notifier.fromGallery,
                  ),
                  const SizedBox(height: 22),
                  result.when(
                    loading: () => const _LoadingView(),
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
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.goldInk),
          const SizedBox(height: 16),
          Text(
            'Aranıyor…',
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
    super.key,
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
              'Görselde ayetin net göründüğünden emin olup tekrar dene.',
        );
      case AyahFinderStatus.error:
        return _ErrorView(code: result.errorCode);
    }
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
    final known = ayahErrorMessage(code);
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
}
