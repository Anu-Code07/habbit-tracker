import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';

/// Shared Pomodoro length options for Focus + Settings.
abstract final class PulsePomodoroMinutes {
  /// Values are minutes. `1` means a **60-second** sprint (not 1 minute).
  static const options = <int>[1, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];

  static int nearest(int minutes) {
    var best = options.first;
    var bestDelta = (best - minutes).abs();
    for (final option in options) {
      final delta = (option - minutes).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }

  static String label(int minutes) {
    if (minutes == 1) return '60 sec';
    return '$minutes min';
  }
}

/// Free-focus lengths (true minutes — no 60-sec alias).
abstract final class PulseFreeMinutes {
  static const options = <int>[15, 30, 45, 60, 90, 120];

  static int nearest(int minutes) {
    var best = options.first;
    var bestDelta = (best - minutes).abs();
    for (final option in options) {
      final delta = (option - minutes).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }

  static String label(int minutes) => '$minutes min';
}

/// iOS-style wheel picker sheet for focus length.
Future<int?> showPulseMinutesPicker(
  BuildContext context, {
  required int initialMinutes,
  List<int>? options,
  String title = 'Pomodoro',
  String Function(int minutes)? labelOf,
}) {
  final opts = options ?? PulsePomodoroMinutes.options;
  final labelFn = labelOf ?? PulsePomodoroMinutes.label;
  final initial = () {
    var best = opts.first;
    var bestDelta = (best - initialMinutes).abs();
    for (final option in opts) {
      final delta = (option - initialMinutes).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }();
  var selected = initial;

  return showCupertinoModalPopup<int>(
    context: context,
    builder: (ctx) {
      return Material(
        color: Colors.transparent,
        child: Container(
          height: 292,
          decoration: const BoxDecoration(
            color: PulseColors.canvas,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(PulseRadii.xl),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PulseSpacing.lg,
                  PulseSpacing.md,
                  PulseSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: PulseTypography.bodyMd(color: PulseColors.mute),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: PulseTypography.bodyMdStrong(),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx, selected),
                      child: Text(
                        'Done',
                        style: PulseTypography.bodyMdStrong(
                          color: PulseColors.positiveDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: opts.indexOf(initial).clamp(0, opts.length - 1),
                  ),
                  itemExtent: 40,
                  magnification: 1.08,
                  useMagnifier: true,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    selected = opts[index];
                  },
                  children: [
                    for (final minutes in opts)
                      Center(
                        child: Text(
                          labelFn(minutes),
                          style: PulseTypography.displayXs(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
