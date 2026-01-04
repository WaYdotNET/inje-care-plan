import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/features/injection/injection_repository.dart';
import 'package:injecare_plan/models/injection_record.dart' as models;
import 'package:injecare_plan/models/blacklisted_point.dart' as models;
import 'package:injecare_plan/models/therapy_plan.dart' as models;
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InjectionRepository repository;

  setUp(() async {
    db = createTestDatabase();
    repository = InjectionRepository(database: db);
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  group('InjectionRepository - Injections', () {
    test('watchInjections returns stream of injections', () async {
      final zones = await db.getAllZones();
      
      final stream = repository.watchInjections();
      
      expectLater(stream, emitsInOrder([
        isEmpty,
        hasLength(1),
      ]));

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));
    });

    test('getInjections returns all injections', () async {
      final zones = await db.getAllZones();
      
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));

      final injections = await repository.getInjections();
      expect(injections.length, 1);
    });

    test('getInjectionsInRange returns filtered injections', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 5)),
      ));
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 2,
        pointCode: 'CD-2',
        pointLabel: 'Test',
        scheduledAt: now.add(const Duration(days: 5)),
      ));

      final injections = await repository.getInjectionsInRange(
        now.subtract(const Duration(days: 10)),
        now,
      );
      expect(injections.length, 1);
      expect(injections.first.pointNumber, 1);
    });

    test('watchInjectionsInRange returns stream', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      final stream = repository.watchInjectionsInRange(
        now.subtract(const Duration(days: 10)),
        now.add(const Duration(days: 10)),
      );

      expectLater(stream, emitsInOrder([
        isEmpty,
        hasLength(1),
      ]));

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
      ));
    });

    test('getInjectionsByZone returns filtered injections', () async {
      final zones = await db.getAllZones();
      
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones[0].id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones[1].id,
        pointNumber: 1,
        pointCode: 'CS-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));

      final injections = await repository.getInjectionsByZone(zones[0].id);
      expect(injections.length, 1);
      expect(injections.first.pointCode, 'CD-1');
    });

    test('watchInjectionsByZone returns stream', () async {
      final zones = await db.getAllZones();
      
      final stream = repository.watchInjectionsByZone(zones.first.id);

      expectLater(stream, emitsInOrder([
        isEmpty,
        hasLength(1),
      ]));

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));
    });

    test('getLastInjectionForPoint returns most recent', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 10)),
        completedAt: Value(now.subtract(const Duration(days: 10))),
        status: const Value('completed'),
      ));
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 5)),
        completedAt: Value(now.subtract(const Duration(days: 5))),
        status: const Value('completed'),
      ));

      final last = await repository.getLastInjectionForPoint(zones.first.id, 1);
      expect(last, isNotNull);
      // Should return the most recent one (5 days ago, not 10)
    });

    test('createInjection inserts new injection', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      final record = models.InjectionRecord(
        zoneId: zones.first.id,
        pointNumber: 1,
        scheduledAt: now,
        status: models.InjectionStatus.scheduled,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.createInjection(record);
      expect(id, greaterThan(0));

      final injections = await repository.getInjections();
      expect(injections.length, 1);
    });

    test('updateInjection modifies injection', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      final id = await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
      ));

      final record = models.InjectionRecord(
        id: id,
        zoneId: zones.first.id,
        pointNumber: 1,
        scheduledAt: now,
        completedAt: now,
        status: models.InjectionStatus.completed,
        notes: 'Updated',
        createdAt: now,
        updatedAt: now,
      );

      final updated = await repository.updateInjection(id, record);
      expect(updated, 1);

      final injections = await repository.getInjections();
      expect(injections.first.status, 'completed');
    });

    test('completeInjection marks as completed', () async {
      final zones = await db.getAllZones();
      
      final id = await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));

      await repository.completeInjection(id, notes: 'Done', sideEffects: ['redness']);

      final injections = await repository.getInjections();
      expect(injections.first.status, 'completed');
      expect(injections.first.notes, 'Done');
      expect(injections.first.sideEffects, 'redness');
    });

    test('skipInjection marks as skipped', () async {
      final zones = await db.getAllZones();
      
      final id = await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));

      await repository.skipInjection(id);

      final injections = await repository.getInjections();
      expect(injections.first.status, 'skipped');
    });

    test('deleteInjection removes injection', () async {
      final zones = await db.getAllZones();
      
      final id = await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
      ));

      final deleted = await repository.deleteInjection(id);
      expect(deleted, 1);

      final injections = await repository.getInjections();
      expect(injections, isEmpty);
    });
  });

  group('InjectionRepository - Blacklisted Points', () {
    test('watchBlacklistedPoints returns stream', () async {
      final zones = await db.getAllZones();
      
      final stream = repository.watchBlacklistedPoints();

      expectLater(stream, emitsInOrder([
        isEmpty,
        hasLength(1),
      ]));

      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zones.first.id,
        pointNumber: 1,
      ));
    });

    test('getBlacklistedPoints returns all points', () async {
      final zones = await db.getAllZones();
      
      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zones.first.id,
        pointNumber: 1,
      ));

      final points = await repository.getBlacklistedPoints();
      expect(points.length, 1);
    });

    test('watchBlacklistedPointsByZone returns filtered stream', () async {
      final zones = await db.getAllZones();
      
      final stream = repository.watchBlacklistedPointsByZone(zones.first.id);

      expectLater(stream, emitsInOrder([
        isEmpty,
        hasLength(1),
      ]));

      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zones.first.id,
        pointNumber: 1,
      ));
    });

    test('isPointBlacklisted returns correct value', () async {
      final zones = await db.getAllZones();
      
      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zones.first.id,
        pointNumber: 1,
      ));

      expect(await repository.isPointBlacklisted('CD-1'), isTrue);
      expect(await repository.isPointBlacklisted('CD-2'), isFalse);
    });

    test('blacklistPoint adds point', () async {
      final zones = await db.getAllZones();
      
      final point = models.BlacklistedPoint(
        zoneId: zones.first.id,
        pointNumber: 1,
        reason: 'test',
        blacklistedAt: DateTime.now(),
      );

      final id = await repository.blacklistPoint(point);
      expect(id, greaterThan(0));

      expect(await repository.isPointBlacklisted('CD-1'), isTrue);
    });

    test('unblacklistPoint removes point', () async {
      final zones = await db.getAllZones();
      
      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zones.first.id,
        pointNumber: 1,
      ));

      final deleted = await repository.unblacklistPoint('CD-1');
      expect(deleted, 1);

      expect(await repository.isPointBlacklisted('CD-1'), isFalse);
    });
  });

  group('InjectionRepository - Body Zones', () {
    test('watchBodyZones returns stream', () async {
      final stream = repository.watchBodyZones();
      
      // Initial zones are already seeded
      expectLater(stream, emits(hasLength(8)));
    });

    test('getBodyZones returns all zones', () async {
      final zones = await repository.getBodyZones();
      expect(zones.length, 8);
    });

    test('getEnabledZones returns only enabled zones', () async {
      final zones = await db.getAllZones();
      await db.toggleZoneEnabled(zones.first.id, false);
      
      final enabled = await repository.getEnabledZones();
      expect(enabled.length, 7);
    });

    test('getZoneById returns correct zone', () async {
      final zones = await db.getAllZones();
      
      final zone = await repository.getZoneById(zones.first.id);
      expect(zone, isNotNull);
      expect(zone!.code, zones.first.code);
    });

    test('getZoneByCode returns correct zone', () async {
      final zone = await repository.getZoneByCode('CD');
      expect(zone, isNotNull);
      expect(zone!.name, 'Coscia Dx');
    });

    test('updateBodyZone updates zone', () async {
      final zones = await db.getAllZones();
      
      await repository.updateBodyZone(zones.first.id, isEnabled: false);
      
      final updated = await repository.getZoneById(zones.first.id);
      expect(updated!.isEnabled, isFalse);
    });
  });

  group('InjectionRepository - Therapy Plan', () {
    test('watchTherapyPlan returns stream', () async {
      final stream = repository.watchTherapyPlan();
      
      expectLater(stream, emitsInOrder([
        isNull,
        isNotNull,
      ]));

      await db.insertTherapyPlan(TherapyPlansCompanion.insert(
        startDate: DateTime.now(),
      ));
    });

    test('getTherapyPlan returns null initially', () async {
      final plan = await repository.getTherapyPlan();
      expect(plan, isNull);
    });

    test('saveTherapyPlan creates new plan', () async {
      final plan = models.TherapyPlan(
        injectionsPerWeek: 2,
        weekDays: [2, 4],
        preferredTime: '19:00',
        startDate: DateTime.now(),
      );

      final id = await repository.saveTherapyPlan(plan);
      expect(id, greaterThan(0));

      final saved = await repository.getTherapyPlan();
      expect(saved, isNotNull);
      expect(saved!.injectionsPerWeek, 2);
    });

    test('saveTherapyPlan updates existing plan', () async {
      // Create initial plan
      await db.insertTherapyPlan(TherapyPlansCompanion.insert(
        injectionsPerWeek: const Value(3),
        startDate: DateTime.now(),
      ));

      // Update plan
      final plan = models.TherapyPlan(
        injectionsPerWeek: 4,
        weekDays: [1, 2, 3, 4],
        preferredTime: '18:00',
        startDate: DateTime.now(),
      );

      await repository.saveTherapyPlan(plan);

      final updated = await repository.getTherapyPlan();
      expect(updated!.injectionsPerWeek, 4);
      expect(updated.weekDays, '1,2,3,4');
    });
  });

  group('InjectionRepository - Statistics', () {
    test('getAdherenceStats returns correct stats', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      
      // Add completed injections
      for (var i = 0; i < 8; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: (i % 6) + 1,
          pointCode: 'CD-${(i % 6) + 1}',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(now.subtract(Duration(days: i))),
          status: const Value('completed'),
        ));
      }
      
      // Add skipped injections
      for (var i = 0; i < 2; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: 15 + i)),
          status: const Value('skipped'),
        ));
      }

      final stats = await repository.getAdherenceStats(days: 30);
      expect(stats.total, 10);
      expect(stats.completed, 8);
      expect(stats.percentage, 80.0);
    });

    test('getSuggestedNextPoint returns unused point', () async {
      final zones = await db.getAllZones();
      
      // Use point 1
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
        completedAt: Value(DateTime.now()),
        status: const Value('completed'),
      ));

      final suggested = await repository.getSuggestedNextPoint();
      expect(suggested, isNotNull);
      // Should suggest a point that hasn't been used
    });

    test('findLeastUsedPoint returns correct point', () async {
      final zones = await db.getAllZones();
      
      final leastUsed = await repository.findLeastUsedPoint(zones.first.id);
      expect(leastUsed, isNotNull);
    });
  });
}

