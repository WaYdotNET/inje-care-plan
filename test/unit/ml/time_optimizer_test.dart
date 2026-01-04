import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/ml/time_optimizer.dart';
import 'package:injecare_plan/core/ml/ml_data_collector.dart';

void main() {
  late TimeOptimizer optimizer;

  setUp(() {
    optimizer = TimeOptimizer();
  });

  group('TimeOptimizer.analyze', () {
    test('returns default recommendation when no data', () {
      const timeData = TimePatternData(
        preferredHours: [],
        completionByHour: {},
        completionByWeekday: {},
      );
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 0,
        totalCompleted: 0,
        totalSkipped: 0,
        adherenceRate: 0.0,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: 0.0,
      );

      final recommendation = optimizer.analyze(timeData, adherenceData);

      expect(recommendation.suggestedHour, 9);
      expect(recommendation.suggestedMinute, 0);
      expect(recommendation.confidence, 0.3);
      expect(recommendation.reason, contains('pratiche standard'));
    });

    test('suggests most common hour from data', () {
      const timeData = TimePatternData(
        preferredHours: [20, 9, 10],
        completionByHour: {20: 15, 9: 5, 10: 3},
        completionByWeekday: {},
      );
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 23,
        totalCompleted: 23,
        totalSkipped: 0,
        adherenceRate: 1.0,
        weeklyTrend: {},
        currentStreak: 10,
        trendDirection: 0.1,
      );

      final recommendation = optimizer.analyze(timeData, adherenceData);

      expect(recommendation.suggestedHour, 20);
      expect(recommendation.alternativeHours, contains(9));
    });

    test('confidence increases with more data', () {
      const fewDataTimeData = TimePatternData(
        preferredHours: [9],
        completionByHour: {9: 3},
        completionByWeekday: {},
      );
      const manyDataTimeData = TimePatternData(
        preferredHours: [9],
        completionByHour: {9: 25},
        completionByWeekday: {},
      );
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 25,
        totalCompleted: 25,
        totalSkipped: 0,
        adherenceRate: 1.0,
        weeklyTrend: {},
        currentStreak: 10,
        trendDirection: 0.0,
      );

      final fewDataRec = optimizer.analyze(fewDataTimeData, adherenceData);
      final manyDataRec = optimizer.analyze(manyDataTimeData, adherenceData);

      expect(manyDataRec.confidence, greaterThan(fewDataRec.confidence));
    });
  });

  group('TimeOptimizer.analyzeBestDay', () {
    test('suggests safe day when risk days exist', () {
      const timeData = TimePatternData(
        preferredHours: [9],
        completionByHour: {9: 10},
        completionByWeekday: {1: 5, 3: 5, 5: 5},
      );
      const skipData = SkipPatternData(
        riskWeekdays: [6, 7], // Weekend
        riskHours: [],
        skipsByWeekday: {6: 3, 7: 5},
        commonReasons: {},
      );

      final recommendation = optimizer.analyzeBestDay(timeData, skipData);

      expect(recommendation.riskDays, [6, 7]);
      expect(recommendation.reason, contains('Sabato'));
    });

    test('returns all days good when no risk days', () {
      const timeData = TimePatternData(
        preferredHours: [9],
        completionByHour: {9: 10},
        completionByWeekday: {},
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final recommendation = optimizer.analyzeBestDay(timeData, skipData);

      expect(recommendation.reason, contains('buoni'));
    });
  });

  group('TimeOptimizer.calculateOptimalWindow', () {
    test('returns default morning window when no data', () {
      const timeData = TimePatternData(
        preferredHours: [],
        completionByHour: {},
        completionByWeekday: {},
      );

      final window = optimizer.calculateOptimalWindow(timeData);

      expect(window.startHour, 8);
      expect(window.endHour, 10);
      expect(window.label, 'Mattina');
    });

    test('calculates window based on average hour', () {
      const timeData = TimePatternData(
        preferredHours: [20],
        completionByHour: {20: 10},
        completionByWeekday: {},
        averageCompletionHour: 20.0,
      );

      final window = optimizer.calculateOptimalWindow(timeData);

      expect(window.startHour, 19);
      expect(window.endHour, 21);
      expect(window.label, 'Sera');
    });

    test('labels afternoon correctly', () {
      const timeData = TimePatternData(
        preferredHours: [14],
        completionByHour: {14: 10},
        completionByWeekday: {},
        averageCompletionHour: 14.0,
      );

      final window = optimizer.calculateOptimalWindow(timeData);

      expect(window.label, 'Pomeriggio');
    });
  });

  group('TimeRecommendation', () {
    test('formattedTime returns correct format', () {
      const recommendation = TimeRecommendation(
        suggestedHour: 9,
        suggestedMinute: 0,
        confidence: 0.8,
        reason: 'Test',
        alternativeHours: [],
        factors: {},
      );

      expect(recommendation.formattedTime, '09:00');
    });

    test('formattedTime handles double digits', () {
      const recommendation = TimeRecommendation(
        suggestedHour: 20,
        suggestedMinute: 30,
        confidence: 0.8,
        reason: 'Test',
        alternativeHours: [],
        factors: {},
      );

      expect(recommendation.formattedTime, '20:30');
    });

    test('confidenceLevel returns correct value', () {
      const high = TimeRecommendation(
        suggestedHour: 9,
        suggestedMinute: 0,
        confidence: 0.8,
        reason: 'Test',
        alternativeHours: [],
        factors: {},
      );
      const medium = TimeRecommendation(
        suggestedHour: 9,
        suggestedMinute: 0,
        confidence: 0.55,
        reason: 'Test',
        alternativeHours: [],
        factors: {},
      );
      const low = TimeRecommendation(
        suggestedHour: 9,
        suggestedMinute: 0,
        confidence: 0.3,
        reason: 'Test',
        alternativeHours: [],
        factors: {},
      );

      expect(high.confidenceLevel, 'Alta');
      expect(medium.confidenceLevel, 'Media');
      expect(low.confidenceLevel, 'Bassa');
    });
  });

  group('TimeWindow', () {
    test('formattedRange returns correct format', () {
      const window = TimeWindow(
        startHour: 8,
        endHour: 10,
        label: 'Mattina',
        confidence: 0.7,
      );

      expect(window.formattedRange, '08:00 - 10:00');
    });
  });
}
