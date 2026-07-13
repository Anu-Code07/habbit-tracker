import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pulse/core/database/pulse_backup_service.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_home_widget_sync.dart';
import 'package:pulse/features/focus/data/focus_live_activity_service.dart';
import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:pulse/features/focus/presentation/pages/focus_page.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:pulse/features/habits/presentation/bloc/today_bloc.dart';
import 'package:pulse/features/habits/presentation/pages/today_page.dart';
import 'package:pulse/features/habits/presentation/widgets/habit_editor_sheet.dart';
import 'package:pulse/features/insights/presentation/bloc/insights_bloc.dart';
import 'package:pulse/features/insights/presentation/pages/insights_page.dart';
import 'package:pulse/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';
import 'package:pulse/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:pulse/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse/features/splash/presentation/pages/splash_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/today',
                builder: (_, __) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/focus',
                builder: (_, __) => const FocusPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/insights',
                builder: (_, __) => const InsightsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TodayBloc(
            getTodayHabits: sl<GetTodayHabits>(),
            toggleHabitCheckIn: sl<ToggleHabitCheckIn>(),
            settingsRepository: sl<SettingsRepository>(),
            homeWidgetSync: sl<PulseHomeWidgetSync>(),
            dedupeHabits: sl<DedupeHabits>(),
          )..add(const TodayStarted()),
        ),
        BlocProvider(
          create: (_) => HabitsBloc(
            getActiveHabits: sl<GetActiveHabits>(),
            createHabit: sl<CreateHabit>(),
            updateHabit: sl<UpdateHabit>(),
            archiveHabit: sl<ArchiveHabit>(),
          )..add(const HabitsStarted()),
        ),
        BlocProvider(
          create: (_) => FocusBloc(
            settingsRepository: sl<SettingsRepository>(),
            saveFocusSession: sl<SaveFocusSession>(),
            getTodayFocusMinutes: sl<GetTodayFocusMinutes>(),
            liveActivityService: sl<FocusLiveActivityService>(),
            homeWidgetSync: sl<PulseHomeWidgetSync>(),
          )..add(const FocusStarted()),
        ),
        BlocProvider(
          create: (_) => InsightsBloc(
            getWeekHabitStats: sl<GetWeekHabitStats>(),
            getTodayFocusMinutes: sl<GetTodayFocusMinutes>(),
            getWeekFocusSessions: sl<GetWeekFocusSessions>(),
          )..add(const InsightsStarted()),
        ),
        BlocProvider(
          create: (_) => SettingsBloc(
            settingsRepository: sl<SettingsRepository>(),
            clearHabitData: sl<ClearHabitData>(),
            clearFocusData: sl<ClearFocusData>(),
            backupService: sl<PulseBackupService>(),
          )..add(const SettingsStarted()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final index = navigationShell.currentIndex;
          return BlocListener<SettingsBloc, SettingsState>(
            listenWhen: (p, c) => p.workMinutes != c.workMinutes,
            listener: (context, _) {
              context.read<FocusBloc>().add(const FocusStarted());
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: navigationShell,
              bottomNavigationBar: _PulseBottomBar(
                currentIndex: index,
                onSelect: (i) {
                  navigationShell.goBranch(i);
                  // IndexedStack keeps tabs alive — refresh stale screens.
                  if (i == 0) {
                    context
                        .read<TodayBloc>()
                        .add(const TodayGreetingRolled());
                  } else if (i == 1) {
                    context.read<FocusBloc>().add(const FocusStarted());
                  } else if (i == 2) {
                    context
                        .read<InsightsBloc>()
                        .add(const InsightsStarted());
                  }
                },
                onAdd: index == 0
                    ? () => showHabitEditorSheet(context)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulseBottomBar extends StatelessWidget {
  const _PulseBottomBar({
    required this.currentIndex,
    required this.onSelect,
    this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final showAdd = onAdd != null;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 56.0;
    const addSize = 52.0;
    const navRowHeight = 48.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset : 10,
      ),
      child: SizedBox(
        height: showAdd ? barHeight + addSize * 0.45 : barHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: PulseGlass(
                opacity: 0.62,
                blur: 24,
                borderOpacity: 0.7,
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: SizedBox(
                  height: navRowHeight,
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Today',
                        selected: currentIndex == 0,
                        onTap: () => onSelect(0),
                      ),
                      _NavItem(
                        icon: Icons.timer_outlined,
                        label: 'Focus',
                        selected: currentIndex == 1,
                        onTap: () => onSelect(1),
                      ),
                      if (showAdd) const SizedBox(width: addSize + 6),
                      _NavItem(
                        icon: Icons.insights_rounded,
                        label: 'Insights',
                        selected: currentIndex == 2,
                        onTap: () => onSelect(2),
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        selected: currentIndex == 3,
                        onTap: () => onSelect(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showAdd)
              Positioned(
                bottom: (barHeight - addSize) / 2 + 4,
                child: Material(
                  color: PulseColors.primary,
                  elevation: 10,
                  shadowColor: PulseColors.ink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: addSize,
                      height: addSize,
                      child: Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: PulseColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? PulseColors.ink : PulseColors.mute,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  style: PulseTypography.navLabel(selected: selected).copyWith(
                    height: 1,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 14 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected ? PulseColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(PulseRadii.pill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
