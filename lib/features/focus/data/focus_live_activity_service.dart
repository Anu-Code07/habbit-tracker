import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:permission_handler/permission_handler.dart';

class FocusLiveActivityService {
  FocusLiveActivityService();

  static const appGroupId = 'group.com.pulse.pulse';
  static const activityId = 'pulse_focus';

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;
  bool _active = false;

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
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
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
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    final remainingLabel =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final progress =
        totalSeconds == 0 ? 0.0 : 1 - (remainingSeconds / totalSeconds);
    final endAt = DateTime.now()
        .add(Duration(seconds: isPaused ? 0 : remainingSeconds))
        .millisecondsSinceEpoch;

    return <String, dynamic>{
      'title': 'Pulse Focus',
      'subtitle': modeLabel,
      'remainingLabel': remainingLabel,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'progress': progress,
      'status': isPaused ? 'paused' : 'running',
      'endAtMs': endAt,
    };
  }

  Future<void> start({
    required String modeLabel,
    required int remainingSeconds,
    required int totalSeconds,
  }) async {
    await init();
    if (!_initialized) return;
    await _ensureNotificationPermission();

    final enabled = await _plugin.areActivitiesEnabled();
    if (!enabled) return;

    final data = _payload(
      modeLabel: modeLabel,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: false,
    );

    try {
      await _plugin.createOrUpdateActivity(
        activityId,
        data,
        removeWhenAppIsKilled: false,
        staleIn: Duration(seconds: totalSeconds + 120),
      );
      _active = true;
    } catch (_) {
      _active = false;
    }
  }

  Future<void> update({
    required String modeLabel,
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
  }) async {
    if (!_active) return;

    final data = _payload(
      modeLabel: modeLabel,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      isPaused: isPaused,
    );

    try {
      await _plugin.updateActivity(activityId, data);
    } catch (_) {}
  }

  Future<void> end() async {
    if (!_active) return;
    try {
      await _plugin.endActivity(activityId);
    } catch (_) {}
    _active = false;
  }
}
