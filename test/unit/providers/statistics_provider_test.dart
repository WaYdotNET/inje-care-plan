import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:injecare_plan/features/statistics/statistics_provider.dart';

void main() {
  group('InjectionStats', () {
    test('empty stats should have zero values', () {
      const stats = InjectionStats.empty;

      expect(stats.totalInjections, 0);
      expect(stats.totalExpected, 0);
      expect(stats.adherenceRate, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.completedCount, 0);
      expect(stats.skippedCount, 0);
      expect(stats.scheduledCount, 0);
      expect(stats.zoneUsage, isEmpty);
      expect(stats.monthlyTrend, isEmpty);
      expect(stats.weeklyTrend, isEmpty);
    });
  });

  group('MonthlyData', () {
    test('should calculate adherence rate correctly', () {
      final data = MonthlyData(
        month: DateTime(2026, 1, 1),
        injections: 8,
        expected: 10,
        adherenceRate: 80.0,
      );

      expect(data.injections, 8);
      expect(data.expected, 10);
      expect(data.adherenceRate, 80.0);
    });
  });

  group('WeeklyData', () {
    test('should store weekly statistics', () {
      final weekStart = DateTime(2026, 1, 1);
      final data = WeeklyData(
        weekStart: weekStart,
        injections: 3,
        expected: 4,
        adherenceRate: 75.0,
      );

      expect(data.weekStart, weekStart);
      expect(data.injections, 3);
      expect(data.expected, 4);
      expect(data.adherenceRate, 75.0);
    });
  });

  group('ZoneUsage', () {
    test('should store zone usage data', () {
      final lastUsed = DateTime(2026, 1, 1);
      final usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Addome',
        emoji: '🫃',
        count: 10,
        percentage: 25.0,
        lastUsed: lastUsed,
      );

      expect(usage.zoneId, 1);
      expect(usage.zoneName, 'Addome');
      expect(usage.emoji, '🫃');
      expect(usage.count, 10);
      expect(usage.percentage, 25.0);
      expect(usage.lastUsed, lastUsed);
    });

    test('should handle null lastUsed', () {
      const usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Test',
        emoji: '💉',
        count: 0,
        percentage: 0,
        lastUsed: null,
      );

      expect(usage.lastUsed, isNull);
    });
  });

  group('StatsPeriod', () {
    test('should have all expected values', () {
      expect(StatsPeriod.values, contains(StatsPeriod.week));
      expect(StatsPeriod.values, contains(StatsPeriod.month));
      expect(StatsPeriod.values, contains(StatsPeriod.quarter));
      expect(StatsPeriod.values, contains(StatsPeriod.year));
      expect(StatsPeriod.values, contains(StatsPeriod.all));
      expect(StatsPeriod.values.length, 5);
    });
  });

  group('statsPeriodProvider', () {
    test('should default to month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(statsPeriodProvider), StatsPeriod.month);
    });

    test('should update period', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(statsPeriodProvider.notifier).state = StatsPeriod.year;

      expect(container.read(statsPeriodProvider), StatsPeriod.year);
    });
  });
}
