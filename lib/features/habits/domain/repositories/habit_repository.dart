import 'package:pulse/features/habits/domain/entities/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getActiveHabits();
  Future<Habit?> getHabitById(String id);
  Future<void> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> archiveHabit(String id);
  Future<void> toggleCheckIn({
    required String habitId,
    required DateTime date,
    String? note,
  });
  Future<bool> isCheckedIn({required String habitId, required DateTime date});
  Future<List<HabitCheckIn>> getCheckInsForHabit(String habitId);
  Future<List<HabitCheckIn>> getCheckInsBetween(DateTime start, DateTime end);
  Future<int> getCurrentStreak(String habitId);
  Future<WeekHabitStats> getWeekStats(DateTime weekStart);
  Future<void> seedHabits(List<Habit> habits);
  Future<int> dedupeActiveHabitsByName();
  Future<void> clearAll();
}
