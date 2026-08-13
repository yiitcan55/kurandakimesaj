import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final collectionsProvider = StreamProvider<List<Collection>>(
  (ref) => ref.watch(collectionsRepositoryProvider).watch(),
);

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionsProvider);
    final repo = ref.read(collectionsRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Koleksiyonlar'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      message:
                          'Henüz kayıt yok.\nAyet ve dualardaki "Kaydet" ile koleksiyonunu oluştur.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final (i, c) in items.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(c.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: AppRadii.mdAll,
                              ),
                              child: Icon(Icons.delete_outline_rounded, color: AppColors.accent),
                            ),
                            onDismissed: (_) => repo.delete(c.id),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(c.arabic,
                                        textAlign: TextAlign.right, style: arabicStyle(size: 22)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(c.meal, style: AppTypography.body(size: 15, color: AppColors.cream)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(c.reference,
                                            style: AppTypography.body(size: 13, color: AppColors.goldInk)),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.share_rounded, color: AppColors.goldInk, size: 20),
                                        onPressed: () => ref
                                            .read(shareServiceProvider)
                                            .shareText('${c.meal}\n(${c.reference})'),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.delete_outline_rounded,
                                            color: AppColors.muted, size: 20),
                                        onPressed: () => repo.delete(c.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            // Yalnız ilk öğelerde belirgin gecikme; uzun listede
                            // kaydırma akıcılığı için gecikme sınırlanır.
                            .animate(delay: ((i < 8 ? i : 8) * 45).ms)
                            .fadeIn(duration: AppDurations.normal)
                            .slideY(begin: 0.1, curve: AppDurations.easeOut),
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
