import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db.customStatement('SELECT 1'); // forza seed
  });

  tearDown(() async {
    await db.close();
  });

  // Helper: crea un'iniezione completata su zona/punto a una certa data
  Future<int> seedCompleted(int zoneId, int point, DateTime date) {
    return db.insertInjection(InjectionsCompanion.insert(
      zoneId: zoneId,
      pointNumber: point,
      pointCode: 'CD-$point',
      pointLabel: 'Coscia Dx · $point',
      scheduledAt: date,
      completedAt: Value(date),
      status: const Value('completed'),
    ));
  }

  test('senza ignoreInjectionId include l\'iniezione completata di oggi', () async {
    await seedCompleted(1, 3, DateTime(2026, 6, 14));
    final history = await db.getPointUsageHistory(1);
    expect(history[3], DateTime(2026, 6, 14));
  });

  test('con ignoreInjectionId esclude quell\'iniezione e restituisce la data precedente', () async {
    await seedCompleted(1, 3, DateTime(2026, 4, 25)); // uso reale ~50 gg prima
    final editingId = await seedCompleted(1, 3, DateTime(2026, 6, 14)); // iniezione in modifica
    final history = await db.getPointUsageHistory(1, ignoreInjectionId: editingId);
    expect(history[3], DateTime(2026, 4, 25));
  });

  test('con ignoreInjectionId e nessun uso precedente restituisce null', () async {
    final editingId = await seedCompleted(1, 3, DateTime(2026, 6, 14));
    final history = await db.getPointUsageHistory(1, ignoreInjectionId: editingId);
    expect(history[3], isNull);
  });
}
