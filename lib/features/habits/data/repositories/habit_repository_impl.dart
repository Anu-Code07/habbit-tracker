import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/repositories/habit_repository.dart';
import 'package:pulse/features/habits/data/datasources/habit_local_datasource.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._local);

  final HabitLocalDataSource _local;

  @override
  Future<List<Habit>> getActiveHabits() => _local.getActiveHabits();

  @override
  Future<Habit?> getHabitById(String id) => _local.getHabitById(id);

  @override
  Future<void> createHabit(Habit habit) => _local.createHabit(habit);

  @override
  Future<void> updateHabit(Habit habit) => _local.updateHabit(habit);

  @override
  Future<void> archiveHabit(String id) => _local.archiveHabit(id);

  @override
  Future<void> toggleCheckIn({
    required String habitId,
    required DateTime date,
    String? note,
  }) =>
      _local.toggleCheckIn(habitId: habitId, date: date, note: note);

  @override
  Future<bool> isCheckedIn({
    required String habitId,
    required DateTime date,
  }) =>
      _local.isCheckedIn(habitId: habitId, date: date);

  @override
  Future<List<HabitCheckIn>> getCheckInsForHabit(String habitId) =>
      _local.getCheckInsForHabit(habitId);

  @override
  Future<List<HabitCheckIn>> getCheckInsBetween(
    DateTime start,
    DateTime end,
  ) =>
      _local.getCheckInsBetween(start, end);

  @override
  Future<int> getCurrentStreak(String habitId) async {
    final checkIns = await _local.getCheckInsForHabit(habitId);
    if (checkIns.isEmpty) return 0;

    final days = checkIns
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Future<WeekHabitStats> getWeekStats(DateTime weekStart) async {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    final habits = await _local.getActiveHabits();
    final checkIns = await _local.getCheckInsBetween(start, end);

    final daily = List<int>.filled(7, 0);
    for (final c in checkIns) {
      final index = c.date.difference(start).inDays;
      if (index >= 0 && index < 7) {
        daily[index]++;
      }
    }

    final expected = habits.length * 7;
    final completed = checkIns.length;
    final rate = expected == 0 ? 0.0 : completed / expected;

    return WeekHabitStats(
      completionRate: rate.clamp(0.0, 1.0),
      completedCount: completed,
      expectedCount: expected,
      dailyCompletions: daily,
    );
  }

  @override
  Future<void> seedHabits(List<Habit> habits) => _local.seedHabits(habits);

  @override
  Future<void> clearAll() => _local.clearAll();
}
