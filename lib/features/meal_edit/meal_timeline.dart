import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../domain/meal_cues.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// '0:00', '1:24', '12:05' — dakika sınırsız, saniye iki hane.
String formatClock(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Video konumu: üstte cue aralıklarını gösteren dalga formu, altında
/// kaydırıcı, en altta süre etiketleri.
class MealTimeline extends StatelessWidget {
  const MealTimeline({
    super.key,
    required this.position,
    required this.cues,
    this.onSeek,
  });

  final ValueListenable<VideoPlayerValue> position;
  final List<MealCue> cues;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: position,
        builder: (context, v, _) {
          final total = v.duration;
          final ms = total.inMilliseconds;
          final progress = ms == 0
              ? 0.0
              : (v.position.inMilliseconds / ms).clamp(0.0, 1.0);
          final label = AppTypography.body(size: 12, color: AppColors.muted);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                width: double.infinity,
                child: CustomPaint(
                  painter: MealWaveformPainter(
                    cues: cues,
                    durationSec: ms / 1000,
                    progress: progress,
                    lit: AppColors.success,
                    dim: AppColors.muted.withValues(alpha: 0.35),
                    played: AppColors.muted,
                  ),
                ),
              ),
              Semantics(
                container: true,
                label: 'Video konumu',
                child: SizedBox(
                  height: 44,
                  child: Slider(
                    value: progress,
                    activeColor: AppColors.success,
                    onChanged: ms == 0 || onSeek == null
                        ? null
                        : (x) =>
                              onSeek!(Duration(milliseconds: (x * ms).round())),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatClock(Duration.zero), style: label),
                  Text(
                    formatClock(Duration(milliseconds: ms ~/ 2)),
                    style: label,
                  ),
                  Text(formatClock(total), style: label),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ponytail: çubuk yükseklikleri dekoratif; gerçek ses dalga formu gerekirse just_waveform ile değiştir. Vurgulu bölgeler gerçek (cue aralıkları).
class MealWaveformPainter extends CustomPainter {
  const MealWaveformPainter({
    required this.cues,
    required this.durationSec,
    required this.progress,
    required this.lit,
    required this.dim,
    required this.played,
  });

  static const _bars = 56;

  final List<MealCue> cues;
  final double durationSec;
  final double progress;

  /// Tema ile dönen renkler alanda yakalanır ki [shouldRepaint] görebilsin.
  final Color lit;
  final Color dim;
  final Color played;

  @override
  void paint(Canvas c, Size size) {
    final slot = size.width / _bars;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, slot * 0.55);
    for (var i = 0; i < _bars; i++) {
      final t = (i + 0.5) / _bars;
      final sec = t * durationSec;
      final inCue = cues.any((q) => sec >= q.startSec && sec < q.endSec);
      paint.color = inCue ? lit : (t <= progress ? played : dim);
      final h =
          size.height *
          (0.25 + 0.75 * (math.sin(i * 0.9) * math.cos(i * 0.37)).abs());
      final x = (i + 0.5) * slot;
      c.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MealWaveformPainter old) =>
      !listEquals(old.cues, cues) ||
      old.durationSec != durationSec ||
      old.progress != progress ||
      old.lit != lit ||
      old.dim != dim ||
      old.played != played;
}
