import 'package:shared_preferences/shared_preferences.dart';

/// One intentional grace day per ISO week — misses don't break streaks.
class GraceDayStore {
  GraceDayStore(this._prefs);

  final SharedPreferences _prefs;

  /// Kept compatible with the earlier mercy_skip_dates key.
  static const _key = 'mercy_skip_dates';

  Set<String> _rawDates() {
    final list = _prefs.getStringList(_key) ?? const <String>[];
    return list.toSet();
  }

  String _keyFor(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  DateTime _normalize(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  /// Monday of the ISO week containing [day].
  DateTime weekStart(DateTime day) {
    final d = _normalize(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  bool isGraceDay(DateTime day) => _rawDates().contains(_keyFor(day));

  bool hasUsedGraceThisWeek([DateTime? now]) {
    final anchor = _normalize(now ?? DateTime.now());
    final start = weekStart(anchor);
    final end = start.add(const Duration(days: 7));
    for (final raw in _rawDates()) {
      final parts = raw.split('-');
      if (parts.length != 3) continue;
      final day = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (!day.isBefore(start) && day.isBefore(end)) return true;
    }
    return false;
  }

  bool canUseGrace([DateTime? now]) => !hasUsedGraceThisWeek(now);

  /// Marks [day] as a grace day. Returns false if already used this week.
  Future<bool> useGraceFor(DateTime day) async {
    final key = _keyFor(day);
    final existing = _rawDates();
    if (existing.contains(key)) return true;
    if (hasUsedGraceThisWeek(day)) return false;
    existing.add(key);
    await _prefs.setStringList(_key, existing.toList()..sort());
    return true;
  }

  Set<DateTime> allGraceDays() {
    final out = <DateTime>{};
    for (final raw in _rawDates()) {
      final parts = raw.split('-');
      if (parts.length != 3) continue;
      out.add(
        DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
      );
    }
    return out;
  }
}
