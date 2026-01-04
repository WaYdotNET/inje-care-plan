import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/models/therapy_plan.dart';

void main() {
  group('TherapyPlan', () {
    test('creates with required fields', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.injectionsPerWeek, 3);
      expect(plan.weekDays, [1, 3, 5]);
      expect(plan.preferredTime, '20:00');
      expect(plan.notificationMinutesBefore, 30);
      expect(plan.missedDoseReminderEnabled, true);
    });

    test('defaults provides standard plan', () {
      final plan = TherapyPlan.defaults;

      expect(plan.injectionsPerWeek, 3);
      expect(plan.weekDays, [1, 3, 5]); // Mon, Wed, Fri
      expect(plan.preferredTime, '20:00');
    });
  });

  group('TherapyPlan.weekDayNames', () {
    test('returns correct day names', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.weekDayNames, ['Lun', 'Mer', 'Ven']);
    });

    test('handles weekend days', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 2,
        weekDays: [6, 7],
        preferredTime: '10:00',
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.weekDayNames, ['Sab', 'Dom']);
    });

    test('weekDaysString joins names with comma', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.weekDaysString, 'Lun, Mer, Ven');
    });
  });

  group('TherapyPlan.fromJson', () {
    test('parses JSON with list weekDays', () {
      final json = {
        'injectionsPerWeek': 3,
        'weekDays': [1, 3, 5],
        'preferredTime': '20:00',
        'startDate': '2026-01-01T00:00:00.000',
      };

      final plan = TherapyPlan.fromJson(json);

      expect(plan.injectionsPerWeek, 3);
      expect(plan.weekDays, [1, 3, 5]);
    });

    test('parses JSON with CSV weekDays', () {
      final json = {
        'injectionsPerWeek': 3,
        'weekDays': '1,3,5',
        'preferredTime': '20:00',
        'startDate': '2026-01-01T00:00:00.000',
      };

      final plan = TherapyPlan.fromJson(json);

      expect(plan.weekDays, [1, 3, 5]);
    });

    test('uses defaults for optional fields', () {
      final json = {
        'injectionsPerWeek': 3,
        'weekDays': [1, 3, 5],
        'preferredTime': '20:00',
        'startDate': '2026-01-01T00:00:00.000',
      };

      final plan = TherapyPlan.fromJson(json);

      expect(plan.notificationMinutesBefore, 30);
      expect(plan.missedDoseReminderEnabled, true);
    });
  });

  group('TherapyPlan.toJson', () {
    test('converts to JSON', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
        notificationMinutesBefore: 45,
        missedDoseReminderEnabled: false,
      );

      final json = plan.toJson();

      expect(json['injectionsPerWeek'], 3);
      expect(json['weekDays'], '1,3,5');
      expect(json['preferredTime'], '20:00');
      expect(json['notificationMinutesBefore'], 45);
      expect(json['missedDoseReminderEnabled'], false);
    });
  });

  group('TherapyPlan.copyWith', () {
    test('creates copy with updated values', () {
      final original = TherapyPlan.defaults;
      final updated = original.copyWith(
        injectionsPerWeek: 2,
        weekDays: [2, 4],
      );

      expect(updated.injectionsPerWeek, 2);
      expect(updated.weekDays, [2, 4]);
      expect(updated.preferredTime, original.preferredTime);
    });
  });

  group('TherapyPlan.getNextInjectionDate', () {
    test('returns today if today is injection day and time not passed', () {
      // Monday at 10:00
      final from = DateTime(2026, 1, 5, 10, 0); // Monday 10:00
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5], // Mon, Wed, Fri
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      final next = plan.getNextInjectionDate(from);

      expect(next.weekday, 1); // Monday
      expect(next.hour, 20);
      expect(next.minute, 0);
    });

    test('returns next injection day if today\'s time passed', () {
      // Monday at 21:00 (after 20:00)
      final from = DateTime(2026, 1, 5, 21, 0);
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      final next = plan.getNextInjectionDate(from);

      expect(next.weekday, 3); // Wednesday
    });

    test('skips non-injection days', () {
      // Tuesday at 10:00
      final from = DateTime(2026, 1, 6, 10, 0); // Tuesday
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5], // Mon, Wed, Fri
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      final next = plan.getNextInjectionDate(from);

      expect(next.weekday, 3); // Wednesday
    });
  });

  group('TherapyPlan.generateSchedule', () {
    test('generates schedule for date range', () {
      final from = DateTime(2026, 1, 5); // Monday
      final to = DateTime(2026, 1, 12); // Next Monday
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: [1, 3, 5], // Mon, Wed, Fri
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      final schedule = plan.generateSchedule(from, to);

      expect(schedule.length, 3); // Mon, Wed, Fri
      expect(schedule[0].weekday, 1); // Monday
      expect(schedule[1].weekday, 3); // Wednesday
      expect(schedule[2].weekday, 5); // Friday
    });

    test('includes correct time', () {
      final from = DateTime(2026, 1, 5);
      final to = DateTime(2026, 1, 7);
      final plan = TherapyPlan(
        injectionsPerWeek: 1,
        weekDays: [1],
        preferredTime: '09:30',
        startDate: DateTime(2026, 1, 1),
      );

      final schedule = plan.generateSchedule(from, to);

      expect(schedule.first.hour, 9);
      expect(schedule.first.minute, 30);
    });

    test('returns empty for range with no injection days', () {
      final from = DateTime(2026, 1, 6); // Tuesday
      final to = DateTime(2026, 1, 7); // Wednesday (excluded)
      final plan = TherapyPlan(
        injectionsPerWeek: 1,
        weekDays: [1], // Only Monday
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
      );

      final schedule = plan.generateSchedule(from, to);

      expect(schedule, isEmpty);
    });
  });
}

