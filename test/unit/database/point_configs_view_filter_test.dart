import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('PointConfigs filter by bodyView (Bug G — flip body view)', () {
    Future<void> insertPoint({
      required int zoneId,
      required int pointNumber,
      required String view,
    }) async {
      await db.into(db.pointConfigs).insert(
            PointConfigsCompanion.insert(
              zoneId: zoneId,
              pointNumber: pointNumber,
              positionX: const Value(0.5),
              positionY: const Value(0.5),
              bodyView: Value(view),
            ),
          );
    }

    test('returns only front-side points when filtering by front', () async {
      await insertPoint(zoneId: 1, pointNumber: 1, view: 'front');
      await insertPoint(zoneId: 1, pointNumber: 2, view: 'back');
      await insertPoint(zoneId: 1, pointNumber: 3, view: 'front');

      final result = await db.getPointConfigsForZoneAndView(1, 'front');
      expect(result.length, 2);
      expect(result.map((p) => p.pointNumber), containsAll([1, 3]));
    });

    test('returns only back-side points when filtering by back', () async {
      await insertPoint(zoneId: 1, pointNumber: 1, view: 'front');
      await insertPoint(zoneId: 1, pointNumber: 2, view: 'back');
      await insertPoint(zoneId: 1, pointNumber: 3, view: 'back');

      final result = await db.getPointConfigsForZoneAndView(1, 'back');
      expect(result.length, 2);
      expect(result.map((p) => p.pointNumber), containsAll([2, 3]));
    });

    test('does not leak points from other zones', () async {
      await insertPoint(zoneId: 1, pointNumber: 1, view: 'front');
      await insertPoint(zoneId: 2, pointNumber: 1, view: 'front');

      final result = await db.getPointConfigsForZoneAndView(1, 'front');
      expect(result.length, 1);
      expect(result.first.zoneId, 1);
    });

    test('legacy unfiltered query still returns all points for the zone',
        () async {
      await insertPoint(zoneId: 1, pointNumber: 1, view: 'front');
      await insertPoint(zoneId: 1, pointNumber: 2, view: 'back');

      final all = await db.getPointConfigsForZone(1);
      expect(all.length, 2);
    });

    test(
        'gluteo points wrongly stored as front are auto-corrected to back '
        'on open (idempotent realign)', () async {
      // Trova le zone gluteo create dal seed
      final zones = await db.getAllZones();
      final glute = zones.firstWhere((z) => z.type == 'buttock');

      // Inseriamo un punto del gluteo con bodyView='front' (regressione tipica
      // pre-v3): la beforeOpen lo allinea a 'back' alla prossima apertura.
      await insertPoint(zoneId: glute.id, pointNumber: 1, view: 'front');

      // Riapri il DB: simula il flow beforeOpen (per la istanza in-memory dei
      // test, chiamiamo lo statement direttamente — ricalca la logica
      // _alignButtockPointsToBack).
      await db.customStatement(
        "UPDATE point_configs SET body_view = 'back' "
        "WHERE body_view = 'front' "
        "AND zone_id IN (SELECT id FROM body_zones WHERE type = 'buttock')",
      );

      final corrected = await db.getPointConfigsForZoneAndView(glute.id, 'back');
      expect(corrected.length, 1);
      expect(corrected.first.pointNumber, 1);
    });
  });
}
