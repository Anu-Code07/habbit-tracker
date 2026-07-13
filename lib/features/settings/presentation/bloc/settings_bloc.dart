import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulse/core/database/pulse_backup_service.dart';
import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsHapticsChanged extends SettingsEvent {
  const SettingsHapticsChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

class SettingsDataReset extends SettingsEvent {
  const SettingsDataReset();
}

class SettingsBackupExportRequested extends SettingsEvent {
  const SettingsBackupExportRequested();
}

class SettingsBackupImportRequested extends SettingsEvent {
  const SettingsBackupImportRequested();
}

class SettingsState extends Equatable {
  const SettingsState({
    this.hapticsEnabled = true,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.resetDone = false,
    this.importDone = false,
    this.busy = false,
    this.message,
  });

  final bool hapticsEnabled;
  final int workMinutes;
  final int breakMinutes;
  final bool resetDone;
  final bool importDone;
  final bool busy;
  final String? message;

  SettingsState copyWith({
    bool? hapticsEnabled,
    int? workMinutes,
    int? breakMinutes,
    bool? resetDone,
    bool? importDone,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return SettingsState(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      resetDone: resetDone ?? this.resetDone,
      importDone: importDone ?? this.importDone,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        hapticsEnabled,
        workMinutes,
        breakMinutes,
        resetDone,
        importDone,
        busy,
        message,
      ];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required SettingsRepository settingsRepository,
    required ClearHabitData clearHabitData,
    required ClearFocusData clearFocusData,
    required PulseBackupService backupService,
  })  : _settings = settingsRepository,
        _clearHabitData = clearHabitData,
        _clearFocusData = clearFocusData,
        _backup = backupService,
        super(const SettingsState()) {
    on<SettingsStarted>((_, emit) {
      emit(
        SettingsState(
          hapticsEnabled: _settings.hapticsEnabled,
          workMinutes: _settings.workMinutes,
          breakMinutes: _settings.breakMinutes,
        ),
      );
    });
    on<SettingsHapticsChanged>((e, emit) async {
      await _settings.setHapticsEnabled(e.enabled);
      emit(state.copyWith(hapticsEnabled: e.enabled));
    });
    on<SettingsDataReset>((_, emit) async {
      await _clearHabitData();
      await _clearFocusData();
      await _settings.resetFlags();
      emit(state.copyWith(resetDone: true));
    });
    on<SettingsBackupExportRequested>((_, emit) async {
      emit(state.copyWith(busy: true, clearMessage: true));
      try {
        await _backup.exportBackup();
        emit(
          state.copyWith(
            busy: false,
            message: 'Backup ready — save it somewhere safe.',
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            busy: false,
            message: 'Couldn’t export backup. Try again.',
          ),
        );
      }
    });
    on<SettingsBackupImportRequested>((_, emit) async {
      emit(state.copyWith(busy: true, clearMessage: true));
      try {
        final restored = await _backup.importBackup();
        if (!restored) {
          emit(state.copyWith(busy: false, clearMessage: true));
          return;
        }
        emit(
          SettingsState(
            hapticsEnabled: _settings.hapticsEnabled,
            workMinutes: _settings.workMinutes,
            breakMinutes: _settings.breakMinutes,
            importDone: true,
            message: 'Backup restored.',
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            busy: false,
            message: 'Couldn’t restore that backup.',
          ),
        );
      }
    });
  }

  final SettingsRepository _settings;
  final ClearHabitData _clearHabitData;
  final ClearFocusData _clearFocusData;
  final PulseBackupService _backup;
}
