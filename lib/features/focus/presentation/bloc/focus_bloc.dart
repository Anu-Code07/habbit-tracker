import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_activities/models/alert_config.dart';
import 'package:uuid/uuid.dart';

import 'package:pulse/features/focus/data/focus_live_activity_service.dart';
import 'package:pulse/features/focus/data/focus_timer_sounds.dart';
import 'package:pulse/features/focus/domain/entities/focus_session.dart';
import 'package:pulse/features/focus/domain/focus_quotes.dart';
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
    this.sessionQuote,
  });

  final FocusMode mode;
  final int totalSeconds;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isRunning;
  final bool isCompleted;
  final int todayMinutes;
  final DateTime? sessionStartedAt;
  final String? sessionQuote;

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
    String? sessionQuote,
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
      sessionQuote: clearSession ? null : (sessionQuote ?? this.sessionQuote),
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
        sessionQuote,
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
    _liveActionSub = _liveActivity.actions.listen(_onLiveAction);
  }

  final SettingsRepository _settings;
  final SaveFocusSession _saveFocusSession;
  final GetTodayFocusMinutes _getTodayFocusMinutes;
  final FocusLiveActivityService _liveActivity;
  final PulseHomeWidgetSync _homeWidgetSync;
  final _uuid = const Uuid();
  Timer? _timer;
  StreamSubscription<FocusLiveAction>? _liveActionSub;
  bool _didWarnTenSeconds = false;

  /// Shared wall-clock deadline for the in-app timer and Live Activity.
  DateTime? _segmentEndsAt;
  int _lastAnnouncedSecond = -1;

  void _onLiveAction(FocusLiveAction action) {
    switch (action) {
      case FocusLiveAction.pause:
        if (state.isRunning) add(const FocusTimerPaused());
      case FocusLiveAction.resume:
        if (!state.isRunning &&
            state.sessionStartedAt != null &&
            !state.isCompleted) {
          add(const FocusTimerResumed());
        }
      case FocusLiveAction.finish:
        if (state.sessionStartedAt != null && !state.isCompleted) {
          add(const FocusTimerFinished());
        }
    }
  }

  int _remainingFromDeadline() {
    final endsAt = _segmentEndsAt;
    if (endsAt == null) return state.remainingSeconds;
    final ms =
        endsAt.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (ms <= 0) return 0;
    // Floor to whole seconds — matches Live Activity timerInterval display.
    return ms ~/ 1000;
  }

  void _startTicker() {
    _timer?.cancel();
    // Sub-second polling keeps the UI aligned with the Live Activity clock.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      add(const FocusTick());
    });
  }

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
    _segmentEndsAt = null;
    _didWarnTenSeconds = false;
    _lastAnnouncedSecond = -1;
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
    _didWarnTenSeconds = false;
    _lastAnnouncedSecond = -1;
    final quote = PulseFocusQuotes.next();
    final remaining = state.remainingSeconds;
    final endsAt = DateTime.now().add(Duration(seconds: remaining));
    _segmentEndsAt = endsAt;
    emit(
      state.copyWith(
        isRunning: true,
        isCompleted: false,
        elapsedSeconds: 0,
        remainingSeconds: remaining,
        sessionStartedAt: DateTime.now(),
        sessionQuote: quote,
      ),
    );
    // Activate the audio session early so warning/completion chimes are heard.
    await FocusTimerSounds.warmUp();
    await _liveActivity.start(
      quote: quote,
      remainingSeconds: remaining,
      totalSeconds: state.totalSeconds,
      endsAt: endsAt,
    );
    _startTicker();
  }

  Future<void> _onPause(
    FocusTimerPaused event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    final remaining = _remainingFromDeadline().clamp(0, state.totalSeconds);
    _segmentEndsAt = null;
    emit(state.copyWith(isRunning: false, remainingSeconds: remaining));
    await _liveActivity.update(
      quote: state.sessionQuote ?? 'Stay with it',
      remainingSeconds: remaining,
      totalSeconds: state.totalSeconds,
      isPaused: true,
    );
  }

  Future<void> _onResume(
    FocusTimerResumed event,
    Emitter<FocusState> emit,
  ) async {
    final remaining = state.remainingSeconds.clamp(0, state.totalSeconds);
    final endsAt = DateTime.now().add(Duration(seconds: remaining));
    _segmentEndsAt = endsAt;
    _lastAnnouncedSecond = -1;
    emit(state.copyWith(isRunning: true, remainingSeconds: remaining));
    await _liveActivity.update(
      quote: state.sessionQuote ?? 'Stay with it',
      remainingSeconds: remaining,
      totalSeconds: state.totalSeconds,
      isPaused: false,
      endsAt: endsAt,
    );
    _startTicker();
  }

  Future<void> _onReset(
    FocusTimerReset event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    _segmentEndsAt = null;
    _didWarnTenSeconds = false;
    _lastAnnouncedSecond = -1;
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
    if (!state.isRunning || _segmentEndsAt == null) return;

    final remaining = _remainingFromDeadline().clamp(0, state.totalSeconds);
    if (remaining <= 0) {
      _timer?.cancel();
      _segmentEndsAt = null;
      add(const FocusTimerFinished());
      return;
    }

    if (remaining != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: remaining));
    }

    // Fire second-boundary cues once per displayed second.
    if (remaining == _lastAnnouncedSecond) return;
    _lastAnnouncedSecond = remaining;

    // Don't await here — overlapping ticks would desync the UI clock.
    unawaited(_announceSecond(remaining));
  }

  Future<void> _announceSecond(int remaining) async {
    AlertConfig? islandAlert;
    var shouldPushLiveActivity = false;

    if (remaining == 10 || (remaining < 10 && !_didWarnTenSeconds)) {
      _didWarnTenSeconds = true;
      shouldPushLiveActivity = true;
      if (_settings.warningSoundEnabled) {
        islandAlert = AlertConfig(
          title: 'Almost done',
          body: '10 seconds left',
        );
        await FocusTimerSounds.warningAlert();
      }
      if (_settings.hapticsEnabled) {
        await HapticFeedback.mediumImpact();
      }
    } else if (remaining < 10) {
      if (_settings.focusTickSoundEnabled) {
        await FocusTimerSounds.warningTick();
      }
      if (_settings.hapticsEnabled) {
        await HapticFeedback.selectionClick();
      }
    }

    // Only refresh Live Activity when entering the warning window.
    // Rewriting endAtMs every tick was the main source of desync.
    if (shouldPushLiveActivity) {
      await _liveActivity.update(
        quote: state.sessionQuote ?? 'Stay with it',
        remainingSeconds: remaining,
        totalSeconds: state.totalSeconds,
        isPaused: false,
        endsAt: _segmentEndsAt,
        alert: islandAlert,
      );
    }
  }

  Future<void> _onFinished(
    FocusTimerFinished event,
    Emitter<FocusState> emit,
  ) async {
    _timer?.cancel();
    _segmentEndsAt = null;
    _lastAnnouncedSecond = -1;
    if (_settings.completionSoundEnabled) {
      await FocusTimerSounds.completed();
    }
    if (_settings.hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
    await _liveActivity.end(
      quote: state.sessionQuote,
      completionAlert: _settings.completionSoundEnabled
          ? AlertConfig(
              title: 'Focus complete',
              body: state.sessionQuote ?? 'Nice work — session finished',
            )
          : null,
    );
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
    _segmentEndsAt = null;
    await _liveActionSub?.cancel();
    await _liveActivity.end();
    return super.close();
  }
}
