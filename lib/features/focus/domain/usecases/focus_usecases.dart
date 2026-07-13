import 'package:pulse/features/focus/domain/entities/focus_session.dart';
import 'package:pulse/features/focus/domain/repositories/focus_repository.dart';

class SaveFocusSession {
  SaveFocusSession(this._repository);

  final FocusRepository _repository;

  Future<void> call(FocusSession session) => _repository.saveSession(session);
}

class GetTodayFocusMinutes {
  GetTodayFocusMinutes(this._repository);

  final FocusRepository _repository;

  Future<int> call({DateTime? day}) =>
      _repository.getTodayFocusMinutes(day ?? DateTime.now());
}

class GetWeekFocusSessions {
  GetWeekFocusSessions(this._repository);

  final FocusRepository _repository;

  Future<List<FocusSession>> call({DateTime? weekStart}) {
    final now = DateTime.now();
    final start = weekStart ??
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _repository.getSessionsBetween(start, end);
  }
}

class ClearFocusData {
  ClearFocusData(this._repository);

  final FocusRepository _repository;

  Future<void> call() => _repository.clearAll();
}
