import 'dart:math';

abstract final class PulseGreetings {
  static String forUser(String rawName) {
    final name = rawName.trim();
    final hour = DateTime.now().hour;
    final pool = name.isEmpty
        ? _anonymous(hour)
        : _named(hour, _firstName(name));
    return pool[Random().nextInt(pool.length)];
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
        'Night owl mode: $name',
        'The world sleeps. You don’t, $name.',
      ];
    }
    if (hour < 12) {
      return [
        'Morning, $name — the plot thickens',
        'Rise and pulse, $name',
        'Look who showed up — $name!',
        'Coffee first, legends later, $name',
        'Hey $name, today’s yours (no pressure… okay, a little)',
        'Good morning, $name. Mischief managed?',
      ];
    }
    if (hour < 17) {
      return [
        'Afternoon, $name — still undefeated?',
        'Back at it, $name?',
        'Midday check-in, $name. Looking dangerous.',
        'You again? Love that for you, $name',
        'Keep the streak warm, $name',
        'Hello $name. The habits missed you. Barely.',
      ];
    }
    if (hour < 21) {
      return [
        'Evening, $name — soft landings only',
        'Wind-down mode: $name',
        'Nice work making it here, $name',
        'Hey $name, clock’s fancy but you’re fancier',
      ];
    }
    return [
      'Late night legend, $name',
      'One more gentle win, $name?',
      'Quiet hours, big vibes, $name',
      'The moon says hi, $name. So do we.',
    ];
  }

  static List<String> _anonymous(int hour) {
    if (hour < 12) {
      return ['Good morning, mysterious stranger', 'Hey early bird — name TBD'];
    }
    if (hour < 17) {
      return ['Good afternoon, you', 'Hey you — we should do names sometime'];
    }
    return ['Good evening, night rider', 'Hey night owl — introductions later'];
  }
}

