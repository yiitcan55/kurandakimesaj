import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/backend_repositories.dart';
import '../../data/content_repository.dart';
import '../../data/repositories.dart';
import '../../ui/core/painters.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Zikir hazır şablonu — (anahtar, etiket, arapça, hedef).
class DhikrPreset {
  const DhikrPreset(this.key, this.label, this.arabic, this.target);
  final String key;
  final String label;
  final String arabic;
  final int target;
}

const List<DhikrPreset> kDhikrPresets = [
  DhikrPreset('subhanallah', 'Sübhânallâh', 'سُبْحَانَ اللَّهِ', 33),
  DhikrPreset('elhamdulillah', 'Elhamdülillâh', 'الْحَمْدُ لِلَّهِ', 33),
  DhikrPreset('allahuekber', 'Allâhü Ekber', 'اللَّهُ أَكْبَرُ', 33),
  DhikrPreset('estagfirullah', 'Estağfirullâh', 'أَسْتَغْفِرُ اللَّهَ', 100),
  DhikrPreset('lailaheillallah', 'Lâ ilâhe illâllâh', 'لَا إِلَٰهَ إِلَّا اللَّهُ', 100),
  DhikrPreset('salavat', 'Salavât', 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ', 100),
];

class DhikrState {
  const DhikrState({required this.preset, required this.count});
  final DhikrPreset preset;
  final int count;

  int get cycle => count ~/ preset.target;
  int get inCycle => count % preset.target;

  DhikrState copyWith({DhikrPreset? preset, int? count}) =>
      DhikrState(preset: preset ?? this.preset, count: count ?? this.count);
}

/// Zikirmatik ViewModel'ı — sayaç bellekte, her değişimde drift'e yazılır.
class DhikrController extends Notifier<DhikrState> {
  late DhikrRepository _repo;
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  DhikrState build() {
    _repo = ref.read(dhikrRepositoryProvider);
    _load(kDhikrPresets.first);
    return DhikrState(preset: kDhikrPresets.first, count: 0);
  }

  Future<void> _load(DhikrPreset p) async {
    final c = await _repo.count(p.key, _today);
    state = DhikrState(preset: p, count: c);
  }

  void select(DhikrPreset p) => _load(p);

  Future<void> increment() async {
    HapticFeedback.lightImpact();
    final next = state.count + 1;
    state = state.copyWith(count: next);
    if (next % state.preset.target == 0) HapticFeedback.mediumImpact();
    await _repo.setCount(state.preset.key, _today, next);
    // Oturum açıksa buluta da yaz (offline-first; başarısızlık yutulur).
    unawaited(ref.read(syncRepositoryProvider).pushDhikr(_today, state.preset.key, next));
  }

  Future<void> reset() async {
    state = state.copyWith(count: 0);
    await _repo.setCount(state.preset.key, _today, 0);
  }
}

final dhikrControllerProvider =
    NotifierProvider<DhikrController, DhikrState>(DhikrController.new);

/// Bugünkü toplam zikir akışı (canlı).
final dhikrDayTotalProvider = StreamProvider.family<int, String>(
  (ref, dateIso) => ref.watch(dhikrRepositoryProvider).watchDayTotal(dateIso),
);

class DhikrScreen extends ConsumerWidget {
  const DhikrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(dhikrControllerProvider);
    final ctrl = ref.read(dhikrControllerProvider.notifier);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = ref.watch(dhikrDayTotalProvider(today)).value ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Zikirmatik',
              trailing: IconButton(
                icon: Icon(Icons.refresh_rounded, color: AppColors.goldInk),
                onPressed: ctrl.reset,
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ctrl.increment,
                child: CenteredScrollBody(
                  builder: (context, maxHeight) {
                    final dial = CenteredScrollBody.dialSize(maxHeight, 280);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child:
                              Text(s.preset.arabic, style: arabicStyle(size: 34)),
                        ),
                        const SizedBox(height: 4),
                        Text(s.preset.label,
                            style: AppTypography.body(
                                size: 15, color: AppColors.cream2)),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: dial,
                          height: dial,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(dial, dial),
                                painter: TasbihPainter(s.inCycle),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedCounter(
                                    value: s.inCycle,
                                    style: AppTypography.display(
                                        size: 64, color: AppColors.goldInk),
                                  ),
                                  Text('/ ${s.preset.target}',
                                      style: AppTypography.body(
                                          size: 14, color: AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ).animate().scale(
                            duration: AppDurations.normal,
                            curve: AppDurations.spring),
                        const SizedBox(height: 14),
                        Text('Tur: ${s.cycle}  ·  Bugün toplam: $total',
                            style: AppTypography.body(
                                size: 14, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text('Saymak için ekrana dokun',
                            style: AppTypography.body(
                                size: 12.5, color: AppColors.muted2)),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Sabit `SizedBox(height: 48)` yoktu: chip doğal yüksekliği 40.3px,
            // sistem yazı ölçeği ~1.4'te 48'i aşıp taşıyordu. Şerit artık
            // içeriğe göre yükseliyor; dokunma hedefini GoldChip garanti ediyor.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final p in kDhikrPresets)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GoldChip(
                        label: p.label,
                        selected: p.key == s.preset.key,
                        onTap: () => ctrl.select(p),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Tesbihat — namaz sonrası 33-33-33 rehberli sayaç ───────────────────────

class _TesbihatPhase {
  const _TesbihatPhase(this.label, this.arabic, this.target);
  final String label;
  final String arabic;
  final int target;
}

const List<_TesbihatPhase> _kTesbihat = [
  _TesbihatPhase('Sübhânallâh', 'سُبْحَانَ اللَّهِ', 33),
  _TesbihatPhase('Elhamdülillâh', 'الْحَمْدُ لِلَّهِ', 33),
  _TesbihatPhase('Allâhü Ekber', 'اللَّهُ أَكْبَرُ', 33),
];

class TasbihatScreen extends StatefulWidget {
  const TasbihatScreen({super.key});
  @override
  State<TasbihatScreen> createState() => _TasbihatScreenState();
}

class _TasbihatScreenState extends State<TasbihatScreen> {
  int _phase = 0;
  int _count = 0;
  bool _done = false;

  void _tap() {
    if (_done) return;
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      if (_count >= _kTesbihat[_phase].target) {
        HapticFeedback.mediumImpact();
        if (_phase < _kTesbihat.length - 1) {
          _phase++;
          _count = 0;
        } else {
          _done = true;
        }
      }
    });
  }

  void _restart() => setState(() {
        _phase = 0;
        _count = 0;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    final p = _kTesbihat[_phase];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Tesbihat',
              trailing: IconButton(
                icon: Icon(Icons.refresh_rounded, color: AppColors.goldInk),
                onPressed: _restart,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_kTesbihat.length, (i) {
                  final active = i <= _phase;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : AppColors.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: _done
                  ? EmptyState(
                      icon: Icons.check_circle_rounded,
                      message: 'Tesbihat tamamlandı.\n33 Sübhânallâh · 33 Elhamdülillâh · 33 Allâhü Ekber',
                      action: FilledButton(onPressed: _restart, child: const Text('Yeniden başla')),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tap,
                      child: CenteredScrollBody(
                        builder: (context, maxHeight) {
                          final dial =
                              CenteredScrollBody.dialSize(maxHeight, 200);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${_phase + 1} / ${_kTesbihat.length}',
                                  style: AppTypography.eyebrow()),
                              const SizedBox(height: 16),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child:
                                    Text(p.arabic, style: arabicStyle(size: 40)),
                              ),
                              const SizedBox(height: 6),
                              Text(p.label,
                                  style: AppTypography.display(size: 26)),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: dial,
                                height: dial,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: Size(dial, dial),
                                      painter: CircularProgressPainter(
                                        progress: _count / p.target,
                                        strokeWidth: 10,
                                      ),
                                    ),
                                    Text('$_count',
                                        style: AppTypography.display(
                                            size: 56, color: AppColors.goldInk)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text('Devam etmek için dokun',
                                  style: AppTypography.body(
                                      size: 13, color: AppColors.muted2)),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
