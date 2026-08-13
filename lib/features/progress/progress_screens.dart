import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/painters.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

// ── Kur'an İstatistikleri ────────────────────────────────────────────────────

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(statsServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kur\'an İstatistiklerim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Ömür boyu istatistikler
          FutureBuilder<Map<String, int>>(
            future: svc.getLifetimeStats(),
            builder: (ctx, snap) {
              final stats = snap.data ?? {};
              return Row(children: [
                _StatCard('Sure', '${stats['surahCount'] ?? 0}', Icons.menu_book_rounded),
                const SizedBox(width: 8),
                _StatCard('Ayet', '${stats['ayahCount'] ?? 0}', Icons.format_list_numbered_rounded),
                const SizedBox(width: 8),
                _StatCard('Dakika', '${stats['minutes'] ?? 0}', Icons.timer_rounded),
              ]);
            },
          ),
          const SizedBox(height: 16),

          // Haftalık çubuk grafik
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Son 7 Gün', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                FutureBuilder<List<int>>(
                  future: svc.getWeeklyAyahCounts(),
                  builder: (ctx, snap) {
                    final data = snap.data ?? List.filled(7, 0);
                    final max = data.isEmpty ? 1 : (data.reduce((a, b) => a > b ? a : b)).clamp(1, 999);
                    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                    final today = DateTime.now().weekday; // 1=Pzt
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final dayIdx = (today - 6 + i - 1 + 7) % 7;
                        final val = data[i];
                        return Expanded(
                          child: Column(children: [
                            Container(
                              height: (val / max * 80).clamp(2.0, 80.0),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == 6
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(days[dayIdx], style: const TextStyle(fontSize: 10)),
                          ]),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

final memorizationsProvider = StreamProvider<List<Memorization>>(
  (ref) => ref.watch(memorizationRepositoryProvider).watch(),
);

final juzListProvider = StreamProvider<List<JuzProgressData>>(
  (ref) => ref.watch(juzRepositoryProvider).watch(),
);

// ── Sure Ezberi ─────────────────────────────────────────────────────────────

class MemorizeScreen extends ConsumerWidget {
  const MemorizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memorizationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Sure Ezberi'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (items) {
                  final totalAyahs = items.fold<int>(0, (s, m) => s + m.totalAyahs);
                  final memorized = items.fold<int>(0, (s, m) => s + m.memorizedAyahs);
                  final pct = totalAyahs == 0 ? 0.0 : memorized / totalAyahs;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      HeroCard(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(64, 64),
                                    painter: CircularProgressPainter(progress: pct, strokeWidth: 7),
                                  ),
                                  Text('${(pct * 100).round()}%',
                                      style: AppTypography.body(
                                          size: 13, weight: FontWeight.w700, color: AppColors.goldInk)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hıfz İlerlemesi', style: AppTypography.display(size: 22)),
                                  Text('$memorized / $totalAyahs ayet ezberlendi',
                                      style: AppTypography.body(size: 13, color: AppColors.cream2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final m in items) _MemoCard(item: m),
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

class _MemoCard extends ConsumerWidget {
  const _MemoCard({required this.item});
  final Memorization item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(memorizationRepositoryProvider);
    final pct = item.totalAyahs == 0 ? 0.0 : item.memorizedAyahs / item.totalAyahs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.surahName,
                      style: AppTypography.body(size: 16, weight: FontWeight.w600, color: AppColors.cream)),
                ),
                Text('${item.memorizedAyahs}/${item.totalAyahs}',
                    style: AppTypography.body(size: 14, color: AppColors.goldInk)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: AppColors.emerald850,
                color: AppColors.goldInk,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.goldInk),
                  onPressed: item.memorizedAyahs <= 0
                      ? null
                      : () => repo.setMemorized(item.id, item.memorizedAyahs - 1),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.goldInk),
                  onPressed: item.memorizedAyahs >= item.totalAyahs
                      ? null
                      : () => repo.setMemorized(item.id, item.memorizedAyahs + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cüz / Hizb Takip ────────────────────────────────────────────────────────

class JuzTrackerScreen extends ConsumerWidget {
  const JuzTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(juzListProvider);
    final repo = ref.read(juzRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Cüz / Hizb Takip'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (juz) {
                  final done = juz.where((j) => j.completed).length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      HeroCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OKUMA HARİTASI', style: AppTypography.eyebrow()),
                            const SizedBox(height: 8),
                            Text('$done / 30 cüz', style: AppTypography.display(size: 30)),
                            Text('Tamamlanan cüzleri işaretle, hatmini takip et.',
                                style: AppTypography.body(size: 13, color: AppColors.cream2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          for (final j in juz)
                            InkWell(
                              borderRadius: AppRadii.smAll,
                              onTap: () => repo.setCompleted(j.juzNumber, !j.completed),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: j.completed ? AppColors.gold : Colors.transparent,
                                  borderRadius: AppRadii.smAll,
                                  border: Border.all(
                                    color: j.completed ? AppColors.gold : AppColors.line,
                                  ),
                                ),
                                child: Text('${j.juzNumber}',
                                    style: AppTypography.body(
                                        size: 16,
                                        weight: FontWeight.w700,
                                        color: j.completed ? AppColors.onGold : AppColors.cream2)),
                              ),
                            ),
                        ],
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
