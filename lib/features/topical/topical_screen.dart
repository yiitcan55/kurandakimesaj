import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final topicsProvider = FutureProvider<List<String>>(
  (ref) => ref.read(contentRepositoryProvider).topics(),
);

final topicalProvider = FutureProvider.family<List<TopicalAyah>, String>(
  (ref, topic) => ref.read(contentRepositoryProvider).topicalByTopic(topic),
);

class TopicalScreen extends ConsumerStatefulWidget {
  const TopicalScreen({super.key});
  @override
  ConsumerState<TopicalScreen> createState() => _TopicalScreenState();
}

class _TopicalScreenState extends ConsumerState<TopicalScreen> {
  String? _topic;

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Konuya Göre Ayet'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Ruh hâline göre ayet keşfet.',
                  style: AppTypography.body(size: 14, color: AppColors.muted)),
            ),
            Expanded(
              child: topicsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (topics) {
                  final current = _topic ?? (topics.isNotEmpty ? topics.first : null);
                  return Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          children: [
                            for (final t in topics)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GoldChip(
                                  label: t,
                                  selected: current == t,
                                  onTap: () => setState(() => _topic = t),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (current != null)
                        Expanded(child: _TopicAyahs(topic: current))
                      else
                        const Expanded(
                          child: EmptyState(
                              icon: Icons.psychology_rounded, message: 'Konu bulunamadı.'),
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
}

class _TopicAyahs extends ConsumerWidget {
  const _TopicAyahs({required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topicalProvider(topic));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final (i, a) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(a.arabic,
                          textAlign: TextAlign.right, style: arabicStyle(size: 24)),
                    ),
                    const SizedBox(height: 12),
                    Text(a.meal, style: AppTypography.body(size: 15.5, color: AppColors.cream)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.reference,
                              style: AppTypography.body(size: 13, color: AppColors.gold)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.share_rounded, color: AppColors.gold, size: 20),
                          onPressed: () => ref
                              .read(shareServiceProvider)
                              .shareText('${a.meal}\n(${a.reference})', subject: topic),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.gold, size: 20),
                          onPressed: () async {
                            await ref.read(collectionsRepositoryProvider).add(
                                  reference: a.reference,
                                  arabic: a.arabic,
                                  meal: a.meal,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Koleksiyona kaydedildi.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
                .animate(delay: ((i < 8 ? i : 8) * 45).ms)
                .fadeIn(duration: AppDurations.normal)
                .slideY(begin: 0.1, curve: AppDurations.easeOut),
        ],
      ),
    );
  }
}
