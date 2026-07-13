import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pulse/core/database/app_database.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

/// Versioned JSON backup of habits, check-ins, focus sessions, and settings.
class PulseBackupService {
  PulseBackupService({
    required AppDatabase database,
    required SettingsRepository settings,
  })  : _db = database,
        _settings = settings;

  static const backupFormatVersion = 1;
  static const fileExtension = 'pulsebackup';

  final AppDatabase _db;
  final SettingsRepository _settings;

  Future<void> exportBackup() async {
    final payload = await _buildPayload();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(dir.path, 'pulse_$stamp.$fileExtension'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Pulse backup',
        text: 'Pulse local backup — keep this file safe.',
      ),
    );
  }

  /// Returns true when a backup was picked and restored.
  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return false;

    final path = result.files.single.path;
    if (path == null) {
      throw StateError('Could not read the selected backup file.');
    }

    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup file is not valid JSON.');
    }

    final version = decoded['version'];
    if (version is! int || version > backupFormatVersion) {
      throw FormatException(
        'Unsupported backup version ($version). Update Pulse and try again.',
      );
    }

    await _restorePayload(decoded);
    return true;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final habits = await _db.select(_db.habits).get();
    final checkIns = await _db.select(_db.checkIns).get();
    final focusSessions = await _db.select(_db.focusSessions).get();

    return {
      'version': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': _settings.exportMap(),
      'habits': habits
          .map(
            (h) => {
              'id': h.id,
              'name': h.name,
              'description': h.description,
              'iconCode': h.iconCode,
              'colorValue': h.colorValue,
              'frequency': h.frequency,
              'archived': h.archived,
              'createdAt': h.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'checkIns': checkIns
          .map(
            (c) => {
              'id': c.id,
              'habitId': c.habitId,
              'date': c.date.toIso8601String(),
              'note': c.note,
              'createdAt': c.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'focusSessions': focusSessions
          .map(
            (f) => {
              'id': f.id,
              'plannedSeconds': f.plannedSeconds,
              'completedSeconds': f.completedSeconds,
              'mode': f.mode,
              'completed': f.completed,
              'startedAt': f.startedAt.toIso8601String(),
              'endedAt': f.endedAt?.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  Future<void> _restorePayload(Map<String, dynamic> payload) async {
    final habits = (payload['habits'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final checkIns = (payload['checkIns'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final focusSessions =
        (payload['focusSessions'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final settings = (payload['settings'] as Map<String, dynamic>?) ?? const {};

    await _db.transaction(() async {
      await _db.delete(_db.checkIns).go();
      await _db.delete(_db.focusSessions).go();
      await _db.delete(_db.habits).go();

      for (final h in habits) {
        await _db.into(_db.habits).insert(
              HabitsCompanion.insert(
                id: h['id'] as String,
                name: h['name'] as String,
                description: Value(h['description'] as String? ?? ''),
                iconCode: Value(h['iconCode'] as int? ?? 0xe8b6),
                colorValue: Value(h['colorValue'] as int? ?? 0xFFE2F6D5),
                frequency: Value(h['frequency'] as String? ?? 'daily'),
                archived: Value(h['archived'] as bool? ?? false),
                createdAt: DateTime.parse(h['createdAt'] as String),
              ),
            );
      }

      for (final c in checkIns) {
        await _db.into(_db.checkIns).insert(
              CheckInsCompanion.insert(
                id: c['id'] as String,
                habitId: c['habitId'] as String,
                date: DateTime.parse(c['date'] as String),
                note: Value(c['note'] as String?),
                createdAt: DateTime.parse(c['createdAt'] as String),
              ),
            );
      }

      for (final f in focusSessions) {
        await _db.into(_db.focusSessions).insert(
              FocusSessionsCompanion.insert(
                id: f['id'] as String,
                plannedSeconds: f['plannedSeconds'] as int,
                completedSeconds: f['completedSeconds'] as int,
                mode: Value(f['mode'] as String? ?? 'pomodoro'),
                completed: Value(f['completed'] as bool? ?? false),
                startedAt: DateTime.parse(f['startedAt'] as String),
                endedAt: Value(
                  f['endedAt'] == null
                      ? null
                      : DateTime.parse(f['endedAt'] as String),
                ),
              ),
            );
      }
    });

    await _settings.importMap(settings);
  }
}
