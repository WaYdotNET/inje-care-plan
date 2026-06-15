import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/log_report_formatter.dart';

AppLog _log({
  required String level,
  required String tag,
  required String message,
  String details = '',
}) =>
    AppLog(
      id: 1,
      createdAt: DateTime(2026, 6, 15, 20, 30, 5),
      level: level,
      tag: tag,
      message: message,
      details: details,
      appVersion: '4.11.0',
      platform: 'android',
    );

void main() {
  test('report vuoto', () {
    final txt = formatLogReport(const [], header: 'InjeCare Plan');
    expect(txt, contains('InjeCare Plan'));
    expect(txt, contains('Nessun evento registrato'));
  });

  test('report con errore e dettagli', () {
    final txt = formatLogReport(
      [
        _log(
          level: 'error',
          tag: 'planning',
          message: 'boom',
          details: 'StackTrace...',
        ),
        _log(level: 'event', tag: 'app', message: 'avviata'),
      ],
      header: 'InjeCare Plan',
    );
    expect(txt, contains('ERROR'));
    expect(txt, contains('planning'));
    expect(txt, contains('boom'));
    expect(txt, contains('StackTrace...'));
    expect(txt, contains('20:30:05'));
  });
}
