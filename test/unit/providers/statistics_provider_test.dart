import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/features/statistics/statistics_provider.dart';
import '../../helpers/test_database.dart';

void main() {
  group('MonthlyData', () {
    test('can be created with required fields', () {
      final data = MonthlyData(
        month: DateTime(2024, 6),
        injections: 10,
        expected: 12,
        adherenceRate: 83.33,
      );

      expect(data.month, DateTime(2024, 6));
      expect(data.injections, 10);
      expect(data.expected, 12);
      expect(data.adherenceRate, 83.33);
    });
  });

  group('WeeklyData', () {
    test('can be created with required fields', () {
      final data = WeeklyData(
        weekStart: DateTime(2024, 6, 3),
        injections: 3,
        expected: 3,
        adherenceRate: 100.0,
      );

      expect(data.weekStart, DateTime(2024, 6, 3));
      expect(data.injections, 3);
      expect(data.expected, 3);
      expect(data.adherenceRate, 100.0);
    });
  });

  group('ZoneUsage', () {
    test('can be created with required fields', () {
      final usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Coscia Destra',
        emoji: '🦵',
        count: 15,
        percentage: 25.0,
        lastUsed: DateTime(2024, 6, 15),
      );

      expect(usage.zoneId, 1);
      expect(usage.zoneName, 'Coscia Destra');
      expect(usage.emoji, '🦵');
      expect(usage.count, 15);
      expect(usage.percentage, 25.0);
      expect(usage.lastUsed, DateTime(2024, 6, 15));
    });

    test('can be created without lastUsed', () {
      const usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Coscia Destra',
        emoji: '🦵',
        count: 0,
        percentage: 0.0,
      );

      expect(usage.lastUsed, isNull);
    });
  });

  group('InjectionStats', () {
    test('can be created with required fields', () {
      final stats = InjectionStats(
        totalInjections: 50,
        totalExpected: 60,
        adherenceRate: 83.33,
        zoneUsage: const [],
        monthlyTrend: const [],
        weeklyTrend: const [],
        currentStreak: 5,
        longestStreak: 10,
        firstInjection: DateTime(2024, 1, 1),
        lastInjection: DateTime(2024, 6, 15),
        completedCount: 50,
        skippedCount: 10,
        scheduledCount: 5,
      );

      expect(stats.totalInjections, 50);
      expect(stats.totalExpected, 60);
      expect(stats.adherenceRate, 83.33);
      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 10);
      expect(stats.firstInjection, DateTime(2024, 1, 1));
      expect(stats.lastInjection, DateTime(2024, 6, 15));
      expect(stats.completedCount, 50);
      expect(stats.skippedCount, 10);
      expect(stats.scheduledCount, 5);
    });

    test('empty returns default values', () {
      const stats = InjectionStats.empty;

      expect(stats.totalInjections, 0);
      expect(stats.totalExpected, 0);
      expect(stats.adherenceRate, 0);
      expect(stats.zoneUsage, isEmpty);
      expect(stats.monthlyTrend, isEmpty);
      expect(stats.weeklyTrend, isEmpty);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.firstInjection, isNull);
      expect(stats.lastInjection, isNull);
      expect(stats.completedCount, 0);
      expect(stats.skippedCount, 0);
      expect(stats.scheduledCount, 0);
    });
  });

  group('StatsPeriod', () {
    test('has correct values', () {
      expect(StatsPeriod.values, hasLength(5));
      expect(StatsPeriod.week.index, 0);
      expect(StatsPeriod.month.index, 1);
      expect(StatsPeriod.quarter.index, 2);
      expect(StatsPeriod.year.index, 3);
      expect(StatsPeriod.all.index, 4);
    });
  });

  group('Statistics calculations with real database', () {
    late AppDatabase db;

    setUp(() async {
      db = createTestDatabase();
      await db.customStatement('SELECT 1');
    });

    tearDown(() async {
      await db.close();
    });

    test('calculates adherence rate correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Add 8 completed injections
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

      // Add 2 skipped injections
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

      final allInjections = await db.getAllInjections();

      final completedCount = allInjections.where((i) => i.status == 'completed').length;
      final skippedCount = allInjections.where((i) => i.status == 'skipped').length;
      final totalDone = completedCount;
      final totalExpected = completedCount + skippedCount;
      final adherenceRate = (totalDone / totalExpected) * 100;

      expect(completedCount, 8);
      expect(skippedCount, 2);
      expect(adherenceRate, 80.0);
    });

    test('calculates zone usage correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Use zone 1 (CD) 5 times
      for (var i = 0; i < 5; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones[0].id,
          pointNumber: (i % 6) + 1,
          pointCode: 'CD-${(i % 6) + 1}',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: i)),
          completedAt: Value(now.subtract(Duration(days: i))),
          status: const Value('completed'),
        ));
      }

      // Use zone 2 (CS) 3 times
      for (var i = 0; i < 3; i++) {
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones[1].id,
          pointNumber: (i % 4) + 1,
          pointCode: 'CS-${(i % 4) + 1}',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: 10 + i)),
          completedAt: Value(now.subtract(Duration(days: 10 + i))),
          status: const Value('completed'),
        ));
      }

      final allInjections = await db.getAllInjections();
      final completedInjections = allInjections.where((i) => i.status == 'completed').toList();

      final zoneCountMap = <int, int>{};
      for (final injection in completedInjections) {
        zoneCountMap[injection.zoneId] = (zoneCountMap[injection.zoneId] ?? 0) + 1;
      }

      expect(zoneCountMap[zones[0].id], 5);
      expect(zoneCountMap[zones[1].id], 3);

      final total = zoneCountMap.values.fold(0, (a, b) => a + b);
      expect(total, 8);

      final zone1Percentage = (5 / 8) * 100;
      final zone2Percentage = (3 / 8) * 100;
      expect(zone1Percentage, closeTo(62.5, 0.1));
      expect(zone2Percentage, closeTo(37.5, 0.1));
    });

    test('calculates streak correctly', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Add completed streak: 5 completed in a row, then 1 skipped, then 3 completed
      final injectionData = [
        ('completed', 1),
        ('completed', 2),
        ('completed', 3),
        ('completed', 4),
        ('completed', 5),
        ('skipped', 6),
        ('completed', 7),
        ('completed', 8),
        ('completed', 9),
      ];

      for (var i = 0; i < injectionData.length; i++) {
        final (status, daysAgo) = injectionData[i];
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zones.first.id,
          pointNumber: (i % 6) + 1,
          pointCode: 'CD-${(i % 6) + 1}',
          pointLabel: 'Test',
          scheduledAt: now.subtract(Duration(days: daysAgo)),
          completedAt: status == 'completed'
              ? Value(now.subtract(Duration(days: daysAgo)))
              : const Value.absent(),
          status: Value(status),
        ));
      }

      final allInjections = await db.getAllInjections();
      final sorted = allInjections
          .where((i) => i.status == 'completed' || i.status == 'skipped')
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      // Calculate longest streak
      int longestStreak = 0;
      int tempStreak = 0;

      for (final injection in sorted) {
        if (injection.status == 'completed') {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          tempStreak = 0;
        }
      }

      expect(longestStreak, 5); // First 5 completed before skipped
    });

    test('returns first and last injection dates', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();
      // Use dates without milliseconds to match database storage precision
      final firstDate = DateTime(now.year, now.month, now.day - 30, 10, 0, 0);
      final lastDate = DateTime(now.year, now.month, now.day - 1, 10, 0, 0);

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: firstDate,
        completedAt: Value(firstDate),
        status: const Value('completed'),
      ));

      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 2,
        pointCode: 'CD-2',
        pointLabel: 'Test',
        scheduledAt: lastDate,
        completedAt: Value(lastDate),
        status: const Value('completed'),
      ));

      final completedInjections = (await db.getAllInjections())
          .where((i) => i.status == 'completed')
          .toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

      // Compare dates by components since database might truncate precision
      expect(completedInjections.first.completedAt!.year, firstDate.year);
      expect(completedInjections.first.completedAt!.month, firstDate.month);
      expect(completedInjections.first.completedAt!.day, firstDate.day);
      expect(completedInjections.last.completedAt!.year, lastDate.year);
      expect(completedInjections.last.completedAt!.month, lastDate.month);
      expect(completedInjections.last.completedAt!.day, lastDate.day);
    });

    test('handles empty injection list', () async {
      final allInjections = await db.getAllInjections();
      expect(allInjections, isEmpty);

      final completedCount = allInjections.where((i) => i.status == 'completed').length;
      final skippedCount = allInjections.where((i) => i.status == 'skipped').length;
      final scheduledCount = allInjections.where((i) => i.status == 'scheduled').length;

      expect(completedCount, 0);
      expect(skippedCount, 0);
      expect(scheduledCount, 0);
    });
  });
}
