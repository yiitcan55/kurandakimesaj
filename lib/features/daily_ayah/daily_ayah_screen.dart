import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Günün ayeti + onun suresi (deterministik — her gün aynı).
final dailyAyahProvider = FutureProvider.autoDispose<(Ayah, Surah?)?>((ref) async {
  final repo = ref.read(contentRepositoryProvider);
  final a = await repo.ayahOfDay(DateTime.now());
  if (a == null) return null;
  final s = await repo.surah(a.surahNumber);
  return (a, s);
});

/// (metin, kaynak, sıhhat) — paylaşıma hazır hadisler.
const List<(String, String, String)> _kHadiths = [
  ('Ameller niyetlere göredir. Herkese ancak niyet ettiği şey vardır.', 'Buhârî, Bed\'ü\'l-vahy 1', 'Sahih'),
  ('Müslüman, dilinden ve elinden müslümanların güvende olduğu kimsedir.', 'Buhârî, Îmân 4', 'Sahih'),
  ('Sizin en hayırlınız, Kur\'an\'ı öğrenen ve öğretendir.', 'Buhârî, Fezâilü\'l-Kur\'ân 21', 'Sahih'),
  ('Kolaylaştırın, zorlaştırmayın; müjdeleyin, nefret ettirmeyin.', 'Buhârî, İlim 11', 'Sahih'),
];

class DailyAyahScreen extends ConsumerWidget {
  const DailyAyahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyAyahProvider);
    final hadith = _kHadiths[DateTime.now().day % _kHadiths.length];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Günün Ayeti & Hadis'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (data) {
                  if (data == null) {
                    return const EmptyState(
                      icon: Icons.wb_sunny_rounded,
                      message: 'Ayet bulunamadı.',
                    );
                  }
                  final (ayah, surah) = data;
                  final ref0 = '${surah?.nameTr ?? 'Sure'}, ${ayah.numberInSurah}';
                  final shareText = '${ayah.meal}\n($ref0)\n\nKur\'an\'da ki Mesaj';
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      HeroCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GÜNÜN AYETİ', style: AppTypography.eyebrow()),
                            const SizedBox(height: 14),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(ayah.arabic,
                                  textAlign: TextAlign.right, style: arabicStyle(size: 26)),
                            ),
                            const SizedBox(height: 16),
                            Text(ayah.meal,
                                style: AppTypography.body(size: 16, color: AppColors.cream)),
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, _) {
                                final tts = ref.watch(ttsServiceProvider);
                                return IconButton(
                                  icon: Icon(
                                    tts.isSpeaking
                                        ? Icons.stop_circle_outlined
                                        : Icons.volume_up_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  tooltip: tts.isSpeaking ? 'Durdur' : 'Sesli Dinle',
                                  onPressed: () {
                                    if (tts.isSpeaking) {
                                      tts.stop();
                                    } else {
                                      tts.speak(ayah.meal);
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(ref0, style: AppTypography.body(size: 13, color: AppColors.goldInk)),
                            const SizedBox(height: 12),
                            AyetActionBar(
                              onUnderstand: () => _showTafsir(context, ayah, ref0),
                              onReflect: () => showReflectionSheet(
                                context,
                                reference: ref0,
                                onSave: (note) async {
                                  await ref.read(collectionsRepositoryProvider).add(
                                        reference: ref0,
                                        arabic: ayah.arabic,
                                        meal: ayah.meal,
                                        note: note.isEmpty ? null : note,
                                      );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(note.isEmpty
                                        ? 'Koleksiyona kaydedildi.'
                                        : 'Düşüncen kaydedildi.'),
                                  ));
                                },
                              ),
                              onShare: () => ref
                                  .read(shareServiceProvider)
                                  .shareText(shareText, subject: 'Günün Ayeti'),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      const SectionLabel(title: 'Günün Hadisi', eyebrow: 'Sünnet'),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('"${hadith.$1}"',
                                style: AppTypography.body(size: 16, color: AppColors.cream)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(hadith.$2,
                                      style: AppTypography.body(size: 13, color: AppColors.muted)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(hadith.$3,
                                      style: AppTypography.body(
                                          size: 12, weight: FontWeight.w700, color: AppColors.success)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Anla" — tefsir varsa alttan sheet'te gösterir, yoksa kısa bilgi verir.
  void _showTafsir(BuildContext context, Ayah ayah, String ref0) {
    final t = ayah.tafsir;
    if (t == null || t.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ayet için tefsir yakında eklenecek.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.emerald850,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANLA · TEFSİR', style: AppTypography.eyebrow()),
              const SizedBox(height: 8),
              Text(ref0, style: AppTypography.body(size: 13, color: AppColors.goldInk)),
              const SizedBox(height: 12),
              Text(t, style: AppTypography.body(size: 15, color: AppColors.cream)),
            ],
          ),
        ),
      ),
    );
  }
}
