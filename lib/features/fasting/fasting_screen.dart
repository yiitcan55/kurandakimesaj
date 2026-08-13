import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../prayer/prayer_screen.dart';

/// Kaza oruç sayacı — prefs ile kalıcı.
class KazaController extends Notifier<int> {
  static const _k = 'kaza_fasting';
  @override
  int build() => ref.watch(prefsProvider).getInt(_k) ?? 0;

  Future<void> set(int v) async {
    final value = v < 0 ? 0 : v;
    await ref.read(prefsProvider).setInt(_k, value);
    state = value;
  }
}

final kazaProvider = NotifierProvider<KazaController, int>(KazaController.new);

class FastingScreen extends ConsumerWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(prayerControllerProvider);
    final kaza = ref.watch(kazaProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Oruç & İmsakiye'),
            Expanded(
              child: dayAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (day) {
                  final imsak = day.slots.firstWhere((s) => s.name == 'İmsak');
                  final iftar = day.slots.firstWhere((s) => s.name == 'Akşam');
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      HeroCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FastingCountdown(imsak: imsak, iftar: iftar, tomorrowFajr: day.tomorrowFajr),
                            const SizedBox(height: 8),
                            Text(day.locationLabel,
                                style: AppTypography.body(size: 13, color: AppColors.cream2)),
                          ],
                        ),
                      ).animate().fadeIn(duration: AppDurations.normal),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeCard(
                              icon: Icons.nightlight_round,
                              label: 'İmsak (Sahur)',
                              time: DateFormat('HH:mm').format(imsak.time),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeCard(
                              icon: Icons.dinner_dining_rounded,
                              label: 'İftar (Akşam)',
                              time: DateFormat('HH:mm').format(iftar.time),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionLabel(title: 'Kaza Oruçları', eyebrow: 'Takip'),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Row(
                          children: [
                            Icon(Icons.event_repeat_rounded, color: AppColors.goldInk),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('Kalan kaza orucu',
                                  style: AppTypography.body(size: 15, color: AppColors.cream)),
                            ),
                            IconButton(
                              onPressed: () => ref.read(kazaProvider.notifier).set(kaza - 1),
                              icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.goldInk),
                            ),
                            Text('$kaza',
                                style: AppTypography.display(size: 24, color: AppColors.goldInk)),
                            IconButton(
                              onPressed: () => ref.read(kazaProvider.notifier).set(kaza + 1),
                              icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.goldInk),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Text(
                          'İmsakiye vakitleri konumunuza göre adhan ile (Türkiye/Diyanet yöntemi) hesaplanır. Ramazan ayında sahur ve iftar vakitleri burada güncellenir.',
                          style: AppTypography.body(size: 13.5, color: AppColors.muted),
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
}

class _FastingCountdown extends StatefulWidget {
  const _FastingCountdown({required this.imsak, required this.iftar, this.tomorrowFajr});
  final PrayerSlot imsak;
  final PrayerSlot iftar;
  final DateTime? tomorrowFajr;

  @override
  State<_FastingCountdown> createState() => _FastingCountdownState();
}

class _FastingCountdownState extends State<_FastingCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String label;
    final DateTime target;
    if (now.isBefore(widget.iftar.time)) {
      label = 'İftara kalan';
      target = widget.iftar.time;
    } else {
      label = 'Sahura (imsak) kalan';
      target = widget.tomorrowFajr ?? widget.imsak.time.add(const Duration(days: 1));
    }
    final r = target.difference(now);
    final hhmmss =
        '${r.inHours.toString().padLeft(2, '0')}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.eyebrow()),
        const SizedBox(height: 6),
        Text(hhmmss,
            style: AppTypography.display(size: 44, color: AppColors.goldInk)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.icon, required this.label, required this.time});
  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldInk),
          const SizedBox(height: 10),
          Text(time, style: AppTypography.display(size: 26, color: AppColors.goldInk)),
          Text(label, style: AppTypography.body(size: 12.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
