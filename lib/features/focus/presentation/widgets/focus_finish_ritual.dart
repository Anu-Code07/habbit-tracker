import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';

/// Soft completion moment — light swell, breath cue, one kind line.
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
  late final Animation<double> _ringReveal;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _metaOpacity;
  late final Animation<double> _doneOpacity;
  late final Animation<double> _breathT;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    _doneReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _wash = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _ringReveal = CurvedAnimation(
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

  String get _breathLabel {
    // First half of the cycle = inhale, second = exhale.
    return _breathT.value < 0.5 ? 'Inhale' : 'Exhale';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _breath, _doneReveal]),
        builder: (context, _) {
          final breath = 0.86 + (_breathT.value * 0.22);
          final breathSoft = 0.9 + (_breathT.value * 0.16);

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
                // Soft white-green wash from the center.
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
                // Outer breathing glow.
                Center(
                  child: Transform.scale(
                    scale: breathSoft * (0.55 + _ringReveal.value * 0.45),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.12 + _breathT.value * 0.08,
                        ),
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
                          height: 220,
                          child: Center(
                            child: Opacity(
                              opacity: _ringReveal.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: breath * (0.7 + _ringReveal.value * 0.3),
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _BreathRingsPainter(
                                    progress: _breathT.value,
                                    accent: PulseColors.ink.withValues(
                                      alpha: 0.55,
                                    ),
                                    soft: Colors.white.withValues(alpha: 0.65),
                                  ),
                                  child: Center(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 280),
                                      opacity: _intro.status ==
                                              AnimationStatus.completed
                                          ? 1
                                          : 0,
                                      child: Text(
                                        _breathLabel,
                                        style: PulseTypography.bodySmStrong(
                                          color: PulseColors.inkDeep,
                                        ),
                                      ),
                                    ),
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
                              'That block is yours',
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
                              if (widget.headline.trim().isNotEmpty) ...[
                                const SizedBox(height: PulseSpacing.sm),
                                Text(
                                  widget.headline,
                                  style: PulseTypography.bodyMd(
                                    color: PulseColors.inkDeep,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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

class _BreathRingsPainter extends CustomPainter {
  _BreathRingsPainter({
    required this.progress,
    required this.accent,
    required this.soft,
  });

  final double progress;
  final Color accent;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.18) % 1.0;
      final expand = 0.55 + phase * 0.45;
      final opacity = (1.0 - phase) * (0.55 - i * 0.12);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 - (i * 0.25)
        ..color = accent.withValues(alpha: opacity.clamp(0.08, 0.55));
      canvas.drawCircle(center, maxR * expand, paint);
    }

    // Core glass disc.
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          soft,
          soft.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.72));
    canvas.drawCircle(center, maxR * (0.42 + progress * 0.08), core);

    // Thin crisp ring.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = accent.withValues(alpha: 0.35 + progress * 0.2);
    canvas.drawCircle(center, maxR * (0.42 + progress * 0.08), rim);

    // Soft highlight arc.
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * (0.42 + progress * 0.08)),
      -math.pi * 0.9,
      math.pi * 0.55,
      false,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathRingsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.soft != soft;
  }
}
