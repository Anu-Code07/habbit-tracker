import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_minutes_picker.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/focus/presentation/bloc/focus_bloc.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusBloc, FocusState>(
      builder: (context, state) {
        if (state.isRunning || state.isCompleted || state.sessionStartedAt != null) {
          return _ActiveFocusView(state: state);
        }
        return _FocusSetupView(state: state);
      },
    );
  }
}

class _FocusSetupView extends StatelessWidget {
  const _FocusSetupView({required this.state});
  final FocusState state;

  Future<void> _pickPomodoro(BuildContext context) async {
    final minutes = await showPulseMinutesPicker(
      context,
      initialMinutes: state.totalSeconds ~/ 60,
    );
    if (minutes == null || !context.mounted) return;
    context.read<FocusBloc>().add(FocusDurationChanged(minutes));
  }

  @override
  Widget build(BuildContext context) {
    final isPomodoro = state.mode == FocusMode.pomodoro;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PulseAtmosphere(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PulseSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Focus', style: PulseTypography.displayMd()),
                const SizedBox(height: PulseSpacing.sm),
                Text(
                  'Today · ${state.todayMinutes} focused minutes',
                  style: PulseTypography.bodyMd(),
                ),
                const SizedBox(height: PulseSpacing.xxl),
                PulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mode', style: PulseTypography.bodySmStrong()),
                      const SizedBox(height: PulseSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeChip(
                              label: 'Pomodoro',
                              selected: isPomodoro,
                              onTap: () => context.read<FocusBloc>().add(
                                    const FocusModeChanged(FocusMode.pomodoro),
                                  ),
                            ),
                          ),
                          const SizedBox(width: PulseSpacing.md),
                          Expanded(
                            child: _ModeChip(
                              label: 'Free',
                              selected: !isPomodoro,
                              onTap: () => context.read<FocusBloc>().add(
                                    const FocusModeChanged(FocusMode.free),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PulseSpacing.xl),
                      if (isPomodoro) ...[
                        Text(
                          'Length',
                          style: PulseTypography.bodySmStrong(),
                        ),
                        const SizedBox(height: PulseSpacing.sm),
                        GestureDetector(
                          onTap: () => _pickPomodoro(context),
                          child: PulseGlass(
                            tint: PulseColors.primaryPale,
                            opacity: 0.65,
                            blur: 10,
                            borderRadius:
                                BorderRadius.circular(PulseRadii.lg),
                            padding: const EdgeInsets.symmetric(
                              horizontal: PulseSpacing.lg,
                              vertical: PulseSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatLength(state.totalSeconds),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PulseTypography.displaySm(),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: PulseColors.ink.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: PulseSpacing.sm),
                        Text(
                          'Tap to choose · deep work block',
                          style: PulseTypography.bodySm(),
                        ),
                      ] else ...[
                        Text(
                          _formatLength(state.totalSeconds),
                          maxLines: 1,
                          style: PulseTypography.displaySm(),
                        ),
                        Text(
                          'Up to 60 minutes',
                          style: PulseTypography.bodySm(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                PulsePrimaryButton(
                  label: 'Start focus',
                  onPressed: () => context
                      .read<FocusBloc>()
                      .add(const FocusTimerStarted()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFocusView extends StatelessWidget {
  const _ActiveFocusView({required this.state});
  final FocusState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8F28A),
              PulseColors.primary,
              Color(0xFF7ED957),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PulseColors.ink.withValues(alpha: 0.08),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PulseGlass(
                        tint: PulseColors.canvas,
                        opacity: 0.45,
                        blur: 12,
                        borderRadius: BorderRadius.circular(PulseRadii.full),
                        child: IconButton(
                          onPressed: () => context
                              .read<FocusBloc>()
                              .add(const FocusTimerReset()),
                          icon: const Icon(Icons.close_rounded, color: PulseColors.ink),
                        ),
                      ),
                    ),
              const Spacer(),
              _FocusTimerReadout(
                totalSeconds: state.isCompleted
                    ? state.elapsedSeconds
                    : state.remainingSeconds,
              ),
              const SizedBox(height: PulseSpacing.sm),
              Text(
                state.isCompleted ? 'Session complete' : 'Stay with it',
                style: PulseTypography.bodyLg(color: PulseColors.inkDeep),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PulseSpacing.xxl),
              const _TipChip(
                icon: Icons.music_note_rounded,
                label: 'Calm music helps you settle in',
              ),
              const SizedBox(height: PulseSpacing.md),
              const _TipChip(
                icon: Icons.air_rounded,
                label: 'Mindful breathing between blocks',
              ),
              const SizedBox(height: PulseSpacing.md),
              const _TipChip(
                icon: Icons.water_drop_outlined,
                label: 'Water is important — keep a glass nearby',
              ),
              const Spacer(),
              if (state.isCompleted)
                PulseSecondaryButton(
                  label: 'Done',
                  onPressed: () =>
                      context.read<FocusBloc>().add(const FocusTimerReset()),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PulseColors.canvas,
                      foregroundColor: PulseColors.ink,
                    ),
                    onPressed: () {
                      final bloc = context.read<FocusBloc>();
                      if (state.isRunning) {
                        bloc.add(const FocusTimerPaused());
                      } else {
                        bloc.add(const FocusTimerResumed());
                      }
                    },
                    child: Text(
                      state.isRunning ? 'Pause' : 'Resume',
                      style: PulseTypography.buttonMd(color: PulseColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: PulseSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PulseColors.ink,
                      foregroundColor: PulseColors.primary,
                    ),
                    onPressed: () => context
                        .read<FocusBloc>()
                        .add(const FocusTimerFinished()),
                    child: Text(
                      'Finish',
                      style: PulseTypography.buttonMd(color: PulseColors.primary),
                    ),
                  ),
                ),
              ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: selected ? PulseColors.primary : PulseColors.canvas,
      opacity: selected ? 0.8 : 0.45,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: PulseTypography.bodyMdStrong(),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: PulseColors.canvas,
      opacity: 0.35,
      blur: 14,
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpacing.lg,
        vertical: PulseSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: PulseColors.ink),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Text(label, style: PulseTypography.bodySmStrong()),
          ),
        ],
      ),
    );
  }
}

String _formatLength(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  if (s == 0) return '$m min';
  return '$m min ${s.toString().padLeft(2, '0')}s';
}

class _FocusTimerReadout extends StatelessWidget {
  const _FocusTimerReadout({required this.totalSeconds});

  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final safe = totalSeconds.clamp(0, 99 * 3600);
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;

    final parts = <(String, String)>[
      if (hours > 0) (hours.toString(), 'hr'),
      (
        hours > 0
            ? minutes.toString().padLeft(2, '0')
            : minutes.toString(),
        'min',
      ),
      (seconds.toString().padLeft(2, '0'), 'sec'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          _TimeUnit(value: parts[i].$1, unit: parts[i].$2),
        ],
      ],
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: PulseTypography.timerDisplay(color: PulseColors.ink),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: PulseTypography.caption(color: PulseColors.inkDeep),
        ),
      ],
    );
  }
}
