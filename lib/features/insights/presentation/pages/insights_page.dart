import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_shimmer.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
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
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    PulseSpacing.xl,
                    PulseSpacing.xl,
                    PulseSpacing.xl,
                    120,
                  ),
                  children: [
                    Text('This week', style: PulseTypography.displayMd()),
                    const SizedBox(height: PulseSpacing.sm),
                    Text(
                      'A quiet look at your rhythm.',
                      style: PulseTypography.bodyMd(),
                    ),
                    const SizedBox(height: PulseSpacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PulseGlass(
                        tint: PulseColors.primaryPale,
                        opacity: 0.75,
                        blur: 12,
                        borderRadius: BorderRadius.circular(PulseRadii.pill),
                        onTap: () => PulseWeekShare.share(
                          context: context,
                          completionPercent:
                              (weekStats.completionRate * 100).round(),
                          checkIns: weekStats.completedCount,
                          focusMinutes: focusMinutes,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: PulseSpacing.lg,
                          vertical: PulseSpacing.md,
                        ),
                        child: Text(
                          'Share this week',
                          style: PulseTypography.bodySmStrong(),
                        ),
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xxl),
                    PulseCard(
                      color: PulseColors.ink,
                      opacity: 0.72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion',
                            style: PulseTypography.bodySm(
                              color: PulseColors.canvasSoft,
                            ),
                          ),
                          const SizedBox(height: PulseSpacing.sm),
                          Text(
                            '${(weekStats.completionRate * 100).round()}%',
                            style: PulseTypography.displayXl(
                              color: PulseColors.primary,
                            ),
                          ),
                          Text(
                            '${weekStats.completedCount} check-ins',
                            style: PulseTypography.bodySm(
                              color: PulseColors.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.lg),
                    PulseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus minutes',
                            style: PulseTypography.bodySmStrong(),
                          ),
                          const SizedBox(height: PulseSpacing.sm),
                          Text(
                            '$focusMinutes',
                            style: PulseTypography.displayMd(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.lg),
                    PulseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily check-ins',
                            style: PulseTypography.bodySmStrong(),
                          ),
                          const SizedBox(height: PulseSpacing.lg),
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0;
                                    i < weekStats.dailyCompletions.length;
                                    i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: FractionallySizedBox(
                                              heightFactor: _barFactor(
                                                weekStats.dailyCompletions[i],
                                                weekStats.dailyCompletions,
                                              ),
                                              widthFactor: 1,
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: PulseColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    PulseRadii.sm,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            const [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S',
                                            ][i],
                                            style: PulseTypography.caption(),
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
                  ],
                ),
            };
          },
          ),
        ),
      ),
    );
  }

  double _barFactor(int value, List<int> all) {
    final max = all.fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) return 0.08;
    return (value / max).clamp(0.08, 1.0);
  }
}
