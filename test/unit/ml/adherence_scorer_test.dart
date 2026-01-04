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
