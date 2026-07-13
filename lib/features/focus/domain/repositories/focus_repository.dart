import 'package:pulse/features/focus/domain/entities/focus_session.dart';

abstract class FocusRepository {
  Future<void> saveSession(FocusSession session);
  Future<List<FocusSession>> getSessionsBetween(DateTime start, DateTime end);
  Future<int> getTodayFocusMinutes(DateTime day);
  Future<void> clearAll();
}
