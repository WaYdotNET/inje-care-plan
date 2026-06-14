import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart' as db;
import 'package:injecare_plan/features/injection/injection_provider.dart';

db.Injection _makeInjection({
  required int id,
  required DateTime scheduledAt,
  required String status,
}) {
  final now = DateTime.now();
  return db.Injection(
    id: id,
    zoneId: 1,
    pointNumber: 1,
    pointCode: 'CD-1',
    pointLabel: 'Coscia Dx - 1',
    scheduledAt: scheduledAt,
    status: status,
    notes: '',
    sideEffects: '',
    calendarEventId: '',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // Anchor "today" to a fixed datetime so tests are deterministic.
  final now = DateTime(2025, 6, 14, 22, 0); // 22:00 on 14 Jun 2025
  final todayAt8 = DateTime(2025, 6, 14, 8, 0); // earlier today
  final todayAt23 = DateTime(2025, 6, 14, 23, 0); // still today, future
  final tomorrow = DateTime(2025, 6, 15, 8, 0);
  final yesterday = DateTime(2025, 6, 13, 20, 0);

  group('pickNextScheduled', () {
    test(
      "bug fix: today's scheduled injection (time already past) is returned, not null",
      () {
        // scheduledAt = today 08:00, now = today 22:00 — time passed but same day
        final inj = _makeInjection(
          id: 1,
          scheduledAt: todayAt8,
          status: 'scheduled',
        );

        final result = pickNextScheduled([inj], now);

        expect(result, isNotNull);
        expect(result!.id, 1);
      },
    );

    test(
      'returns the earliest injection when both a past-time-today and a future one exist',
      () {
        final todayInj = _makeInjection(
          id: 1,
          scheduledAt: todayAt8,
          status: 'scheduled',
        );
        final tomorrowInj = _makeInjection(
          id: 2,
          scheduledAt: tomorrow,
          status: 'scheduled',
        );

        final result = pickNextScheduled([tomorrowInj, todayInj], now);

        // must return the earliest (today's), not tomorrow's
        expect(result, isNotNull);
        expect(result!.id, 1);
      },
    );

    test('delayed status is treated like scheduled (included)', () {
      final inj = _makeInjection(
        id: 3,
        scheduledAt: todayAt23,
        status: 'delayed',
      );

      final result = pickNextScheduled([inj], now);

      expect(result, isNotNull);
      expect(result!.id, 3);
    });

    test('completed injection today is excluded', () {
      final inj = _makeInjection(
        id: 4,
        scheduledAt: todayAt8,
        status: 'completed',
      );

      final result = pickNextScheduled([inj], now);

      expect(result, isNull);
    });

    test('scheduled injection from before today (yesterday) is excluded', () {
      final inj = _makeInjection(
        id: 5,
        scheduledAt: yesterday,
        status: 'scheduled',
      );

      final result = pickNextScheduled([inj], now);

      expect(result, isNull);
    });

    test('empty list returns null', () {
      expect(pickNextScheduled(const [], now), isNull);
    });
  });
}
