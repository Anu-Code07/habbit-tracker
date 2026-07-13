import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';

/// Soft expanding concentric ripples behind the brand — no orbs/dots.
class SplashConcentricPainter extends CustomPainter {
  SplashConcentricPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final maxR = math.min(size.width, size.height) * 0.72;

    // Soft lime bloom at the focus point (gradient only — not a solid ball).
    final bloom = Paint()
      ..shader = RadialGradient(
        colors: [
          PulseColors.primary.withValues(alpha: 0.18),
          PulseColors.primary.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.55));
    canvas.drawCircle(center, maxR * 0.55, bloom);

    // Static faint rings for depth (like the reference artwork).
    for (var i = 1; i <= 5; i++) {
      final r = maxR * (0.18 + i * 0.14);
      final paint = Paint()
        ..color = PulseColors.ink.withValues(alpha: 0.045 + (i % 2) * 0.015)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawCircle(center, r, paint);
    }

    // Animated expanding ripples — continuous, soft, fading out.
    const rippleCount = 4;
    for (var i = 0; i < rippleCount; i++) {
      final phase = (t + i / rippleCount) % 1.0;
      final eased = Curves.easeOut.transform(phase);
      final radius = maxR * (0.08 + eased * 0.85);
      final fade = (1.0 - phase);
      final alpha = 0.14 * fade * fade;

      final ring = Paint()
        ..color = PulseColors.ink.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (1.0 - phase) * 1.8;
      canvas.drawCircle(center, radius, ring);

      // Subtle lime highlight on the leading edge of each ripple.
      final lime = Paint()
        ..color = PulseColors.primary.withValues(alpha: 0.22 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + fade * 1.2;
      canvas.drawCircle(center, radius, lime);
    }
  }

  @override
  bool shouldRepaint(covariant SplashConcentricPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Tiny corner brackets framing the brand block.
class SplashFrameAccent extends StatelessWidget {
  const SplashFrameAccent({
    super.key,
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _FramePainter(color: PulseColors.ink.withValues(alpha: 0.14)),
        child: child,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 16.0;
    const inset = 2.0;

    canvas.drawLine(const Offset(inset, inset + arm), const Offset(inset, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + arm, inset), paint);

    canvas.drawLine(
      Offset(size.width - inset - arm, inset),
      Offset(size.width - inset, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + arm),
      paint,
    );

    canvas.drawLine(
      Offset(inset, size.height - inset - arm),
      Offset(inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + arm, size.height - inset),
      paint,
    );

    canvas.drawLine(
      Offset(size.width - inset - arm, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset - arm),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.color != color;
}
