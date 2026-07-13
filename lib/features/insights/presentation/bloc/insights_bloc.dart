import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';

sealed class InsightsEvent extends Equatable {
  const InsightsEvent();
  @override
  List<Object?> get props => [];
}

class InsightsStarted extends InsightsEvent {
  const InsightsStarted();
}

sealed class InsightsState extends Equatable {
  const InsightsState();
  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsSuccess extends InsightsState {
  const InsightsSuccess({
    required this.weekStats,
    required this.focusMinutes,
  });

  final WeekHabitStats weekStats;
  final int focusMinutes;

  @override
  List<Object?> get props => [weekStats, focusMinutes];
}

class InsightsError extends InsightsState {
  const InsightsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc({
    required GetWeekHabitStats getWeekHabitStats,
    required GetTodayFocusMinutes getTodayFocusMinutes,
    required GetWeekFocusSessions getWeekFocusSessions,
  })  : _getWeekHabitStats = getWeekHabitStats,
        _getWeekFocusSessions = getWeekFocusSessions,
        super(const InsightsInitial()) {
    on<InsightsStarted>(_onStarted);
  }

  final GetWeekHabitStats _getWeekHabitStats;
  final GetWeekFocusSessions _getWeekFocusSessions;

  Future<void> _onStarted(
    InsightsStarted event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());
    try {
      final stats = await _getWeekHabitStats();
      final sessions = await _getWeekFocusSessions();
      final minutes = sessions.fold<int>(
            0,
            (sum, s) => sum + s.completedSeconds,
         ) ~/
          60;
      emit(InsightsSuccess(weekStats: stats, focusMinutes: minutes));
    } catch (_) {
      emit(const InsightsError('Could not load insights.'));
    }
  }
}
