import 'dart:math';

/// Short calm lines for a focus session — one quote per timer.
abstract final class PulseFocusQuotes {
  static String? _last;

  static const List<String> _quotes = [
    'One quiet block at a time',
    'Stay with this breath',
    'Small steps still count',
    'Presence over pace',
    'Keep the pulse steady',
    'Soft focus, clear mind',
    'You’re already here',
    'Gentle and unbroken',
    'Less noise, more now',
    'Depth before speed',
    'This minute is enough',
    'Calm hands, clear work',
    'Let the timer hold you',
    'Quiet wins stack up',
    'Return when you drift',
    'No rush — just rhythm',
    'Stillness is progress',
    'Finish what you started',
    'One thread, full attention',
    'Make room for deep work',
    'Protect this pocket of time',
    'Slow is smooth',
    'Anchor in the present',
    'Breathe, then begin again',
    'The work will wait kindly',
    'Stay curious, stay kind',
    'A clear mind moves well',
    'Hold the line gently',
    'This is your quiet hour',
    'Trust the next tick',
  ];

  /// Picks a quote for a new session, avoiding an immediate repeat.
  static String next() {
    if (_quotes.length == 1) {
      _last = _quotes.first;
      return _quotes.first;
    }
    String pick;
    do {
      pick = _quotes[Random().nextInt(_quotes.length)];
    } while (pick == _last);
    _last = pick;
    return pick;
  }
}
