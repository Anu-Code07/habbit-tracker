import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Pleasant Kenney UI chimes for focus countdown / completion.
abstract final class FocusTimerSounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool _configured = false;

  static AudioContext get _alarmContext => AudioContext(
        iOS: AudioContextIOS(
          // playback ignores the Ring/Silent switch; speaker so it isn't
          // routed quietly to the earpiece.
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );

  static Future<void> warmUp() async {
    await _ensureConfigured();
  }

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await AudioPlayer.global.setAudioContext(_alarmContext);
      await _player.setAudioContext(_alarmContext);
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1);
      _configured = true;
    } catch (error, stack) {
      debugPrint('FocusTimerSounds configure failed: $error\n$stack');
    }
  }

  static Future<void> _play(
    String assetPath, {
    bool waitUntilDone = false,
  }) async {
    try {
      await _ensureConfigured();
      // Re-assert context in case another plugin changed the session.
      await _player.setAudioContext(_alarmContext);
      await _player.stop();
      await _player.setVolume(1);
      await _player.play(AssetSource(assetPath));
      if (waitUntilDone) {
        await _player.onPlayerComplete.first.timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      }
    } catch (error, stack) {
      debugPrint('FocusTimerSounds failed ($assetPath): $error\n$stack');
    }
  }

  static Future<void> warningTick() => _play('sounds/focus_tick.wav');

  static Future<void> warningAlert() =>
      _play('sounds/focus_warning.wav', waitUntilDone: true);

  static Future<void> completed() =>
      _play('sounds/focus_complete.wav', waitUntilDone: true);
}
