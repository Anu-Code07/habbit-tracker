import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/alert_config.dart';
import 'package:permission_handler/permission_handler.dart';

class FocusLiveActivityService {
  FocusLiveActivityService();

  static const appGroupId = 'group.com.anurag.pulse';
  static const activityId = 'pulse_focus';

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;
  bool _active = false;

  /// ActivityKit system id — required by [LiveActivities.updateActivity].
  String? _systemActivityId;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!(Platform.isIOS || Platform.isAndroid)) return;

    try {
      await _plugin.init(
        appGroupId: appGroupId,
        urlScheme: 'pulse',
      );
      _initialized = true;
    } catch (error, stack) {
      debugPrint('FocusLiveActivity init failed: $error\n$stack');
      _initialized = false;
    }
  }

  Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Map<String, dynamic> _payload({
    required String modeLabel,
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
  }) {
    final safeRemaining = remainingSeconds.clamp(0, totalSeconds);
    final m = safeRemaining ~/ 60;
    final s = safeRemaining % 60;
    final remainingLabel =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final progress =
        totalSeconds == 0 ? 0.0 : 1 - (safeRemaining / totalSeconds);
    final endAt = isPaused
        ? 0
        : DateTime.now()
            .add(Duration(seconds: safeRemaining))
            .millisecondsSinceEpoch;

    return <String, dynamic>{
      'title': 'Pulse Focus',
      'subtitle': modeLabel,
      'remainingLabel': remainingLabel,
      'remainingSeconds': safeRemaining,
      'totalSeconds': totalSeconds,
      'progress': progress,
      'status': isPaused ? 'paused' : 'running',
      'endAtMs': endAt,
    };
  }

  Duration _staleIn(int totalSeconds) {
    final minutes = ((totalSeconds + 120) / 60).ceil().clamp(1, 24 * 60);
    return Duration(minutes: minutes);
  }

  Future<void> _resolveSystemActivityId() async {
    if (_systemActivityId != null) return;
    try {
      final ids = await _plugin.getAllActivitiesIds();
      if (ids.isNotEmpty) {
        _systemActivityId = ids.first;
      }
    } catch (error) {
      debugPrint('FocusLiveActivity resolve id failed: $error');
    }
  }

  Future<void> _clearExisting() async {
    try {
      if (_systemActivityId != null) {
        await _plugin.endActivity(_systemActivityId!);
      }
      await _plugin.endActivity(activityId);
    } catch (_) {
      // Best-effort cleanup before a fresh Dynamic Island session.
    }
    _systemActivityId = null;
    _active = false;
  }

  /// Starts (or restarts) the focus Live Activity so Dynamic Island shows
  /// the timer as soon as the session begins.
  Future<void> start({
    required String modeLabel,
    required int remainingSeconds,
    required int totalSeconds,
  }) async {
    await init();
    if (!_initialized) return;
    await _ensureNotificationPermission();

    final supported = await _plugin.areActivitiesSupported();
    if (!supported) {
      debugPrint('FocusLiveActivity: not supported on this device/OS');
      return;
    }

    final enabled = await _plugin.areActivitiesEnabled();
    if (!enabled) {
      debugPrint(
        'FocusLiveActivity: disabled in Settings → Pulse → Live Activities',
      );
      return;
    }

    await _clearExisting();

    final data = _payload(
      modeLabel: modeLabel,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );

    try {
      // createActivity returns the ActivityKit id and always opens a new LA.
      final created = await _plugin.createActivity(
        activityId,
        data,
        removeWhenAppIsKilled: false,
        staleIn: _staleIn(totalSeconds),
      );

      if (created is String && created.isNotEmpty) {
        _systemActivityId = created;
      } else {
        await _resolveSystemActivityId();
      }

      _active = true;
      debugPrint(
        'FocusLiveActivity started on Dynamic Island id=$_systemActivityId',
      );

      // Brief island presentation so the timer is obvious at session start.
      final systemId = _systemActivityId;
      if (systemId != null) {
        await _plugin.updateActivity(
          systemId,
          data,
          AlertConfig(
            title: 'Pulse Focus',
            body: '$modeLabel · ${remainingLabel(remainingSeconds)}',
          ),
        );
      }
    } catch (error, stack) {
      debugPrint('FocusLiveActivity start failed: $error\n$stack');
      // Fallback if createActivity failed after a partial create.
      try {
        final created = await _plugin.createOrUpdateActivity(
          activityId,
          data,
          removeWhenAppIsKilled: false,
          staleIn: _staleIn(totalSeconds),
        );
        if (created is String && created.isNotEmpty) {
          _systemActivityId = created;
        }
        await _resolveSystemActivityId();
        _active = true;
      } catch (fallbackError) {
        debugPrint('FocusLiveActivity fallback failed: $fallbackError');
        _active = false;
        _systemActivityId = null;
      }
    }
  }

  String remainingLabel(int remainingSeconds) {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> update({
    required String modeLabel,
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
    AlertConfig? alert,
  }) async {
    if (!_active) return;

    final data = _payload(
      modeLabel: modeLabel,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: isPaused,
    );

    try {
      await _resolveSystemActivityId();
      final systemId = _systemActivityId;
      if (systemId != null) {
        await _plugin.updateActivity(systemId, data, alert);
      } else {
        await _plugin.createOrUpdateActivity(
          activityId,
          data,
          removeWhenAppIsKilled: false,
          staleIn: _staleIn(totalSeconds),
        );
        await _resolveSystemActivityId();
        final resolved = _systemActivityId;
        if (resolved != null && alert != null) {
          await _plugin.updateActivity(resolved, data, alert);
        }
      }
    } catch (error) {
      debugPrint('FocusLiveActivity update failed: $error');
    }
  }

  Future<void> end({AlertConfig? completionAlert}) async {
    if (!_active && _systemActivityId == null) return;

    try {
      if (completionAlert != null) {
        await _resolveSystemActivityId();
        final systemId = _systemActivityId;
        if (systemId != null) {
          await _plugin.updateActivity(
            systemId,
            _payload(
              modeLabel: 'Done',
              remainingSeconds: 0,
              totalSeconds: 1,
              isPaused: false,
            ),
            completionAlert,
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
      if (_systemActivityId != null) {
        await _plugin.endActivity(_systemActivityId!);
      }
      await _plugin.endActivity(activityId);
    } catch (error) {
      debugPrint('FocusLiveActivity end failed: $error');
    }

    _active = false;
    _systemActivityId = null;
  }
}

/// Short device sounds for focus countdown / completion.
abstract final class FocusTimerSounds {
  static Future<void> warningTick() async {
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> warningAlert() async {
    await SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> completed() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await SystemSound.play(SystemSoundType.alert);
  }
}
