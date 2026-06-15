import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/diagnostic_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logError e logEvent scrivono; recent ordina; clear svuota', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final svc = DiagnosticLogService.forTesting(db);

    await svc.logEvent('app', 'avviata');
    await svc.logError('planning', Exception('boom'), StackTrace.current);

    final logs = await svc.recent();
    expect(logs.length, 2);
    expect(logs.first.level, 'error');
    expect(logs.first.message, contains('boom'));

    final report = await svc.buildReport();
    expect(report, contains('planning'));

    await svc.clear();
    expect((await svc.recent()).isEmpty, isTrue);
  });

  test('logError non lancia mai anche senza DB attaccato', () async {
    final svc = DiagnosticLogService.forTesting(null);
    await svc.logError('x', Exception('y'));
    expect(await svc.recent(), isEmpty);
  });
}
