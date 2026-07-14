import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pulse/core/theme/pulse_colors.dart';

/// Builds a mint week poster and opens the system share sheet.
abstract final class PulseWeekShare {
  static const _posterSize = Size(390, 720);

  static Future<void> share({
    required BuildContext context,
    required int completionPercent,
    required int checkIns,
    required int focusMinutes,
    List<int> dailyCompletions = const [],
  }) async {
    final origin = _shareOrigin(context);
    final summary =
        'My week on Pulse — $completionPercent% kept, '
        '$checkIns check-ins, $focusMinutes focus minutes.';

    File? file;
    try {
      final bytes = await _renderPosterBytes(
        completionPercent: completionPercent,
        checkIns: checkIns,
        focusMinutes: focusMinutes,
        dailyCompletions: dailyCompletions,
      );
      if (bytes != null && bytes.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        file = File(
          '${dir.path}/pulse_week_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes, flush: true);
      }
    } catch (_) {
      file = null;
    }

    if (file != null) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                file.path,
                mimeType: 'image/png',
                name: 'pulse_week.png',
              ),
            ],
            sharePositionOrigin: origin,
          ),
        );
        return;
      } catch (_) {
        // Fall through to text share.
      }
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: summary,
          subject: 'My week on Pulse',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share didn’t open — try again.')),
        );
      }
      rethrow;
    }
  }

  static Rect _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.isEmpty) return rect;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }

  /// Paints [widget] off-tree so we never depend on Overlay / Impeller quirks.
  static Future<Uint8List?> _renderPosterBytes({
    required int completionPercent,
    required int checkIns,
    required int focusMinutes,
    required List<int> dailyCompletions,
  }) async {
    const pixelRatio = 3.0;
    final logical = _posterSize;
    final physical = logical * pixelRatio;

    final repaintBoundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(physical),
        logicalConstraints: BoxConstraints.tight(logical),
        devicePixelRatio: pixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final adapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: _posterSize),
          child: ColoredBox(
            color: const Color(0xFFF4F7F0),
            child: SizedBox(
              width: logical.width,
              height: logical.height,
              child: _WeekSharePoster(
                completionPercent: completionPercent,
                checkIns: checkIns,
                focusMinutes: focusMinutes,
                dailyCompletions: dailyCompletions,
              ),
            ),
          ),
        ),
      ),
    );

    final rootElement = adapter.attachToRenderTree(buildOwner);
    try {
      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      try {
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      // Detach by swapping in an empty child, then drop owners.
      RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: const SizedBox.shrink(),
      ).attachToRenderTree(buildOwner, rootElement);
      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();
      renderView.child = null;
      pipelineOwner.rootNode = null;
    }
  }
}

class _WeekSharePoster extends StatelessWidget {
  const _WeekSharePoster({
    required this.completionPercent,
    required this.checkIns,
    required this.focusMinutes,
    required this.dailyCompletions,
  });

  final int completionPercent;
  final int checkIns;
  final int focusMinutes;
  final List<int> dailyCompletions;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final bars = dailyCompletions.length == 7
        ? dailyCompletions
        : List<int>.filled(7, 0);
    final max = bars.fold<int>(0, (a, b) => a > b ? a : b);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4F7F0),
            Color(0xFFE8EBE6),
            Color(0xFFE2F6D5),
            Color(0xFFE8EBE6),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -28,
            child: _Glow(
              size: 160,
              color: PulseColors.primary.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            top: 200,
            left: -64,
            child: _Glow(
              size: 180,
              color: const Color(0xFFFFC091).withValues(alpha: 0.32),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: _Glow(
              size: 200,
              color: const Color(0xFFD6ECFF).withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pulse',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                    height: 0.95,
                    color: PulseColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This week · quiet rhythm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: PulseColors.body,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: PulseColors.ink.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CustomPaint(
                          painter: _ShareRingPainter(
                            progress:
                                (completionPercent / 100).clamp(0.0, 1.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$completionPercent%',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: PulseColors.primary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'kept',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: PulseColors.canvasSoft
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ShareStat(
                              label: 'Focus',
                              value: '$focusMinutes',
                              unit: 'min',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Expanded(
                            child: _ShareStat(
                              label: 'Check-ins',
                              value: '$checkIns',
                              unit: '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily check-ins',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 88,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                            heightFactor:
                                                _barFactor(bars[i], max),
                                            widthFactor: 1,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: bars[i] > 0
                                                      ? const [
                                                          PulseColors.primary,
                                                          PulseColors
                                                              .primaryActive,
                                                        ]
                                                      : [
                                                          PulseColors.primary
                                                              .withValues(
                                                            alpha: 0.28,
                                                          ),
                                                          PulseColors
                                                              .primaryPale,
                                                        ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _days[i],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: PulseColors.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Made for quiet work',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PulseColors.mute,
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
    if (max == 0) return 0.1;
    return (value / max).clamp(0.1, 1.0);
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PulseColors.canvasSoft.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: Colors.white,
                height: 1,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ShareRingPainter extends CustomPainter {
  _ShareRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 5;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    stroke.color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, stroke);

    stroke.color = PulseColors.primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ShareRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
