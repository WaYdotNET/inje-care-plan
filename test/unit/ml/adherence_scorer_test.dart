import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/ml/adherence_scorer.dart';
import 'package:injecare_plan/core/ml/ml_data_collector.dart';

void main() {
  late AdherenceScorer scorer;

  setUp(() {
    scorer = AdherenceScorer();
  });

  group('AdherenceScorer.analyze', () {
    test('detects high risk for low adherence', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 10,
        totalSkipped: 10,
        adherenceRate: 0.5,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.riskLevel, RiskLevel.high);
    });

    test('detects low risk for high adherence', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 19,
        totalSkipped: 1,
        adherenceRate: 0.95,
        weeklyTrend: {},
        currentStreak: 10,
        trendDirection: 0.1,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.riskLevel, RiskLevel.low);
    });

    test('detects medium risk for average adherence', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 14, // 70%
        totalSkipped: 6,
        adherenceRate: 0.7,
        weeklyTrend: {},
        currentStreak: 2,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.riskLevel, RiskLevel.medium);
    });

    test('considers negative trend in risk calculation', () {
      const goodWithBadTrend = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18, // 90% but declining
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 3,
        trendDirection: -0.2,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(goodWithBadTrend, skipData);

      expect(score.riskLevel, RiskLevel.lowMedium);
    });

    test('generates recommendations for high risk', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 8,
        totalSkipped: 12,
        adherenceRate: 0.4,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: -0.1,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.recommendations, isNotEmpty);
      expect(score.recommendations.any((r) => r.contains('promemoria')), isTrue);
    });

    test('generates insights for streak', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 7,
        trendDirection: 0.05,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.insights.any((i) => i.title == 'Serie attiva'), isTrue);
    });

    test('includes risk days in recommendations', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 14,
        totalSkipped: 6,
        adherenceRate: 0.7,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [6, 7],
        riskHours: [],
        skipsByWeekday: {6: 3, 7: 5},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);

      expect(score.recommendations.any((r) => r.contains('Sab') || r.contains('Dom')), isTrue);
    });
  });

  group('AdherenceScore', () {
    test('currentRatePercentage returns correct value', () {
      const score = AdherenceScore(
        currentRate: 0.85,
        riskLevel: RiskLevel.low,
        trendDirection: TrendDirection.stable,
        currentStreak: 5,
        predictedNextWeek: 0.9,
        recommendations: [],
        insights: [],
        factors: {},
      );

      expect(score.currentRatePercentage, 85);
    });

    test('predictedPercentage returns correct value', () {
      const score = AdherenceScore(
        currentRate: 0.85,
        riskLevel: RiskLevel.low,
        trendDirection: TrendDirection.stable,
        currentStreak: 5,
        predictedNextWeek: 0.92,
        recommendations: [],
        insights: [],
        factors: {},
      );

      expect(score.predictedPercentage, 92);
    });

    test('riskColor returns correct color for each level', () {
      expect(_createScore(RiskLevel.low).riskColor, 'green');
      expect(_createScore(RiskLevel.lowMedium).riskColor, 'lightGreen');
      expect(_createScore(RiskLevel.medium).riskColor, 'orange');
      expect(_createScore(RiskLevel.mediumHigh).riskColor, 'deepOrange');
      expect(_createScore(RiskLevel.high).riskColor, 'red');
    });

    test('trendIcon returns correct icon for each direction', () {
      expect(_createScoreWithTrend(TrendDirection.improving).trendIcon, '📈');
      expect(_createScoreWithTrend(TrendDirection.slightlyImproving).trendIcon, '↗️');
      expect(_createScoreWithTrend(TrendDirection.stable).trendIcon, '➡️');
      expect(_createScoreWithTrend(TrendDirection.slightlyDeclining).trendIcon, '↘️');
      expect(_createScoreWithTrend(TrendDirection.declining).trendIcon, '📉');
    });
  });

  group('AdherenceInsight', () {
    test('creates insight with all fields', () {
      const insight = AdherenceInsight(
        type: InsightType.positive,
        title: 'Test Title',
        description: 'Test description',
        icon: '🔥',
      );

      expect(insight.type, InsightType.positive);
      expect(insight.title, 'Test Title');
      expect(insight.description, 'Test description');
      expect(insight.icon, '🔥');
    });
  });

  group('AdherenceScorer._calculateRiskLevel', () {
    test('detects mediumHigh risk for medium adherence with negative trend', () {
      // 65% adherence (medium) with strongly negative trend
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 13,
        totalSkipped: 7,
        adherenceRate: 0.65, // Between 0.6 and 0.8
        weeklyTrend: {},
        currentStreak: 1,
        trendDirection: -0.2, // Strongly negative (< -0.1)
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.riskLevel, RiskLevel.mediumHigh);
    });
  });

  group('AdherenceScorer._predictNextWeekAdherence', () {
    test('returns adherence rate when weekly trend is empty', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 10,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.predictedNextWeek, 0.9);
    });

    test('calculates prediction from weekly trend data', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {0: 0.8, 1: 0.85, 2: 0.9}, // 3 weeks
        currentStreak: 5,
        trendDirection: 0.1, // Positive trend
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      // Average of last 3: (0.9 + 0.85 + 0.8) / 3 = 0.85
      // Prediction: 0.85 + (0.1 * 0.5) = 0.90
      expect(score.predictedNextWeek, closeTo(0.90, 0.01));
    });

    test('clamps prediction to valid range', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 19,
        totalSkipped: 1,
        adherenceRate: 0.95,
        weeklyTrend: {0: 0.95, 1: 0.98, 2: 1.0},
        currentStreak: 10,
        trendDirection: 0.5, // Very positive trend
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      // Average: ~0.976, + 0.25 = 1.226 -> clamped to 1.0
      expect(score.predictedNextWeek, 1.0);
    });
  });

  group('AdherenceScorer._interpretTrend', () {
    test('detects improving trend (> 0.15)', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.2, // > 0.15 = improving
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.trendDirection, TrendDirection.improving);
    });

    test('detects slightlyImproving trend (0.05-0.15)', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.1, // 0.05 < 0.1 < 0.15 = slightlyImproving
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.trendDirection, TrendDirection.slightlyImproving);
    });

    test('detects declining trend (< -0.15)', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: -0.2, // < -0.15 = declining
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.trendDirection, TrendDirection.declining);
    });

    test('detects slightlyDeclining trend (-0.05 to -0.15)', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: -0.1, // -0.15 < -0.1 < -0.05 = slightlyDeclining
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.trendDirection, TrendDirection.slightlyDeclining);
    });
  });

  group('AdherenceScorer._generateRecommendations', () {
    test('generates recommendations for mediumHigh risk with highestRiskDay', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 13,
        totalSkipped: 7,
        adherenceRate: 0.65,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: -0.15,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [6], // Saturday
        riskHours: [],
        skipsByWeekday: {6: 5},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.recommendations.any((r) => r.contains('orari')), isTrue);
      expect(score.recommendations.any((r) => r.contains('Sab')), isTrue);
    });

    test('generates recommendations for medium risk with active streak', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 14,
        totalSkipped: 6,
        adherenceRate: 0.7,
        weeklyTrend: {},
        currentStreak: 3, // Has a streak
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.recommendations.any((r) => r.contains('Mantieni')), isTrue);
      expect(score.recommendations.any((r) => r.contains('3')), isTrue);
    });

    test('generates recommendations for medium risk without streak', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 14,
        totalSkipped: 6,
        adherenceRate: 0.7,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.recommendations.any((r) => r.contains('routine')), isTrue);
    });

    test('generates recommendations for lowMedium risk', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 3,
        trendDirection: -0.15, // Negative trend triggers lowMedium
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.recommendations.any((r) => r.contains('Buon lavoro')), isTrue);
    });

    test('generates recommendations for low risk with long streak', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 19,
        totalSkipped: 1,
        adherenceRate: 0.95,
        weeklyTrend: {},
        currentStreak: 10, // >= 7
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.recommendations.any((r) => r.contains('Eccellente')), isTrue);
      expect(score.recommendations.any((r) => r.contains('10 giorni')), isTrue);
    });
  });

  group('AdherenceScorer._generateInsights', () {
    test('generates improving trend insight', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.15, // > 0.1 = improvement insight
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.insights.any((i) => i.title == 'In miglioramento'), isTrue);
    });

    test('generates declining trend insight', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: -0.15, // < -0.1 = decline insight
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.insights.any((i) => i.title == 'In calo'), isTrue);
    });

    test('generates highest risk day insight', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 16,
        totalSkipped: 4,
        adherenceRate: 0.8,
        weeklyTrend: {},
        currentStreak: 2,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [6], // Saturday is riskiest
        riskHours: [],
        skipsByWeekday: {6: 4},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.insights.any((i) => i.title == 'Giorno critico'), isTrue);
    });

    test('generates excellent adherence insight for >= 90%', () {
      const adherenceData = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9, // 90%
        weeklyTrend: {},
        currentStreak: 5,
        trendDirection: 0.0,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final score = scorer.analyze(adherenceData, skipData);
      expect(score.insights.any((i) => i.title == 'Ottima aderenza'), isTrue);
    });
  });

  group('AdherenceScorer._riskLevelToScore', () {
    test('returns correct score for all risk levels', () {
      // This is tested implicitly through the factors map
      const adherenceDataLow = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 19,
        totalSkipped: 1,
        adherenceRate: 0.95,
        weeklyTrend: {},
        currentStreak: 10,
        trendDirection: 0.0,
      );
      const adherenceDataLowMedium = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 18,
        totalSkipped: 2,
        adherenceRate: 0.9,
        weeklyTrend: {},
        currentStreak: 3,
        trendDirection: -0.15,
      );
      const adherenceDataMediumHigh = AdherenceData(
        periodDays: 30,
        totalScheduled: 20,
        totalCompleted: 13,
        totalSkipped: 7,
        adherenceRate: 0.65,
        weeklyTrend: {},
        currentStreak: 0,
        trendDirection: -0.15,
      );
      const skipData = SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );

      final scoreLow = scorer.analyze(adherenceDataLow, skipData);
      expect(scoreLow.factors['riskScore'], 1.0);

      final scoreLowMedium = scorer.analyze(adherenceDataLowMedium, skipData);
      expect(scoreLowMedium.factors['riskScore'], 0.8);

      final scoreMediumHigh = scorer.analyze(adherenceDataMediumHigh, skipData);
      expect(scoreMediumHigh.factors['riskScore'], 0.4);
    });
  });
}

AdherenceScore _createScore(RiskLevel level) {
  return AdherenceScore(
    currentRate: 0.8,
    riskLevel: level,
    trendDirection: TrendDirection.stable,
    currentStreak: 5,
    predictedNextWeek: 0.8,
    recommendations: const [],
    insights: const [],
    factors: const {},
  );
}

AdherenceScore _createScoreWithTrend(TrendDirection trend) {
  return AdherenceScore(
    currentRate: 0.8,
    riskLevel: RiskLevel.low,
    trendDirection: trend,
    currentStreak: 5,
    predictedNextWeek: 0.8,
    recommendations: const [],
    insights: const [],
    factors: const {},
  );
}
