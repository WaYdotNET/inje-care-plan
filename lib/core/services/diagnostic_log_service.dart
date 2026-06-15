import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import 'log_report_formatter.dart';

class DiagnosticLogService {
  DiagnosticLogService._();
  static final DiagnosticLogService instance = DiagnosticLogService._();

  factory DiagnosticLogService.forTesting(AppDatabase? db) {
    final s = DiagnosticLogService._();
    s._db = db;
    return s;
  }

  AppDatabase? _db;
  String _appVersion = '';
  String _platform = '';

  Future<void> attach(AppDatabase db) async {
    _db = db;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (_) {}
    _platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
  }

  Future<void> logEvent(String tag, String message) =>
      _write('event', tag, message, '');

  Future<void> logError(String tag, Object error, [StackTrace? stack]) =>
      _write('error', tag, error.toString(), stack?.toString() ?? '');

  Future<void> _write(
    String level,
    String tag,
    String message,
    String details,
  ) async {
    // Stampa SEMPRE in console (visibile in `flutter run`/`flutter logs`),
    // oltre a salvare nel DB: utile per il debug live in debug mode.
    debugPrint('[diag] $level/$tag: $message'
        '${details.isNotEmpty ? ' | ${details.split('\n').first}' : ''}');
    final db = _db;
    if (db == null) return;
    try {
      await db.insertLog(
        level: level,
        tag: tag,
        message: message,
        details: details,
        appVersion: _appVersion,
        platform: _platform,
      );
    } catch (_) {}
  }

  Future<List<AppLog>> recent({int limit = 300}) async {
    final db = _db;
    if (db == null) return const [];
    try {
      return await db.recentLogs(limit: limit);
    } catch (_) {
      return const [];
    }
  }

  Future<void> clear() async {
    try {
      await _db?.clearLogs();
    } catch (_) {}
  }

  Future<String> buildReport() async =>
      formatLogReport(await recent(), header: 'InjeCare Plan v$_appVersion');

  Future<void> shareReport() async {
    try {
      final text = await buildReport();
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'InjeCare Plan — log diagnostico',
          ),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/injecare_log.txt');
      await file.writeAsString(text);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'InjeCare Plan — log diagnostico',
        ),
      );
    } catch (_) {}
  }
}
