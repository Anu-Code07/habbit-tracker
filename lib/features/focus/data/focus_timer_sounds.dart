import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:pulse/features/settings/domain/focus_sound_pack.dart';

/// Focus countdown / completion chimes for Soft and Wood packs.
abstract final class FocusTimerSounds {
  static bool _warmed = false;

  static AudioContext get _context => AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );

  static String _asset(FocusSoundPack pack, String softName) {
    if (pack == FocusSoundPack.wood) {
      final stem = softName.replaceAll('.wav', '');
      return 'sounds/${stem}_wood.wav';
    }
    return 'sounds/$softName';
  }

  static Future<void> warmUp(FocusSoundPack pack) async {
    if (!pack.playsAudio) return;
    if (_warmed) return;
    try {
      await AudioPlayer.global.setAudioContext(_context);
      final probe = AudioPlayer();
      await probe.setAudioContext(_context);
      await probe.setSource(AssetSource(_asset(pack, 'focus_complete.wav')));
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
      if (waitUntilDone) {
        try {
          await player.onPlayerComplete.first.timeout(
            const Duration(seconds: 4),
          );
        } on TimeoutException {
          // best-effort
        }
      } else {
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
    } finally {
      if (waitUntilDone) {
        try {
          await player.dispose();
        } catch (_) {}
      }
    }
  }

  static Future<void> warningTick(FocusSoundPack pack) async {
    if (!pack.playsAudio) return;
    await _play(_asset(pack, 'focus_tick.wav'), volume: 0.85);
  }

  static Future<void> warningAlert(FocusSoundPack pack) async {
    if (!pack.playsAudio) return;
    await _play(
      _asset(pack, 'focus_warning.wav'),
      volume: pack == FocusSoundPack.wood ? 0.8 : 1.0,
      waitUntilDone: true,
    );
  }

  static Future<void> completed(FocusSoundPack pack) async {
    if (!pack.playsAudio) return;
    await _play(
      _asset(pack, 'focus_complete.wav'),
      volume: pack == FocusSoundPack.wood ? 0.7 : 0.72,
      waitUntilDone: true,
    );
  }
}
