import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';

void main() {
  test('schemaVersion è 6 e la tabella app_logs esiste', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 6);
    final info = await db.customSelect("PRAGMA table_info('app_logs')").get();
    final names = info.map((r) => r.data['name'] as String).toSet();
    expect(names, containsAll(<String>['id', 'created_at', 'level', 'tag', 'message', 'details', 'app_version', 'platform']));
  });

  test('insertLog + recentLogs (desc) e cap a 300', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    for (var i = 0; i < 305; i++) {
      await db.insertLog(level: 'event', tag: 't', message: 'm$i', details: '', appVersion: '1', platform: 'test');
    }
    final logs = await db.recentLogs();
    expect(logs.length, 300);
    expect(logs.first.message, 'm304');
    await db.clearLogs();
    expect((await db.recentLogs()).isEmpty, isTrue);
  });
}
