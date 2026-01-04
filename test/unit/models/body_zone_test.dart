import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/models/body_zone.dart';

void main() {
  group('BodyZone', () {
    test('creates with all required fields', () {
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
      expect(zone.type, 'thigh');
      expect(zone.side, 'right');
      expect(zone.numberOfPoints, 6);
      expect(zone.isEnabled, true);
      expect(zone.sortOrder, 1);
    });

    test('pointCount is alias for numberOfPoints', () {
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

      expect(zone.pointCount, zone.numberOfPoints);
    });

    test('totalPoints is alias for numberOfPoints', () {
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

      expect(zone.totalPoints, zone.numberOfPoints);
    });
  });

  group('BodyZone.displayName', () {
    test('returns customName when set', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        customName: 'My Thigh',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.displayName, 'My Thigh');
    });

    test('returns name when customName is null', () {
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

    test('returns name when customName is empty', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        customName: '',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.displayName, 'Coscia Destra');
    });
  });

  group('BodyZone.emoji', () {
    test('returns custom icon when set', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Test',
        icon: '🎯',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.emoji, '🎯');
    });

    test('returns default emoji for thigh', () {
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

      expect(zone.emoji, '🦵');
    });

    test('returns default emoji for arm', () {
      const zone = BodyZone(
        id: 1,
        code: 'BD',
        name: 'Test',
        type: 'arm',
        side: 'right',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.emoji, '💪');
    });

    test('returns default emoji for abdomen', () {
      const zone = BodyZone(
        id: 1,
        code: 'AD',
        name: 'Test',
        type: 'abdomen',
        side: 'right',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.emoji, '💧');
    });

    test('returns default emoji for buttock', () {
      const zone = BodyZone(
        id: 1,
        code: 'GD',
        name: 'Test',
        type: 'buttock',
        side: 'right',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.emoji, '🍑');
    });

    test('returns pin emoji for unknown type', () {
      const zone = BodyZone(
        id: 1,
        code: 'XX',
        name: 'Test',
        type: 'unknown',
        side: 'none',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.emoji, '📍');
    });
  });

  group('BodyZone.pointLabel', () {
    test('returns formatted label', () {
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

      expect(zone.pointLabel(3), 'Coscia Destra · 3');
    });
  });

  group('BodyZone.pointCode', () {
    test('returns formatted code', () {
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

      expect(zone.pointCode(3), 'CD-3');
    });
  });

  group('BodyZone static methods', () {
    test('typeFromCode returns correct type for thigh', () {
      expect(BodyZone.typeFromCode('CD'), 'thigh');
      expect(BodyZone.typeFromCode('CS'), 'thigh');
    });

    test('typeFromCode returns correct type for arm', () {
      expect(BodyZone.typeFromCode('BD'), 'arm');
      expect(BodyZone.typeFromCode('BS'), 'arm');
    });

    test('typeFromCode returns correct type for abdomen', () {
      expect(BodyZone.typeFromCode('AD'), 'abdomen');
      expect(BodyZone.typeFromCode('AS'), 'abdomen');
    });

    test('typeFromCode returns correct type for buttock', () {
      expect(BodyZone.typeFromCode('GD'), 'buttock');
      expect(BodyZone.typeFromCode('GS'), 'buttock');
    });

    test('typeFromCode returns custom for unknown', () {
      expect(BodyZone.typeFromCode('XX'), 'custom');
    });

    test('sideFromCode returns right for D suffix', () {
      expect(BodyZone.sideFromCode('CD'), 'right');
      expect(BodyZone.sideFromCode('BD'), 'right');
    });

    test('sideFromCode returns left for S suffix', () {
      expect(BodyZone.sideFromCode('CS'), 'left');
      expect(BodyZone.sideFromCode('BS'), 'left');
    });

    test('sideFromCode returns none for unknown', () {
      expect(BodyZone.sideFromCode('XX'), 'none');
    });
  });

  group('BodyZone.defaults', () {
    test('returns 8 default zones', () {
      expect(BodyZone.defaults.length, 8);
    });

    test('contains all zone types', () {
      final types = BodyZone.defaults.map((z) => z.type).toSet();
      expect(types, containsAll(['thigh', 'arm', 'abdomen', 'buttock']));
    });

    test('zones are ordered by sortOrder', () {
      final sortOrders = BodyZone.defaults.map((z) => z.sortOrder).toList();
      expect(sortOrders, [1, 2, 3, 4, 5, 6, 7, 8]);
    });
  });

  group('BodyZone.fromJson', () {
    test('parses full JSON', () {
      final json = {
        'id': 1,
        'code': 'CD',
        'name': 'Coscia Destra',
        'customName': 'My Thigh',
        'icon': '🎯',
        'type': 'thigh',
        'side': 'right',
        'numberOfPoints': 6,
        'isEnabled': true,
        'sortOrder': 1,
      };

      final zone = BodyZone.fromJson(json);

      expect(zone.id, 1);
      expect(zone.code, 'CD');
      expect(zone.customName, 'My Thigh');
      expect(zone.icon, '🎯');
    });

    test('uses defaults for optional fields', () {
      final json = {
        'id': 1,
        'code': 'CD',
        'name': 'Test',
        'numberOfPoints': 6,
      };

      final zone = BodyZone.fromJson(json);

      expect(zone.type, 'custom');
      expect(zone.side, 'none');
      expect(zone.isEnabled, true);
      expect(zone.sortOrder, 0);
    });
  });

  group('BodyZone.toJson', () {
    test('converts to JSON', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        customName: 'My Thigh',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      final json = zone.toJson();

      expect(json['id'], 1);
      expect(json['code'], 'CD');
      expect(json['customName'], 'My Thigh');
      expect(json['numberOfPoints'], 6);
    });
  });

  group('BodyZone.copyWith', () {
    test('copies with updated values', () {
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
        customName: 'New Name',
        isEnabled: false,
      );

      expect(updated.id, 1);
      expect(updated.customName, 'New Name');
      expect(updated.isEnabled, false);
      expect(updated.name, 'Coscia Destra');
    });
  });

  group('BodyZone equality', () {
    test('zones with same id are equal', () {
      const zone1 = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Zone 1',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );
      const zone2 = BodyZone(
        id: 1,
        code: 'CS',
        name: 'Zone 2',
        type: 'thigh',
        side: 'left',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 2,
      );

      expect(zone1, equals(zone2));
    });

    test('zones with different id are not equal', () {
      const zone1 = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Zone 1',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );
      const zone2 = BodyZone(
        id: 2,
        code: 'CD',
        name: 'Zone 1',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone1, isNot(equals(zone2)));
    });
  });
}
