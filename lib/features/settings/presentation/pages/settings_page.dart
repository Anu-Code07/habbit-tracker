import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_minutes_picker.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
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
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Pomodoro length',
                            style: PulseTypography.bodyMdStrong(),
                          ),
                          subtitle: Text(
                            '${state.workMinutes} minutes',
                            style: PulseTypography.bodySm(),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: state.busy
                              ? null
                              : () async {
                                  final minutes = await showPulseMinutesPicker(
                                    context,
                                    initialMinutes: state.workMinutes,
                                  );
                                  if (minutes == null || !context.mounted) {
                                    return;
                                  }
                                  context.read<SettingsBloc>().add(
                                        SettingsWorkMinutesChanged(minutes),
                                      );
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
