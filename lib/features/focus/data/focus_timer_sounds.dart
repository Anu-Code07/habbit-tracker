import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Pleasant Kenney UI chimes for focus countdown / completion.
abstract final class FocusTimerSounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool _configured = false;

  /// Prefer notification/sonification routing — `alarm` is silent on many OEMs
  /// unless the app is treated as an alarm clock.
  static AudioContext get _chimeContext => AudioContext(
        iOS: AudioContextIOS(
          // playback ignores the Ring/Silent switch; duckOthers keeps it audible
          // without killing background music permanently.
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.duckOthers,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );

  static Future<void> warmUp() async {
    await _ensureConfigured();
  }

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await AudioPlayer.global.setAudioContext(_chimeContext);
      await _player.setAudioContext(_chimeContext);
      // mediaPlayer is reliable for short WAV assets; lowLatency skips some.
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
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
      await _player.setAudioContext(_chimeContext);
      await _player.stop();
      await _player.setVolume(1.0);
      // AssetSource paths are relative to the Flutter assets/ root.
      await _player.play(
        AssetSource(assetPath),
        ctx: _chimeContext,
        volume: 1.0,
      );
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
