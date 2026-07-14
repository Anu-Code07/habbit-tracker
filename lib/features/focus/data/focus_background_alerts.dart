import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Schedules OS-level focus alerts that still fire when Flutter is suspended.
///
/// - Android: AlarmManager + MediaPlayer for warn/complete
/// - iOS: UNUserNotificationCenter + optional AVAudioPlayer
/// - Per-second ticks are owned by Flutter [FocusTimerSounds] while the app
///   ticker is alive.
abstract final class FocusBackgroundAlerts {
  static const _channel = MethodChannel('pulse/focus_alerts');
  static const _actions = EventChannel('pulse/focus_actions');

  static StreamSubscription<dynamic>? _actionSub;
  static final _actionController = StreamController<String>.broadcast();
  /// Emits whether Flutter should play the completion pack chime.
  static final _nativeCompleteController = StreamController<bool>.broadcast();
  static bool _handlerInstalled = false;

  static Stream<String> get androidActions => _actionController.stream;

  /// Fired when iOS dismisses the Live Activity at session end.
  /// Value is `true` when Flutter should play the completion sound.
  static Stream<bool> get nativeCompletes => _nativeCompleteController.stream;

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

  /// Lets AppDelegate invoke `focusNativeComplete` when the LA should dismiss.
  static void ensureNativeCompleteHandler() {
    if (_handlerInstalled) return;
    if (kIsWeb || !Platform.isIOS) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'focusNativeComplete') {
        if (_nativeCompleteController.isClosed) return;
        final args = call.arguments;
        var nativePlayed = false;
        if (args is Map) {
          nativePlayed = args['nativePlayed'] == true;
        }
        // If native already chimed, Flutter must not replay.
        _nativeCompleteController.add(!nativePlayed);
      }
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
    String soundPack = 'soft',
  }) async {
    if (kIsWeb) return;
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    ensureNativeCompleteHandler();
    try {
      await _channel.invokeMethod<void>('schedule', {
        'remainingSeconds': remainingSeconds,
        'endAtMs': endsAt?.millisecondsSinceEpoch,
        'quote': quote,
        'paused': paused,
        'warningEnabled': warningEnabled,
        'ticksEnabled': ticksEnabled,
        'completionEnabled': completionEnabled,
        'soundPack': soundPack,
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
