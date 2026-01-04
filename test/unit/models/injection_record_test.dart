import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/models/injection_record.dart';

void main() {
  group('InjectionStatus', () {
    test('should have all expected values', () {
      expect(InjectionStatus.values, hasLength(4));
      expect(InjectionStatus.values, contains(InjectionStatus.scheduled));
      expect(InjectionStatus.values, contains(InjectionStatus.completed));
      expect(InjectionStatus.values, contains(InjectionStatus.skipped));
      expect(InjectionStatus.values, contains(InjectionStatus.delayed));
    });
  });

  group('InjectionRecord', () {
    late InjectionRecord record;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      record = InjectionRecord(
        id: 1,
        zoneId: 1,
        pointNumber: 3,
        scheduledAt: DateTime(2024, 1, 15, 20, 0),
        status: InjectionStatus.scheduled,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('creates with required fields', () {
      expect(record.id, 1);
      expect(record.zoneId, 1);
      expect(record.pointNumber, 3);
      expect(record.status, InjectionStatus.scheduled);
    });

    test('creates with default values', () {
      expect(record.completedAt, isNull);
      expect(record.notes, '');
      expect(record.sideEffects, isEmpty);
      expect(record.calendarEventId, '');
    });

    test('creates with all optional fields', () {
      final fullRecord = InjectionRecord(
        id: 1,
        zoneId: 2,
        pointNumber: 3,
        scheduledAt: DateTime(2024, 1, 15, 20, 0),
        completedAt: DateTime(2024, 1, 15, 20, 5),
        status: InjectionStatus.completed,
        notes: 'Test note',
        sideEffects: ['rossore', 'gonfiore'],
        calendarEventId: 'cal-123',
        createdAt: now,
        updatedAt: now,
      );

      expect(fullRecord.completedAt, isNotNull);
      expect(fullRecord.notes, 'Test note');
      expect(fullRecord.sideEffects, ['rossore', 'gonfiore']);
      expect(fullRecord.calendarEventId, 'cal-123');
    });

    group('zoneCode getter', () {
      test('returns CD for zoneId 1', () {
        final r = record.copyWith(zoneId: 1);
        expect(r.zoneCode, 'CD');
      });

      test('returns CS for zoneId 2', () {
        final r = record.copyWith(zoneId: 2);
        expect(r.zoneCode, 'CS');
      });

      test('returns BD for zoneId 3', () {
        final r = record.copyWith(zoneId: 3);
        expect(r.zoneCode, 'BD');
      });

      test('returns BS for zoneId 4', () {
        final r = record.copyWith(zoneId: 4);
        expect(r.zoneCode, 'BS');
      });

      test('returns AD for zoneId 5', () {
        final r = record.copyWith(zoneId: 5);
        expect(r.zoneCode, 'AD');
      });

      test('returns AS for zoneId 6', () {
        final r = record.copyWith(zoneId: 6);
        expect(r.zoneCode, 'AS');
      });

      test('returns GD for zoneId 7', () {
        final r = record.copyWith(zoneId: 7);
        expect(r.zoneCode, 'GD');
      });

      test('returns GS for zoneId 8', () {
        final r = record.copyWith(zoneId: 8);
        expect(r.zoneCode, 'GS');
      });

      test('returns ?? for unknown zoneId', () {
        final r = record.copyWith(zoneId: 99);
        expect(r.zoneCode, '??');
      });
    });

    group('zoneName getter', () {
      test('returns Coscia Dx for zoneId 1', () {
        final r = record.copyWith(zoneId: 1);
        expect(r.zoneName, 'Coscia Dx');
      });

      test('returns Coscia Sx for zoneId 2', () {
        final r = record.copyWith(zoneId: 2);
        expect(r.zoneName, 'Coscia Sx');
      });

      test('returns Sconosciuto for unknown zoneId', () {
        final r = record.copyWith(zoneId: 99);
        expect(r.zoneName, 'Sconosciuto');
      });
    });

    test('pointCode returns formatted code', () {
      expect(record.pointCode, 'CD-3');
    });

    test('pointLabel returns formatted label', () {
      expect(record.pointLabel, 'Coscia Dx · 3');
    });

    group('emoji getter', () {
      test('returns leg emoji for thigh zones', () {
        expect(record.copyWith(zoneId: 1).emoji, '🦵');
        expect(record.copyWith(zoneId: 2).emoji, '🦵');
      });

      test('returns arm emoji for arm zones', () {
        expect(record.copyWith(zoneId: 3).emoji, '💪');
        expect(record.copyWith(zoneId: 4).emoji, '💪');
      });

      test('returns abdomen emoji for abdomen zones', () {
        expect(record.copyWith(zoneId: 5).emoji, '🫁');
        expect(record.copyWith(zoneId: 6).emoji, '🫁');
      });

      test('returns buttock emoji for buttock zones', () {
        expect(record.copyWith(zoneId: 7).emoji, '🍑');
        expect(record.copyWith(zoneId: 8).emoji, '🍑');
      });

      test('returns pin emoji for unknown zones', () {
        expect(record.copyWith(zoneId: 99).emoji, '📍');
      });
    });

    test('copyWith creates new record with updated values', () {
      final updated = record.copyWith(
        pointNumber: 5,
        status: InjectionStatus.completed,
        notes: 'Updated note',
      );

      expect(updated.id, 1);
      expect(updated.pointNumber, 5);
      expect(updated.status, InjectionStatus.completed);
      expect(updated.notes, 'Updated note');
    });

    test('copyWith preserves unchanged values', () {
      final updated = record.copyWith(notes: 'New note');

      expect(updated.id, record.id);
      expect(updated.zoneId, record.zoneId);
      expect(updated.pointNumber, record.pointNumber);
      expect(updated.scheduledAt, record.scheduledAt);
    });

    test('toJson converts to JSON map', () {
      final completedRecord = InjectionRecord(
        id: 1,
        zoneId: 2,
        pointNumber: 3,
        scheduledAt: DateTime(2024, 1, 15, 20, 0),
        completedAt: DateTime(2024, 1, 15, 20, 5),
        status: InjectionStatus.completed,
        notes: 'Test',
        sideEffects: ['rossore'],
        calendarEventId: 'cal-123',
        createdAt: now,
        updatedAt: now,
      );

      final json = completedRecord.toJson();

      expect(json['id'], 1);
      expect(json['zoneId'], 2);
      expect(json['pointNumber'], 3);
      expect(json['pointCode'], 'CS-3');
      expect(json['pointLabel'], 'Coscia Sx · 3');
      expect(json['status'], 'completed');
      expect(json['notes'], 'Test');
      expect(json['sideEffects'], 'rossore');
      expect(json['calendarEventId'], 'cal-123');
    });

    test('fromJson parses JSON map', () {
      final json = {
        'id': 1,
        'zoneId': 2,
        'pointNumber': 3,
        'scheduledAt': '2024-01-15T20:00:00.000',
        'completedAt': '2024-01-15T20:05:00.000',
        'status': 'completed',
        'notes': 'Test',
        'sideEffects': 'rossore,gonfiore',
        'calendarEventId': 'cal-123',
        'createdAt': '2024-01-15T20:00:00.000',
        'updatedAt': '2024-01-15T20:05:00.000',
      };

      final parsed = InjectionRecord.fromJson(json);

      expect(parsed.id, 1);
      expect(parsed.zoneId, 2);
      expect(parsed.status, InjectionStatus.completed);
      expect(parsed.sideEffects, ['rossore', 'gonfiore']);
    });

    test('fromJson handles empty sideEffects', () {
      final json = {
        'id': 1,
        'zoneId': 2,
        'pointNumber': 3,
        'scheduledAt': '2024-01-15T20:00:00.000',
        'status': 'scheduled',
        'sideEffects': '',
        'createdAt': '2024-01-15T20:00:00.000',
        'updatedAt': '2024-01-15T20:05:00.000',
      };

      final parsed = InjectionRecord.fromJson(json);
      expect(parsed.sideEffects, isEmpty);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'zoneId': 2,
        'pointNumber': 3,
        'scheduledAt': '2024-01-15T20:00:00.000',
        'status': 'scheduled',
        'createdAt': '2024-01-15T20:00:00.000',
        'updatedAt': '2024-01-15T20:05:00.000',
      };

      final parsed = InjectionRecord.fromJson(json);
      expect(parsed.notes, '');
      expect(parsed.sideEffects, isEmpty);
      expect(parsed.calendarEventId, '');
    });

    test('fromJson defaults to scheduled for unknown status', () {
      final json = {
        'id': 1,
        'zoneId': 2,
        'pointNumber': 3,
        'scheduledAt': '2024-01-15T20:00:00.000',
        'status': 'unknown_status',
        'createdAt': '2024-01-15T20:00:00.000',
        'updatedAt': '2024-01-15T20:05:00.000',
      };

      final parsed = InjectionRecord.fromJson(json);
      expect(parsed.status, InjectionStatus.scheduled);
    });

    test('scheduled factory creates a scheduled injection', () {
      final scheduled = InjectionRecord.scheduled(
        zoneId: 1,
        pointNumber: 3,
        scheduledAt: DateTime(2024, 1, 15, 20, 0),
      );

      expect(scheduled.zoneId, 1);
      expect(scheduled.pointNumber, 3);
      expect(scheduled.status, InjectionStatus.scheduled);
      expect(scheduled.createdAt, isNotNull);
      expect(scheduled.updatedAt, isNotNull);
    });
  });
}
