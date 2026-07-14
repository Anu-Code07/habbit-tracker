import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_shimmer.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/focus/domain/focus_quotes.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/insights/presentation/bloc/insights_bloc.dart';
import 'package:pulse/features/insights/presentation/widgets/pulse_week_share.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PulseAtmosphere(
        child: SafeArea(
          child: BlocBuilder<InsightsBloc, InsightsState>(
            builder: (context, state) {
              return switch (state) {
                InsightsLoading() || InsightsInitial() =>
                  const PulseInsightsSkeleton(),
                InsightsError(:final message) => PulseErrorView(
                    message: message,
                    onRetry: () => context
                        .read<InsightsBloc>()
                        .add(const InsightsStarted()),
                  ),
                InsightsSuccess(:final weekStats, :final focusMinutes) =>
                  _InsightsSuccessView(
                    weekStats: weekStats,
                    focusMinutes: focusMinutes,
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _InsightsSuccessView extends StatefulWidget {
  const _InsightsSuccessView({
    required this.weekStats,
    required this.focusMinutes,
  });

  final WeekHabitStats weekStats;
  final int focusMinutes;

  @override
  State<_InsightsSuccessView> createState() => _InsightsSuccessViewState();
}

class _InsightsSuccessViewState extends State<_InsightsSuccessView>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _ring;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _heroScale;
  late final Animation<double> _rowOpacity;
  late final Animation<double> _chartOpacity;
  late final Animation<double> _quoteOpacity;
  late final Animation<double> _countT;
  late final Animation<double> _barsT;

  late final String _weekLine;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _weekLine = PulseFocusQuotes.next();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headerOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _heroOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.18, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _rowOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
    );
    _chartOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 0.88, curve: Curves.easeOut),
    );
    _quoteOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
    _countT = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
    );
    _barsT = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );

    _intro.forward();
    _ring.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  int get _percent => (widget.weekStats.completionRate * 100).round();

  Future<void> _share(BuildContext shareContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await PulseWeekShare.share(
        context: shareContext,
        completionPercent: _percent,
        checkIns: widget.weekStats.completedCount,
        focusMinutes: widget.focusMinutes,
        dailyCompletions: widget.weekStats.dailyCompletions,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share didn’t open — try again.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _pulse, _ring]),
      builder: (context, _) {
        final pulse = 0.96 + (_pulse.value * 0.08);
        final shownPercent = (_percent * _countT.value).round();
        final shownFocus = (widget.focusMinutes * _countT.value).round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            PulseSpacing.xl,
            PulseSpacing.xl,
            PulseSpacing.xl,
            120,
          ),
          children: [
            FadeTransition(
              opacity: _headerOpacity,
              child: SlideTransition(
                position: _headerSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pulse',
                      style: PulseTypography.displayMd(
                        color: PulseColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This week',
                      style: PulseTypography.bodyLg(
                        color: PulseColors.body,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xs),
                    Text(
                      'A quiet look at your rhythm.',
                      style: PulseTypography.bodySm(
                        color: PulseColors.mute,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.lg),
                    _ShareChip(
                      busy: _sharing,
                      onTap: _share,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: PulseSpacing.xxl),
            FadeTransition(
              opacity: _heroOpacity,
              child: Transform.scale(
                scale: _heroScale.value,
                child: _CompletionHero(
                  percent: shownPercent,
                  checkIns: widget.weekStats.completedCount,
                  ringProgress: _ring.value * widget.weekStats.completionRate,
                  pulseScale: pulse,
                ),
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            FadeTransition(
              opacity: _rowOpacity,
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Focus minutes',
                      value: '$shownFocus',
                      accent: true,
                    ),
                  ),
                  const SizedBox(width: PulseSpacing.md),
                  Expanded(
                    child: _MetricTile(
                      label: 'Check-ins',
                      value: '${widget.weekStats.completedCount}',
                      accent: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            FadeTransition(
              opacity: _chartOpacity,
              child: _WeekBarsCard(
                values: widget.weekStats.dailyCompletions,
                progress: _barsT.value,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            FadeTransition(
              opacity: _quoteOpacity,
              child: _WeekQuoteRibbon(line: _weekLine),
            ),
          ],
        );
      },
    );
  }
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({required this.onTap, required this.busy});

  final Future<void> Function(BuildContext context) onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: PulseColors.primaryPale,
      opacity: 0.88,
      blur: 14,
      borderRadius: BorderRadius.circular(PulseRadii.pill),
      onTap: busy ? null : () => onTap(context),
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpacing.lg,
        vertical: PulseSpacing.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PulseColors.ink,
              ),
            )
          else
            Icon(
              Icons.ios_share_rounded,
              size: 16,
              color: PulseColors.ink.withValues(alpha: 0.85),
            ),
          const SizedBox(width: PulseSpacing.sm),
          Text(
            busy ? 'Preparing…' : 'Share this week',
            style: PulseTypography.bodySmStrong(),
          ),
        ],
      ),
    );
  }
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({
    required this.percent,
    required this.checkIns,
    required this.ringProgress,
    required this.pulseScale,
  });

  final int percent;
  final int checkIns;
  final double ringProgress;
  final double pulseScale;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: PulseColors.ink,
      opacity: 0.86,
      blur: 22,
      borderRadius: BorderRadius.circular(PulseRadii.xl),
      padding: const EdgeInsets.fromLTRB(
        PulseSpacing.xl,
        PulseSpacing.xxl,
        PulseSpacing.xl,
        PulseSpacing.xxl,
      ),
      child: SizedBox(
        height: 228,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulseScale,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _SoftBlobPainter(
                  t: (pulseScale - 0.96) / 0.08,
                  color: PulseColors.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(168, 168),
              painter: _RingPainter(
                progress: ringProgress.clamp(0.0, 1.0),
                track: Colors.white.withValues(alpha: 0.12),
                progressColor: PulseColors.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completion',
                  style: PulseTypography.bodySm(
                    color: PulseColors.canvasSoft.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent%',
                  style: PulseTypography.displayXl(
                    color: PulseColors.primary,
                  ),
                ),
                Text(
                  checkIns == 1
                      ? '1 check-in kept'
                      : '$checkIns check-ins kept',
                  style: PulseTypography.bodySm(
                    color: PulseColors.mute,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: accent ? PulseColors.primaryPale : PulseColors.canvas,
      opacity: accent ? 0.82 : 0.62,
      blur: 16,
      borderRadius: BorderRadius.circular(PulseRadii.lg),
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PulseTypography.bodySmStrong()),
          const SizedBox(height: PulseSpacing.sm),
          Text(value, style: PulseTypography.displayMd()),
        ],
      ),
    );
  }
}

class _WeekBarsCard extends StatelessWidget {
  const _WeekBarsCard({
    required this.values,
    required this.progress,
  });

  final List<int> values;
  final double progress;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(0, (a, b) => a > b ? a : b);

    return PulseGlass(
      tint: PulseColors.canvas,
      opacity: 0.68,
      blur: 16,
      borderRadius: BorderRadius.circular(PulseRadii.lg),
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily check-ins', style: PulseTypography.bodySmStrong()),
          const SizedBox(height: PulseSpacing.lg),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _AnimatedBar(
                        label: _days[i],
                        heightFactor: _barFactor(values[i], max),
                        localProgress:
                            ((progress - i * 0.07) / 0.55).clamp(0.0, 1.0),
                        highlighted: values[i] > 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _barFactor(int value, int max) {
    if (max == 0) return 0.08;
    return (value / max).clamp(0.08, 1.0);
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({
    required this.label,
    required this.heightFactor,
    required this.localProgress,
    required this.highlighted,
  });

  final String label;
  final double heightFactor;
  final double localProgress;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(localProgress);
    final h = heightFactor * eased;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: h.clamp(0.04, 1.0),
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: highlighted
                        ? [
                            PulseColors.primary,
                            PulseColors.primaryActive,
                          ]
                        : [
                            PulseColors.primary.withValues(alpha: 0.35),
                            PulseColors.primaryPale,
                          ],
                  ),
                  boxShadow: highlighted && eased > 0.6
                      ? [
                          BoxShadow(
                            color: PulseColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: PulseTypography.caption()),
      ],
    );
  }
}

class _WeekQuoteRibbon extends StatelessWidget {
  const _WeekQuoteRibbon({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: PulseColors.primaryPale,
      opacity: 0.62,
      blur: 18,
      borderRadius: BorderRadius.circular(PulseRadii.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpacing.xl,
        vertical: PulseSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: PulseSpacing.lg),
          Expanded(
            child: Text(
              line,
              style: PulseTypography.bodyMd(
                color: PulseColors.inkDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.progressColor,
  });

  final double progress;
  final Color track;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    stroke.color = track;
    canvas.drawCircle(center, radius, stroke);

    stroke.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SoftBlobPainter extends CustomPainter {
  _SoftBlobPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * 0.42;
    final path = Path();
    const lobes = 7;
    Offset mid(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

    final points = <Offset>[];
    for (var i = 0; i < lobes; i++) {
      final angle = (i / lobes) * math.pi * 2;
      final wobble = 0.82 +
          0.12 * math.sin(angle * 2.2 + t * math.pi * 2) +
          0.08 * math.cos(angle * 3.1 - t * math.pi);
      final r = base * wobble;
      points.add(
        Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r),
      );
    }

    path.moveTo(
      mid(points.last, points.first).dx,
      mid(points.last, points.first).dy,
    );
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

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _SoftBlobPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}
