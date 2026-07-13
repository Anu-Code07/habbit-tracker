import 'dart:math';

abstract final class PulseGreetings {
  static String? _last;

  /// Short greetings (about one line). Avoids repeating the last one.
  static String forUser(String rawName) {
    final name = rawName.trim();
    final hour = DateTime.now().hour;
    final pool = name.isEmpty
        ? _anonymous(hour)
        : _named(hour, _firstName(name));

    if (pool.length == 1) {
      _last = pool.first;
      return pool.first;
    }

    String next;
    do {
      next = pool[Random().nextInt(pool.length)];
    } while (next == _last);
    _last = next;
    return next;
  }

  static String _firstName(String name) {
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first;
    if (first.isEmpty) return name;
    return first[0].toUpperCase() + first.substring(1);
  }

  static List<String> _named(int hour, String name) {
    if (hour < 5) {
      return [
        'Still up, $name?',
        'Night owl, $name',
        'Quiet hours, $name',
      ];
    }
    if (hour < 12) {
      return [
        'Morning, $name',
        'Rise and pulse, $name',
        'Hey $name',
        'Let’s go, $name',
        'Fresh start, $name',
        'Coffee first, $name',
      ];
    }
    if (hour < 17) {
      return [
        'Hey $name',
        'Back at it, $name',
        'Afternoon, $name',
        'Keep going, $name',
        'You got this, $name',
        'Midday pulse, $name',
      ];
    }
    if (hour < 21) {
      return [
        'Evening, $name',
        'Soft landings, $name',
        'Nice work, $name',
        'Wind down, $name',
        'Hey $name',
      ];
    }
    return [
      'Late legend, $name',
      'One more, $name?',
      'Quiet wins, $name',
      'Night pulse, $name',
    ];
  }

  static List<String> _anonymous(int hour) {
    if (hour < 12) {
      return ['Good morning', 'Hey early bird', 'Fresh start'];
    }
    if (hour < 17) {
      return ['Good afternoon', 'Hey you', 'Back at it'];
    }
    return ['Good evening', 'Night rider', 'Soft landings'];
  }
}
