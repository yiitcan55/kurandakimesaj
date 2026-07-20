import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Splash — marka + "Anla / Düşün / Paylaş" vaadi, animasyonlu giriş.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    context.go(settings.onboardingComplete ? '/home' : '/setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.lgAll,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.emerald700, AppColors.emerald950],
                  ),
                ),
                alignment: Alignment.center,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text('إقرأ', style: arabicStyle(size: 44)),
                ),
              )
                  .animate()
                  .scale(duration: AppDurations.entrance, curve: AppDurations.spring)
                  .fadeIn(),
              const SizedBox(height: 26),
              Text('Kur\'an\'da ki Mesaj', style: AppTypography.display(size: 34))
                  .animate(delay: 300.ms)
                  .fadeIn()
                  .slideY(begin: 0.3, curve: AppDurations.easeOut),
              const SizedBox(height: 10),
              Text(
                'Anla  ·  Düşün  ·  Paylaş',
                style: AppTypography.body(size: 15, color: AppColors.gold),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3 adımlı kurulum — meal tercihi · ilgi alanları · bildirim izni.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _page = PageController();
  int _index = 0;

  void _next() {
    if (_index < 3) {
      _page.nextPage(duration: AppDurations.normal, curve: AppDurations.easeOut);
    } else {
      _complete();
    }
  }

  /// Kurulumu bitir ve hedef rotaya geç. "Aha" adımındaki "ilk videonu
  /// oluştur" CTA'sı doğrudan stüdyoya götürebilsin diye rota parametreli.
  void _complete([String route = '/home']) {
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go(route);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _index;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _ParallaxPage(
                    controller: _page,
                    index: 0,
                    child: _MealStep(
                      selected: settings.mealOption,
                      onSelect: controller.setMeal,
                    ),
                  ),
                  _ParallaxPage(
                    controller: _page,
                    index: 1,
                    child: _InterestStep(
                      selected: settings.interests,
                      onToggle: controller.toggleInterest,
                    ),
                  ),
                  _ParallaxPage(
                    controller: _page,
                    index: 2,
                    child: _NotificationStep(
                      granted: settings.notificationsGranted,
                      onRequest: () async {
                        final ok = await ref
                            .read(permissionServiceProvider)
                            .requestNotifications();
                        await controller.setNotifications(ok);
                      },
                    ),
                  ),
                  _ParallaxPage(
                    controller: _page,
                    index: 3,
                    child: _AhaStep(
                      interests: settings.interests,
                      onCreate: () => _complete('/studio'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_index < 3 ? 'Devam' : 'Hemen başla'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Programatik PageView geçişlerinde her sayfaya hafif paralaks (yatay
/// kayma) + solma uygular. "Hareketi azalt" açıkken efekt atlanır.
class _ParallaxPage extends StatelessWidget {
  const _ParallaxPage({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        // Sayfanın viewport merkezine olan uzaklığı (−1..0..1).
        double delta = 0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? controller.initialPage.toDouble()) - index;
        }
        final clamped = delta.clamp(-1.0, 1.0);
        final opacity = (1 - clamped.abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          // Paralaks: içerik sayfadan biraz daha yavaş kayar.
          child: Transform.translate(
            offset: Offset(clamped * 28, 0),
            child: child,
          ),
        );
      },
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({required this.eyebrow, required this.title, required this.child});
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: AppTypography.eyebrow()),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.display(size: 30)),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ).animate().fadeIn(duration: AppDurations.normal),
    );
  }
}

class _MealStep extends StatelessWidget {
  const _MealStep({required this.selected, required this.onSelect});
  final MealOption selected;
  final ValueChanged<MealOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Adım 1 / 3',
      title: 'Meal tercihin',
      child: ListView(
        children: [
          for (final m in MealOption.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => onSelect(m),
                child: Row(
                  children: [
                    Icon(
                      selected == m
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 14),
                    Text(m.label, style: AppTypography.body(size: 16, color: AppColors.cream)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestStep extends StatelessWidget {
  const _InterestStep({required this.selected, required this.onToggle});
  final Set<AppInterest> selected;
  final ValueChanged<AppInterest> onToggle;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Adım 2 / 3',
      title: 'İlgi alanların',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final i in AppInterest.values)
            GoldChip(
              label: i.label,
              selected: selected.contains(i),
              onTap: () => onToggle(i),
            ),
        ],
      ),
    );
  }
}

class _NotificationStep extends StatelessWidget {
  const _NotificationStep({required this.granted, required this.onRequest});
  final bool granted;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Adım 3 / 3',
      title: 'Bildirimler',
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ezan · Günün Ayeti · Kandil',
                    style: AppTypography.body(size: 16, color: AppColors.cream)),
                const SizedBox(height: 8),
                Text(
                  'Namaz vakitleri, günün ayeti ve kandil gecelerinde hatırlatma alabilirsin.',
                  style: AppTypography.body(size: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: granted ? null : onRequest,
                  child: Text(granted ? 'İzin verildi ✓' : 'Bildirimlere izin ver'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kurulumun "aha" anı — kullanıcının ilk ilgi alanına göre kişiselleştirilmiş
/// ilk ayet kartı. Pasif kurulumun ardından ürünün çekirdek vaadini ("ayet →
/// paylaşılabilir içerik") daha ilk saniyelerde hissettirir. İçerik çevrimdışı
/// küratörlüdür (Diyanet meali) — onboarding'i DB/ağ bağımlılığından arındırır.
class _AhaStep extends StatelessWidget {
  const _AhaStep({required this.interests, required this.onCreate});
  final Set<AppInterest> interests;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ayah = _firstAyahFor(
      interests.isEmpty ? AppInterest.okuma : interests.first,
    );
    return _StepShell(
      eyebrow: 'Adım 4 / 4',
      title: 'İlk ayetin hazır',
      child: ListView(
        children: [
          Text(
            'İlgine göre seçtik. Hadi bunu paylaşılabilir bir karta dönüştürelim.',
            style: AppTypography.body(size: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AyetFrame(arabic: ayah.arabic, fontSize: 24),
                const SizedBox(height: 14),
                Text(ayah.meal,
                    style: AppTypography.body(size: 15.5, color: AppColors.cream)),
                const SizedBox(height: 8),
                Text(ayah.reference,
                    style: AppTypography.body(size: 12.5, color: AppColors.gold)),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppDurations.normal)
              .slideY(begin: 0.12, curve: AppDurations.easeOut),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.movie_creation_rounded, size: 18),
            label: const Text('İlk videonu oluştur'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'veya aşağıdan keşfetmeye başla',
              style: AppTypography.body(size: 12.5, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// İlgi alanına göre küratörlü ilk ayet (referans · Arapça · Diyanet meali).
typedef _FirstAyah = ({String reference, String arabic, String meal});

_FirstAyah _firstAyahFor(AppInterest interest) => switch (interest) {
      AppInterest.okuma => (
          reference: 'Alak 96:1',
          arabic: 'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ',
          meal: 'Yaratan Rabbinin adıyla oku!',
        ),
      AppInterest.ibadet => (
          reference: 'Bakara 2:152',
          arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ',
          meal: 'Öyleyse yalnız beni anın ki ben de sizi anayım.',
        ),
      AppInterest.ezber => (
          reference: 'Kamer 54:17',
          arabic: 'وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِنْ مُدَّكِرٍ',
          meal:
              'Andolsun, biz Kur\'an\'ı düşünüp öğüt almak için kolaylaştırdık. Var mı düşünüp öğüt alan?',
        ),
      AppInterest.uretim => (
          reference: 'İbrahim 14:24',
          arabic: 'كَلِمَةً طَيِّبَةً كَشَجَرَةٍ طَيِّبَةٍ',
          meal:
              'Güzel bir söz; kökü sağlam, dalları göğe yükselen güzel bir ağaç gibidir.',
        ),
      AppInterest.topluluk => (
          reference: 'Âl-i İmrân 3:103',
          arabic: 'وَاعْتَصِمُوا بِحَبْلِ اللَّهِ جَمِيعًا وَلَا تَفَرَّقُوا',
          meal:
              'Hep birlikte Allah\'ın ipine sımsıkı sarılın. Parçalanıp ayrılmayın.',
        ),
    };
