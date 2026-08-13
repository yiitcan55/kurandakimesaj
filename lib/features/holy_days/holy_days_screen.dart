import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories.dart';
import '../../data/seed/seed_data.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Hicri ay adları (Türkçe).
const List<String> _kHijriMonths = [
  'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel',
  'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce',
];

class _HolyDay {
  const _HolyDay(this.name, this.date, this.desc);
  final String name;
  final DateTime date;
  final String desc;
}

/// Sabit hicri tarihli dini günler — (ay, gün, ad, açıklama).
const List<(int, int, String, String)> _kFixed = [
  (1, 1, 'Hicri Yılbaşı', 'Muharrem ayının ilk günü, hicri yılın başlangıcı.'),
  (1, 10, 'Aşure Günü', 'Muharrem\'in 10. günü; oruç tutmanın faziletli olduğu gün.'),
  (3, 12, 'Mevlid Kandili', 'Peygamber Efendimizin (s.a.v.) doğum gecesi.'),
  (7, 27, 'Mirac Kandili', 'İsra ve Mirac mucizesinin gerçekleştiği gece.'),
  (8, 15, 'Berat Kandili', 'Günahların affı için dua edilen mübarek gece.'),
  (9, 1, 'Ramazan Başlangıcı', 'On bir ayın sultanı Ramazan ayının ilk günü.'),
  (9, 27, 'Kadir Gecesi', 'Bin aydan hayırlı, Kur\'an\'ın indirildiği gece.'),
  (10, 1, 'Ramazan Bayramı', 'Şevval ayının ilk günü; Ramazan Bayramı.'),
  (12, 9, 'Arefe Günü', 'Kurban Bayramı\'ndan önceki gün; duaların kabul olduğu gün.'),
  (12, 10, 'Kurban Bayramı', 'Zilhicce\'nin 10. günü; Kurban Bayramı.'),
];

List<_HolyDay> _upcoming() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cal = HijriCalendar();
  cal.gregorianToHijri(now.year, now.month, now.day);
  final hY = cal.hYear;

  DateTime nextOf(int m, int d) {
    var g = HijriCalendar().hijriToGregorian(hY, m, d);
    var gd = DateTime(g.year, g.month, g.day);
    if (gd.isBefore(today)) {
      g = HijriCalendar().hijriToGregorian(hY + 1, m, d);
      gd = DateTime(g.year, g.month, g.day);
    }
    return gd;
  }

  // Regaib — Recep ayının ilk Cuma gecesi.
  DateTime regaib() {
    for (final y in [hY, hY + 1]) {
      for (var d = 1; d <= 7; d++) {
        final g = HijriCalendar().hijriToGregorian(y, 7, d);
        final gd = DateTime(g.year, g.month, g.day);
        if (gd.weekday == DateTime.friday && !gd.isBefore(today)) return gd;
      }
    }
    return nextOf(7, 1);
  }

  final list = <_HolyDay>[
    for (final f in _kFixed) _HolyDay(f.$3, nextOf(f.$1, f.$2), f.$4),
    _HolyDay('Regaib Kandili', regaib(),
        'Üç ayların başlangıcı; Recep ayının ilk Cuma gecesi.'),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return list;
}

class HolyDaysScreen extends ConsumerStatefulWidget {
  const HolyDaysScreen({super.key});

  @override
  ConsumerState<HolyDaysScreen> createState() => _HolyDaysScreenState();
}

class _HolyDaysScreenState extends ConsumerState<HolyDaysScreen> {
  bool _holyNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadHolyPrefs();
  }

  Future<void> _loadHolyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _holyNotificationsEnabled = prefs.getBool('holy_notifications') ?? false;
    });
  }

  Future<void> _toggleHolyNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('holy_notifications', enabled);
    setState(() => _holyNotificationsEnabled = enabled);

    final svc = ref.read(notificationServiceProvider);
    for (int i = 0; i < kIslamicDays2026.length; i++) {
      final day = kIslamicDays2026[i];
      if (!enabled) {
        await svc.cancel(100 + i);
        await svc.cancel(150 + i);
        continue;
      }
      // 1 gün önce, saat 20:00
      await svc.scheduleOnce(
        id: 100 + i,
        dateTime: day.date.subtract(const Duration(days: 1)).copyWith(hour: 20, minute: 0),
        title: '${day.name} Yaklaşıyor',
        body: 'Yarın ${day.name}. Hayırlı kandiller dileriz.',
      );
      // Gün sabahı, saat 08:00
      await svc.scheduleOnce(
        id: 150 + i,
        dateTime: day.date.copyWith(hour: 8, minute: 0),
        title: day.name,
        body: 'Bugün ${day.name}. Dualarınız kabul olsun.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cal = HijriCalendar();
    cal.gregorianToHijri(now.year, now.month, now.day);
    final hijriToday = '${cal.hDay} ${_kHijriMonths[cal.hMonth - 1]} ${cal.hYear}';
    final days = _upcoming();
    final next = days.first;
    final daysToNext = next.date.difference(DateTime(now.year, now.month, now.day)).inDays;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Dini Günler'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUGÜN (HİCRİ)', style: AppTypography.eyebrow()),
                        const SizedBox(height: 8),
                        Text(hijriToday, style: AppTypography.display(size: 30)),
                        const SizedBox(height: 14),
                        Text('Yaklaşan: ${next.name}',
                            style: AppTypography.body(size: 15, color: AppColors.cream)),
                        Text(
                            '$daysToNext gün kaldı · ${DateFormat('d MMMM yyyy', 'tr').format(next.date)}',
                            style: AppTypography.body(size: 13, color: AppColors.goldInk)),
                      ],
                    ),
                  ).animate().fadeIn(duration: AppDurations.normal),
                  const SizedBox(height: 16),
                  // Bildirim switch
                  Card(
                    child: SwitchListTile(
                      title: const Text('Kandil & Bayram Bildirimleri'),
                      subtitle: const Text('Özel günlerde hatırlatma al'),
                      value: _holyNotificationsEnabled,
                      onChanged: _toggleHolyNotifications,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(title: 'Yaklaşan Mübarek Günler', eyebrow: 'Takvim'),
                  const SizedBox(height: 12),
                  for (final d in days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.goldFaint,
                                borderRadius: AppRadii.smAll,
                              ),
                              child: Column(
                                children: [
                                  Text(DateFormat('d').format(d.date),
                                      style: AppTypography.display(
                                          size: 22, color: AppColors.goldInk)),
                                  Text(DateFormat('MMM', 'tr').format(d.date),
                                      style:
                                          AppTypography.body(size: 11, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name,
                                      style: AppTypography.body(
                                          size: 16,
                                          weight: FontWeight.w600,
                                          color: AppColors.cream)),
                                  const SizedBox(height: 2),
                                  Text(d.desc,
                                      style:
                                          AppTypography.body(size: 12.5, color: AppColors.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
