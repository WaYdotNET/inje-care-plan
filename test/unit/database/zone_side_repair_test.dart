import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import '../../helpers/test_database.dart';

void main() {
  group('Zone side auto-repair (Bug 4a — side invertito)', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> runRealign() async {
      // Replica la logica di _alignZoneSideToCode (privata): D=right, S=left.
      await db.customStatement(
        "UPDATE body_zones SET side = 'right' "
        "WHERE code LIKE '%D' AND side != 'right'",
      );
      await db.customStatement(
        "UPDATE body_zones SET side = 'left' "
        "WHERE code LIKE '%S' AND side != 'left'",
      );
    }

    test('CS con side=right viene riportato a left', () async {
      // Forziamo lo stato corrotto
      await db.customStatement(
        "UPDATE body_zones SET side = 'right' WHERE code = 'CS'",
      );
      var cs = await db.getZoneByCode('CS');
      expect(cs?.side, 'right');

      await runRealign();

      cs = await db.getZoneByCode('CS');
      expect(cs?.side, 'left');
    });

    test('CD con side=left viene riportato a right', () async {
      await db.customStatement(
        "UPDATE body_zones SET side = 'left' WHERE code = 'CD'",
      );
      var cd = await db.getZoneByCode('CD');
      expect(cd?.side, 'left');

      await runRealign();

      cd = await db.getZoneByCode('CD');
      expect(cd?.side, 'right');
    });

    test('seed corretto rimane invariato (idempotenza)', () async {
      final before = await db.getAllZones();
      await runRealign();
      final after = await db.getAllZones();

      for (var i = 0; i < before.length; i++) {
        expect(after[i].side, before[i].side,
            reason: 'side cambiato per ${before[i].code}');
      }
    });

    test('zone custom con code senza suffix D/S non vengono toccate', () async {
      // Inserisce una zona custom con code='MX' e side='none'
      await db.into(db.bodyZones).insert(BodyZonesCompanion.insert(
            code: 'MX',
            name: 'Mia Zona Custom',
            type: const Value('custom'),
            side: const Value('none'),
            numberOfPoints: const Value(2),
            sortOrder: const Value(100),
          ));

      await runRealign();

      final mx = await db.getZoneByCode('MX');
      expect(mx?.side, 'none');
    });
  });
}
