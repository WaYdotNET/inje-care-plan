import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/ml/zone_prediction_model.dart';
import 'package:injecare_plan/core/ml/ml_data_collector.dart';
import 'package:injecare_plan/models/body_zone.dart';

void main() {
  late ZonePredictionModel model;

  setUp(() {
    model = ZonePredictionModel();
  });

  group('ZonePredictionModel.predict', () {
    test('returns empty list for empty input', () {
      final predictions = model.predict([]);
      expect(predictions, isEmpty);
    });

    test('filters out disabled zones', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', isEnabled: true),
        _createZoneData(id: 2, code: 'CS', isEnabled: false),
      ];

      final predictions = model.predict(data);

      expect(predictions.length, 1);
      expect(predictions.first.zone.code, 'CD');
    });

    test('filters out fully blacklisted zones', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', fullyBlacklisted: false),
        _createZoneData(id: 2, code: 'CS', fullyBlacklisted: true),
      ];

      final predictions = model.predict(data);

      expect(predictions.length, 1);
      expect(predictions.first.zone.code, 'CD');
    });

    test('prioritizes never used zones', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', neverUsed: false, daysSinceLastInjection: 5),
        _createZoneData(id: 2, code: 'CS', neverUsed: true),
      ];

      final predictions = model.predict(data);

      expect(predictions.first.zone.code, 'CS');
      expect(predictions.first.reason, contains('mai utilizzata'));
    });

    test('prioritizes zones not used for longer', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', daysSinceLastInjection: 3),
        _createZoneData(id: 2, code: 'CS', daysSinceLastInjection: 14),
        _createZoneData(id: 3, code: 'BD', daysSinceLastInjection: 7),
      ];

      final predictions = model.predict(data);

      expect(predictions.first.zone.code, 'CS');
      expect(predictions[1].zone.code, 'BD');
      expect(predictions[2].zone.code, 'CD');
    });

    test('considers completion rate in scoring', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', completionRate: 0.95, daysSinceLastInjection: 7),
        _createZoneData(id: 2, code: 'CS', completionRate: 0.50, daysSinceLastInjection: 7),
      ];

      final predictions = model.predict(data);

      // Higher completion rate should score higher when days are equal
      expect(predictions.first.zone.code, 'CD');
    });

    test('returns predictions sorted by score descending', () {
      final data = [
        _createZoneData(id: 1, code: 'CD', daysSinceLastInjection: 1),
        _createZoneData(id: 2, code: 'CS', daysSinceLastInjection: 10),
        _createZoneData(id: 3, code: 'BD', daysSinceLastInjection: 5),
      ];

      final predictions = model.predict(data);

      for (int i = 0; i < predictions.length - 1; i++) {
        expect(predictions[i].score, greaterThanOrEqualTo(predictions[i + 1].score));
      }
    });
  });

  group('ZonePrediction', () {
    test('scorePercentage returns correct value', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.75,
        reason: 'Test reason',
        confidence: 0.8,
      );

      expect(prediction.scorePercentage, 75);
    });

    test('confidencePercentage returns correct value', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.75,
        reason: 'Test reason',
        confidence: 0.65,
      );

      expect(prediction.confidencePercentage, 65);
    });

    test('confidenceLevel returns Alta for high confidence', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.8,
        reason: 'Test',
        confidence: 0.80,
      );

      expect(prediction.confidenceLevel, 'Alta');
    });

    test('confidenceLevel returns Media for medium confidence', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.8,
        reason: 'Test',
        confidence: 0.55,
      );

      expect(prediction.confidenceLevel, 'Media');
    });

    test('confidenceLevel returns Bassa for low confidence', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.8,
        reason: 'Test',
        confidence: 0.30,
      );

      expect(prediction.confidenceLevel, 'Bassa');
    });

    test('scoreIcon returns green for high score', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.85,
        reason: 'Test',
        confidence: 0.8,
      );

      expect(prediction.scoreIcon, '🟢');
    });

    test('scoreIcon returns yellow for medium score', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.65,
        reason: 'Test',
        confidence: 0.8,
      );

      expect(prediction.scoreIcon, '🟡');
    });

    test('scoreIcon returns orange for low-medium score', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.45,
        reason: 'Test',
        confidence: 0.8,
      );

      expect(prediction.scoreIcon, '🟠');
    });

    test('scoreIcon returns red for low score', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Test', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.25,
        reason: 'Test',
        confidence: 0.8,
      );

      expect(prediction.scoreIcon, '🔴');
    });

    test('toString returns formatted string', () {
      const prediction = ZonePrediction(
        zone: BodyZone(id: 1, code: 'CD', name: 'Coscia Destra', type: 'thigh', side: 'right', numberOfPoints: 6, isEnabled: true, sortOrder: 1),
        score: 0.75,
        reason: 'Non usata da 7 giorni',
        confidence: 0.8,
      );

      final str = prediction.toString();
      expect(str, contains('ZonePrediction'));
      expect(str, contains('75%'));
    });
  });
}

ZoneInjectionData _createZoneData({
  required int id,
  required String code,
  bool isEnabled = true,
  bool fullyBlacklisted = false,
  bool neverUsed = false,
  int? daysSinceLastInjection,
  double completionRate = 0.75,
  int totalInjections = 5,
  int availablePointsCount = 4,
}) {
  final completedCount = (totalInjections * completionRate).round();
  return ZoneInjectionData(
    zone: BodyZone(
      id: id,
      code: code,
      name: 'Test Zone $code',
      type: 'thigh',
      side: 'right',
      numberOfPoints: 6,
      isEnabled: isEnabled,
      sortOrder: id,
    ),
    totalInjections: neverUsed ? 0 : totalInjections,
    completedCount: completedCount,
    skippedCount: totalInjections - completedCount,
    completionRate: completionRate,
    lastInjectionDate: neverUsed
        ? null
        : daysSinceLastInjection != null
            ? DateTime.now().subtract(Duration(days: daysSinceLastInjection))
            : null,
    daysSinceLastInjection: neverUsed ? null : daysSinceLastInjection,
    blacklistedPointsCount: fullyBlacklisted ? 6 : 0,
    availablePointsCount: fullyBlacklisted ? 0 : availablePointsCount,
  );
}
