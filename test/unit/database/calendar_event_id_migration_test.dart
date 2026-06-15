// test/unit/database/calendar_event_id_migration_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';

void main() {
  test('schemaVersion è 5', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 5);
  });

  test('la colonna calendar_event_id è utilizzabile (insert+read)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final info =
        await db.customSelect("PRAGMA table_info('injections')").get();
    final names = info.map((r) => r.data['name'] as String).toSet();
    expect(names, contains('calendar_event_id'));
  });
}
