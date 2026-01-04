import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/models/body_zone.dart';

void main() {
  group('BodyZone Model', () {
    test('creates zone with correct defaults', () {
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

      expect(zone.id, 1);
      expect(zone.code, 'CD');
      expect(zone.name, 'Coscia Destra');
      expect(zone.customName, null);
      expect(zone.isEnabled, true);
    });

    test('displayName returns customName when set', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        customName: 'My Custom Name',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.displayName, 'My Custom Name');
    });

    test('displayName returns name when customName is null', () {
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

      expect(zone.displayName, 'Coscia Destra');
    });

    test('totalPoints returns numberOfPoints', () {
      const zoneWith6 = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const zoneWith4 = BodyZone(
        id: 2,
        code: 'BD',
        name: 'Braccio Destro',
        type: 'arm',
        side: 'right',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 2,
      );

      expect(zoneWith6.totalPoints, 6);
      expect(zoneWith4.totalPoints, 4);
    });

    test('copyWith creates new zone with updated values', () {
      const original = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final updated = original.copyWith(
        customName: 'Custom',
        isEnabled: false,
      );

      expect(updated.id, 1);
      expect(updated.code, 'CD');
      expect(updated.name, 'Coscia Destra');
      expect(updated.customName, 'Custom');
      expect(updated.isEnabled, false);
    });

    test('copyWith preserves values when not specified', () {
      const original = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        customName: 'Custom',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final updated = original.copyWith(isEnabled: false);

      expect(updated.customName, 'Custom');
      expect(updated.numberOfPoints, 6);
      expect(updated.isEnabled, false);
    });
  });

  group('Zone Side', () {
    test('left zones have side = left', () {
      const zone = BodyZone(
        id: 1,
        code: 'CS',
        name: 'Coscia Sinistra',
        type: 'thigh',
        side: 'left',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.side, 'left');
    });

    test('right zones have side = right', () {
      const zone = BodyZone(
        id: 2,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.side, 'right');
    });
  });

  group('Zone Type', () {
    test('thigh type is recognized', () {
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

      expect(zone.type, 'thigh');
    });

    test('can create custom type zone', () {
      const zone = BodyZone(
        id: 1,
        code: 'CU',
        name: 'Custom Zone',
        type: 'custom',
        side: 'none',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.type, 'custom');
    });
  });
}
