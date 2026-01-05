import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/missed_injection_service.dart';
import '../../helpers/test_database.dart';

void main() {
  group('MissedInjectionService', () {
    test('marks overdue scheduled injections as missed (respects grace)', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final now = DateTime.now();
      final overdueAt = now.subtract(const Duration(hours: 2));
      final withinGraceAt = now.subtract(const Duration(minutes: 30));

      final overdueId = await db.into(db.injections).insert(
            TestData.createInjection(
              status: 'scheduled',
              scheduledAt: overdueAt,
            ),
          );
      final withinGraceId = await db.into(db.injections).insert(
            TestData.createInjection(
              status: 'scheduled',
              scheduledAt: withinGraceAt,
              pointNumber: 2,
            ),
          );
      await db.into(db.injections).insert(
            TestData.createInjection(
              status: 'completed',
              scheduledAt: overdueAt,
              pointNumber: 3,
              completedAt: overdueAt,
            ),
          );

      final service = MissedInjectionService(database: db);
      final marked = await service.checkAndMarkMissedInjections(
        grace: const Duration(minutes: 60),
      );

      expect(marked, 1);

      final overdue = await db.getInjectionById(overdueId);
      final withinGrace = await db.getInjectionById(withinGraceId);

      expect(overdue?.status, 'missed');
      expect(withinGrace?.status, 'scheduled');
    });
  });
}
