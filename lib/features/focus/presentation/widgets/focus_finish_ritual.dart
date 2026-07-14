import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/focus/domain/focus_quotes.dart';

/// Soft completion moment — light swell, amoeba pulse, one kind line.
class FocusFinishRitual extends StatefulWidget {
  const FocusFinishRitual({
    super.key,
    required this.elapsedSeconds,
    required this.headline,
    required this.onDone,
  });

  final int elapsedSeconds;
  final String headline;
  final VoidCallback onDone;

  @override
  State<FocusFinishRitual> createState() => _FocusFinishRitualState();
}

class _FocusFinishRitualState extends State<FocusFinishRitual>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _breath;
  late final AnimationController _doneReveal;

  late final Animation<double> _wash;
  late final Animation<double> _blobReveal;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _metaOpacity;
  late final Animation<double> _doneOpacity;
  late final Animation<double> _breathT;

  late final String _comfortQuote;
  late final String _comfortTitle;

  static const _titles = [
    'You can soften now',
    'That was enough for today',
    'Rest in what you gave',
    'You held it kindly',
    'A quiet win is still a win',
  ];

  @override
  void initState() {
    super.initState();

    _comfortQuote = widget.headline.trim().isNotEmpty
        ? widget.headline.trim()
        : PulseFocusQuotes.next();
    _comfortTitle = _titles[math.Random().nextInt(_titles.length)];

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _doneReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _wash = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _blobReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOutBack),
    );
    _titleOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.38, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _metaOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _doneOpacity = CurvedAnimation(
      parent: _doneReveal,
      curve: Curves.easeOut,
    );
    _breathT = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await HapticFeedback.lightImpact();
    await _intro.forward();
    if (!mounted) return;
    _breath.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _doneReveal.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _breath.dispose();
    _doneReveal.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final m = widget.elapsedSeconds ~/ 60;
    final s = widget.elapsedSeconds % 60;
    if (m <= 0) return '$s sec kept';
    if (s == 0) return '$m min kept';
    return '$m min ${s.toString().padLeft(2, '0')}s kept';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _breath, _doneReveal]),
        builder: (context, _) {
          final pulse = 0.92 + (_breathT.value * 0.14);

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFFB8F28A),
                    const Color(0xFFEAF8DC),
                    _wash.value * 0.55,
                  )!,
                  Color.lerp(
                    PulseColors.primary,
                    const Color(0xFFC8F2A0),
                    _wash.value * 0.4,
                  )!,
                  Color.lerp(
                    const Color(0xFF7ED957),
                    const Color(0xFFD4F5B8),
                    _wash.value * 0.5,
                  )!,
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: (0.25 + _wash.value * 0.55).clamp(0.0, 0.85),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.08),
                        radius: 0.75 + _wash.value * 0.55,
                        colors: [
                          Colors.white.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(PulseSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        SizedBox(
                          height: 240,
                          child: Center(
                            child: Opacity(
                              opacity: _blobReveal.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale:
                                    pulse * (0.72 + _blobReveal.value * 0.28),
                                child: CustomPaint(
                                  size: const Size(220, 220),
                                  painter: _AmoebaBlobPainter(
                                    progress: _breathT.value,
                                    fill: const Color(0xFF9BE86A),
                                    glow: Colors.white,
                                    ink: PulseColors.inkDeep,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: PulseSpacing.xl),
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: Text(
                              _comfortTitle,
                              style: PulseTypography.displayMd(
                                color: PulseColors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: PulseSpacing.md),
                        FadeTransition(
                          opacity: _metaOpacity,
                          child: Column(
                            children: [
                              Text(
                                _durationLabel,
                                style: PulseTypography.bodyLg(
                                  color: PulseColors.inkDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: PulseSpacing.md),
                              Text(
                                _comfortQuote,
                                style: PulseTypography.bodyMd(
                                  color: PulseColors.inkDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _doneOpacity,
                          child: PulseSecondaryButton(
                            label: 'Done',
                            onPressed: widget.onDone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Soft organic amoeba that gently morphs while pulsing.
class _AmoebaBlobPainter extends CustomPainter {
  _AmoebaBlobPainter({
    required this.progress,
    required this.fill,
    required this.glow,
    required this.ink,
  });

  final double progress;
  final Color fill;
  final Color glow;
  final Color ink;

  Path _blobPath(Offset center, double radius, double t) {
    const lobes = 8;
    final points = <Offset>[];
    for (var i = 0; i < lobes; i++) {
      final angle = (i / lobes) * math.pi * 2;
      // Uneven radii + slow phase drift = living amoeba silhouette.
      final wobble =
          0.78 +
          0.14 * math.sin(angle * 3 + t * math.pi * 2) +
          0.10 * math.cos(angle * 5 - t * math.pi * 2 * 0.7) +
          0.06 * math.sin(angle * 2 + t * math.pi);
      final r = radius * wobble;
      points.add(
        Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        ),
      );
    }

    final path = Path();
    if (points.isEmpty) return path;

    // Smooth closed curve through points (midpoint quadratic chain).
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    path.moveTo(mid(points.last, points.first).dx, mid(points.last, points.first).dy);
    for (var i = 0; i < lobes; i++) {
      final current = points[i];
      final next = points[(i + 1) % lobes];
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        mid(current, next).dx,
        mid(current, next).dy,
      );
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.shortestSide * 0.38;
    final path = _blobPath(center, baseR, progress);

    // Soft outer glow (larger, more transparent twin).
    final glowPath = _blobPath(center, baseR * 1.22, progress + 0.08);
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = glow.withValues(alpha: 0.35 + progress * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    final shader = ui.Gradient.radial(
      center,
      baseR * 1.15,
      [
        Colors.white.withValues(alpha: 0.92),
        fill.withValues(alpha: 0.95),
        fill.withValues(alpha: 0.55),
      ],
      const [0.0, 0.45, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.fill,
    );

    // Gentle rim for definition without hard rings.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = ink.withValues(alpha: 0.12 + progress * 0.08),
    );

    // Specular highlight blob inside.
    final highlight = Path()
      ..addOval(
        Rect.fromCenter(
          center: center.translate(-baseR * 0.18, -baseR * 0.22),
          width: baseR * 0.55,
          height: baseR * 0.38,
        ),
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant _AmoebaBlobPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fill != fill ||
        oldDelegate.glow != glow ||
        oldDelegate.ink != ink;
  }
}
