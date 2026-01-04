import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/ml/ml_data_collector.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late MLDataCollector collector;

  setUp(() async {
    db = createTestDatabase();
    collector = MLDataCollector(db);
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  group('ZoneInjectionData', () {
    test('neverUsed returns true when no injections', () async {
      final zoneData = await collector.getZoneInjectionData();

      // All zones should have no injections initially
      for (final data in zoneData) {
        expect(data.neverUsed, isTrue);
        expect(data.totalInjections, 0);
      }
    });

    test('neverUsed returns false when has injections', () async {
      final zones = await db.getAllZones();
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: DateTime.now(),
        status: const Value('completed'),
      ));

      final zoneData = await collector.getZoneInjectionData();
      final zone1Data = zoneData.firstWhere((d) => d.zone.id == zones.first.id);

      expect(zone1Data.neverUsed, isFalse);
      expect(zone1Data.totalInjections, 1);
    });

    test('fullyBlacklisted returns true when all points blacklisted', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      // Blacklist all points (zone has 6 points by default)
      for (var i = 1; i <= zone.numberOfPoints; i++) {
        await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
          pointCode: 'CD-$i',
          pointLabel: 'Test',
          zoneId: zone.id,
          pointNumber: i,
        ));
      }

      final zoneData = await collector.getZoneInjectionData();
      final zone1Data = zoneData.firstWhere((d) => d.zone.id == zone.id);

      expect(zone1Data.fullyBlacklisted, isTrue);
      expect(zone1Data.availablePointsCount, lessThanOrEqualTo(0));
    });

    test('completionRate calculated correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Add 3 completed and 2 skipped
      for (var i = 0; i < 3; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: i + 1,
          pointCode: 'CD-${i + 1}',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(now.subtract(Duration(days: i))),
          status: const Value('completed'),
        ));
      }
      for (var i = 0; i < 2; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: 10 + i)),
          status: const Value('skipped'),
        ));
      }

      final zoneData = await collector.getZoneInjectionData();
      final zone1Data = zoneData.firstWhere((d) => d.zone.id == zones.first.id);

      expect(zone1Data.completedCount, 3);
      expect(zone1Data.skippedCount, 2);
      expect(zone1Data.completionRate, closeTo(0.6, 0.01)); // 3/5
    });
  });

  group('TimePatternData', () {
    test('returns empty data when no completed injections', () async {
      final data = await collector.getTimePatternData();

      expect(data.preferredHours, isEmpty);
      expect(data.completionByWeekday, isEmpty);
      expect(data.completionByHour, isEmpty);
      expect(data.averageCompletionHour, isNull);
      expect(data.suggestedTime, isNull);
    });

    test('calculates preferred hours correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Add injections at different hours
      // 3 at 20:00, 2 at 9:00, 1 at 14:00
      for (var i = 0; i < 3; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(DateTime(now.year, now.month, now.day - i, 20, 0)),
          status: const Value('completed'),
        ));
      }
      for (var i = 0; i < 2; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 2,
          pointCode: 'CD-2',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: 5 + i)),
          completedAt: Value(DateTime(now.year, now.month, now.day - 5 - i, 9, 0)),
          status: const Value('completed'),
        ));
      }
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 3,
        pointCode: 'CD-3',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 10)),
        completedAt: Value(DateTime(now.year, now.month, now.day - 10, 14, 0)),
        status: const Value('completed'),
      ));

      final data = await collector.getTimePatternData();

      expect(data.preferredHours, contains(20)); // Most frequent
      expect(data.preferredHours.first, 20); // First should be most frequent
      expect(data.completionByHour[20], 3);
      expect(data.completionByHour[9], 2);
      expect(data.completionByHour[14], 1);
    });

    test('suggestedTime returns correct time tuple', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Add injection at 10:30
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
        completedAt: Value(DateTime(now.year, now.month, now.day, 10, 30)),
        status: const Value('completed'),
      ));

      final data = await collector.getTimePatternData();

      expect(data.suggestedTime, isNotNull);
      final (hour, _) = data.suggestedTime!;
      expect(hour, 10);
    });
  });

  group('AdherenceData', () {
    test('calculates adherence rate correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // 7 completed, 3 skipped = 70% adherence
      for (var i = 0; i < 7; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(now.subtract(Duration(days: i))),
          status: const Value('completed'),
        ));
      }
      for (var i = 0; i < 3; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 2,
          pointCode: 'CD-2',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: 10 + i)),
          status: const Value('skipped'),
        ));
      }

      final data = await collector.getAdherenceData(days: 30);

      expect(data.totalCompleted, 7);
      expect(data.totalSkipped, 3);
      expect(data.adherenceRate, closeTo(0.7, 0.01));
      expect(data.adherencePercentage, closeTo(70.0, 1));
    });

    test('trendDescription returns correct description', () {
      const improving = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.83,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.2,
      );
      expect(improving.trendDescription, 'In miglioramento');

      const declining = AdherenceData(
        periodDays: 30,
        totalCompleted: 8,
        totalSkipped: 4,
        totalScheduled: 0,
        adherenceRate: 0.67,
        weeklyTrend: {},
        currentStreak: 2,
        trendDirection: -0.15,
      );
      expect(declining.trendDescription, 'In calo');

      const stable = AdherenceData(
        periodDays: 30,
        totalCompleted: 9,
        totalSkipped: 3,
        totalScheduled: 0,
        adherenceRate: 0.75,
        weeklyTrend: {},
        currentStreak: 3,
        trendDirection: 0.05,
      );
      expect(stable.trendDescription, 'Stabile');
    });

    test('calculates current streak correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Recent: 4 completed in a row
      for (var i = 0; i < 4; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(now.subtract(Duration(days: i))),
          status: const Value('completed'),
        ));
      }
      // Then 1 skipped
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 2,
        pointCode: 'CD-2',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 5)),
        status: const Value('skipped'),
      ));

      final data = await collector.getAdherenceData(days: 30);

      expect(data.currentStreak, 4);
    });
  });

  group('SkipPatternData', () {
    test('returns empty data when no skipped injections', () async {
      final data = await collector.getSkipPatternData();

      expect(data.riskWeekdays, isEmpty);
      expect(data.riskHours, isEmpty);
      expect(data.skipsByWeekday, isEmpty);
      expect(data.commonReasons, isEmpty);
      expect(data.highestRiskDay, isNull);
    });

    test('identifies risk weekdays correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Skip on Monday (1) 3 times, Friday (5) 2 times
      for (var i = 0; i < 3; i++) {
        // Calculate a Monday
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        final monday = now.add(Duration(days: daysUntilMonday - 7 * (i + 1)));

        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 1,
          pointCode: 'CD-1',
          pointLabel: 'Test',
          scheduledAt: monday,
          status: const Value('skipped'),
        ));
      }
      for (var i = 0; i < 2; i++) {
        // Calculate a Friday
        final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
        final friday = now.add(Duration(days: daysUntilFriday - 7 * (i + 1)));

        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: 2,
          pointCode: 'CD-2',
          pointLabel: 'Test',
          scheduledAt: friday,
          status: const Value('skipped'),
        ));
      }

      final data = await collector.getSkipPatternData();

      expect(data.riskWeekdays, isNotEmpty);
      expect(data.riskWeekdays.first, DateTime.monday); // Most skipped
      expect(data.skipsByWeekday[DateTime.monday], 3);
      expect(data.skipsByWeekday[DateTime.friday], 2);
    });

    test('highestRiskDay returns correct day name', () {
      const data = SkipPatternData(
        riskWeekdays: [1], // Monday
        riskHours: [],
        skipsByWeekday: {1: 5},
        commonReasons: {},
      );

      expect(data.highestRiskDay, 'Lunedì');
    });

    test('highestRiskDay returns correct names for all days', () {
      final dayNames = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];

      for (var i = 1; i <= 7; i++) {
        final data = SkipPatternData(
          riskWeekdays: [i],
          riskHours: [],
          skipsByWeekday: {i: 1},
          commonReasons: {},
        );
        expect(data.highestRiskDay, dayNames[i]);
      }
    });
  });

  group('MLDataCollector - Integration', () {
    test('getZoneInjectionData returns data for all zones', () async {
      final zoneData = await collector.getZoneInjectionData();

      // Should have data for all 8 default zones
      expect(zoneData.length, 8);
    });

    test('lastInjectionDate is set correctly', () async {
      final zones = await db.getAllZones();
      final completedAt = DateTime(2024, 6, 15, 10, 30);

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: completedAt,
        completedAt: Value(completedAt),
        status: const Value('completed'),
      ));

      final zoneData = await collector.getZoneInjectionData();
      final zone1Data = zoneData.firstWhere((d) => d.zone.id == zones.first.id);

      expect(zone1Data.lastInjectionDate, isNotNull);
      expect(zone1Data.daysSinceLastInjection, isNotNull);
    });
  });
}
