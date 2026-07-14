/// Focus chime character — Soft (default), Wood (warmer pluck), Silent.
enum FocusSoundPack {
  soft,
  wood,
  silent;

  static FocusSoundPack fromStorage(String? raw) {
    return switch (raw) {
      'wood' => FocusSoundPack.wood,
      'silent' => FocusSoundPack.silent,
      _ => FocusSoundPack.soft,
    };
  }

  String get storageValue => name;

  String get label => switch (this) {
        FocusSoundPack.soft => 'Soft',
        FocusSoundPack.wood => 'Wood',
        FocusSoundPack.silent => 'Silent',
      };

  String get subtitle => switch (this) {
        FocusSoundPack.soft => 'Gentle chord chime',
        FocusSoundPack.wood => 'Warm wooden plucks',
        FocusSoundPack.silent => 'No focus sounds',
      };

  bool get playsAudio => this != FocusSoundPack.silent;
}
