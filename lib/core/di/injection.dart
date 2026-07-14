import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulse/core/database/app_database.dart';
import 'package:pulse/core/database/pulse_backup_service.dart';
import 'package:pulse/core/widgets/pulse_home_widget_sync.dart';
import 'package:pulse/features/focus/data/datasources/focus_local_datasource.dart';
import 'package:pulse/features/focus/data/focus_live_activity_service.dart';
import 'package:pulse/features/focus/data/repositories/focus_repository_impl.dart';
import 'package:pulse/features/focus/domain/repositories/focus_repository.dart';
import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/habits/data/datasources/habit_local_datasource.dart';
import 'package:pulse/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:pulse/features/habits/domain/repositories/habit_repository.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<AppDatabase>(db)
    ..registerSingleton<SettingsRepository>(SettingsRepository(prefs))
    ..registerLazySingleton(
      () => PulseBackupService(database: sl(), settings: sl()),
    )
    ..registerLazySingleton(() => HabitLocalDataSource(sl()))
    ..registerLazySingleton(() => FocusLocalDataSource(sl()))
    ..registerLazySingleton<HabitRepository>(
      () => HabitRepositoryImpl(sl()),
    )
    ..registerLazySingleton<FocusRepository>(() => FocusRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetTodayHabits(sl()))
    ..registerLazySingleton(() => ToggleHabitCheckIn(sl()))
    ..registerLazySingleton(() => CreateHabit(sl()))
    ..registerLazySingleton(() => UpdateHabit(sl()))
    ..registerLazySingleton(() => ArchiveHabit(sl()))
    ..registerLazySingleton(() => GetActiveHabits(sl()))
    ..registerLazySingleton(() => GetWeekHabitStats(sl()))
    ..registerLazySingleton(() => SeedStarterHabits(sl()))
    ..registerLazySingleton(() => DedupeHabits(sl()))
    ..registerLazySingleton(() => ClearHabitData(sl()))
    ..registerLazySingleton(() => FocusLiveActivityService())
    ..registerLazySingleton(() => SaveFocusSession(sl()))
    ..registerLazySingleton(() => GetTodayFocusMinutes(sl()))
    ..registerLazySingleton(() => GetWeekFocusSessions(sl()))
    ..registerLazySingleton(() => ClearFocusData(sl()))
    ..registerLazySingleton(
      () => PulseHomeWidgetSync(
        getTodayHabits: sl(),
        getTodayFocusMinutes: sl(),
      ),
    );
}
