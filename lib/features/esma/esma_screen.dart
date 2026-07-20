import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final esmaProvider = FutureProvider<List<EsmaName>>(
  (ref) => ref.read(contentRepositoryProvider).esma(),
);

class EsmaScreen extends ConsumerWidget {
  const EsmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(esmaProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Esmaü\'l-Hüsna'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'Esmaül Hüsna yüklenemedi: $e',
                ),
                data: (names) => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: names.length,
                  itemBuilder: (context, i) {
                    final e = names[i];
                    return AppCard(
                      onTap: () => _showDetail(context, e),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(e.arabic,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: arabicStyle(size: 30).copyWith(height: 1.35)),
                          ),
                          const SizedBox(height: 8),
                          Text(e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(
                                  size: 14, weight: FontWeight.w700, color: AppColors.cream)),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(e.meaning,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body(size: 11.5, color: AppColors.muted)),
                          ),
                        ],
                      ),
                    ).animate(delay: (i * 18).ms).fadeIn(duration: AppDurations.fast);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, EsmaName e) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${e.order}. İsim', style: AppTypography.eyebrow()),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(e.arabic, style: arabicStyle(size: 52)),
            ),
            const SizedBox(height: 12),
            Text(e.name, style: AppTypography.display(size: 28)),
            const SizedBox(height: 8),
            Text(e.meaning,
                textAlign: TextAlign.center,
                style: AppTypography.body(size: 16, color: AppColors.cream2)),
          ],
        ),
      ),
    );
  }
}
