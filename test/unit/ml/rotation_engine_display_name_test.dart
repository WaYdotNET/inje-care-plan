import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/ml/rotation_pattern_engine.dart';
import 'package:injecare_plan/models/rotation_pattern.dart';
import '../../helpers/test_database.dart';

void main() {
  group('RotationPatternEngine — displayName in ZoneSuggestion (Bug D)', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'sequential pattern returns suggestion with customName when zone has '
        'a customName (was using zone.name before fix)', () async {
      // Rinomina la zona "Coscia Dx" con un nome custom
      final zones = await db.getAllZones();
      final firstZone = zones.first; // CD = Coscia Dx
      await db.updateZone(BodyZonesCompanion(
        id: Value(firstZone.id),
        customName: const Value('Mia Coscia'),
      ));

      // Ricarica zone con customName aggiornato
      final updatedZones = await db.getAllZones();

      final engine = RotationPatternEngine(
        db: db,
        zones: updatedZones,
        currentPattern: const RotationPattern(
          type: RotationPatternType.sequential,
          currentIndex: 0,
        ),
      );

      final suggestion = await engine.getNextSuggestion();
      expect(suggestion, isNotNull);
      // Il fix di Bug D: ora usa displayName (customName) invece di name
      expect(suggestion!.zoneName, 'Mia Coscia');
    });

    test('falls back to default name when no customName is set', () async {
      final zones = await db.getAllZones();

      final engine = RotationPatternEngine(
        db: db,
        zones: zones,
        currentPattern: const RotationPattern(
          type: RotationPatternType.sequential,
          currentIndex: 0,
        ),
      );

      final suggestion = await engine.getNextSuggestion();
      expect(suggestion, isNotNull);
      expect(suggestion!.zoneName, isNotEmpty);
    });
  });
}
