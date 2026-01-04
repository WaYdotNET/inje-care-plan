import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/ml/smart_suggestion_provider.dart';
import 'package:injecare_plan/core/ml/zone_prediction_model.dart';
import 'package:injecare_plan/core/ml/time_optimizer.dart';
import 'package:injecare_plan/core/ml/adherence_scorer.dart';
import 'package:injecare_plan/models/body_zone.dart';

void main() {
  group('SmartSuggestion', () {
    test('empty() factory creates suggestion with no data', () {
      final suggestion = SmartSuggestion.empty();

      expect(suggestion.topZonePrediction, isNull);
      expect(suggestion.timeRecommendation, isNull);
      expect(suggestion.adherenceScore, isNull);
      expect(suggestion.allZonePredictions, isEmpty);
      expect(suggestion.overallConfidence, 0);
      expect(suggestion.hasEnoughData, isFalse);
      expect(suggestion.mainMessage, contains('Inizia'));
    });

    test('confidencePercentage returns correct value', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.85,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidencePercentage, 85);
    });

    test('hasZoneSuggestion returns true when topZonePrediction exists', () {
      const testZone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const prediction = ZonePrediction(
        zone: testZone,
        score: 0.8,
        confidence: 0.9,
        reason: 'Test reason',
        factors: {},
      );

      const suggestion = SmartSuggestion(
        topZonePrediction: prediction,
        overallConfidence: 0.85,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.hasZoneSuggestion, isTrue);
    });

    test('hasZoneSuggestion returns false when topZonePrediction is null', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.5,
        mainMessage: 'Test',
        hasEnoughData: false,
      );

      expect(suggestion.hasZoneSuggestion, isFalse);
    });

    test('hasTimeSuggestion returns true for high confidence time rec', () {
      const timeRec = TimeRecommendation(
        suggestedHour: 20,
        suggestedMinute: 0,
        confidence: 0.8,
        reason: 'Test reason',
        alternativeHours: [19, 21],
        factors: {},
      );

      const suggestion = SmartSuggestion(
        timeRecommendation: timeRec,
        overallConfidence: 0.7,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.hasTimeSuggestion, isTrue);
    });

    test('hasTimeSuggestion returns false for low confidence time rec', () {
      const timeRec = TimeRecommendation(
        suggestedHour: 20,
        suggestedMinute: 0,
        confidence: 0.2, // Below 0.3 threshold
        reason: 'Test reason',
        alternativeHours: [],
        factors: {},
      );

      const suggestion = SmartSuggestion(
        timeRecommendation: timeRec,
        overallConfidence: 0.7,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.hasTimeSuggestion, isFalse);
    });

    test('hasTimeSuggestion returns false when timeRecommendation is null', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.7,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.hasTimeSuggestion, isFalse);
    });

    test('confidenceLevel returns Alta for >= 0.75', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.75,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceLevel, 'Alta');
    });

    test('confidenceLevel returns Media for >= 0.50', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.55,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceLevel, 'Media');
    });

    test('confidenceLevel returns Bassa for >= 0.30', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.35,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceLevel, 'Bassa');
    });

    test('confidenceLevel returns Insufficiente for < 0.30', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.2,
        mainMessage: 'Test',
        hasEnoughData: false,
      );

      expect(suggestion.confidenceLevel, 'Insufficiente');
    });

    test('confidenceIcon returns correct icon for Alta', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.8,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceIcon, '🎯');
    });

    test('confidenceIcon returns correct icon for Media', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.6,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceIcon, '💡');
    });

    test('confidenceIcon returns correct icon for Bassa', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.35,
        mainMessage: 'Test',
        hasEnoughData: true,
      );

      expect(suggestion.confidenceIcon, '🤔');
    });

    test('confidenceIcon returns correct icon for Insufficiente', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.1,
        mainMessage: 'Test',
        hasEnoughData: false,
      );

      expect(suggestion.confidenceIcon, '📊');
    });

    test('secondarySuggestions can contain multiple suggestions', () {
      const suggestion = SmartSuggestion(
        overallConfidence: 0.7,
        mainMessage: 'Test',
        hasEnoughData: true,
        secondarySuggestions: [
          'Suggestion 1',
          'Suggestion 2',
          'Suggestion 3',
        ],
      );

      expect(suggestion.secondarySuggestions.length, 3);
      expect(suggestion.secondarySuggestions[0], 'Suggestion 1');
    });

    test('allZonePredictions can contain multiple predictions', () {
      const testZone1 = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const testZone2 = BodyZone(
        id: 2,
        code: 'CS',
        name: 'Coscia Sinistra',
        type: 'thigh',
        side: 'left',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 2,
      );

      const prediction1 = ZonePrediction(
        zone: testZone1,
        score: 0.9,
        confidence: 0.85,
        reason: 'Reason 1',
        factors: {},
      );

      const prediction2 = ZonePrediction(
        zone: testZone2,
        score: 0.7,
        confidence: 0.75,
        reason: 'Reason 2',
        factors: {},
      );

      final suggestion = SmartSuggestion(
        topZonePrediction: prediction1,
        overallConfidence: 0.85,
        mainMessage: 'Suggerisco Coscia Destra',
        hasEnoughData: true,
        allZonePredictions: [prediction1, prediction2],
      );

      expect(suggestion.allZonePredictions.length, 2);
      expect(suggestion.allZonePredictions[0].zone.code, 'CD');
      expect(suggestion.allZonePredictions[1].zone.code, 'CS');
    });

    test('full suggestion with all components', () {
      const testZone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const zonePrediction = ZonePrediction(
        zone: testZone,
        score: 0.85,
        confidence: 0.9,
        reason: 'Zona non usata da tempo',
        factors: {'daysSinceLastUse': 10.0},
      );

      const timeRec = TimeRecommendation(
        suggestedHour: 20,
        suggestedMinute: 30,
        confidence: 0.8,
        reason: 'Orario con massima aderenza',
        alternativeHours: [19, 21],
        factors: {},
      );

      const adherenceScoreData = AdherenceScore(
        currentRate: 0.85,
        riskLevel: RiskLevel.low,
        trendDirection: TrendDirection.slightlyImproving,
        currentStreak: 5,
        predictedNextWeek: 0.88,
        recommendations: ['Continua così!'],
        insights: [],
        factors: {'adherence': 0.85},
      );

      final suggestion = SmartSuggestion(
        topZonePrediction: zonePrediction,
        timeRecommendation: timeRec,
        adherenceScore: adherenceScoreData,
        allZonePredictions: [zonePrediction],
        overallConfidence: 0.85,
        mainMessage: 'Suggerisco Coscia Destra alle 20:30',
        secondarySuggestions: ['Continua così!'],
        hasEnoughData: true,
      );

      expect(suggestion.hasZoneSuggestion, isTrue);
      expect(suggestion.hasTimeSuggestion, isTrue);
      expect(suggestion.confidenceLevel, 'Alta');
      expect(suggestion.confidenceIcon, '🎯');
      expect(suggestion.confidencePercentage, 85);
      expect(suggestion.mainMessage, contains('Coscia Destra'));
      expect(suggestion.mainMessage, contains('20:30'));
    });
  });
}
