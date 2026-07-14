import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/theme/pulse_greetings.dart';
import 'package:pulse/core/widgets/pulse_home_widget_sync.dart';
import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/habits/data/grace_day_store.dart';
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

class TodayGreetingRolled extends TodayEvent {
  const TodayGreetingRolled();
}

class TodayGraceDayRequested extends TodayEvent {
  const TodayGraceDayRequested();
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
    required this.greeting,
    this.isRefreshing = false,
    this.graceAvailable = true,
    this.isGraceDay = false,
    this.message,
  });

  final List<HabitWithStatus> habits;
  final DateTime selectedDate;
  final String greeting;
  final bool isRefreshing;
  final bool graceAvailable;
  final bool isGraceDay;
  final String? message;

  double get completionRate {
    if (habits.isEmpty) return 0;
    final done = habits.where((h) => h.isCompletedToday).length;
    return done / habits.length;
  }

  TodaySuccess copyWith({
    List<HabitWithStatus>? habits,
    DateTime? selectedDate,
    String? greeting,
    bool? isRefreshing,
    bool? graceAvailable,
    bool? isGraceDay,
    String? message,
    bool clearMessage = false,
  }) {
    return TodaySuccess(
      habits: habits ?? this.habits,
      selectedDate: selectedDate ?? this.selectedDate,
      greeting: greeting ?? this.greeting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      graceAvailable: graceAvailable ?? this.graceAvailable,
      isGraceDay: isGraceDay ?? this.isGraceDay,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        habits,
        selectedDate,
        greeting,
        isRefreshing,
        graceAvailable,
        isGraceDay,
        message,
      ];
}

class TodayEmpty extends TodayState {
  const TodayEmpty({
    required this.selectedDate,
    required this.greeting,
    this.isRefreshing = false,
    this.graceAvailable = true,
    this.isGraceDay = false,
    this.message,
  });

  final DateTime selectedDate;
  final String greeting;
  final bool isRefreshing;
  final bool graceAvailable;
  final bool isGraceDay;
  final String? message;

  TodayEmpty copyWith({
    DateTime? selectedDate,
    String? greeting,
    bool? isRefreshing,
    bool? graceAvailable,
    bool? isGraceDay,
    String? message,
    bool clearMessage = false,
  }) {
    return TodayEmpty(
      selectedDate: selectedDate ?? this.selectedDate,
      greeting: greeting ?? this.greeting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      graceAvailable: graceAvailable ?? this.graceAvailable,
      isGraceDay: isGraceDay ?? this.isGraceDay,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        selectedDate,
        greeting,
        isRefreshing,
        graceAvailable,
        isGraceDay,
        message,
      ];
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
    required DedupeHabits dedupeHabits,
    required GetTodayFocusMinutes getTodayFocusMinutes,
    required GraceDayStore graceDayStore,
  })  : _getTodayHabits = getTodayHabits,
        _toggleHabitCheckIn = toggleHabitCheckIn,
        _settingsRepository = settingsRepository,
        _homeWidgetSync = homeWidgetSync,
        _dedupeHabits = dedupeHabits,
        _getTodayFocusMinutes = getTodayFocusMinutes,
        _grace = graceDayStore,
        super(const TodayInitial()) {
    on<TodayStarted>(_onStarted);
    on<TodayRefreshed>(_onRefresh);
    on<TodayDateSelected>(_onDate);
    on<TodayHabitToggled>(_onToggle);
    on<TodayGreetingRolled>(_onGreetingRolled);
    on<TodayGraceDayRequested>(_onGraceDay);
  }

  final GetTodayHabits _getTodayHabits;
  final ToggleHabitCheckIn _toggleHabitCheckIn;
  final SettingsRepository _settingsRepository;
  final PulseHomeWidgetSync _homeWidgetSync;
  final DedupeHabits _dedupeHabits;
  final GetTodayFocusMinutes _getTodayFocusMinutes;
  final GraceDayStore _grace;

  DateTime _selected = DateTime.now();
  int _loadGeneration = 0;

  Future<String> _rollGreeting() async {
    final focusMinutes = await _getTodayFocusMinutes();
    return PulseGreetings.forUser(
      _settingsRepository.userName,
      hasFocusedToday: focusMinutes > 0,
    );
  }

  Future<void> _onGreetingRolled(
    TodayGreetingRolled event,
    Emitter<TodayState> emit,
  ) async {
    final greeting = await _rollGreeting();
    final current = state;
    if (current is TodaySuccess) {
      emit(current.copyWith(greeting: greeting));
    } else if (current is TodayEmpty) {
      emit(current.copyWith(greeting: greeting));
    }
  }

  Future<void> _onGraceDay(
    TodayGraceDayRequested event,
    Emitter<TodayState> emit,
  ) async {
    final day = _normalize(_selected);
    final ok = await _grace.useGraceFor(day);
    if (!ok) {
      final current = state;
      if (current is TodaySuccess) {
        emit(
          current.copyWith(
            message: 'Grace already used this week.',
          ),
        );
      } else if (current is TodayEmpty) {
        emit(
          current.copyWith(
            message: 'Grace already used this week.',
          ),
        );
      }
      return;
    }

    if (_settingsRepository.hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }

    final habits = await _getTodayHabits(date: _selected);
    final greeting = await _rollGreeting();
    final message = 'Grace used · streak safe.';
    if (habits.isEmpty) {
      emit(
        TodayEmpty(
          selectedDate: day,
          greeting: greeting,
          graceAvailable: false,
          isGraceDay: true,
          message: message,
        ),
      );
    } else {
      emit(
        TodaySuccess(
          habits: habits,
          selectedDate: day,
          greeting: greeting,
          graceAvailable: false,
          isGraceDay: true,
          message: message,
        ),
      );
    }
    await _homeWidgetSync.sync();
  }

  Future<void> _onStarted(TodayStarted event, Emitter<TodayState> emit) async {
    emit(const TodayLoading());
    await _dedupeHabits();
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
      final greeting = await _rollGreeting();
      final day = _normalize(_selected);
      final graceAvailable = _grace.canUseGrace(day);
      final isGraceDay = _grace.isGraceDay(day);
      if (habits.isEmpty) {
        emit(
          TodayEmpty(
            selectedDate: day,
            greeting: greeting,
            isRefreshing: false,
            graceAvailable: graceAvailable,
            isGraceDay: isGraceDay,
          ),
        );
      } else {
        emit(
          TodaySuccess(
            habits: habits,
            selectedDate: day,
            greeting: greeting,
            isRefreshing: false,
            graceAvailable: graceAvailable,
            isGraceDay: isGraceDay,
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
      final day = _normalize(_selected);
      if (habits.isEmpty) {
        emit(
          TodayEmpty(
            selectedDate: day,
            greeting: current.greeting,
            graceAvailable: current.graceAvailable,
            isGraceDay: current.isGraceDay,
          ),
        );
      } else {
        emit(
          TodaySuccess(
            habits: habits,
            selectedDate: day,
            greeting: current.greeting,
            graceAvailable: current.graceAvailable,
            isGraceDay: current.isGraceDay,
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
