import 'package:equatable/equatable.dart';

class FocusSession extends Equatable {
  const FocusSession({
    required this.id,
    required this.plannedSeconds,
    required this.completedSeconds,
    required this.mode,
    required this.completed,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final int plannedSeconds;
  final int completedSeconds;
  final String mode;
  final bool completed;
  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  List<Object?> get props => [
        id,
        plannedSeconds,
        completedSeconds,
        mode,
        completed,
        startedAt,
        endedAt,
      ];
}

class FocusConfig extends Equatable {
  const FocusConfig({
    this.workMinutes = 25,
    this.breakMinutes = 5,
  });

  final int workMinutes;
  final int breakMinutes;

  FocusConfig copyWith({int? workMinutes, int? breakMinutes}) {
    return FocusConfig(
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
    );
  }

  @override
  List<Object?> get props => [workMinutes, breakMinutes];
}
