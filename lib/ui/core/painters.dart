import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

/// 33 boncuklu tesbih ipi — imame + püskül. Zikirmatik imza ekranının
/// çekirdeği (Flutter Planı.html §07). [filled] dolu boncuk sayısı (0..33).
class TasbihPainter extends CustomPainter {
  TasbihPainter(this.filled);

  final int filled;
  static const int beads = 33;

  @override
  void paint(Canvas c, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.37;
    const startA = 1.99;
    const sweep = 5.44; // imame için üstte boşluk

    final cord = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pts = [
      for (var i = 0; i < beads; i++)
        Offset(
          cx + cos(startA + i / (beads - 1) * sweep) * r,
          cy + sin(startA + i / (beads - 1) * sweep) * r,
        ),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, cord);

    for (var i = 0; i < beads; i++) {
      final isNow = i == filled && filled < beads;
      final on = i < filled;
      final rad = isNow ? 9.5 : 7.2;
      if (isNow) {
        c.drawCircle(
          pts[i],
          15,
          Paint()..color = AppColors.goldBright.withValues(alpha: 0.18),
        );
      }
      final fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: on || isNow
              ? const [Color(0xFFF6E09A), AppColors.gold, Color(0xFF9C7D36)]
              : const [Color(0xFF1E4434), Color(0xFF0C2017)],
        ).createShader(Rect.fromCircle(center: pts[i], radius: rad));
      c.drawCircle(pts[i], rad, fill);
    }

    // imame (lider boncuk) + püskül
    final imame = Offset(cx, cy + r + 22);
    c.drawOval(
      Rect.fromCenter(center: imame, width: 18, height: 30),
      Paint()..color = AppColors.gold,
    );
    for (final dx in [-5.0, -2.5, 0.0, 2.5, 5.0]) {
      c.drawLine(
        Offset(cx, imame.dy + 16),
        Offset(cx + dx, imame.dy + 30),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.4)
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(TasbihPainter old) => old.filled != filled;
}

/// Dairesel ilerleme halkası — cüz takibi, zikir hedefi, ezber yüzdesi.
/// [progress] 0..1 arası. Altın gradyanlı yay.
class CircularProgressPainter extends CustomPainter {
  CircularProgressPainter({required this.progress, this.strokeWidth = 12});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas c, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    c.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [AppColors.goldSoft, AppColors.goldBright, AppColors.gold],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    c.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(CircularProgressPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

/// Kıble kadranı — [headingToQibla] radyan (cihaz yönüne göre Kâbe açısı).
class QiblaDialPainter extends CustomPainter {
  QiblaDialPainter({required this.headingToQibla, required this.aligned});

  final double headingToQibla;
  final bool aligned;

  @override
  void paint(Canvas c, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;

    final ring = Paint()
      ..color = (aligned ? AppColors.success : AppColors.gold)
          .withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawCircle(center, radius, ring);

    final tick = Paint()..color = AppColors.gold.withValues(alpha: 0.3);
    for (var i = 0; i < 72; i++) {
      final a = i * pi / 36;
      final outer = center + Offset(cos(a), sin(a)) * radius;
      final inner =
          center + Offset(cos(a), sin(a)) * (radius - (i % 9 == 0 ? 12 : 6));
      c.drawLine(inner, outer, tick..strokeWidth = i % 9 == 0 ? 2 : 1);
    }

    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(headingToQibla);
    final arrow = Path()
      ..moveTo(0, -radius + 14)
      ..lineTo(-11, 14)
      ..lineTo(0, 4)
      ..lineTo(11, 14)
      ..close();
    c.drawPath(
      arrow,
      Paint()..color = aligned ? AppColors.success : AppColors.goldBright,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(QiblaDialPainter old) =>
      old.headingToQibla != headingToQibla || old.aligned != aligned;
}
