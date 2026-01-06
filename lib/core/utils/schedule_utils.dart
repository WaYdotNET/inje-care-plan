import '../../models/therapy_plan.dart';

/// Utilities for computing the next valid therapy slot based on the selected
/// week days and preferred time.
class ScheduleUtils {
  const ScheduleUtils._();

  static DateTime combinePreferredTime(DateTime day, String preferredTime) {
    final parts = preferredTime.split(':');
    final hour = parts.length >= 2 ? int.tryParse(parts[0]) ?? 20 : 20;
    final minute = parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Returns the next date/time that matches the plan weekday list and preferred
  /// time, starting from [from] (inclusive if the slot is >= from).
  ///
  /// If [plan.weekDays] is empty, returns [from] as-is.
  static DateTime nextTherapySlot({
    required DateTime from,
    required TherapyPlan plan,
  }) {
    if (plan.weekDays.isEmpty) return from;

    // Search up to 14 days ahead (covers any sparse plan).
    for (var add = 0; add <= 14; add++) {
      final day = DateTime(from.year, from.month, from.day).add(
        Duration(days: add),
      );
      if (!plan.weekDays.contains(day.weekday)) continue;

      final slot = combinePreferredTime(day, plan.preferredTime);
      if (!slot.isBefore(from)) return slot;
    }

    // Fallback: next week same weekday/time.
    final fallbackDay = DateTime(from.year, from.month, from.day).add(
      const Duration(days: 7),
    );
    return combinePreferredTime(fallbackDay, plan.preferredTime);
  }
}


