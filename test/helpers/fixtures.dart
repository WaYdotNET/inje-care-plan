import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/models/body_zone.dart';

/// Test fixtures for common test data
class Fixtures {
  // Sample zones
  static const zones = BodyZone.values;

  // Sample injection data
  static Injection createInjection({
    int id = 1,
    String zoneCode = 'CD',
    int pointNumber = 1,
    DateTime? date,
    String? notes,
    bool completed = true,
  }) {
    return Injection(
      id: id,
      zoneCode: zoneCode,
      pointNumber: pointNumber,
      scheduledDate: date ?? DateTime.now(),
      actualDate: completed ? (date ?? DateTime.now()) : null,
      status: completed ? 'completed' : 'scheduled',
      notes: notes,
    );
  }

  // Sample list of injections for statistics
  static List<Injection> createInjectionHistory({
    int count = 10,
    DateTime? startDate,
    String zoneCode = 'CD',
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    return List.generate(count, (i) {
      return createInjection(
        id: i + 1,
        zoneCode: zoneCode,
        pointNumber: (i % 6) + 1,
        date: start.add(Duration(days: i * 3)),
        completed: i % 4 != 0, // 75% completion rate
      );
    });
  }

  // Sample point config
  static PointConfig createPointConfig({
    int id = 1,
    String zoneCode = 'CD',
    int pointNumber = 1,
    double x = 0.5,
    double y = 0.5,
    String? customName,
  }) {
    return PointConfig(
      id: id,
      zoneCode: zoneCode,
      pointNumber: pointNumber,
      xPosition: x,
      yPosition: y,
      customName: customName,
    );
  }

  // Sample blacklisted point
  static BlacklistedPointEntry createBlacklistedPoint({
    int id = 1,
    String zoneCode = 'CD',
    int pointNumber = 1,
    String reason = 'Test reason',
  }) {
    return BlacklistedPointEntry(
      id: id,
      zoneCode: zoneCode,
      pointNumber: pointNumber,
      reason: reason,
      excludedAt: DateTime.now(),
    );
  }

  // Weekly injection schedule
  static List<int> defaultWeeklyDays = [1, 3, 5]; // Mon, Wed, Fri

  // Default therapy plan values
  static const defaultInjectionsPerWeek = 3;
  static const defaultReminderMinutes = 30;
}
