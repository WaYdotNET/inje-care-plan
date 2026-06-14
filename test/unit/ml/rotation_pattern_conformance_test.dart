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
}
