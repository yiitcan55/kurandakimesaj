import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/feature_catalog.dart';
import '../../data/backend_repositories.dart';
import '../../data/repositories.dart';
import '../../data/services.dart';
import '../../data/widget_sync_service.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import '../daily_ayah/daily_ayah_screen.dart';
import '../dhikr/dhikr_screens.dart';
import '../prayer/prayer_screen.dart';
import '../progress/progress_screens.dart';

FeatureDef _feature(String route) =>
    kFeatures.firstWhere((f) => f.route == route);

/// 5 slotlu alt menü: Ana Sayfa · Akış · (+) Oluştur · Mesajlar · Profil.
/// StatefulShellRoute.indexedStack ile her sekme kendi yığınını korur.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int branch) => navigationShell.goBranch(
    branch,
    initialLocation: branch == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        onCreate: () => showCreateSheet(context),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCreate,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald900,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_rounded, 'Ana Sayfa'),
              _item(1, Icons.dynamic_feed_rounded, 'Akış'),
              _fab(),
              _item(2, Icons.mail_rounded, 'Mesajlar'),
              _item(3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int branch, IconData icon, String label) {
    final active = currentIndex == branch;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(branch),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.12 : 1.0,
              duration: AppDurations.normal,
              curve: AppDurations.spring,
              child: TweenAnimationBuilder<Color?>(
                duration: AppDurations.fast,
                curve: AppDurations.easeOut,
                tween: ColorTween(
                  end: active ? AppColors.gold : AppColors.muted,
                ),
                builder: (_, color, _) => Icon(icon, size: 24, color: color),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              curve: AppDurations.easeOut,
              style: AppTypography.body(
                size: 10.5,
                weight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.gold : AppColors.muted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab() {
    return Expanded(
      child: Center(
        child:
            GestureDetector(
              onTap: onCreate,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.fabGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.onGold,
                  size: 28,
                ),
              ),
            ).animate().scale(
              duration: AppDurations.normal,
              curve: AppDurations.spring,
            ),
      ),
    );
  }
}

/// Oluştur sheet — Video Edit / AI / Paylaşım / Hikaye (FAB'den açılır).
Future<void> showCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oluştur', style: AppTypography.display(size: 26)),
          const SizedBox(height: 4),
          Text(
            'Ayetten içerik üret ve paylaş.',
            style: AppTypography.body(size: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          _createItem(
            ctx,
            Icons.image_search_rounded,
            'Ayet Bul',
            'Görselden/bağlantıdan ayeti bul',
            '/ayah-finder',
          ),
          _createItem(
            ctx,
            Icons.movie_creation_rounded,
            'Video Edit',
            'Şablon + tilavet + meal',
            '/studio',
          ),
          _createItem(
            ctx,
            Icons.dashboard_customize_rounded,
            'Şablonlar',
            'Hazır temalardan başla',
            '/templates',
          ),
          _createItem(
            ctx,
            Icons.share_rounded,
            'Paylaşım',
            'Günün ayetini paylaş',
            '/daily-ayah',
          ),
        ],
      ),
    ),
  );
}

Widget _createItem(
  BuildContext ctx,
  IconData icon,
  String title,
  String sub,
  String route,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      onTap: () {
        Navigator.of(ctx).pop();
        ctx.push(route);
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldFaint,
              borderRadius: AppRadii.smAll,
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.cream,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.body(size: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

/// Ana Sayfa — selamlama, vakit şeridi, Günün Ayeti, 8'li hızlı işlem grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quick = kQuickActionRoutes.map(_feature).toList();
    // Veri hazır oldukça telefon ana ekran widget'larını besle.
    _syncHomeWidgets(ref);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Selamünaleyküm', style: AppTypography.display(size: 30)),
            Text(
              'Hayırlı günler dileriz.',
              style: AppTypography.body(size: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            const _HijriDateCard(),
            const SizedBox(height: 12),
            const _ReadingGoalCard(),
            const SizedBox(height: 12),
            const _PrayerStrip(),
            const SizedBox(height: 12),
            const _QiblaMosqueCard(),
            const SizedBox(height: 16),
            const _DailyAyahHero(),
            const SizedBox(height: 22),
            const SectionLabel(title: 'Hızlı İşlemler', eyebrow: 'Kısayollar'),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              // Sabit hücre yüksekliği: ikon kutusu (72) + boşluk (8) + 2 satır
              // başlık metni. childAspectRatio genişliğe bağlı olduğundan dar
              // ekranlarda taşıyordu; mainAxisExtent bunu garanti eder.
              mainAxisExtent: 120,
              children: [
                for (var i = 0; i < quick.length; i++)
                  _QuickAction(feature: quick[i])
                      .animate(delay: (60 + i * 70).ms)
                      .fadeIn(duration: AppDurations.normal)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: AppDurations.slow,
                        curve: AppDurations.spring,
                      )
                      .slideY(begin: 0.22, curve: AppDurations.easeOut),
              ],
            ),
            const SizedBox(height: 12),
            // Ana sayfa yalnızca 8 öne çıkan kısayol gösterir; 24 özelliğin
            // tamamına buradan erişilir (keşfedilebilirlik).
            AppCard(
              onTap: () => context.push('/features'),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: AppColors.gold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tüm Özellikler',
                      style: AppTypography.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _HomeStats(),
          ],
        ),
      ),
    );
  }
}

/// Namaz + günün ayeti verisi hazır oldukça telefon ana ekran widget'larını
/// günceller. ref.listen değişimde tetikler; ilk karede yüklü değer varsa
/// kaçırmamak için hemen de yazar.
void _syncHomeWidgets(WidgetRef ref) {
  final sync = ref.read(widgetSyncServiceProvider);
  ref.listen(prayerControllerProvider, (_, next) {
    final day = next.value;
    if (day != null) sync.syncPrayer(day);
  });
  ref.listen(dailyAyahProvider, (_, next) {
    final data = next.value;
    if (data != null) sync.syncAyah(data.$1, data.$2);
  });
  final day = ref.read(prayerControllerProvider).value;
  if (day != null) sync.syncPrayer(day);
  final ayah = ref.read(dailyAyahProvider).value;
  if (ayah != null) sync.syncAyah(ayah.$1, ayah.$2);
}

/// Hicri + miladi tarih kartı.
class _HijriDateCard extends StatelessWidget {
  const _HijriDateCard();

  @override
  Widget build(BuildContext context) {
    final greg = DateFormat('d MMMM yyyy', 'tr').format(DateTime.now());
    return AppCard(
      onTap: () => context.push('/holy-days'),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: AppColors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WidgetSyncService.hijriToday(),
                  style: AppTypography.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.cream,
                  ),
                ),
                Text(
                  greg,
                  style: AppTypography.body(size: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Kıble + En Yakın Cami kısayol kartı (yan yana iki aksiyon).
class _QiblaMosqueCard extends StatelessWidget {
  const _QiblaMosqueCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _mini(context, Icons.explore_rounded, 'Kıble', '/qibla'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _mini(
            context,
            Icons.mosque_rounded,
            'En Yakın Cami',
            '/mosque',
          ),
        ),
      ],
    );
  }

  Widget _mini(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return AppCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.cream,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Günün ayeti hero kartı — gerçek seed verisinden (deterministik).
class _DailyAyahHero extends ConsumerWidget {
  const _DailyAyahHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyAyahProvider);
    return HeroCard(
      child: async.when(
        // Spinner yerine hero içeriğinin yerleşimini taklit eden shimmer
        // iskeleti — uygulama genelindeki yükleme diliyle tutarlı.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerSkeleton(height: 11, width: 90),
            SizedBox(height: 14),
            ShimmerSkeleton(height: 22, width: 160),
            SizedBox(height: 14),
            ShimmerSkeleton(height: 14),
            SizedBox(height: 8),
            ShimmerSkeleton(height: 14, width: 220),
          ],
        ),
        error: (_, _) => Text(
          'Günün ayeti yüklenemedi.',
          style: AppTypography.body(color: AppColors.muted),
        ),
        data: (data) {
          if (data == null) {
            return Text('Günün ayeti', style: AppTypography.display(size: 22));
          }
          final (ayah, surah) = data;
          final ref0 = '${surah?.nameTr ?? 'Sure'}, ${ayah.numberInSurah}';
          final shareText = '${ayah.meal}\n($ref0)\n\nKur\'an\'da ki Mesaj';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GÜNÜN AYETİ', style: AppTypography.eyebrow()),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.arabic,
                  textAlign: TextAlign.right,
                  style: arabicStyle(size: 24),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ayah.meal,
                style: AppTypography.body(size: 15, color: AppColors.cream),
              ),
              const SizedBox(height: 8),
              Text(
                ref0,
                style: AppTypography.body(size: 12.5, color: AppColors.gold),
              ),
              const SizedBox(height: 8),
              AyetActionBar(
                onUnderstand: () => context.push('/daily-ayah'),
                onReflect: () => showReflectionSheet(
                  context,
                  reference: ref0,
                  onSave: (note) async {
                    await ref
                        .read(collectionsRepositoryProvider)
                        .add(
                          reference: ref0,
                          arabic: ayah.arabic,
                          meal: ayah.meal,
                          note: note.isEmpty ? null : note,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          note.isEmpty
                              ? 'Koleksiyona kaydedildi.'
                              : 'Düşüncen kaydedildi.',
                        ),
                      ),
                    );
                  },
                ),
                onShare: () => ref
                    .read(shareServiceProvider)
                    .shareText(shareText, subject: 'Günün Ayeti'),
              ),
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.15);
  }
}

/// Ana sayfa istatistik kartları — bugünkü zikir + tamamlanan cüz.
class _HomeStats extends ConsumerWidget {
  const _HomeStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dhikr = ref.watch(dhikrDayTotalProvider(today)).value ?? 0;
    final juzDone =
        ref.watch(juzListProvider).value?.where((j) => j.completed).length ?? 0;
    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            icon: Icons.donut_large_rounded,
            value: juzDone,
            label: 'Tamamlanan cüz',
            onTap: () => context.push('/juz-tracker'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StreakCard(
            icon: Icons.fingerprint_rounded,
            value: dhikr,
            label: 'Bugünkü zikir',
            onTap: () => context.push('/dhikr'),
          ),
        ),
      ],
    );
  }
}

/// Günlük okuma hedefi + streak kartı.
class _ReadingGoalCard extends StatefulWidget {
  const _ReadingGoalCard();

  @override
  State<_ReadingGoalCard> createState() => _ReadingGoalCardState();
}

class _ReadingGoalCardState extends State<_ReadingGoalCard> {
  int _goal = 2;
  int _today = 0;
  int _streak = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await ReadingGoalService.getDailyGoal();
    final today = await ReadingGoalService.getTodayRead();
    final streak = await ReadingGoalService.getStreak();
    if (mounted) {
      setState(() {
        _goal = goal;
        _today = today;
        _streak = streak;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final progress = (_today / _goal).clamp(0.0, 1.0);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_streak gün streak',
                  style: AppTypography.body(
                    size: 15,
                    weight: FontWeight.bold,
                    color: AppColors.cream,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_today/$_goal sayfa',
                  style: AppTypography.body(size: 13, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              // Sayaçlarla aynı dilde: bar 0'dan değerine yumuşak dolar, snap'lemez.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: AppDurations.slow,
                curve: AppDurations.easeOut,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _today >= _goal
                  ? 'Hedef tamamlandı!'
                  : '${_goal - _today} sayfa kaldı',
              style: AppTypography.body(size: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppDurations.normal);
  }
}

class _PrayerStrip extends ConsumerStatefulWidget {
  const _PrayerStrip();
  @override
  ConsumerState<_PrayerStrip> createState() => _PrayerStripState();
}

class _PrayerStripState extends ConsumerState<_PrayerStrip> {
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
    final dayAsync = ref.watch(prayerControllerProvider);
    final now = DateTime.now();
    String label = 'Namaz vakitleri';
    String countdown = '—';
    final next = dayAsync.value?.nextAfter(now);
    if (next != null) {
      label = 'Sıradaki: ${next.name}';
      final r = next.time.difference(now);
      countdown =
          '${r.inHours}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return AppCard(
      onTap: () => context.push('/prayer'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTypography.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
          Text(
            countdown,
            style: AppTypography.body(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.gold,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({required this.feature});
  final FeatureDef feature;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final content = InkWell(
      onTap: () => context.push(widget.feature.route),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      borderRadius: AppRadii.lgAll,
      splashColor: AppColors.goldFaint,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          // Büyük ikon kutusu — dokununca altın kenarlık + altın glow ile parlar.
          AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppDurations.easeOut,
            height: 72,
            decoration: BoxDecoration(
              gradient: _pressed
                  ? AppColors.cardGradientActive
                  : AppColors.cardGradient,
              borderRadius: AppRadii.lgAll,
              border: Border.all(
                color: _pressed ? AppColors.gold : AppColors.line,
                width: _pressed ? 1.4 : 1,
              ),
              boxShadow: _pressed
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedScale(
              scale: _pressed ? 1.14 : 1.0,
              duration: AppDurations.fast,
              curve: AppDurations.spring,
              child: Icon(widget.feature.icon, color: AppColors.gold, size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.feature.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(size: 12, color: AppColors.cream2),
          ),
        ],
      ),
    );

    if (reduceMotion) return content;
    return AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: AppDurations.fast,
      curve: AppDurations.easeOut,
      child: content,
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: value,
                  style: AppTypography.display(size: 24, color: AppColors.gold),
                ),
                Text(
                  label,
                  style: AppTypography.body(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Supabase profil verisi — oturum yoksa null döner.
final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final isSignedIn = ref.watch(isSignedInProvider);
  if (!isSignedIn) return null;
  return ref.read(profileRepositoryProvider).myProfile();
});

/// Profil — istatistik, ayarlar, oturum.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İsim Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Görünen adınız'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                await ref
                    .read(profileRepositoryProvider)
                    .updateDisplayName(text);
                ref.invalidate(myProfileProvider);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authRepositoryProvider);
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(myProfileProvider);

    final displayName =
        (profileAsync.value?['display_name'] as String?)?.isNotEmpty == true
        ? profileAsync.value!['display_name'] as String
        : (auth.isSignedIn
              ? (auth.currentUser?.email ?? 'Kullanıcı')
              : 'Misafir');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Profil', style: AppTypography.display(size: 30)),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.goldFaint,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: AppTypography.body(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: AppColors.cream,
                                ),
                              ),
                            ),
                            if (auth.isSignedIn) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _showEditNameDialog,
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.muted,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Meal: ${settings.mealOption.label}',
                          style: AppTypography.body(
                            size: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              onTap: () => context.push('/features'),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: AppColors.gold),
                  const SizedBox(width: 14),
                  Text(
                    'Tüm Özellikler',
                    style: AppTypography.body(size: 16, color: AppColors.cream),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: auth.isSignedIn
                  ? FilledButton.tonal(
                      onPressed: () => auth.signOut(),
                      child: const Text('Çıkış yap'),
                    )
                  : FilledButton(
                      onPressed: () => context.push('/auth'),
                      child: const Text('Giriş yap / Kayıt ol'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tüm Özellikler kataloğu — kategorili, tüm 24 özellik.
class FeaturesCatalogScreen extends StatelessWidget {
  const FeaturesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Tüm Özellikler'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  for (final cat in FeatureCategory.values) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        cat.label,
                        style: AppTypography.display(size: 22),
                      ),
                    ),
                    for (final (i, f)
                        in kFeatures.where((f) => f.category == cat).indexed)
                      Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => context.push(f.route),
                              child: Row(
                                children: [
                                  Icon(f.icon, color: AppColors.gold),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      f.title,
                                      style: AppTypography.body(
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: AppColors.cream,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: AppDurations.normal)
                          .slideY(begin: 0.12, curve: AppDurations.easeOut),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google "G" resmi logosu (4 renkli) — asset dosyası gerektirmeden inline
/// SVG olarak render edilir (flutter_svg). Google marka kılavuzuna uygundur.
const String _kGoogleLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
    '<path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>'
    '<path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>'
    '<path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>'
    '<path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>'
    '</svg>';

/// Auth ekranı — e-posta/parola giriş & kayıt + Google (Supabase).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Giriş başarılı olduğunda ekrandan ayrıl. `/auth`'a `push` ile gelindiyse
  /// önceki ekrana döner; `go('/auth')` ile gelindiyse (yığın değiştirilmiş,
  /// pop edilecek route yok) ana sekmeye gider. `canPop` guard'ı olmadan
  /// `context.pop()` "nothing to pop" fırlatır ve genel catch onu yanlışlıkla
  /// "giriş başarısız" sanardı — başarılı girişin başarısız görünmesinin nedeni.
  void _afterAuthSuccess() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await auth.signUp(_email.text.trim(), _password.text);
      } else {
        await auth.signIn(_email.text.trim(), _password.text);
      }
      _afterAuthSuccess();
    } catch (_) {
      setState(
        () =>
            _error = 'Giriş başarısız. Supabase yapılandırmasını kontrol edin.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      _afterAuthSuccess();
    } on GoogleSignInException catch (e) {
      // Kullanıcı hesap seçiciyi kapattıysa hata gösterme (sessiz iptal).
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _error = 'Google ile giriş başarısız.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Google ile giriş başarısız. Yapılandırmayı kontrol edin.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: _isSignUp ? 'Kayıt Ol' : 'Giriş Yap'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'E-posta'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Parola'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'Kayıt Ol' : 'Giriş Yap'),
                  ),
                  if (defaultTargetPlatform != TargetPlatform.iOS) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.gold.withValues(alpha: 0.25),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'veya',
                            style: AppTypography.body(
                              size: 13,
                              color: AppColors.cream.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.gold.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _googleSignIn,
                        icon: SvgPicture.string(
                          _kGoogleLogoSvg,
                          width: 20,
                          height: 20,
                        ),
                        label: Text(
                          'Google ile devam et',
                          style: AppTypography.body(
                            size: 15,
                            color: const Color(0xFF1F1F1F),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Zaten hesabım var' : 'Hesabım yok, kayıt ol',
                      style: AppTypography.body(
                        size: 14,
                        color: AppColors.gold,
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
