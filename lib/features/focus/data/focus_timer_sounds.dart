import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:pulse/features/settings/domain/focus_sound_pack.dart';

/// Focus countdown / completion chimes for Soft and Wood packs.
///
/// Ticks are serialized on one player. Warning/complete use [PlayerMode.mediaPlayer]
/// so longer WAVs are reliable on iOS.
abstract final class FocusTimerSounds {
  static bool _warmed = false;
  static AudioPlayer? _tickPlayer;
  static AudioPlayer? _alertPlayer;
  static AudioPlayer? _completePlayer;
  static FocusSoundPack? _warmedPack;
  static Future<void> _tickGate = Future<void>.value();

  static AudioContext get _context => AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.duckOthers,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
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

  static Future<AudioPlayer> _makePlayer({
    required PlayerMode mode,
  }) async {
    final player = AudioPlayer();
    await AudioPlayer.global.setAudioContext(_context);
    await player.setAudioContext(_context);
    await player.setPlayerMode(mode);
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  static Future<void> warmUp(FocusSoundPack pack) async {
    if (!pack.playsAudio) return;
    if (_warmed && _warmedPack == pack) return;
    try {
      await AudioPlayer.global.setAudioContext(_context);
      await _tickPlayer?.dispose();
      await _alertPlayer?.dispose();
      await _completePlayer?.dispose();
      _tickPlayer =
          await _makePlayer(mode: PlayerMode.lowLatency);
      _alertPlayer =
          await _makePlayer(mode: PlayerMode.mediaPlayer);
      _completePlayer =
          await _makePlayer(mode: PlayerMode.mediaPlayer);
      await _tickPlayer!.setSource(AssetSource(_asset(pack, 'focus_tick.wav')));
      await _alertPlayer!
          .setSource(AssetSource(_asset(pack, 'focus_warning.wav')));
      await _completePlayer!
          .setSource(AssetSource(_asset(pack, 'focus_complete.wav')));
      _warmed = true;
      _warmedPack = pack;
    } catch (error, stack) {
      debugPrint('FocusTimerSounds warmUp failed: $error\n$stack');
      _warmed = false;
    }
  }

  static Future<void> _playOn(
    AudioPlayer? preferred,
    FocusSoundPack pack,
    String softName, {
    required PlayerMode mode,
    double volume = 1.0,
    bool waitUntilDone = false,
  }) async {
    if (!pack.playsAudio) return;
    await warmUp(pack);
    final asset = _asset(pack, softName);
    final v = volume.clamp(0.0, 1.0);

    Future<void> attempt(AudioPlayer player) async {
      await AudioPlayer.global.setAudioContext(_context);
      await player.setAudioContext(_context);
      await player.setPlayerMode(mode);
      await player.stop();
      await player.setVolume(v);
      debugPrint('FocusTimerSounds play AssetSource($asset) vol=$v mode=$mode');
      await player.play(
        AssetSource(asset),
        ctx: _context,
        volume: v,
        mode: mode,
      );
      if (waitUntilDone) {
        try {
          await player.onPlayerComplete.first.timeout(
            const Duration(seconds: 5),
          );
        } on TimeoutException {
          // best-effort
        }
      }
    }

    try {
      final player = preferred ?? await _makePlayer(mode: mode);
      await attempt(player);
      if (preferred == null) {
        unawaited(
          player.onPlayerComplete.first
              .timeout(const Duration(seconds: 3))
              .then((_) => player.dispose())
              .catchError((_) => player.dispose()),
        );
      }
    } catch (error, stack) {
      debugPrint('FocusTimerSounds retry ($asset): $error\n$stack');
      try {
        final fallback = await _makePlayer(mode: mode);
        await attempt(fallback);
        if (waitUntilDone) {
          await fallback.dispose();
        } else {
          unawaited(
            fallback.onPlayerComplete.first
                .timeout(const Duration(seconds: 3))
                .then((_) => fallback.dispose())
                .catchError((_) => fallback.dispose()),
          );
        }
      } catch (error2, stack2) {
        debugPrint('FocusTimerSounds failed ($asset): $error2\n$stack2');
      }
    }
  }

  /// Serialized so overlapping announce calls don't clip each other.
  static Future<void> warningTick(FocusSoundPack pack) {
    final run = _tickGate.then((_) async {
      await _playOn(
        _tickPlayer,
        pack,
        'focus_tick.wav',
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    });
    _tickGate = run.catchError((_) {});
    return run;
  }

  static Future<void> warningAlert(FocusSoundPack pack) async {
    // Fire-and-forget — don't block later ticks on the full sample length.
    unawaited(
      _playOn(
        _alertPlayer,
        pack,
        'focus_warning.wav',
        mode: PlayerMode.mediaPlayer,
        volume: 1.0,
        waitUntilDone: false,
      ),
    );
  }

  /// Completion chime — awaited so finish UI doesn't cut it off.
  static Future<void> completed(FocusSoundPack pack) async {
    await _playOn(
      _completePlayer,
      pack,
      'focus_complete.wav',
      mode: PlayerMode.mediaPlayer,
      volume: 1.0,
      waitUntilDone: true,
    );
  }
}
