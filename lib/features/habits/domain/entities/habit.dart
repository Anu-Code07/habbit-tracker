import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.iconCode,
    required this.colorValue,
    required this.frequency,
    required this.archived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final int iconCode;
  final int colorValue;
  final String frequency;
  final bool archived;
  final DateTime createdAt;

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCode,
    int? colorValue,
    String? frequency,
    bool? archived,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconCode,
        colorValue,
        frequency,
        archived,
        createdAt,
      ];
}

class HabitCheckIn extends Equatable {
  const HabitCheckIn({
    required this.id,
    required this.habitId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, habitId, date, note, createdAt];
}

class HabitWithStatus extends Equatable {
  const HabitWithStatus({
    required this.habit,
    required this.isCompletedToday,
    required this.currentStreak,
  });

  final Habit habit;
  final bool isCompletedToday;
  final int currentStreak;

  @override
  List<Object?> get props => [habit, isCompletedToday, currentStreak];
}

class WeekHabitStats extends Equatable {
  const WeekHabitStats({
    required this.completionRate,
    required this.completedCount,
    required this.expectedCount,
    required this.dailyCompletions,
  });

  final double completionRate;
  final int completedCount;
  final int expectedCount;
  final List<int> dailyCompletions;

  @override
  List<Object?> get props => [
        completionRate,
        completedCount,
        expectedCount,
        dailyCompletions,
      ];
}
