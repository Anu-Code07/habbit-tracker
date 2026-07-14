import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Focus countdown / completion chimes.
///
/// Uses [AssetSource] (proven on desktop) plus a fresh player per cue so a
/// stuck Android MediaPlayer can't silence the next chime.
abstract final class FocusTimerSounds {
  static bool _warmed = false;

  static AudioContext get _context => AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
        android: const AudioContextAndroid(
          // Keep false — speakerphone routing fights media on Nothing OS.
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );

  static Future<void> warmUp() async {
    if (_warmed) return;
    try {
      await AudioPlayer.global.setAudioContext(_context);
      final probe = AudioPlayer();
      await probe.setAudioContext(_context);
      await probe.setSource(AssetSource('sounds/focus_complete.wav'));
      await probe.dispose();
      _warmed = true;
    } catch (error, stack) {
      debugPrint('FocusTimerSounds warmUp failed: $error\n$stack');
    }
  }

  static Future<void> _play(
    String assetPath, {
    double volume = 1.0,
    bool waitUntilDone = false,
  }) async {
    final player = AudioPlayer();
    try {
      await AudioPlayer.global.setAudioContext(_context);
      await player.setAudioContext(_context);
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(ReleaseMode.release);
      final v = volume.clamp(0.0, 1.0);
      debugPrint('FocusTimerSounds play AssetSource($assetPath) vol=$v');
      await player.play(
        AssetSource(assetPath),
        ctx: _context,
        volume: v,
        mode: PlayerMode.mediaPlayer,
      );
      debugPrint('FocusTimerSounds state=${player.state}');
      if (waitUntilDone) {
        try {
          await player.onPlayerComplete.first.timeout(
            const Duration(seconds: 4),
          );
        } on TimeoutException {
          // best-effort
        }
      } else {
        // Let short ticks finish without holding the player.
        unawaited(
          player.onPlayerComplete.first
              .timeout(const Duration(seconds: 2))
              .then((_) => player.dispose())
              .catchError((_) => player.dispose()),
        );
        return;
      }
    } catch (error, stack) {
      debugPrint('FocusTimerSounds failed ($assetPath): $error\n$stack');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    } finally {
      if (waitUntilDone) {
        try {
          await player.dispose();
        } catch (_) {}
      }
    }
  }

  static Future<void> warningTick() => _play(
        'sounds/focus_tick.wav',
        volume: 1.0,
      );

  static Future<void> warningAlert() => _play(
        'sounds/focus_warning.wav',
        volume: 1.0,
        waitUntilDone: true,
      );

  static Future<void> completed() async {
    await _play(
      'sounds/focus_complete.wav',
      volume: 1.0,
      waitUntilDone: true,
    );
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
