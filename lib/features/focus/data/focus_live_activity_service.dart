import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/alert_config.dart';
import 'package:permission_handler/permission_handler.dart';

enum FocusLiveAction { pause, resume, finish }

class FocusLiveActivityService {
  FocusLiveActivityService();

  static const appGroupId = 'group.com.anurag.pulse';
  static const activityId = 'pulse_focus';

  final LiveActivities _plugin = LiveActivities();
  final _actionsController = StreamController<FocusLiveAction>.broadcast();
  StreamSubscription<dynamic>? _urlSub;

  bool _initialized = false;
  bool _active = false;

  /// ActivityKit system id — required by [LiveActivities.updateActivity].
  String? _systemActivityId;

  Stream<FocusLiveAction> get actions => _actionsController.stream;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!(Platform.isIOS || Platform.isAndroid)) return;

    try {
      await _plugin.init(
        appGroupId: appGroupId,
        urlScheme: 'pulse',
      );
      _listenUrlActions();
      _initialized = true;
    } catch (error, stack) {
      debugPrint('FocusLiveActivity init failed: $error\n$stack');
      _initialized = false;
    }
  }

  void _listenUrlActions() {
    if (_urlSub != null) return;
    if (!Platform.isIOS) return;

    _urlSub = _plugin.urlSchemeStream().listen((data) {
      final path = (data.path ?? '').toLowerCase().replaceAll('/', '');
      final host = (data.host ?? '').toLowerCase();
      final url = (data.url ?? '').toLowerCase();
      final token = path.isNotEmpty
          ? path
          : (url.contains('/') ? url.split('/').last : '');

      final action = switch (token.isNotEmpty ? token : host) {
        'pause' => FocusLiveAction.pause,
        'resume' => FocusLiveAction.resume,
        'finish' || 'stop' => FocusLiveAction.finish,
        _ when url.contains('focus/pause') => FocusLiveAction.pause,
        _ when url.contains('focus/resume') => FocusLiveAction.resume,
        _ when url.contains('focus/finish') || url.contains('focus/stop') =>
          FocusLiveAction.finish,
        _ => null,
      };

      if (action != null) {
        debugPrint('FocusLiveActivity action from Live Activity: $action');
        _actionsController.add(action);
      }
    }, onError: (Object error) {
      debugPrint('FocusLiveActivity url scheme error: $error');
    });
  }

  Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Map<String, dynamic> _payload({
    required String quote,
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
    DateTime? endsAt,
    bool alertSound = false,
    String? alertTitle,
    String? alertBody,
  }) {
    final safeRemaining = remainingSeconds.clamp(0, totalSeconds);
    final m = safeRemaining ~/ 60;
    final s = safeRemaining % 60;
    final remainingLabel =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final progress =
        totalSeconds == 0 ? 0.0 : 1 - (safeRemaining / totalSeconds);
    // Prefer a stable wall-clock deadline so Live Activity and the app stay aligned.
    final endAt = isPaused
        ? 0
        : (endsAt ??
                DateTime.now().add(Duration(seconds: safeRemaining)))
            .millisecondsSinceEpoch;

    return <String, dynamic>{
      'title': 'Pulse Focus',
      'subtitle': quote,
      'quote': quote,
      'remainingLabel': remainingLabel,
      'remainingSeconds': safeRemaining,
      'totalSeconds': totalSeconds,
      'progress': progress,
      'status': isPaused ? 'paused' : 'running',
      'endAtMs': endAt,
      // Android Live Activity updates ignore AlertConfig; flag the payload so
      // CustomLiveActivityManager can use a sounding notification channel.
      'alertSound': alertSound,
      if (alertTitle != null) 'alertTitle': alertTitle,
      if (alertBody != null) 'alertBody': alertBody,
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
    required String quote,
    required int remainingSeconds,
    required int totalSeconds,
    required DateTime endsAt,
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
      quote: quote,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
      endsAt: endsAt,
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
            body: quote,
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
    required String quote,
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
    DateTime? endsAt,
    AlertConfig? alert,
  }) async {
    if (!_active) return;

    final data = _payload(
      quote: quote,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: isPaused,
      endsAt: endsAt,
      alertSound: alert != null,
      alertTitle: alert?.title,
      alertBody: alert?.body,
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

  Future<void> end({AlertConfig? completionAlert, String? quote}) async {
    if (!_active && _systemActivityId == null) return;

    try {
      if (completionAlert != null) {
        await _resolveSystemActivityId();
        final systemId = _systemActivityId;
        if (systemId != null) {
          await _plugin.updateActivity(
            systemId,
            _payload(
              quote: quote ?? 'Session complete',
              remainingSeconds: 0,
              totalSeconds: 1,
              isPaused: false,
              endsAt: DateTime.now(),
              alertSound: true,
              alertTitle: completionAlert.title,
              alertBody: completionAlert.body,
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

  Future<void> dispose() async {
    await _urlSub?.cancel();
    _urlSub = null;
    await _actionsController.close();
  }
}
