import 'package:pulse/features/focus/domain/entities/focus_session.dart';
import 'package:pulse/features/focus/domain/repositories/focus_repository.dart';
import 'package:pulse/features/focus/data/datasources/focus_local_datasource.dart';

class FocusRepositoryImpl implements FocusRepository {
  FocusRepositoryImpl(this._local);

  final FocusLocalDataSource _local;

  @override
  Future<void> saveSession(FocusSession session) => _local.saveSession(session);

  @override
  Future<List<FocusSession>> getSessionsBetween(DateTime start, DateTime end) =>
      _local.getSessionsBetween(start, end);

  @override
  Future<int> getTodayFocusMinutes(DateTime day) =>
      _local.getTodayFocusMinutes(day);

  @override
  Future<void> clearAll() => _local.clearAll();
}
