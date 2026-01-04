import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/ml/ml_data_collector.dart';
import 'package:injecare_plan/models/body_zone.dart';

void main() {
  group('ZoneInjectionData', () {
    test('creates with required fields', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final data = ZoneInjectionData(
        zone: zone,
        totalInjections: 10,
        completedCount: 8,
        skippedCount: 2,
        lastInjectionDate: DateTime(2024, 1, 15),
        daysSinceLastInjection: 5,
        completionRate: 0.8,
        blacklistedPointsCount: 1,
        availablePointsCount: 5,
      );

      expect(data.zone, zone);
      expect(data.totalInjections, 10);
      expect(data.completedCount, 8);
      expect(data.skippedCount, 2);
      expect(data.completionRate, 0.8);
      expect(data.blacklistedPointsCount, 1);
      expect(data.availablePointsCount, 5);
    });

    test('neverUsed returns true when totalInjections is 0', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Test',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final data = ZoneInjectionData(
        zone: zone,
        totalInjections: 0,
        completedCount: 0,
        skippedCount: 0,
        completionRate: 0.0,
        blacklistedPointsCount: 0,
        availablePointsCount: 6,
      );

      expect(data.neverUsed, isTrue);
    });

    test('neverUsed returns false when has injections', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Test',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final data = ZoneInjectionData(
        zone: zone,
        totalInjections: 5,
        completedCount: 5,
        skippedCount: 0,
        completionRate: 1.0,
        blacklistedPointsCount: 0,
        availablePointsCount: 6,
      );

      expect(data.neverUsed, isFalse);
    });

    test('fullyBlacklisted returns true when no available points', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Test',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final data = ZoneInjectionData(
        zone: zone,
        totalInjections: 0,
        completedCount: 0,
        skippedCount: 0,
        completionRate: 0.0,
        blacklistedPointsCount: 6,
        availablePointsCount: 0,
      );

      expect(data.fullyBlacklisted, isTrue);
    });

    test('fullyBlacklisted returns false when has available points', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Test',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final data = ZoneInjectionData(
        zone: zone,
        totalInjections: 0,
        completedCount: 0,
        skippedCount: 0,
        completionRate: 0.0,
        blacklistedPointsCount: 2,
        availablePointsCount: 4,
      );

      expect(data.fullyBlacklisted, isFalse);
    });
  });

  group('TimePatternData', () {
    test('creates with required fields', () {
      const data = TimePatternData(
        preferredHours: [20, 9, 10],
        completionByWeekday: {1: 5, 3: 4, 5: 6},
        completionByHour: {20: 10, 9: 5},
        averageCompletionHour: 18.5,
      );

      expect(data.preferredHours, [20, 9, 10]);
      expect(data.completionByWeekday, {1: 5, 3: 4, 5: 6});
      expect(data.completionByHour, {20: 10, 9: 5});
      expect(data.averageCompletionHour, 18.5);
    });

    test('suggestedTime returns tuple for valid averageCompletionHour', () {
      const data = TimePatternData(
        preferredHours: [20],
        completionByWeekday: {},
        completionByHour: {},
        averageCompletionHour: 20.5,
      );

      final suggested = data.suggestedTime;
      expect(suggested, isNotNull);
      expect(suggested!.$1, 20); // hour
      expect(suggested.$2, 30); // minute (0.5 * 60)
    });

    test('suggestedTime returns null when averageCompletionHour is null', () {
      const data = TimePatternData(
        preferredHours: [],
        completionByWeekday: {},
        completionByHour: {},
        averageCompletionHour: null,
      );

      expect(data.suggestedTime, isNull);
    });

    test('suggestedTime handles whole hours', () {
      const data = TimePatternData(
        preferredHours: [9],
        completionByWeekday: {},
        completionByHour: {},
        averageCompletionHour: 9.0,
      );

      final suggested = data.suggestedTime;
      expect(suggested!.$1, 9);
      expect(suggested.$2, 0);
    });
  });

  group('AdherenceData', () {
    test('creates with all required fields', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 3,
        adherenceRate: 0.833,
        weeklyTrend: {0: 0.8, 1: 0.9, 2: 0.85},
        currentStreak: 5,
        trendDirection: 0.05,
      );

      expect(data.periodDays, 30);
      expect(data.totalCompleted, 10);
      expect(data.totalSkipped, 2);
      expect(data.totalScheduled, 3);
      expect(data.adherenceRate, 0.833);
      expect(data.currentStreak, 5);
      expect(data.trendDirection, 0.05);
    });

    test('adherencePercentage returns rate * 100', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.833,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.0,
      );

      expect(data.adherencePercentage, 83.3);
    });

    test('trendDescription returns In miglioramento for positive trend', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.833,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.15,
      );

      expect(data.trendDescription, 'In miglioramento');
    });

    test('trendDescription returns In calo for negative trend', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.833,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: -0.15,
      );

      expect(data.trendDescription, 'In calo');
    });

    test('trendDescription returns Stabile for neutral trend', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.833,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.05,
      );

      expect(data.trendDescription, 'Stabile');
    });

    test('trendDescription returns Stabile for exactly -0.1', () {
      const data = AdherenceData(
        periodDays: 30,
        totalCompleted: 10,
        totalSkipped: 2,
        totalScheduled: 0,
        adherenceRate: 0.833,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: -0.1,
      );

      expect(data.trendDescription, 'Stabile');
    });
  });

  group('SkipPatternData', () {
    test('creates with all required fields', () {
      const data = SkipPatternData(
        riskWeekdays: [6, 7],
        riskHours: [22, 23],
        skipsByWeekday: {6: 3, 7: 5},
        commonReasons: {'busy': 2, 'forgot': 3},
      );

      expect(data.riskWeekdays, [6, 7]);
      expect(data.riskHours, [22, 23]);
      expect(data.skipsByWeekday, {6: 3, 7: 5});
      expect(data.commonReasons, {'busy': 2, 'forgot': 3});
    });

    test('highestRiskDay returns first risk day name', () {
      const data = SkipPatternData(
        riskWeekdays: [6, 7],
        riskHours: [],
        skipsByWeekday: {6: 3, 7: 5},
        commonReasons: {},
      );

      expect(data.highestRiskDay, 'Sabato');
    });

    test('highestRiskDay returns Domenica for Sunday', () {
      const data = SkipPatternData(
        riskWeekdays: [7],
        riskHours: [],
        skipsByWeekday: {7: 5},
        commonReasons: {},
      );

      expect(data.highestRiskDay, 'Domenica');
    });

    test('highestRiskDay returns Lunedì for Monday', () {
      const data = SkipPatternData(
        riskWeekdays: [1],
        riskHours: [],
        skipsByWeekday: {1: 2},
        commonReasons: {},
      );

      expect(data.highestRiskDay, 'Lunedì');
    });

    test('highestRiskDay returns null when no risk weekdays', () {
      const data = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      expect(data.highestRiskDay, isNull);
    });

    test('highestRiskDay returns correct day for all weekdays', () {
      const days = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
      
      for (var i = 1; i <= 7; i++) {
        final data = SkipPatternData(
          riskWeekdays: [i],
          riskHours: [],
          skipsByWeekday: {i: 1},
          commonReasons: {},
        );
        expect(data.highestRiskDay, days[i]);
      }
    });
  });
}

