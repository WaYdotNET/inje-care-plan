import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart' as db;
import 'package:injecare_plan/features/injection/injection_provider.dart';

void main() {
  group('WeeklyEventData', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('can be created with required fields', () {
      final event = WeeklyEventData(
        date: today,
      );

      expect(event.date, today);
      expect(event.confirmedEvent, isNull);
      expect(event.suggestion, isNull);
      expect(event.isTherapyDay, isFalse);
      expect(event.preferredTime, isNull);
    });

    test('can be created with all fields', () {
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx - 1',
        scheduledAt: today,
        status: 'completed',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final event = WeeklyEventData(
        date: today,
        confirmedEvent: injection,
        isTherapyDay: true,
        preferredTime: '20:00',
      );

      expect(event.date, today);
      expect(event.confirmedEvent, injection);
      expect(event.isTherapyDay, isTrue);
      expect(event.preferredTime, '20:00');
    });

    test('isSuggested returns true when no confirmed event but has suggestion', () {
      final event = WeeklyEventData(
        date: today,
        suggestion: (zoneId: 1, pointNumber: 2),
        isTherapyDay: true,
      );

      expect(event.isSuggested, isTrue);
      expect(event.isConfirmed, isFalse);
    });

    test('isSuggested returns false when has confirmed event', () {
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx - 1',
        scheduledAt: today,
        status: 'scheduled',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final event = WeeklyEventData(
        date: today,
        confirmedEvent: injection,
        suggestion: (zoneId: 1, pointNumber: 2),
        isTherapyDay: true,
      );

      expect(event.isSuggested, isFalse);
      expect(event.isConfirmed, isTrue);
    });

    test('isConfirmed returns true when has confirmed event', () {
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx - 1',
        scheduledAt: today,
        status: 'completed',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final event = WeeklyEventData(
        date: today,
        confirmedEvent: injection,
      );

      expect(event.isConfirmed, isTrue);
    });

    test('isConfirmed returns false when no confirmed event', () {
      final event = WeeklyEventData(
        date: today,
      );

      expect(event.isConfirmed, isFalse);
    });

    test('isPast returns true for past dates', () {
      final pastDate = today.subtract(const Duration(days: 5));
      final event = WeeklyEventData(
        date: pastDate,
      );

      expect(event.isPast, isTrue);
    });

    test('isPast returns false for today', () {
      final event = WeeklyEventData(
        date: today,
      );

      expect(event.isPast, isFalse);
    });

    test('isPast returns false for future dates', () {
      final futureDate = today.add(const Duration(days: 5));
      final event = WeeklyEventData(
        date: futureDate,
      );

      expect(event.isPast, isFalse);
    });

    test('status returns confirmed event status when present', () {
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx - 1',
        scheduledAt: today,
        status: 'completed',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final event = WeeklyEventData(
        date: today,
        confirmedEvent: injection,
      );

      expect(event.status, 'completed');
    });

    test('status returns missed for past days without confirmed event', () {
      final pastDate = today.subtract(const Duration(days: 3));
      final event = WeeklyEventData(
        date: pastDate,
      );

      expect(event.status, 'missed');
    });

    test('status returns suggested for future days without confirmed event', () {
      final futureDate = today.add(const Duration(days: 3));
      final event = WeeklyEventData(
        date: futureDate,
        suggestion: (zoneId: 1, pointNumber: 1),
        isTherapyDay: true,
      );

      expect(event.status, 'suggested');
    });

    test('status returns suggested for today without confirmed event', () {
      final event = WeeklyEventData(
        date: today,
        suggestion: (zoneId: 1, pointNumber: 1),
        isTherapyDay: true,
      );

      expect(event.status, 'suggested');
    });
  });

  group('SelectedDayNotifier', () {
    test('initial state is null', () {
      final notifier = SelectedDayNotifier();
      expect(notifier.build(), isNull);
    });
  });

  group('FocusedDayNotifier', () {
    test('initial state is today', () {
      final notifier = FocusedDayNotifier();
      final now = DateTime.now();
      final result = notifier.build();

      expect(result.year, now.year);
      expect(result.month, now.month);
      expect(result.day, now.day);
    });
  });
}
