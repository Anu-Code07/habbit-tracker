import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:pulse/core/database/app_database.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';

class HabitLocalDataSource {
  HabitLocalDataSource(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<Habit>> getActiveHabits() async {
    final rows = await (_db.select(_db.habits)
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_mapHabit).toList();
  }

  Future<Habit?> getHabitById(String id) async {
    final row = await (_db.select(_db.habits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapHabit(row);
  }

  Future<void> createHabit(Habit habit) async {
    await _db.into(_db.habits).insert(_toCompanion(habit));
  }

  Future<void> updateHabit(Habit habit) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(habit.id)))
        .write(_toCompanion(habit));
  }

  Future<void> archiveHabit(String id) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
      const HabitsCompanion(archived: Value(true)),
    );
  }

  Future<void> toggleCheckIn({
    required String habitId,
    required DateTime date,
    String? note,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));
    final existing = await (_db.select(_db.checkIns)
          ..where(
            (t) =>
                t.habitId.equals(habitId) &
                t.date.isBiggerOrEqualValue(day) &
                t.date.isSmallerThanValue(next),
          ))
        .get();

    if (existing.isNotEmpty) {
      for (final row in existing) {
        await (_db.delete(_db.checkIns)..where((t) => t.id.equals(row.id))).go();
      }
      return;
    }

    await _db.into(_db.checkIns).insert(
          CheckInsCompanion.insert(
            id: _uuid.v4(),
            habitId: habitId,
            date: day,
            note: Value(note),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<bool> isCheckedIn({
    required String habitId,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));
    final rows = await (_db.select(_db.checkIns)
          ..where(
            (t) =>
                t.habitId.equals(habitId) &
                t.date.isBiggerOrEqualValue(day) &
                t.date.isSmallerThanValue(next),
          ))
        .get();
    return rows.isNotEmpty;
  }

  Future<List<HabitCheckIn>> getCheckInsForHabit(String habitId) async {
    final rows = await (_db.select(_db.checkIns)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_mapCheckIn).toList();
  }

  Future<List<HabitCheckIn>> getCheckInsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await (_db.select(_db.checkIns)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          ))
        .get();
    return rows.map(_mapCheckIn).toList();
  }

  Future<void> seedHabits(List<Habit> habits) async {
    await _db.batch((batch) {
      batch.insertAll(
        _db.habits,
        habits.map(_toCompanion).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// Keeps the oldest active habit per name; archives newer duplicates.
  Future<int> dedupeActiveHabitsByName() async {
    final habits = await getActiveHabits();
    final keepByName = <String, Habit>{};
    final toArchive = <String>[];

    for (final habit in habits) {
      final key = habit.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      final existing = keepByName[key];
      if (existing == null) {
        keepByName[key] = habit;
        continue;
      }
      if (habit.createdAt.isBefore(existing.createdAt)) {
        toArchive.add(existing.id);
        keepByName[key] = habit;
      } else {
        toArchive.add(habit.id);
      }
    }

    for (final id in toArchive) {
      await archiveHabit(id);
    }
    return toArchive.length;
  }

  Future<void> clearAll() async {
    await _db.delete(_db.checkIns).go();
    await _db.delete(_db.habits).go();
  }

  Habit _mapHabit(HabitRow row) => Habit(
        id: row.id,
        name: row.name,
        description: row.description,
        iconCode: row.iconCode,
        colorValue: row.colorValue,
        frequency: row.frequency,
        archived: row.archived,
        createdAt: row.createdAt,
      );

  HabitCheckIn _mapCheckIn(CheckInRow row) => HabitCheckIn(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
        note: row.note,
        createdAt: row.createdAt,
      );

  HabitsCompanion _toCompanion(Habit habit) => HabitsCompanion.insert(
        id: habit.id,
        name: habit.name,
        description: Value(habit.description),
        iconCode: Value(habit.iconCode),
        colorValue: Value(habit.colorValue),
        frequency: Value(habit.frequency),
        archived: Value(habit.archived),
        createdAt: habit.createdAt,
      );
}
