import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/database_provider.dart';
import 'package:injecare_plan/features/injection/injection_provider.dart';
import 'package:injecare_plan/models/rotation_pattern.dart';

import '../../helpers/test_database.dart';

void main() {
  group('suggestedPointForDateProvider', () {
    test('sequential pattern advances across scheduled injections by date', () async {
      final db = createTestDatabase();
      addTearDown(() async => db.close());

      // Activate sequential plan (instead of default smart)
      final plans = await db.getAllTherapyPlans();
      final sequentialPlan = plans.firstWhere(
        (p) => p.rotationPatternType == RotationPatternType.sequential.name,
        orElse: () => plans.first,
      );
      await db.activateTherapyPlan(sequentialPlan.id);

      // Create one scheduled injection on Jan 7
      await db.insertInjection(
        TestData.createInjection(
          zoneId: 1,
          pointNumber: 1,
          status: 'scheduled',
          scheduledAt: DateTime(2026, 1, 7, 20, 0),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final sug = await container.read(
        suggestedPointForDateProvider((
          scheduledAt: DateTime(2026, 1, 9, 20, 0),
          ignoreInjectionId: null,
        )).future,
      );

      // After 1 scheduled injection, next in DefaultZoneSequence.standard is zoneId 2
      expect(sug, isNotNull);
      expect(sug!.zoneId, 2);
    });
  });
}


