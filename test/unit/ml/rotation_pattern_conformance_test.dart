import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/ml/rotation_pattern_engine.dart';
import 'package:injecare_plan/models/rotation_pattern.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late List<BodyZone> zones;

  setUp(() async {
    db = createTestDatabase();
    await db.customStatement('SELECT 1'); // seed zone + piani
    zones = await db.getAllZones(); // ids 1..8, ordinati per sortOrder
  });

  tearDown(() async {
    await db.close();
  });

  RotationPatternEngine engineWith(RotationPattern pattern, {List<BodyZone>? z}) {
    return RotationPatternEngine(
      db: db,
      zones: z ?? zones,
      currentPattern: pattern,
    );
  }

  // ==== ADD THE 4 GROUPS HERE ====

  group('Pattern lineari (happy path, tutte le zone abilitate)', () {
    test('sequential segue DefaultZoneSequence.standard', () async {
      for (var i = 0; i < DefaultZoneSequence.standard.length; i++) {
        final s = await engineWith(
          RotationPattern(type: RotationPatternType.sequential, currentIndex: i),
        ).getNextSuggestion();
        expect(s!.zoneId, DefaultZoneSequence.standard[i], reason: 'index $i');
      }
    });

    test('clockwise segue DefaultZoneSequence.clockwise', () async {
      for (var i = 0; i < DefaultZoneSequence.clockwise.length; i++) {
        final s = await engineWith(
          RotationPattern(type: RotationPatternType.clockwise, currentIndex: i),
        ).getNextSuggestion();
        expect(s!.zoneId, DefaultZoneSequence.clockwise[i], reason: 'index $i');
      }
    });

    test('counterClockwise segue DefaultZoneSequence.counterClockwise', () async {
      for (var i = 0; i < DefaultZoneSequence.counterClockwise.length; i++) {
        final s = await engineWith(
          RotationPattern(
            type: RotationPatternType.counterClockwise,
            currentIndex: i,
          ),
        ).getNextSuggestion();
        expect(s!.zoneId, DefaultZoneSequence.counterClockwise[i], reason: 'index $i');
      }
    });
  });

  group('Pattern custom', () {
    test('segue la customSequence fornita', () async {
      final s = await engineWith(
        const RotationPattern(
          type: RotationPatternType.custom,
          customSequence: [7, 3, 1],
          currentIndex: 1,
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, 3);
    });

    test('customSequence vuota ricade su sequential', () async {
      final s = await engineWith(
        const RotationPattern(
          type: RotationPatternType.custom,
          customSequence: null,
          currentIndex: 0,
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, DefaultZoneSequence.standard[0]); // 1
    });

    test('setCustomSequence persiste la sequenza e attiva il piano custom', () async {
      final service = RotationPatternService(db);
      await service.setCustomSequence([8, 7]);

      final plan = await db.getCurrentTherapyPlan();
      expect(plan, isNotNull);
      expect(plan!.rotationPatternType, 'custom');
      expect(plan.customPatternSequence, '8,7');
      expect(plan.patternCurrentIndex, 0);
    });
  });

  group('alternateSides', () {
    test('lastSide null suggerisce un lato sinistro (prima zona left = CS id 2)', () async {
      final s = await engineWith(
        const RotationPattern(type: RotationPatternType.alternateSides),
      ).getNextSuggestion();
      expect(s!.zoneId, 2);
    });

    test('lastSide left suggerisce un lato destro (prima zona right = CD id 1)', () async {
      final s = await engineWith(
        const RotationPattern(
          type: RotationPatternType.alternateSides,
          lastSide: 'left',
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, 1);
    });

    test('lastSide left + lastZoneId evita di ripetere la stessa zona destra', () async {
      final s = await engineWith(
        const RotationPattern(
          type: RotationPatternType.alternateSides,
          lastSide: 'left',
          lastZoneId: 1,
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, isNot(1));
      expect([3, 5, 7], contains(s.zoneId));
    });
  });

  group('weeklyRotation', () {
    test('settimana 0 suggerisce il gruppo cosce (prima zona = CD id 1)', () async {
      final s = await engineWith(
        RotationPattern(
          type: RotationPatternType.weeklyRotation,
          weekStartDate: DateTime.now(),
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, 1);
    });

    test('dopo 2 settimane suggerisce il gruppo addome (prima zona = AD id 5)', () async {
      final s = await engineWith(
        RotationPattern(
          type: RotationPatternType.weeklyRotation,
          weekStartDate: DateTime.now().subtract(const Duration(days: 14)),
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, 5);
    });

    test('lastZoneId nel gruppo passa alla zona successiva del gruppo', () async {
      final s = await engineWith(
        RotationPattern(
          type: RotationPatternType.weeklyRotation,
          weekStartDate: DateTime.now(),
          lastZoneId: 1,
        ),
      ).getNextSuggestion();
      expect(s!.zoneId, 2);
    });
  });

  group('advancePattern self-healing (FIX B6)', () {
    test('happy path: usare la zona suggerita avanza di 1', () async {
      final service = RotationPatternService(db);
      await service.activatePlanByType(RotationPatternType.sequential);
      // index 0 -> suggerisce standard[0]=1; l'utente usa la zona 1
      await service.advancePattern(1, 'right');
      final plan = await db.getCurrentTherapyPlan();
      expect(plan!.patternCurrentIndex, 1);
    });

    test('deviazione: l\'indice segue la posizione della zona usata', () async {
      final service = RotationPatternService(db);
      await service.activatePlanByType(RotationPatternType.clockwise);
      // clockwise=[4,3,5,7,1,2,8,6], index 0 suggerisce 4.
      // L'utente usa invece la zona 7 (posizione 3) -> nuovo indice atteso 4.
      await service.advancePattern(7, 'right');
      final plan = await db.getCurrentTherapyPlan();
      expect(plan!.patternCurrentIndex, 4);
    });

    test('zona fuori sequenza: fallback a currentIndex+1', () async {
      final service = RotationPatternService(db);
      await service.activatePlanByType(RotationPatternType.clockwise);
      await service.advancePattern(999, 'right'); // id inesistente in sequenza
      final plan = await db.getCurrentTherapyPlan();
      expect(plan!.patternCurrentIndex, 1);
    });
  });

  group('smart (FIX B5): zona meno usata di recente', () {
    Future<int> seedUse(int zoneId, int point, DateTime date) {
      return db.insertInjection(InjectionsCompanion.insert(
        zoneId: zoneId,
        pointNumber: point,
        pointCode: 'Z$zoneId-$point',
        pointLabel: 'Zona $zoneId · $point',
        scheduledAt: date,
        completedAt: Value(date),
        status: const Value('completed'),
      ));
    }

    test('preferisce una zona mai usata rispetto a una usata di recente', () async {
      await seedUse(1, 1, DateTime(2026, 6, 14)); // CD usata oggi
      final s = await engineWith(
        const RotationPattern(type: RotationPatternType.smart),
      ).getNextSuggestion();
      expect(s!.zoneId, 2); // prima zona mai usata in ordine = CS (id 2)
    });

    test('non suggerisce zone disabilitate', () async {
      await seedUse(1, 1, DateTime(2026, 6, 14)); // CD usata
      await db.toggleZoneEnabled(2, false); // CS disabilitata
      final fresh = await db.getAllZones();
      final s = await engineWith(
        const RotationPattern(type: RotationPatternType.smart),
        z: fresh,
      ).getNextSuggestion();
      expect(s!.zoneId, 3); // CD usata, CS disabilitata -> prima mai usata abilitata = BD (id 3)
    });

    test('se tutte le zone sono usate sceglie la meno recente', () async {
      for (final z in [1, 2, 3, 4, 5, 6, 8]) {
        await seedUse(z, 1, DateTime(2026, 6, 1));
      }
      await seedUse(7, 1, DateTime(2026, 1, 1)); // GD molto più vecchia
      final s = await engineWith(
        const RotationPattern(type: RotationPatternType.smart),
      ).getNextSuggestion();
      expect(s!.zoneId, 7);
    });
  });
}
