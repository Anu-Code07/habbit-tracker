import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulse/features/settings/domain/focus_sound_pack.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingKey = 'onboarding_complete';
  static const _hapticsKey = 'haptics_enabled';
  static const _legacyTimerSoundsKey = 'timer_sounds_enabled';
  static const _completionSoundKey = 'completion_sound_enabled';
  static const _warningSoundKey = 'warning_sound_enabled';
  static const _focusTickSoundKey = 'focus_tick_sound_enabled';
  static const _soundPackKey = 'focus_sound_pack';
  static const _workMinutesKey = 'work_minutes';
  static const _freeMinutesKey = 'free_minutes';
  static const _breakMinutesKey = 'break_minutes';
  static const _userNameKey = 'user_name';

  bool get isOnboardingComplete => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;

  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_hapticsKey, value);

  /// Falls back to the old combined timer-sounds flag when unset.
  bool _soundFlag(String key) {
    final value = _prefs.getBool(key);
    if (value != null) return value;
    return _prefs.getBool(_legacyTimerSoundsKey) ?? true;
  }

  bool get completionSoundEnabled => _soundFlag(_completionSoundKey);

  Future<void> setCompletionSoundEnabled(bool value) =>
      _prefs.setBool(_completionSoundKey, value);

  bool get warningSoundEnabled => _soundFlag(_warningSoundKey);

  Future<void> setWarningSoundEnabled(bool value) =>
      _prefs.setBool(_warningSoundKey, value);

  bool get focusTickSoundEnabled => _soundFlag(_focusTickSoundKey);

  Future<void> setFocusTickSoundEnabled(bool value) =>
      _prefs.setBool(_focusTickSoundKey, value);

  FocusSoundPack get soundPack =>
      FocusSoundPack.fromStorage(_prefs.getString(_soundPackKey));

  Future<void> setSoundPack(FocusSoundPack pack) =>
      _prefs.setString(_soundPackKey, pack.storageValue);

  /// Pomodoro length in minutes. Special case: `1` means a 60-second sprint.
  int get workMinutes => _prefs.getInt(_workMinutesKey) ?? 25;

  Future<void> setWorkMinutes(int value) =>
      _prefs.setInt(_workMinutesKey, value);

  /// Free-focus length in minutes (default one quiet hour).
  int get freeMinutes => _prefs.getInt(_freeMinutesKey) ?? 60;

  Future<void> setFreeMinutes(int value) =>
      _prefs.setInt(_freeMinutesKey, value);

  int get breakMinutes => _prefs.getInt(_breakMinutesKey) ?? 5;

  Future<void> setBreakMinutes(int value) =>
      _prefs.setInt(_breakMinutesKey, value);

  String get userName => (_prefs.getString(_userNameKey) ?? '').trim();

  Future<void> setUserName(String value) =>
      _prefs.setString(_userNameKey, value.trim());

  Future<void> resetFlags() async {
    await _prefs.remove(_onboardingKey);
    await _prefs.remove(_userNameKey);
  }

  Map<String, dynamic> exportMap() => {
        'onboardingComplete': isOnboardingComplete,
        'hapticsEnabled': hapticsEnabled,
        'completionSoundEnabled': completionSoundEnabled,
        'warningSoundEnabled': warningSoundEnabled,
        'focusTickSoundEnabled': focusTickSoundEnabled,
        'soundPack': soundPack.storageValue,
        'workMinutes': workMinutes,
        'freeMinutes': freeMinutes,
        'breakMinutes': breakMinutes,
        'userName': userName,
      };

  Future<void> importMap(Map<String, dynamic> map) async {
    final onboarding = map['onboardingComplete'];
    if (onboarding is bool) {
      await setOnboardingComplete(onboarding);
    }
    final haptics = map['hapticsEnabled'];
    if (haptics is bool) {
      await setHapticsEnabled(haptics);
    }
    final completionSound = map['completionSoundEnabled'];
    if (completionSound is bool) {
      await setCompletionSoundEnabled(completionSound);
    }
    final warningSound = map['warningSoundEnabled'];
    if (warningSound is bool) {
      await setWarningSoundEnabled(warningSound);
    }
    final tickSound = map['focusTickSoundEnabled'];
    if (tickSound is bool) {
      await setFocusTickSoundEnabled(tickSound);
    }
    final pack = map['soundPack'];
    if (pack is String) {
      await setSoundPack(FocusSoundPack.fromStorage(pack));
    }
    // Older backups used a single timerSoundsEnabled flag.
    final legacySounds = map['timerSoundsEnabled'];
    if (legacySounds is bool &&
        completionSound is! bool &&
        warningSound is! bool &&
        tickSound is! bool) {
      await setCompletionSoundEnabled(legacySounds);
      await setWarningSoundEnabled(legacySounds);
      await setFocusTickSoundEnabled(legacySounds);
    }
    final work = map['workMinutes'];
    if (work is int) {
      await setWorkMinutes(work);
    }
    final free = map['freeMinutes'];
    if (free is int) {
      await setFreeMinutes(free);
    }
    final breakMins = map['breakMinutes'];
    if (breakMins is int) {
      await setBreakMinutes(breakMins);
    }
    final name = map['userName'];
    if (name is String) {
      await setUserName(name);
    }
  }
}
