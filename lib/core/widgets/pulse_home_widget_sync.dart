import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'package:pulse/features/focus/domain/usecases/focus_usecases.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';

/// Pushes today's habit + focus stats to the home-screen widget.
class PulseHomeWidgetSync {
  PulseHomeWidgetSync({
    required GetTodayHabits getTodayHabits,
    required GetTodayFocusMinutes getTodayFocusMinutes,
  })  : _getTodayHabits = getTodayHabits,
        _getTodayFocusMinutes = getTodayFocusMinutes;

  static const appGroupId = 'group.com.pulse.pulse';
  static const androidName = 'PulseHomeWidgetProvider';
  static const iOSName = 'PulseHomeWidget';
  static const qualifiedAndroidName = 'com.pulse.pulse.PulseHomeWidgetProvider';

  final GetTodayHabits _getTodayHabits;
  final GetTodayFocusMinutes _getTodayFocusMinutes;
  bool _ready = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> sync() async {
    if (kIsWeb) return;
    await init();
    if (!_ready) return;

    try {
      final habits = await _getTodayHabits();
      final done = habits.where((h) => h.isCompletedToday).length;
      final total = habits.length;
      final focusMinutes = await _getTodayFocusMinutes();

      final status = total == 0
          ? 'Add a habit to begin'
          : done >= total
              ? 'All done today'
              : '${total - done} left today';

      await HomeWidget.saveWidgetData<int>('habits_done', done);
      await HomeWidget.saveWidgetData<int>('habits_total', total);
      await HomeWidget.saveWidgetData<int>('focus_minutes', focusMinutes);
      await HomeWidget.saveWidgetData<String>('status_label', status);
      await HomeWidget.saveWidgetData<String>(
        'habits_label',
        total == 0 ? '— / —' : '$done / $total',
      );

      await HomeWidget.updateWidget(
        name: androidName,
        androidName: androidName,
        iOSName: iOSName,
        qualifiedAndroidName: qualifiedAndroidName,
      );
    } catch (_) {
      // Widgets are best-effort; never block the app.
    }
  }
}
