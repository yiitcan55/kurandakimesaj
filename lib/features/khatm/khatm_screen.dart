import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_repositories.dart';
import '../../ui/core/painters.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final circlesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(khatmRepositoryProvider).publicCircles(),
);

final _claimsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, circleId) => ref.watch(khatmRepositoryProvider).watchClaims(circleId),
);

class KhatmScreen extends ConsumerStatefulWidget {
  const KhatmScreen({super.key});
  @override
  ConsumerState<KhatmScreen> createState() => _KhatmScreenState();
}

class _KhatmScreenState extends ConsumerState<KhatmScreen> {
  final _takenByOthers = {2, 5, 9, 14, 18, 23, 27};
  final _mine = <int>{};

  String? _selectedCircleId;
  String _selectedCircleTitle = 'Ramazan Hatmi';
  bool _claiming = false;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);

    if (!isSignedIn) {
      return _buildOfflineView();
    }

    if (_selectedCircleId == null) {
      return _buildCircleListView();
    }

    return _buildJuzGridView();
  }

  Widget _buildOfflineView() {
    final claimed = _takenByOthers.length + _mine.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Hatim Halkaları'),
            Expanded(
              child: ListView(
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
                                painter: CircularProgressPainter(
                                    progress: claimed / 30, strokeWidth: 7),
                              ),
                              Text('$claimed/30',
                                  style: AppTypography.body(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.goldInk)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ramazan Hatmi',
                                  style: AppTypography.display(size: 22)),
                              Text(
                                  'Bir cüz seç, halkanın hatmine katkıda bulun.',
                                  style: AppTypography.body(
                                      size: 13, color: AppColors.cream2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(title: 'Cüz Dağıtımı', eyebrow: 'Halka'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var n = 1; n <= 30; n++)
                        _juzCell(n, takenByOthers: _takenByOthers, mine: _mine),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not: Gerçek zamanlı grup hatmi ve üye senkronizasyonu Supabase Realtime ile sağlanır.',
                    style: AppTypography.body(size: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleListView() {
    final circlesAsync = ref.watch(circlesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Hatim Halkaları'),
            Expanded(
              child: circlesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const EmptyState(
                  icon: Icons.error_outline,
                  message: 'Halkalar yüklenemedi.',
                ),
                data: (circles) {
                  if (circles.isEmpty) {
                    return const EmptyState(
                      icon: Icons.group_outlined,
                      message: 'Henüz halka yok.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: circles.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final circle = circles[index];
                      final title =
                          circle['title'] as String? ?? 'Hatim Halkası';
                      final description =
                          circle['description'] as String?;
                      return AppCard(
                        onTap: () => setState(() {
                          _selectedCircleId = circle['id'] as String;
                          _selectedCircleTitle = title;
                        }),
                        child: Row(
                          children: [
                            Icon(Icons.group_outlined,
                                color: AppColors.goldInk, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: AppTypography.display(size: 18)),
                                  if (description != null &&
                                      description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(description,
                                        style: AppTypography.body(
                                            size: 13,
                                            color: AppColors.cream2)),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: AppColors.muted, size: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzGridView() {
    final claimsAsync = ref.watch(_claimsProvider(_selectedCircleId!));
    final myId =
        ref.read(supabaseClientProvider)?.auth.currentUser?.id;

    return claimsAsync.when(
      loading: () => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: _selectedCircleTitle,
                onBack: () => setState(() => _selectedCircleId = null),
              ),
              const Expanded(
                  child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      ),
      error: (err, st) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: _selectedCircleTitle,
                onBack: () => setState(() => _selectedCircleId = null),
              ),
              const Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  message: 'Cüz bilgileri yüklenemedi.',
                ),
              ),
            ],
          ),
        ),
      ),
      data: (claims) {
        final takenByOthers = claims
            .where((c) => myId == null || c['user_id'] != myId)
            .map((c) => c['juz_number'] as int)
            .toSet();
        final mine = myId == null
            ? <int>{}
            : claims
                .where((c) => c['user_id'] == myId)
                .map((c) => c['juz_number'] as int)
                .toSet();
        final claimed = takenByOthers.length + mine.length;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: _selectedCircleTitle,
                  onBack: () => setState(() => _selectedCircleId = null),
                ),
                Expanded(
                  child: ListView(
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
                                    painter: CircularProgressPainter(
                                        progress: claimed / 30,
                                        strokeWidth: 7),
                                  ),
                                  Text('$claimed/30',
                                      style: AppTypography.body(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: AppColors.goldInk)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedCircleTitle,
                                      style: AppTypography.display(size: 22)),
                                  Text(
                                      'Bir cüz seç, halkanın hatmine katkıda bulun.',
                                      style: AppTypography.body(
                                          size: 13,
                                          color: AppColors.cream2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SectionLabel(
                          title: 'Cüz Dağıtımı', eyebrow: 'Halka'),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          for (var n = 1; n <= 30; n++)
                            _juzCell(n,
                                takenByOthers: takenByOthers,
                                mine: mine,
                                onTap: () => _claimJuz(n, mine)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _claimJuz(int n, Set<int> mine) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      await ref
          .read(khatmRepositoryProvider)
          .claim(_selectedCircleId!, n);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Widget _juzCell(
    int n, {
    required Set<int> takenByOthers,
    required Set<int> mine,
    VoidCallback? onTap,
  }) {
    final isMine = mine.contains(n);
    final taken = takenByOthers.contains(n);
    final Color bg;
    final Color fg;
    if (isMine) {
      bg = AppColors.gold;
      fg = AppColors.onGold;
    } else if (taken) {
      bg = AppColors.emerald700;
      fg = AppColors.muted;
    } else {
      bg = Colors.transparent;
      fg = AppColors.cream2;
    }
    return InkWell(
      borderRadius: AppRadii.smAll,
      onTap: (taken && !isMine) || _claiming
          ? null
          : onTap ??
              () => setState(() {
                    isMine ? _mine.remove(n) : _mine.add(n);
                  }),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: isMine ? AppColors.gold : AppColors.line),
        ),
        child: Text('$n',
            style: AppTypography.body(
                size: 15, weight: FontWeight.w700, color: fg)),
      ),
    );
  }
}
