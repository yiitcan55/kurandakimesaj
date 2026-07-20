import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/device_services.dart';
import '../../data/repositories.dart';
import '../../data/services.dart';
import '../../data/widget_background.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Namaz vakitleri ViewModel'ı — konumu alır, adhan ile günü hesaplar.
class PrayerController extends AsyncNotifier<PrayerDay> {
  @override
  Future<PrayerDay> build() async {
    final svc = ref.read(prayerServiceProvider);
    final loc = await ref.read(locationServiceProvider).current();
    final lat = loc?.lat ?? LocationService.defaultLat;
    final lng = loc?.lng ?? LocationService.defaultLng;
    final label = loc != null ? 'Konumunuz' : LocationService.defaultLabel;
    // Background widget yenilemesi geolocator çağırmadan kullansın diye sakla.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kLastLatKey, lat);
    await prefs.setDouble(kLastLngKey, lng);
    await prefs.setString(kLastLocLabelKey, label);
    return svc.compute(lat: lat, lng: lng, locationLabel: label);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Bildirim izni ister ve günün namaz vakitlerini zamanlar.
  Future<bool> enableNotifications() async {
    final day = state.value;
    if (day == null) return false;
    final notif = ref.read(notificationServiceProvider);
    await notif.init();
    final ok = await notif.requestPermission();
    if (!ok) return false;
    await notif.cancelAll();
    var id = 100;
    for (final s in day.slots.where((s) => s.isPrayer)) {
      await notif.schedulePrayer(id++, s.name, s.time);
    }
    return true;
  }
}

final prayerControllerProvider =
    AsyncNotifierProvider<PrayerController, PrayerDay>(PrayerController.new);

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(prayerControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'Namaz Vakitleri',
              trailing: IconButton(
                icon: const Icon(Icons.my_location_rounded, color: AppColors.gold),
                onPressed: () => ref.read(prayerControllerProvider.notifier).refresh(),
              ),
            ),
            Expanded(
              child: dayAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'Vakitler hesaplanamadı.\n$e',
                ),
                data: (day) => _PrayerBody(day: day),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beş vakit namaz listesi.
const _kPrayers = ['Sabah', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];

class _PrayerBody extends ConsumerStatefulWidget {
  const _PrayerBody({required this.day});
  final PrayerDay day;

  @override
  ConsumerState<_PrayerBody> createState() => _PrayerBodyState();
}

class _PrayerBodyState extends ConsumerState<_PrayerBody> {
  Set<String> _donePrayers = {};
  int _weeklyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    final done = await PrayerTracker.getTodayPrayers();
    final weekly = await PrayerTracker.weeklyCount();
    if (mounted) {
      setState(() {
        _donePrayers = done;
        _weeklyCount = weekly;
      });
    }
  }

  Future<void> _toggle(String prayer) async {
    final updated = await PrayerTracker.togglePrayer(prayer);
    final weekly = await PrayerTracker.weeklyCount();
    if (mounted) {
      setState(() {
        _donePrayers = updated;
        _weeklyCount = weekly;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIRADAKİ VAKİT', style: AppTypography.eyebrow()),
              const SizedBox(height: 10),
              _NextPrayerCountdown(day: widget.day),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 15, color: AppColors.cream2),
                  const SizedBox(width: 5),
                  Text(widget.day.locationLabel,
                      style: AppTypography.body(size: 13, color: AppColors.cream2)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1),
        const SizedBox(height: 18),
        for (final slot in widget.day.slots)
          _PrayerRow(slot: slot, day: widget.day),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: () async {
            final ok =
                await ref.read(prayerControllerProvider.notifier).enableNotifications();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      ok ? 'Ezan bildirimleri açıldı.' : 'Bildirim izni verilmedi.')),
            );
          },
          icon: const Icon(Icons.notifications_active_rounded),
          label: const Text('Ezan bildirimlerini aç'),
        ),
        const SizedBox(height: 24),
        // ── Bugünün Namazları ─────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bugünün Namazları', style: AppTypography.eyebrow()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kPrayers.map((p) {
                  final isDone = _donePrayers.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: isDone,
                    selectedColor: AppColors.gold.withValues(alpha: 0.22),
                    checkmarkColor: AppColors.gold,
                    labelStyle: AppTypography.body(
                      size: 14,
                      color: isDone ? AppColors.gold : AppColors.cream2,
                      weight: isDone ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isDone ? AppColors.gold : AppColors.line,
                      width: isDone ? 1.5 : 1,
                    ),
                    backgroundColor: Colors.transparent,
                    onSelected: (_) => _toggle(p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Bu hafta: $_weeklyCount/35 namaz',
                    style: AppTypography.body(size: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.08),
      ],
    );
  }
}

class _NextPrayerCountdown extends StatefulWidget {
  const _NextPrayerCountdown({required this.day});
  final PrayerDay day;

  @override
  State<_NextPrayerCountdown> createState() => _NextPrayerCountdownState();
}

class _NextPrayerCountdownState extends State<_NextPrayerCountdown> {
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
    final next = widget.day.nextAfter(now);
    if (next == null) {
      return Text('—', style: AppTypography.display(size: 34));
    }
    final remaining = next.time.difference(now);
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final hhmmss =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(next.name, style: AppTypography.display(size: 32)),
        Text(hhmmss,
            style: AppTypography.body(size: 22, weight: FontWeight.w700, color: AppColors.gold)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.slot, required this.day});
  final PrayerSlot slot;
  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNext = day.nextAfter(now)?.name == slot.name &&
        slot.time.isAfter(now);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(
              slot.isPrayer ? Icons.mosque_rounded : Icons.wb_twilight_rounded,
              color: isNext ? AppColors.goldBright : AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                slot.name,
                style: AppTypography.body(
                  size: 16,
                  weight: isNext ? FontWeight.w700 : FontWeight.w500,
                  color: isNext ? AppColors.gold : AppColors.cream,
                ),
              ),
            ),
            Text(
              DateFormat('HH:mm').format(slot.time),
              style: AppTypography.body(size: 17, weight: FontWeight.w700, color: AppColors.cream)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}
