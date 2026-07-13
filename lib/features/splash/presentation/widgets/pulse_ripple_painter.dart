import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';

class PulseSplashPainter extends CustomPainter {
  PulseSplashPainter({
    required this.drawProgress,
    required this.breath,
    required this.glow,
  });

  final double drawProgress;
  final double breath;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final unit = math.min(size.width, size.height);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          PulseColors.primary.withValues(alpha: 0.35 * glow),
          PulseColors.primary.withValues(alpha: 0.08 * glow),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: unit * 0.42));
    canvas.drawCircle(center, unit * 0.42, glowPaint);

    final rings = <(double, double, double)>[
      (0.11, 5.5, 0.95),
      (0.17, 3.5, 0.55),
      (0.23, 2.2, 0.28),
    ];

    for (var i = 0; i < rings.length; i++) {
      final (radiusFactor, stroke, opacity) = rings[i];
      final start = i * 0.12;
      final local = ((drawProgress - start) / (1 - start)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final radius = unit * radiusFactor * breath;
      final sweep = 2 * math.pi * Curves.easeOutCubic.transform(local);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..color = PulseColors.ink.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);

      if (local > 0.85 && i == 0) {
        final accent = Paint()
          ..color = PulseColors.primary.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 1
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, -math.pi / 2, sweep * 0.28, false, accent);
      }
    }

    final coreScale = Curves.easeOutBack.transform(drawProgress.clamp(0.0, 1.0));
    final core = Paint()..color = PulseColors.primary;
    canvas.drawCircle(center, unit * 0.028 * coreScale * breath, core);

    final coreRing = Paint()
      ..color = PulseColors.ink.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, unit * 0.045 * coreScale * breath, coreRing);
  }

  @override
  bool shouldRepaint(covariant PulseSplashPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.breath != breath ||
        oldDelegate.glow != glow;
  }
}

class SplashGlassMark extends StatelessWidget {
  const SplashGlassMark({
    super.key,
    required this.progress,
    required this.breath,
    required this.glow,
  });

  final double progress;
  final double breath;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: PulseColors.ink.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: CustomPaint(
            painter: PulseSplashPainter(
              drawProgress: progress,
              breath: breath,
              glow: glow,
            ),
          ),
        ),
      ),
    );
  }
}
