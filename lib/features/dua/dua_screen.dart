import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final duasProvider = FutureProvider<List<Dua>>(
  (ref) => ref.read(contentRepositoryProvider).duas(),
);

final selectedDuaCategoryProvider = StateProvider<String?>((ref) => null);

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key});

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen> {
  TimeOfDay? _morningTime;
  TimeOfDay? _eveningTime;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('dua_notifications_enabled') ?? false;
      final mh = prefs.getInt('dua_morning_h');
      final mm = prefs.getInt('dua_morning_m');
      if (mh != null) _morningTime = TimeOfDay(hour: mh, minute: mm ?? 0);
      final eh = prefs.getInt('dua_evening_h');
      final em = prefs.getInt('dua_evening_m');
      if (eh != null) _eveningTime = TimeOfDay(hour: eh, minute: em ?? 0);
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _notificationsEnabled = enabled);
    await prefs.setBool('dua_notifications_enabled', enabled);

    final svc = ref.read(notificationServiceProvider);
    if (!enabled) {
      await svc.cancel(1);
      await svc.cancel(2);
      return;
    }
    if (_morningTime != null) {
      await svc.scheduleDailyDua(
        id: 1,
        hour: _morningTime!.hour,
        minute: _morningTime!.minute,
        title: 'Sabah Duası',
        body: 'Güne besmele ile başla',
      );
    }
    if (_eveningTime != null) {
      await svc.scheduleDailyDua(
        id: 2,
        hour: _eveningTime!.hour,
        minute: _eveningTime!.minute,
        title: 'Akşam Duası',
        body: 'Günü şükranla kapat',
      );
    }
  }

  Future<void> _pickTime({required bool isMorning}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isMorning
          ? (_morningTime ?? const TimeOfDay(hour: 6, minute: 0))
          : (_eveningTime ?? const TimeOfDay(hour: 20, minute: 0)),
    );
    if (time == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => isMorning ? _morningTime = time : _eveningTime = time);
    if (isMorning) {
      await prefs.setInt('dua_morning_h', time.hour);
      await prefs.setInt('dua_morning_m', time.minute);
    } else {
      await prefs.setInt('dua_evening_h', time.hour);
      await prefs.setInt('dua_evening_m', time.minute);
    }
    if (_notificationsEnabled) await _toggleNotifications(true);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(duasProvider);
    final selected = ref.watch(selectedDuaCategoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Dua Kitaplığı'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (duas) {
                  final categories = <String>{for (final d in duas) d.category}.toList();
                  final filtered =
                      selected == null ? duas : duas.where((d) => d.category == selected).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      // Hatırlatıcı bölümü
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Günlük Dua Hatırlatıcısı'),
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                            ),
                            if (_notificationsEnabled) ...[
                              ListTile(
                                leading: const Icon(Icons.wb_sunny_rounded),
                                title: const Text('Sabah'),
                                trailing: Text(
                                  _morningTime?.format(context) ?? 'Ayarla',
                                ),
                                onTap: () => _pickTime(isMorning: true),
                              ),
                              ListTile(
                                leading: const Icon(Icons.nights_stay_rounded),
                                title: const Text('Akşam'),
                                trailing: Text(
                                  _eveningTime?.format(context) ?? 'Ayarla',
                                ),
                                onTap: () => _pickTime(isMorning: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Kategori filtresi
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GoldChip(
                                label: 'Tümü',
                                selected: selected == null,
                                onTap: () =>
                                    ref.read(selectedDuaCategoryProvider.notifier).state = null,
                              ),
                            ),
                            for (final c in categories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GoldChip(
                                  label: c,
                                  selected: selected == c,
                                  onTap: () =>
                                      ref.read(selectedDuaCategoryProvider.notifier).state = c,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final (i, d) in filtered.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            onTap: () => _showDua(context, ref, d),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.goldFaint,
                                    borderRadius: AppRadii.smAll,
                                  ),
                                  child: const Icon(Icons.volunteer_activism_rounded,
                                      color: AppColors.gold, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.title,
                                          style: AppTypography.body(
                                              size: 16,
                                              weight: FontWeight.w600,
                                              color: AppColors.cream)),
                                      Text(d.category,
                                          style: AppTypography.body(
                                              size: 12.5, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                              ],
                            ),
                          ),
                        )
                            .animate(delay: ((i < 10 ? i : 10) * 40).ms)
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

  void _showDua(BuildContext context, WidgetRef ref, Dua d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(d.title, style: AppTypography.display(size: 24)),
            Text(d.category, style: AppTypography.body(size: 13, color: AppColors.gold)),
            const SizedBox(height: 18),
            AyetFrame(arabic: d.arabic, fontSize: 26),
            if (d.latin.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(d.latin,
                  style: AppTypography.body(size: 15, color: AppColors.cream2)
                      .copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            Text(d.body, style: AppTypography.body(size: 16, color: AppColors.cream)),
            if (d.source.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Kaynak: ${d.source}',
                  style: AppTypography.body(size: 13, color: AppColors.muted)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => ref
                  .read(shareServiceProvider)
                  .shareText('${d.title}\n\n${d.body}\n\n${d.source}', subject: d.title),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Paylaş'),
            ),
          ],
        ),
      ),
    );
  }
}
