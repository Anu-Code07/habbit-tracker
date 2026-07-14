import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Schedules OS-level focus alerts that still fire when Flutter is suspended.
///
/// - Android: AlarmManager → notification with custom WAV
/// - iOS: UNUserNotificationCenter time-sensitive local notifications
///
/// Per-second warning *ticks* play via [FocusTimerSounds] while Flutter is
/// alive, and are also scheduled here (Android MediaPlayer / iOS local notifs)
/// so they still fire when the process is suspended.
abstract final class FocusBackgroundAlerts {
  static const _channel = MethodChannel('pulse/focus_alerts');
  static const _actions = EventChannel('pulse/focus_actions');

  static StreamSubscription<dynamic>? _actionSub;
  static final _actionController = StreamController<String>.broadcast();

  static Stream<String> get androidActions => _actionController.stream;

  static Future<void> listenAndroidActions() async {
    if (!Platform.isAndroid || _actionSub != null) return;
    _actionSub = _actions.receiveBroadcastStream().listen((event) {
      if (event is String && event.isNotEmpty) {
        _actionController.add(event);
      }
    }, onError: (Object e) {
      debugPrint('FocusBackgroundAlerts action stream error: $e');
    });
  }

  static Future<void> schedule({
    required int remainingSeconds,
    required DateTime? endsAt,
    required String quote,
    required bool paused,
    bool warningEnabled = true,
    bool ticksEnabled = true,
    bool completionEnabled = true,
  }) async {
    if (kIsWeb) return;
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    try {
      await _channel.invokeMethod<void>('schedule', {
        'remainingSeconds': remainingSeconds,
        'endAtMs': endsAt?.millisecondsSinceEpoch,
        'quote': quote,
        'paused': paused,
        'warningEnabled': warningEnabled,
        'ticksEnabled': ticksEnabled,
        'completionEnabled': completionEnabled,
      });
    } catch (error, stack) {
      debugPrint('FocusBackgroundAlerts schedule failed: $error\n$stack');
    }
  }

  static Future<void> cancel() async {
    if (kIsWeb) return;
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (error, stack) {
      debugPrint('FocusBackgroundAlerts cancel failed: $error\n$stack');
    }
  }
}
