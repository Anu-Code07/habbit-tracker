import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/features/focus/domain/focus_quotes.dart';

/// Quiet weekly share card — habits + focus + one line. Made to post.
abstract final class PulseWeekShare {
  static Future<void> share({
    required BuildContext context,
    required int completionPercent,
    required int checkIns,
    required int focusMinutes,
  }) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -5000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: _WeekShareCard(
              completionPercent: completionPercent,
              checkIns: checkIns,
              focusMinutes: focusMinutes,
              line: PulseFocusQuotes.next(),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/pulse_week_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My week on Pulse — quiet work, kept.',
        ),
      );
    } finally {
      entry.remove();
    }
  }
}

class _WeekShareCard extends StatelessWidget {
  const _WeekShareCard({
    required this.completionPercent,
    required this.checkIns,
    required this.focusMinutes,
    required this.line,
  });

  final int completionPercent;
  final int checkIns;
  final int focusMinutes;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E0F0C),
            Color(0xFF1A2216),
            Color(0xFF0E0F0C),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pulse',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: PulseColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This week',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.4,
              color: PulseColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completionPercent%',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: PulseColors.primary,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'done',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB4B8B0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _StatRow(label: 'Check-ins', value: '$checkIns'),
          const SizedBox(height: 10),
          _StatRow(label: 'Focus minutes', value: '$focusMinutes'),
          const SizedBox(height: 28),
          Text(
            line,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 17,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: Color(0xFFF2F4F0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Made for quiet work',
            style: TextStyle(
              fontSize: 12,
              color: PulseColors.primary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFFB4B8B0)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF2F4F0),
          ),
        ),
      ],
    );
  }
}
