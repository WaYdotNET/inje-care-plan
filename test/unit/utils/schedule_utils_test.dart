import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/utils/schedule_utils.dart';
import 'package:injecare_plan/models/therapy_plan.dart';

void main() {
  group('ScheduleUtils.nextTherapySlot', () {
    test('returns same-day slot if today is a plan day and time is in future', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: const [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
        notificationMinutesBefore: 30,
        missedDoseReminderEnabled: true,
      );

      final from = DateTime(2026, 1, 5, 8, 0); // Monday
      final next = ScheduleUtils.nextTherapySlot(from: from, plan: plan);
      expect(next, DateTime(2026, 1, 5, 20, 0));
    });

    test('skips to next plan day if today is not a plan day', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: const [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
        notificationMinutesBefore: 30,
        missedDoseReminderEnabled: true,
      );

      final from = DateTime(2026, 1, 6, 8, 0); // Tuesday
      final next = ScheduleUtils.nextTherapySlot(from: from, plan: plan);
      expect(next, DateTime(2026, 1, 7, 20, 0)); // Wednesday
    });

    test('moves to next plan day if time already passed today', () {
      final plan = TherapyPlan(
        injectionsPerWeek: 3,
        weekDays: const [1, 3, 5],
        preferredTime: '20:00',
        startDate: DateTime(2026, 1, 1),
        notificationMinutesBefore: 30,
        missedDoseReminderEnabled: true,
      );

      final from = DateTime(2026, 1, 5, 21, 0); // Monday, after preferred time
      final next = ScheduleUtils.nextTherapySlot(from: from, plan: plan);
      expect(next, DateTime(2026, 1, 7, 20, 0)); // Wednesday
    });
  });
}


