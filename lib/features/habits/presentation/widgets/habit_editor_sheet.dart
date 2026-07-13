import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/theme/habit_palette.dart';
import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:pulse/features/habits/presentation/bloc/today_bloc.dart';

Future<void> showHabitEditorSheet(
  BuildContext context, {
  Habit? habit,
}) {
  final habitsBloc = context.read<HabitsBloc>();
  final todayBloc = context.read<TodayBloc>();

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: PulseColors.ink.withValues(alpha: 0.45),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: habitsBloc,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: _HabitEditorSheet(habit: habit),
        ),
      );
    },
  ).then((_) {
    todayBloc.add(const TodayRefreshed());
  });
}

class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({this.habit});
  final Habit? habit;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _color;
  late int _icon;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _description = TextEditingController(text: habit?.description ?? '');
    _color = habit?.colorValue ?? HabitPalette.colors.first;
    _icon = habit?.iconCode ?? HabitPalette.icons.first.codePoint;
    _frequency = habit?.frequency ?? 'daily';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final bloc = context.read<HabitsBloc>();
    if (widget.habit == null) {
      bloc.add(
        HabitCreated(
          name: name,
          description: _description.text.trim(),
          iconCode: _icon,
          colorValue: _color,
          frequency: _frequency,
        ),
      );
    } else {
      bloc.add(
        HabitUpdated(
          widget.habit!.copyWith(
            name: name,
            description: _description.text.trim(),
            iconCode: _icon,
            colorValue: _color,
            frequency: _frequency,
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.habit != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PulseSpacing.md,
        0,
        PulseSpacing.md,
        PulseSpacing.md + bottom,
      ),
      child: PulseGlass(
        opacity: 0.72,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(
          PulseSpacing.xl,
          PulseSpacing.lg,
          PulseSpacing.xl,
          PulseSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                Expanded(
                  child: Text(
                    editing ? 'Edit habit' : "Let's start a new habit",
                    style: PulseTypography.displayXs(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: PulseSpacing.lg),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'Type habit name',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: PulseSpacing.md),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe a habit',
                filled: true,
                fillColor: PulseColors.canvasSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Text('Interval', style: PulseTypography.bodySmStrong()),
            const SizedBox(height: PulseSpacing.sm),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _frequency,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Every day')),
                DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                DropdownMenuItem(value: 'weekly', child: Text('Once a week')),
              ],
              onChanged: (v) => setState(() => _frequency = v ?? 'daily'),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Text('Icon', style: PulseTypography.bodySmStrong()),
            const SizedBox(height: PulseSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < HabitPalette.icons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() {
                      _icon = HabitPalette.icons[i].codePoint;
                      _color = HabitPalette.colors[i % HabitPalette.colors.length];
                    }),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(
                          HabitPalette.colors[i % HabitPalette.colors.length],
                        ),
                        borderRadius: BorderRadius.circular(PulseRadii.lg),
                        border: Border.all(
                          color: _icon == HabitPalette.icons[i].codePoint
                              ? PulseColors.ink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(HabitPalette.icons[i], color: PulseColors.ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: PulseSpacing.xxl),
            PulsePrimaryButton(
              label: editing ? 'Save changes' : 'Create habit',
              onPressed: _save,
            ),
            if (editing) ...[
              const SizedBox(height: PulseSpacing.md),
              PulseSecondaryButton(
                label: 'Archive habit',
                onPressed: () {
                  context
                      .read<HabitsBloc>()
                      .add(HabitArchived(widget.habit!.id));
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
