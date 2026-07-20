import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device_services.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../ui/core/painters.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Kâbe yönü (kuzeyden derece) — konuma göre tek seferlik hesap.
final qiblaBearingProvider = FutureProvider<double>((ref) async {
  final svc = ref.read(prayerServiceProvider);
  final loc = await ref.read(locationServiceProvider).current();
  if (loc == null) {
    return svc.qiblaBearing(LocationService.defaultLat, LocationService.defaultLng);
  }
  return svc.qiblaBearing(loc.lat, loc.lng);
});

/// Cihaz pusula yönü (derece) — sürekli akış.
final headingProvider = StreamProvider<double?>(
  (ref) => ref.watch(qiblaServiceProvider).headingStream(),
);

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bearing = ref.watch(qiblaBearingProvider);
    final heading = ref.watch(headingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Pusula (Kıble)'),
            Expanded(
              child: bearing.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (qiblaBearing) {
                  final deviceHeading = heading.value;
                  final hasSensor = deviceHeading != null;
                  final info = QiblaInfo(
                    qiblaBearing: qiblaBearing,
                    deviceHeading: deviceHeading ?? 0,
                  );
                  final angleRad = info.angleToQibla * math.pi / 180;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        info.aligned && hasSensor ? 'Kâbe yönündesiniz' : 'Telefonu yatay tutun',
                        style: AppTypography.display(
                          size: 24,
                          color: info.aligned && hasSensor ? AppColors.success : AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: CustomPaint(
                          painter: QiblaDialPainter(
                            headingToQibla: angleRad,
                            aligned: info.aligned && hasSensor,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 30),
                                Text('${qiblaBearing.toStringAsFixed(0)}°',
                                    style: AppTypography.display(size: 28, color: AppColors.gold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (!hasSensor)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Cihazınızda pusula sensörü algılanamadı. Ok, kuzeye göre Kâbe yönünü (${qiblaBearing.toStringAsFixed(0)}°) gösterir.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body(size: 13, color: AppColors.muted),
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
