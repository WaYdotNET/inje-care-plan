import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/models/blacklisted_point.dart';

void main() {
  group('BlacklistReason', () {
    test('should have all expected values', () {
      expect(BlacklistReason.values, hasLength(4));
      expect(BlacklistReason.values, contains(BlacklistReason.skinReaction));
      expect(BlacklistReason.values, contains(BlacklistReason.scar));
      expect(BlacklistReason.values, contains(BlacklistReason.hardToReach));
      expect(BlacklistReason.values, contains(BlacklistReason.other));
    });
  });

  group('BlacklistedPoint', () {
    late BlacklistedPoint point;
    late DateTime blacklistedAt;

    setUp(() {
      blacklistedAt = DateTime(2024, 1, 15, 10, 30);
      point = BlacklistedPoint(
        id: 1,
        zoneId: 1,
        pointNumber: 3,
        reason: 'skinReaction',
        blacklistedAt: blacklistedAt,
      );
    });

    test('creates with required fields', () {
      expect(point.id, 1);
      expect(point.zoneId, 1);
      expect(point.pointNumber, 3);
      expect(point.reason, 'skinReaction');
      expect(point.blacklistedAt, blacklistedAt);
    });

    test('creates with default notes', () {
      expect(point.notes, '');
    });

    test('creates with custom notes', () {
      final withNotes = BlacklistedPoint(
        id: 1,
        zoneId: 1,
        pointNumber: 3,
        reason: 'scar',
        notes: 'Evitare questa zona',
        blacklistedAt: blacklistedAt,
      );

      expect(withNotes.notes, 'Evitare questa zona');
    });

    group('zoneCode getter', () {
      test('returns CD for zoneId 1', () {
        expect(point.copyWith(zoneId: 1).zoneCode, 'CD');
      });

      test('returns CS for zoneId 2', () {
        expect(point.copyWith(zoneId: 2).zoneCode, 'CS');
      });

      test('returns BD for zoneId 3', () {
        expect(point.copyWith(zoneId: 3).zoneCode, 'BD');
      });

      test('returns BS for zoneId 4', () {
        expect(point.copyWith(zoneId: 4).zoneCode, 'BS');
      });

      test('returns AD for zoneId 5', () {
        expect(point.copyWith(zoneId: 5).zoneCode, 'AD');
      });

      test('returns AS for zoneId 6', () {
        expect(point.copyWith(zoneId: 6).zoneCode, 'AS');
      });

      test('returns GD for zoneId 7', () {
        expect(point.copyWith(zoneId: 7).zoneCode, 'GD');
      });

      test('returns GS for zoneId 8', () {
        expect(point.copyWith(zoneId: 8).zoneCode, 'GS');
      });

      test('returns ?? for unknown zoneId', () {
        expect(point.copyWith(zoneId: 99).zoneCode, '??');
      });
    });

    group('zoneName getter', () {
      test('returns Coscia Dx for zoneId 1', () {
        expect(point.copyWith(zoneId: 1).zoneName, 'Coscia Dx');
      });

      test('returns Coscia Sx for zoneId 2', () {
        expect(point.copyWith(zoneId: 2).zoneName, 'Coscia Sx');
      });

      test('returns Braccio Dx for zoneId 3', () {
        expect(point.copyWith(zoneId: 3).zoneName, 'Braccio Dx');
      });

      test('returns Braccio Sx for zoneId 4', () {
        expect(point.copyWith(zoneId: 4).zoneName, 'Braccio Sx');
      });

      test('returns Addome Dx for zoneId 5', () {
        expect(point.copyWith(zoneId: 5).zoneName, 'Addome Dx');
      });

      test('returns Addome Sx for zoneId 6', () {
        expect(point.copyWith(zoneId: 6).zoneName, 'Addome Sx');
      });

      test('returns Gluteo Dx for zoneId 7', () {
        expect(point.copyWith(zoneId: 7).zoneName, 'Gluteo Dx');
      });

      test('returns Gluteo Sx for zoneId 8', () {
        expect(point.copyWith(zoneId: 8).zoneName, 'Gluteo Sx');
      });

      test('returns Sconosciuto for unknown zoneId', () {
        expect(point.copyWith(zoneId: 99).zoneName, 'Sconosciuto');
      });
    });

    test('pointCode returns formatted code', () {
      expect(point.pointCode, 'CD-3');
    });

    test('pointLabel returns formatted label', () {
      expect(point.pointLabel, 'Coscia Dx · 3');
    });

    group('reasonLabel getter', () {
      test('returns Italian label for skinReaction', () {
        expect(point.copyWith(reason: 'skinReaction').reasonLabel, 'Reazione cutanea');
      });

      test('returns Italian label for scar', () {
        expect(point.copyWith(reason: 'scar').reasonLabel, 'Cicatrice / lesione');
      });

      test('returns Italian label for hardToReach', () {
        expect(point.copyWith(reason: 'hardToReach').reasonLabel, 'Difficile da raggiungere');
      });

      test('returns Italian label for other', () {
        expect(point.copyWith(reason: 'other').reasonLabel, 'Altro');
      });

      test('returns raw reason for unknown values', () {
        expect(point.copyWith(reason: 'customReason').reasonLabel, 'customReason');
      });
    });

    test('copyWith creates new point with updated values', () {
      final updated = point.copyWith(
        reason: 'scar',
        notes: 'New notes',
      );

      expect(updated.id, 1);
      expect(updated.reason, 'scar');
      expect(updated.notes, 'New notes');
    });

    test('copyWith preserves unchanged values', () {
      final updated = point.copyWith(notes: 'Just notes');

      expect(updated.id, point.id);
      expect(updated.zoneId, point.zoneId);
      expect(updated.pointNumber, point.pointNumber);
      expect(updated.reason, point.reason);
      expect(updated.blacklistedAt, point.blacklistedAt);
    });

    test('toJson converts to JSON map', () {
      final json = point.toJson();

      expect(json['id'], 1);
      expect(json['zoneId'], 1);
      expect(json['pointNumber'], 3);
      expect(json['pointCode'], 'CD-3');
      expect(json['pointLabel'], 'Coscia Dx · 3');
      expect(json['reason'], 'skinReaction');
      expect(json['notes'], '');
      expect(json['blacklistedAt'], isNotNull);
    });

    test('fromJson parses JSON map', () {
      final json = {
        'id': 1,
        'zoneId': 2,
        'pointNumber': 3,
        'reason': 'scar',
        'notes': 'Test note',
        'blacklistedAt': '2024-01-15T10:30:00.000',
      };

      final parsed = BlacklistedPoint.fromJson(json);

      expect(parsed.id, 1);
      expect(parsed.zoneId, 2);
      expect(parsed.pointNumber, 3);
      expect(parsed.reason, 'scar');
      expect(parsed.notes, 'Test note');
      expect(parsed.blacklistedAt, DateTime(2024, 1, 15, 10, 30));
    });

    test('fromJson handles missing optional notes', () {
      final json = {
        'id': 1,
        'zoneId': 1,
        'pointNumber': 3,
        'reason': 'hardToReach',
        'blacklistedAt': '2024-01-15T10:30:00.000',
      };

      final parsed = BlacklistedPoint.fromJson(json);
      expect(parsed.notes, '');
    });
  });
}
