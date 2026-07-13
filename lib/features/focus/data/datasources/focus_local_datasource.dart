import 'package:drift/drift.dart';

import 'package:pulse/core/database/app_database.dart';
import 'package:pulse/features/focus/domain/entities/focus_session.dart';

class FocusLocalDataSource {
  FocusLocalDataSource(this._db);

  final AppDatabase _db;

  Future<void> saveSession(FocusSession session) async {
    await _db.into(_db.focusSessions).insertOnConflictUpdate(
          FocusSessionsCompanion.insert(
            id: session.id,
            plannedSeconds: session.plannedSeconds,
            completedSeconds: session.completedSeconds,
            mode: Value(session.mode),
            completed: Value(session.completed),
            startedAt: session.startedAt,
            endedAt: Value(session.endedAt),
          ),
        );
  }

  Future<List<FocusSession>> getSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await (_db.select(_db.focusSessions)
          ..where(
            (t) =>
                t.startedAt.isBiggerOrEqualValue(start) &
                t.startedAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.map(_map).toList();
  }

  Future<int> getTodayFocusMinutes(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await getSessionsBetween(start, end);
    final seconds = sessions.fold<int>(
      0,
      (sum, s) => sum + s.completedSeconds,
    );
    return (seconds / 60).floor();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.focusSessions).go();
  }

  FocusSession _map(FocusSessionRow row) => FocusSession(
        id: row.id,
        plannedSeconds: row.plannedSeconds,
        completedSeconds: row.completedSeconds,
        mode: row.mode,
        completed: row.completed,
        startedAt: row.startedAt,
        endedAt: row.endedAt,
      );
}
