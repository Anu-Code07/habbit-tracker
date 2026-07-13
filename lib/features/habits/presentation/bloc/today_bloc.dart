import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/widgets/pulse_home_widget_sync.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

sealed class TodayEvent extends Equatable {
  const TodayEvent();
  @override
  List<Object?> get props => [];
}

class TodayStarted extends TodayEvent {
  const TodayStarted();
}

class TodayDateSelected extends TodayEvent {
  const TodayDateSelected(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class TodayHabitToggled extends TodayEvent {
  const TodayHabitToggled(this.habitId);
  final String habitId;
  @override
  List<Object?> get props => [habitId];
}

class TodayRefreshed extends TodayEvent {
  const TodayRefreshed();
}

sealed class TodayState extends Equatable {
  const TodayState();
  @override
  List<Object?> get props => [];
}

class TodayInitial extends TodayState {
  const TodayInitial();
}

class TodayLoading extends TodayState {
  const TodayLoading();
}

class TodaySuccess extends TodayState {
  const TodaySuccess({
    required this.habits,
    required this.selectedDate,
    this.isRefreshing = false,
  });

  final List<HabitWithStatus> habits;
  final DateTime selectedDate;
  final bool isRefreshing;

  double get completionRate {
    if (habits.isEmpty) return 0;
    final done = habits.where((h) => h.isCompletedToday).length;
    return done / habits.length;
  }

  TodaySuccess copyWith({
    List<HabitWithStatus>? habits,
    DateTime? selectedDate,
    bool? isRefreshing,
  }) {
    return TodaySuccess(
      habits: habits ?? this.habits,
      selectedDate: selectedDate ?? this.selectedDate,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [habits, selectedDate, isRefreshing];
}

class TodayEmpty extends TodayState {
  const TodayEmpty({
    required this.selectedDate,
    this.isRefreshing = false,
  });

  final DateTime selectedDate;
  final bool isRefreshing;

  TodayEmpty copyWith({
    DateTime? selectedDate,
    bool? isRefreshing,
  }) {
    return TodayEmpty(
      selectedDate: selectedDate ?? this.selectedDate,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [selectedDate, isRefreshing];
}

class TodayError extends TodayState {
  const TodayError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class TodayBloc extends Bloc<TodayEvent, TodayState> {
  TodayBloc({
    required GetTodayHabits getTodayHabits,
    required ToggleHabitCheckIn toggleHabitCheckIn,
    required SettingsRepository settingsRepository,
    required PulseHomeWidgetSync homeWidgetSync,
  })  : _getTodayHabits = getTodayHabits,
        _toggleHabitCheckIn = toggleHabitCheckIn,
        _settingsRepository = settingsRepository,
        _homeWidgetSync = homeWidgetSync,
        super(const TodayInitial()) {
    on<TodayStarted>(_onStarted);
    on<TodayRefreshed>(_onRefresh);
    on<TodayDateSelected>(_onDate);
    on<TodayHabitToggled>(_onToggle);
  }

  final GetTodayHabits _getTodayHabits;
  final ToggleHabitCheckIn _toggleHabitCheckIn;
  final SettingsRepository _settingsRepository;
  final PulseHomeWidgetSync _homeWidgetSync;

  DateTime _selected = DateTime.now();
  int _loadGeneration = 0;

  Future<void> _onStarted(TodayStarted event, Emitter<TodayState> emit) async {
    emit(const TodayLoading());
    await _fetchHabits(emit);
  }

  Future<void> _onRefresh(
    TodayRefreshed event,
    Emitter<TodayState> emit,
  ) async {
    _emitRefreshingShell(emit);
    await _fetchHabits(emit);
  }

  Future<void> _onDate(
    TodayDateSelected event,
    Emitter<TodayState> emit,
  ) async {
    _selected = event.date;
    _emitRefreshingShell(emit, selectedDate: _normalize(event.date));
    await _fetchHabits(emit);
  }

  void _emitRefreshingShell(
    Emitter<TodayState> emit, {
    DateTime? selectedDate,
  }) {
    final date = selectedDate ?? _normalize(_selected);
    final current = state;
    if (current is TodaySuccess) {
      emit(current.copyWith(selectedDate: date, isRefreshing: true));
      return;
    }
    if (current is TodayEmpty) {
      emit(current.copyWith(selectedDate: date, isRefreshing: true));
      return;
    }
    emit(const TodayLoading());
  }

  Future<void> _fetchHabits(Emitter<TodayState> emit) async {
    final generation = ++_loadGeneration;
    try {
      final habits = await _getTodayHabits(date: _selected);
      if (generation != _loadGeneration) return;
      if (habits.isEmpty) {
        emit(
          TodayEmpty(
            selectedDate: _normalize(_selected),
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          TodaySuccess(
            habits: habits,
            selectedDate: _normalize(_selected),
            isRefreshing: false,
          ),
        );
      }
      await _homeWidgetSync.sync();
    } catch (_) {
      if (generation != _loadGeneration) return;
      emit(const TodayError('Could not load habits.'));
    }
  }

  Future<void> _onToggle(
    TodayHabitToggled event,
    Emitter<TodayState> emit,
  ) async {
    final current = state;
    if (current is! TodaySuccess || current.isRefreshing) return;

    final optimistic = current.habits
        .map(
          (item) => item.habit.id == event.habitId
              ? HabitWithStatus(
                  habit: item.habit,
                  isCompletedToday: !item.isCompletedToday,
                  currentStreak: item.currentStreak,
                )
              : item,
        )
        .toList();
    emit(current.copyWith(habits: optimistic));

    try {
      if (_settingsRepository.hapticsEnabled) {
        await HapticFeedback.lightImpact();
      }
      await _toggleHabitCheckIn(habitId: event.habitId, date: _selected);
      final habits = await _getTodayHabits(date: _selected);
      if (habits.isEmpty) {
        emit(TodayEmpty(selectedDate: _normalize(_selected)));
      } else {
        emit(
          TodaySuccess(
            habits: habits,
            selectedDate: _normalize(_selected),
          ),
        );
      }
      await _homeWidgetSync.sync();
    } catch (_) {
      emit(current);
      emit(const TodayError('Could not update habit.'));
    }
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
