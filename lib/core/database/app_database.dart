import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get iconCode => integer().withDefault(const Constant(0xe8b6))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFFE2F6D5))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CheckInRow')
class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FocusSessionRow')
class FocusSessions extends Table {
  TextColumn get id => text()();
  IntColumn get plannedSeconds => integer()();
  IntColumn get completedSeconds => integer()();
  TextColumn get mode => text().withDefault(const Constant('pomodoro'))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Habits, CheckIns, FocusSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Bump this when tables/columns change, then add a step in [migration].
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await _createIndexes();
          }
          // When you bump [schemaVersion] again, add steps here, e.g.:
          // if (from < 3) {
          //   await m.addColumn(habits, habits.someNewColumn);
          // }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_check_ins_habit_date '
      'ON check_ins (habit_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_started '
      'ON focus_sessions (started_at)',
    );
  }

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'pulse.sqlite'));
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final file = await databaseFile();
      return NativeDatabase.createInBackground(file);
    });
  }
}
