import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/repositories/habit_repository.dart';

class GetTodayHabits {
  GetTodayHabits(this._repository);

  final HabitRepository _repository;

  Future<List<HabitWithStatus>> call({DateTime? date}) async {
    final day = date ?? DateTime.now();
    final habits = await _repository.getActiveHabits();
    final result = <HabitWithStatus>[];
    for (final habit in habits) {
      final completed = await _repository.isCheckedIn(
        habitId: habit.id,
        date: day,
      );
      final streak = await _repository.getCurrentStreak(habit.id);
      result.add(
        HabitWithStatus(
          habit: habit,
          isCompletedToday: completed,
          currentStreak: streak,
        ),
      );
    }
    return result;
  }
}

class ToggleHabitCheckIn {
  ToggleHabitCheckIn(this._repository);

  final HabitRepository _repository;

  Future<void> call({required String habitId, DateTime? date, String? note}) {
    return _repository.toggleCheckIn(
      habitId: habitId,
      date: date ?? DateTime.now(),
      note: note,
    );
  }
}

class CreateHabit {
  CreateHabit(this._repository);

  final HabitRepository _repository;

  Future<void> call(Habit habit) => _repository.createHabit(habit);
}

class UpdateHabit {
  UpdateHabit(this._repository);

  final HabitRepository _repository;

  Future<void> call(Habit habit) => _repository.updateHabit(habit);
}

class ArchiveHabit {
  ArchiveHabit(this._repository);

  final HabitRepository _repository;

  Future<void> call(String id) => _repository.archiveHabit(id);
}

class GetActiveHabits {
  GetActiveHabits(this._repository);

  final HabitRepository _repository;

  Future<List<Habit>> call() => _repository.getActiveHabits();
}

class GetWeekHabitStats {
  GetWeekHabitStats(this._repository);

  final HabitRepository _repository;

  Future<WeekHabitStats> call({DateTime? weekStart}) {
    final now = DateTime.now();
    final start = weekStart ??
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
    return _repository.getWeekStats(start);
  }
}

class SeedStarterHabits {
  SeedStarterHabits(this._repository);

  final HabitRepository _repository;

  Future<void> call(List<Habit> habits) => _repository.seedHabits(habits);
}

class ClearHabitData {
  ClearHabitData(this._repository);

  final HabitRepository _repository;

  Future<void> call() => _repository.clearAll();
}
