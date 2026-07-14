import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/focus/data/focus_timer_sounds.dart';
import 'package:pulse/features/settings/domain/focus_sound_pack.dart';
import 'package:pulse/features/settings/presentation/bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PulseAtmosphere(
        child: SafeArea(
          child: BlocConsumer<SettingsBloc, SettingsState>(
            listenWhen: (p, c) =>
                (!p.resetDone && c.resetDone) ||
                (!p.importDone && c.importDone) ||
                (p.message != c.message && c.message != null),
            listener: (context, state) {
              if (state.resetDone) {
                context.go('/onboarding');
                return;
              }
              if (state.importDone) {
                context.go('/splash');
                return;
              }
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message!)),
                );
              }
            },
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  PulseSpacing.xl,
                  PulseSpacing.xl,
                  PulseSpacing.xl,
                  120,
                ),
                children: [
                  Text('Settings', style: PulseTypography.displayMd()),
                  const SizedBox(height: PulseSpacing.sm),
                  Text(
                    'Your calm space for habits and focus',
                    style: PulseTypography.bodyMd(),
                  ),
                  const SizedBox(height: PulseSpacing.xxl),
                  PulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Haptics',
                            style: PulseTypography.bodyMdStrong(),
                          ),
                          subtitle: Text(
                            'Soft feedback on check-ins and focus',
                            style: PulseTypography.bodySm(),
                          ),
                          value: state.hapticsEnabled,
                          onChanged: state.busy
                              ? null
                              : (v) => context
                                  .read<SettingsBloc>()
                                  .add(SettingsHapticsChanged(v)),
                        ),
                        const SizedBox(height: PulseSpacing.md),
                        Text(
                          'Focus sound',
                          style: PulseTypography.bodyMdStrong(),
                        ),
                        const SizedBox(height: PulseSpacing.xs),
                        Text(
                          state.soundPack.subtitle,
                          style: PulseTypography.bodySm(),
                        ),
                        const SizedBox(height: PulseSpacing.md),
                        Row(
                          children: [
                            for (final pack in FocusSoundPack.values) ...[
                              if (pack != FocusSoundPack.values.first)
                                const SizedBox(width: PulseSpacing.sm),
                              Expanded(
                                child: _SoundPackChip(
                                  label: pack.label,
                                  selected: state.soundPack == pack,
                                  onTap: state.busy
                                      ? null
                                      : () async {
                                          context.read<SettingsBloc>().add(
                                                SettingsSoundPackChanged(pack),
                                              );
                                          if (pack.playsAudio) {
                                            await FocusTimerSounds.completed(
                                              pack,
                                            );
                                          }
                                        },
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (state.soundPack.playsAudio) ...[
                          const SizedBox(height: PulseSpacing.md),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Completion',
                              style: PulseTypography.bodyMdStrong(),
                            ),
                            subtitle: Text(
                              'Chime when a session ends',
                              style: PulseTypography.bodySm(),
                            ),
                            value: state.completionSoundEnabled,
                            onChanged: state.busy
                                ? null
                                : (v) => context.read<SettingsBloc>().add(
                                      SettingsCompletionSoundChanged(v),
                                    ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Warning',
                              style: PulseTypography.bodyMdStrong(),
                            ),
                            subtitle: Text(
                              'Alert when 10 seconds remain',
                              style: PulseTypography.bodySm(),
                            ),
                            value: state.warningSoundEnabled,
                            onChanged: state.busy
                                ? null
                                : (v) => context.read<SettingsBloc>().add(
                                      SettingsWarningSoundChanged(v),
                                    ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Focus ticks',
                              style: PulseTypography.bodyMdStrong(),
                            ),
                            subtitle: Text(
                              'Soft pluck on the last seconds',
                              style: PulseTypography.bodySm(),
                            ),
                            value: state.focusTickSoundEnabled,
                            onChanged: state.busy
                                ? null
                                : (v) => context.read<SettingsBloc>().add(
                                      SettingsFocusTickSoundChanged(v),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  PulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backup', style: PulseTypography.bodyMdStrong()),
                        const SizedBox(height: PulseSpacing.sm),
                        Text(
                          'Everything stays on this device. Export a backup file so you can restore habits and focus history later.',
                          style: PulseTypography.bodySm(),
                        ),
                        const SizedBox(height: PulseSpacing.lg),
                        PulseSecondaryButton(
                          label: state.busy ? 'Working…' : 'Export backup',
                          onPressed: state.busy
                              ? null
                              : () => context.read<SettingsBloc>().add(
                                    const SettingsBackupExportRequested(),
                                  ),
                        ),
                        const SizedBox(height: PulseSpacing.sm),
                        PulseSecondaryButton(
                          label: 'Restore backup',
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Restore backup?'),
                                      content: const Text(
                                        'This replaces your current habits, check-ins, focus history, and settings.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Restore'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    context.read<SettingsBloc>().add(
                                          const SettingsBackupImportRequested(),
                                        );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  PulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data', style: PulseTypography.bodyMdStrong()),
                        const SizedBox(height: PulseSpacing.sm),
                        Text(
                          'Reset clears habits, focus history, and onboarding.',
                          style: PulseTypography.bodySm(),
                        ),
                        const SizedBox(height: PulseSpacing.lg),
                        PulseSecondaryButton(
                          label: 'Reset all data',
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Reset Pulse?'),
                                      content: const Text(
                                        'This cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(
                                            'Reset',
                                            style: PulseTypography.bodyMdStrong(
                                              color: PulseColors.negative,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    context
                                        .read<SettingsBloc>()
                                        .add(const SettingsDataReset());
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  PulseCard(
                    color: PulseColors.primaryPale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Pulse',
                          style: PulseTypography.bodyMdStrong(),
                        ),
                        const SizedBox(height: PulseSpacing.sm),
                        Text(
                          'Pulse helps you keep small daily promises — habits you can actually finish, focus sessions that protect your attention, and a gentle weekly view of your rhythm. Everything stays on your device.',
                          style: PulseTypography.bodySm(),
                        ),
                        const SizedBox(height: PulseSpacing.md),
                        Text(
                          'Made with ♥ by Anurag',
                          style: PulseTypography.bodySm(
                            color: PulseColors.body.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SoundPackChip extends StatelessWidget {
  const _SoundPackChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: selected ? PulseColors.primary : PulseColors.canvas,
      opacity: selected ? 0.8 : 0.45,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: PulseTypography.bodySmStrong(),
      ),
    );
  }
}
