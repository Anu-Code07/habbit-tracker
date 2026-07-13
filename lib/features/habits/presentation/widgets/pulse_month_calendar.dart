import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';

class PulseMonthCalendar extends StatelessWidget {
  const PulseMonthCalendar({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingEmpty = monthStart.weekday % 7;
    final today = DateTime.now();
    final cells = <Widget>[];

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final selected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        GestureDetector(
          onTap: () => onDateSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? PulseColors.ink
                  : isToday
                      ? PulseColors.primary.withValues(alpha: 0.85)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: PulseTypography.bodyMdStrong(
                color: selected
                    ? PulseColors.canvas
                    : isToday
                        ? PulseColors.ink
                        : PulseColors.ink,
              ),
            ),
          ),
        ),
      );
    }

    return PulseGlass(
      opacity: 0.55,
      blur: 20,
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(monthStart),
                  style: PulseTypography.displayXs(),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.sm),
          Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(d, style: PulseTypography.caption()),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: PulseSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }
}
