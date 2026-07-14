import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'package:pulse/core/theme/habit_palette.dart';
import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_shimmer.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/presentation/bloc/today_bloc.dart';
import 'package:pulse/features/habits/presentation/widgets/habit_editor_sheet.dart';
import 'package:pulse/features/habits/presentation/widgets/pulse_month_calendar.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TodayBloc, TodayState>(
      listenWhen: (p, c) {
        final prevMsg = switch (p) {
          TodaySuccess(:final message) => message,
          TodayEmpty(:final message) => message,
          _ => null,
        };
        final nextMsg = switch (c) {
          TodaySuccess(:final message) => message,
          TodayEmpty(:final message) => message,
          _ => null,
        };
        return nextMsg != null && nextMsg != prevMsg;
      },
      listener: (context, state) {
        final message = switch (state) {
          TodaySuccess(:final message) => message,
          TodayEmpty(:final message) => message,
          _ => null,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: PulseAtmosphere(
            child: SafeArea(
              child: switch (state) {
                TodayLoading() || TodayInitial() => const PulseTodaySkeleton(),
                TodayError(:final message) => PulseErrorView(
                    message: message,
                    onRetry: () =>
                        context.read<TodayBloc>().add(const TodayRefreshed()),
                  ),
                TodayEmpty(
                  :final selectedDate,
                  :final greeting,
                  :final isRefreshing,
                ) =>
                  _TodayBody(
                    selectedDate: selectedDate,
                    habits: const [],
                    greeting: greeting,
                    empty: true,
                    isRefreshing: isRefreshing,
                  ),
                TodaySuccess(
                  :final habits,
                  :final selectedDate,
                  :final greeting,
                  :final isRefreshing,
                ) =>
                  _TodayBody(
                    selectedDate: selectedDate,
                    habits: habits,
                    greeting: greeting,
                    empty: false,
                    isRefreshing: isRefreshing,
                  ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _TodayBody extends StatefulWidget {
  const _TodayBody({
    required this.selectedDate,
    required this.habits,
    required this.greeting,
    required this.empty,
    this.isRefreshing = false,
  });

  final DateTime selectedDate;
  final List<HabitWithStatus> habits;
  final String greeting;
  final bool empty;
  final bool isRefreshing;

  @override
  State<_TodayBody> createState() => _TodayBodyState();
}

class _TodayBodyState extends State<_TodayBody> {
  bool _calendarExpanded = false;
  late DateTime _visibleMonth;
  bool _askedForName = false;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskName());
  }

  @override
  void didUpdateWidget(covariant _TodayBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate && !_calendarExpanded) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  Future<void> _maybeAskName() async {
    if (_askedForName || !mounted) return;
    final settings = sl<SettingsRepository>();
    if (settings.userName.isNotEmpty) return;
    _askedForName = true;
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _NameAskDialog(),
    );
    if (!mounted || name == null || name.trim().length < 2) return;
    await settings.setUserName(name);
    if (!mounted) return;
    context.read<TodayBloc>().add(const TodayGreetingRolled());
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedDate;
    final habits = widget.habits;
    final empty = widget.empty;

    // Week containing the selected date (Mon–Sun), not always "this" week.
    final days = List.generate(7, (i) {
      final base = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final start = base.subtract(Duration(days: base.weekday - 1));
      return start.add(Duration(days: i));
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PulseSpacing.xl,
              PulseSpacing.lg,
              PulseSpacing.xl,
              PulseSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: PulseSpacing.xl,
                      top: PulseSpacing.xs,
                      bottom: PulseSpacing.xs,
                    ),
                    child: Text(
                      widget.greeting,
                      style: PulseTypography.displayMd(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: PulseSpacing.xs),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _TodayPulseMark(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.xl),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: PulseTypography.bodySmStrong(),
                ),
                const Spacer(),
                PulseGlass(
                  tint: PulseColors.primaryPale,
                  opacity: 0.7,
                  blur: 12,
                  borderRadius: BorderRadius.circular(PulseRadii.pill),
                  onTap: () {
                    setState(() {
                      _calendarExpanded = !_calendarExpanded;
                      if (_calendarExpanded) {
                        _visibleMonth = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                        );
                      }
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _calendarExpanded ? 'Week' : 'Month',
                        style: PulseTypography.bodySmStrong(),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _calendarExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: PulseSpacing.md)),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _calendarExpanded
                ? Padding(
                    key: const ValueKey('month'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PulseSpacing.xl,
                    ),
                    child: PulseMonthCalendar(
                      visibleMonth: _visibleMonth,
                      selectedDate: selectedDate,
                      onMonthChanged: (month) {
                        setState(() => _visibleMonth = month);
                      },
                      onDateSelected: (date) {
                        context
                            .read<TodayBloc>()
                            .add(TodayDateSelected(date));
                        setState(() {
                          _calendarExpanded = false;
                          _visibleMonth = DateTime(date.year, date.month);
                        });
                      },
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('week'),
                    height: 78,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PulseSpacing.xl,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final selected = day.year == selectedDate.year &&
                            day.month == selectedDate.month &&
                            day.day == selectedDate.day;
                        final isToday = day.year == DateTime.now().year &&
                            day.month == DateTime.now().month &&
                            day.day == DateTime.now().day;
                        return GestureDetector(
                          onTap: () => context
                              .read<TodayBloc>()
                              .add(TodayDateSelected(day)),
                          child: PulseGlass(
                            width: 56,
                            height: 72,
                            blur: 12,
                            opacity: selected ? 0.85 : 0.45,
                            tint: selected
                                ? PulseColors.ink
                                : isToday
                                    ? PulseColors.primary
                                    : PulseColors.canvas,
                            borderRadius: BorderRadius.circular(PulseRadii.lg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: PulseTypography.bodyMdStrong(
                                    color: selected
                                        ? PulseColors.canvas
                                        : PulseColors.ink,
                                  ),
                                ),
                                Text(
                                  DateFormat('E').format(day),
                                  style: PulseTypography.caption(
                                    color: selected
                                        ? PulseColors.canvasSoft
                                        : PulseColors.mute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: PulseSpacing.xl)),
        if (widget.isRefreshing)
          const SliverToBoxAdapter(child: PulseHabitGridShimmer())
        else if (empty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(PulseSpacing.xl),
              child: PulseEmptyState(
                title: 'No habits yet',
                message: 'Tap + to start a colorful new habit.',
                actionLabel: 'Add habit',
                onAction: () => showHabitEditorSheet(context),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              PulseSpacing.xl,
              0,
              PulseSpacing.xl,
              120,
            ),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: habits.length,
              itemBuilder: (context, index) {
                final item = habits[index];
                final tall = index.isOdd;
                return _HabitCard(
                  item: item,
                  tall: tall,
                  onToggle: () => context
                      .read<TodayBloc>()
                      .add(TodayHabitToggled(item.habit.id)),
                  onEdit: () =>
                      showHabitEditorSheet(context, habit: item.habit),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Soft branded breath mark — replaces the old header edit control.
class _TodayPulseMark extends StatelessWidget {
  const _TodayPulseMark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Lottie.asset(
        'assets/lottie/pulse_soft_breath.json',
        fit: BoxFit.contain,
        repeat: true,
        frameRate: FrameRate.max,
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.item,
    required this.tall,
    required this.onToggle,
    required this.onEdit,
  });

  final HabitWithStatus item;
  final bool tall;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    return PulseGlass(
      tint: HabitPalette.of(habit.colorValue),
      opacity: item.isCompletedToday ? 0.78 : 0.55,
      height: tall ? 180 : 150,
      padding: const EdgeInsets.all(PulseSpacing.lg),
      onTap: onToggle,
      onLongPress: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                HabitPalette.iconOf(habit.iconCode),
                size: 28,
                color: PulseColors.ink,
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isCompletedToday
                      ? PulseColors.ink
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: PulseColors.ink, width: 2),
                ),
                child: item.isCompletedToday
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: PulseColors.primary,
                      )
                    : null,
              ),
            ],
          ),
          const Spacer(),
          Text(
            habit.name,
            style: PulseTypography.bodyMdStrong(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              habit.description,
              style: PulseTypography.bodySm(color: PulseColors.body),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.currentStreak > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${item.currentStreak} day streak',
              style: PulseTypography.caption(color: PulseColors.inkDeep),
            ),
          ],
        ],
      ),
    );
  }
}

class _NameAskDialog extends StatefulWidget {
  const _NameAskDialog();

  @override
  State<_NameAskDialog> createState() => _NameAskDialogState();
}

class _NameAskDialogState extends State<_NameAskDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PulseColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.xl),
      ),
      title: Text('Quick — who are you?', style: PulseTypography.displayXs()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We skipped introductions. Unforgivable. What’s your name?',
            style: PulseTypography.bodyMd(),
          ),
          const SizedBox(height: PulseSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: false,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Type it like you mean it',
            ),
            onSubmitted: (value) {
              if (value.trim().length >= 2) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.length < 2) return;
            Navigator.pop(context, value);
          },
          child: const Text('That’s me'),
        ),
      ],
    );
  }
}
