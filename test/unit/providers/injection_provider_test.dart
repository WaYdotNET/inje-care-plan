import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:injecare_plan/features/injection/injection_provider.dart';
import 'package:injecare_plan/core/database/app_database.dart' as db;

void main() {
  group('WeeklyEventData', () {
    test('isSuggested returns true when no confirmed event but has suggestion', () {
      final data = WeeklyEventData(
        date: DateTime.now(),
        suggestion: (zoneId: 1, pointNumber: 1),
        isTherapyDay: true,
      );

      expect(data.isSuggested, true);
      expect(data.isConfirmed, false);
    });

    test('isConfirmed returns true when has confirmed event', () {
      final now = DateTime.now();
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx · 1',
        scheduledAt: now,
        status: 'completed',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final data = WeeklyEventData(
        date: now,
        confirmedEvent: injection,
        isTherapyDay: true,
      );

      expect(data.isConfirmed, true);
      expect(data.isSuggested, false);
    });

    test('isPast returns true for past dates', () {
      final data = WeeklyEventData(
        date: DateTime.now().subtract(const Duration(days: 2)),
        isTherapyDay: true,
      );

      expect(data.isPast, true);
    });

    test('isPast returns false for future dates', () {
      final data = WeeklyEventData(
        date: DateTime.now().add(const Duration(days: 2)),
        isTherapyDay: true,
      );

      expect(data.isPast, false);
    });

    test('status returns confirmed event status when present', () {
      final now = DateTime.now();
      final injection = db.Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx · 1',
        scheduledAt: now,
        status: 'completed',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: now,
        updatedAt: now,
      );

      final data = WeeklyEventData(
        date: now,
        confirmedEvent: injection,
        isTherapyDay: true,
      );

      expect(data.status, 'completed');
    });

    test('status returns missed for past dates without confirmed event', () {
      final data = WeeklyEventData(
        date: DateTime.now().subtract(const Duration(days: 2)),
        isTherapyDay: true,
      );

      expect(data.status, 'missed');
    });

    test('status returns suggested for future dates without confirmed event', () {
      final data = WeeklyEventData(
        date: DateTime.now().add(const Duration(days: 2)),
        suggestion: (zoneId: 1, pointNumber: 1),
        isTherapyDay: true,
      );

      expect(data.status, 'suggested');
    });
  });

  group('SelectedDayNotifier', () {
    test('select updates selected day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedDayProvider.notifier);
      final date = DateTime(2024, 7, 15);

      notifier.select(date);
      expect(container.read(selectedDayProvider), date);

      notifier.select(null);
      expect(container.read(selectedDayProvider), null);
    });
  });

  group('FocusedDayNotifier', () {
    test('focus updates focused day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(focusedDayProvider.notifier);
      final date = DateTime(2024, 7, 15);

      notifier.focus(date);
      expect(container.read(focusedDayProvider), date);
    });
  });
}
