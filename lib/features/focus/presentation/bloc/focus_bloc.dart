import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:pulse/features/focus/data/focus_live_activity_service.dart';
import 'package:pulse/features/focus/domain/entities/focus_session.dart';
import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/core/widgets/pulse_home_widget_sync.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

enum FocusMode { pomodoro, free }

sealed class FocusEvent extends Equatable {
  const FocusEvent();
  @override
  List<Object?> get props => [];
}

class FocusStarted extends FocusEvent {
  const FocusStarted();
}

class FocusModeChanged extends FocusEvent {
  const FocusModeChanged(this.mode);
  final FocusMode mode;
  @override
  List<Object?> get props => [mode];
}

class FocusDurationChanged extends FocusEvent {
  const FocusDurationChanged(this.minutes);
  final int minutes;
  @override
  List<Object?> get props => [minutes];
}

class FocusTimerStarted extends FocusEvent {
  const FocusTimerStarted();
}

class FocusTimerPaused extends FocusEvent {
  const FocusTimerPaused();
}

class FocusTimerResumed extends FocusEvent {
  const FocusTimerResumed();
}

class FocusTimerReset extends FocusEvent {
  const FocusTimerReset();
}

class FocusTimerFinished extends FocusEvent {
  const FocusTimerFinished();
}

class FocusTick extends FocusEvent {
  const FocusTick();
}

class FocusState extends Equatable {
  const FocusState({
    this.mode = FocusMode.pomodoro,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.isCompleted = false,
    this.todayMinutes = 0,
    this.sessionStartedAt,
  });

  final FocusMode mode;
  final int totalSeconds;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isRunning;
  final bool isCompleted;
  final int todayMinutes;
  final DateTime? sessionStartedAt;

  double get progress {
    if (totalSeconds == 0) return 0;
    return 1 - (remainingSeconds / totalSeconds);
  }

  String get modeLabel =>
      mode == FocusMode.pomodoro ? 'Pomodoro' : 'Free focus';

  FocusState copyWith({
    FocusMode? mode,
    int? totalSeconds,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isRunning,
    bool? isCompleted,
    int? todayMinutes,
    DateTime? sessionStartedAt,
    bool clearSession = false,
  }) {
    return FocusState(
      mode: mode ?? this.mode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      sessionStartedAt:
          clearSession ? null : (sessionStartedAt ?? this.sessionStartedAt),
    );
  }

  @override
  List<Object?> get props => [
        mode,
        totalSeconds,
        remainingSeconds,
        elapsedSeconds,
        isRunning,
        isCompleted,
        todayMinutes,
        sessionStartedAt,
      ];
}

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  FocusBloc({
    required SettingsRepository settingsRepository,
    required SaveFocusSession saveFocusSession,
    required GetTodayFocusMinutes getTodayFocusMinutes,
    required FocusLiveActivityService liveActivityService,
    required PulseHomeWidgetSync homeWidgetSync,
  })  : _settings = settingsRepository,
        _saveFocusSession = saveFocusSession,
        _getTodayFocusMinutes = getTodayFocusMinutes,
        _liveActivity = liveActivityService,
        _homeWidgetSync = homeWidgetSync,
        super(const FocusState()) {
    on<FocusStarted>(_onStarted);
    on<FocusModeChanged>(_onMode);
    on<FocusDurationChanged>(_onDuration);
    on<FocusTimerStarted>(_onStartTimer);
    on<FocusTimerPaused>(_onPause);
    on<FocusTimerResumed>(_onResume);
    on<FocusTimerReset>(_onReset);
    on<FocusTick>(_onTick);
    on<FocusTimerFinished>(_onFinished);
  }

  final SettingsRepository _settings;
  final SaveFocusSession _saveFocusSession;
  final GetTodayFocusMinutes _getTodayFocusMinutes;
  final FocusLiveActivityService _liveActivity;
  final PulseHomeWidgetSync _homeWidgetSync;
  final _uuid = const Uuid();
  Timer? _timer;

  Future<void> _onStarted(FocusStarted event, Emitter<FocusState> emit) async {
    await _liveActivity.init();
    final today = await _getTodayFocusMinutes();
    // Don't wipe an in-progress or just-finished session (e.g. tab revisit).
    if (state.isRunning ||
        state.isCompleted ||
        state.sessionStartedAt != null) {
      emit(state.copyWith(todayMinutes: today));
      return;
    }
    final seconds = state.mode == FocusMode.pomodoro
        ? _settings.workMinutes * 60
        : 60 * 60;
    emit(
      state.copyWith(
        totalSeconds: seconds,
        remainingSeconds: seconds,
        elapsedSeconds: 0,
        todayMinutes: today,
        isRunning: false,
        isCompleted: false,
        clearSession: true,
      ),
    );
  }

  Future<void> _onMode(FocusModeChanged event, Emitter<FocusState> emit) async {
    _timer?.cancel();
    await _liveActivity.end();
    final seconds = event.mode == FocusMode.pomodoro
        ? _settings.workMinutes * 60
        : 60 * 60;
    emit(
      state.copyWith(
        mode: event.mode,
        totalSeconds: seconds,
        remainingSeconds: seconds,
        elapsedSeconds: 0,
        isRunning: false,
        isCompleted: false,
        clearSession: true,
      ),
    );
  }

  Future<void> _onDuration(
    FocusDurationChanged event,
    Emitter<FocusState> emit,
  ) async {
    if (state.isRunning || state.sessionStartedAt != null) return;
    final minutes = event.minutes.clamp(1, 120);
    await _settings.setWorkMinutes(minutes);
    if (state.mode != FocusMode.pomodoro) return;
    final seconds = minutes * 60;
    emit(
      state.copyWith(
        totalSeconds: seconds,
        remainingSeconds: seconds,
        elapsedSeconds: 0,
        isCompleted: false,
        clearSession: true,
      ),
    );
  }

  Future<void> _onStartTimer(
    FocusTimerStarted event,
    Emitter<FocusState> emit,
  ) async {
    if (_settings.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    emit(
      state.copyWith(
        isRunning: true,
        isCompleted: false,
        elapsedSeconds: 0,
        sessionStartedAt: DateTime.now(),
      ),
    );
    await _liveActivity.start(
      modeLabel: state.modeLabel,
      remainingSeconds: state.remainingSeconds,
      totalSeconds: state.totalSeconds,
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const FocusTick());
    });
  }

  Future<void> _onPause(
    FocusTimerPaused event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    emit(state.copyWith(isRunning: false));
    await _liveActivity.update(
      modeLabel: state.modeLabel,
      remainingSeconds: state.remainingSeconds,
      totalSeconds: state.totalSeconds,
      isPaused: true,
    );
  }

  Future<void> _onResume(
    FocusTimerResumed event,
    Emitter<FocusState> emit,
  ) async {
    emit(state.copyWith(isRunning: true));
    await _liveActivity.update(
      modeLabel: state.modeLabel,
      remainingSeconds: state.remainingSeconds,
      totalSeconds: state.totalSeconds,
      isPaused: false,
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const FocusTick());
    });
  }

  Future<void> _onReset(
    FocusTimerReset event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    await _liveActivity.end();
    emit(
      state.copyWith(
        remainingSeconds: state.totalSeconds,
        elapsedSeconds: 0,
        isRunning: false,
        isCompleted: false,
        clearSession: true,
      ),
    );
  }

  Future<void> _onTick(FocusTick event, Emitter<FocusState> emit) async {
    if (!state.isRunning) return;
    if (state.remainingSeconds <= 1) {
      _timer?.cancel();
      add(const FocusTimerFinished());
      return;
    }
    final next = state.remainingSeconds - 1;
    emit(state.copyWith(remainingSeconds: next));
    await _liveActivity.update(
      modeLabel: state.modeLabel,
      remainingSeconds: next,
      totalSeconds: state.totalSeconds,
      isPaused: false,
    );
  }

  Future<void> _onFinished(
    FocusTimerFinished event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    await _liveActivity.end();
    if (_settings.hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
    // Timer-based elapsed excludes paused time; clamp to planned length.
    final fromTimer =
        (state.totalSeconds - state.remainingSeconds).clamp(0, state.totalSeconds);
    // Natural end (≤1s left) counts as the full planned block.
    final actual =
        state.remainingSeconds <= 1 ? state.totalSeconds : fromTimer;
    final started = state.sessionStartedAt ?? DateTime.now();
    await _saveFocusSession(
      FocusSession(
        id: _uuid.v4(),
        plannedSeconds: state.totalSeconds,
        completedSeconds: actual,
        mode: state.mode.name,
        completed: true,
        startedAt: started,
        endedAt: DateTime.now(),
      ),
    );
    final today = await _getTodayFocusMinutes();
    emit(
      state.copyWith(
        remainingSeconds: 0,
        elapsedSeconds: actual,
        isRunning: false,
        isCompleted: true,
        todayMinutes: today,
      ),
    );
    await _homeWidgetSync.sync();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _liveActivity.end();
    return super.close();
  }
}
