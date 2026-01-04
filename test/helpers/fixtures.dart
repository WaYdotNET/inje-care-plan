import 'package:injecare_plan/core/database/app_database.dart';

/// Test fixtures for common test data
class Fixtures {
  /// Sample zone IDs (matching database defaults)
  static const zoneIds = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
  ]; // CD, CS, BD, BS, AD, AS, GD, GS

  // Sample injection data
  static Injection createInjection({
    int id = 1,
    int zoneId = 1,
    int pointNumber = 1,
    DateTime? date,
    String? notes,
    bool completed = true,
  }) {
    final now = DateTime.now();
    final scheduledAt = date ?? now;
    return Injection(
      id: id,
      zoneId: zoneId,
      pointNumber: pointNumber,
      pointCode: 'CD-$pointNumber',
      pointLabel: 'Coscia Dx · $pointNumber',
      scheduledAt: scheduledAt,
      completedAt: completed ? scheduledAt : null,
      status: completed ? 'completed' : 'scheduled',
      notes: notes ?? '',
      sideEffects: '',
      calendarEventId: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Sample list of injections for statistics
  static List<Injection> createInjectionHistory({
    int count = 10,
    DateTime? startDate,
    int zoneId = 1,
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    return List.generate(count, (i) {
      return createInjection(
        id: i + 1,
        zoneId: zoneId,
        pointNumber: (i % 6) + 1,
        date: start.add(Duration(days: i * 3)),
        completed: i % 4 != 0, // 75% completion rate
      );
    });
  }

  // Sample point config
  static PointConfig createPointConfig({
    int id = 1,
    int zoneId = 1,
    int pointNumber = 1,
    double x = 0.5,
    double y = 0.5,
    String? customName,
  }) {
    final now = DateTime.now();
    return PointConfig(
      id: id,
      zoneId: zoneId,
      pointNumber: pointNumber,
      customName: customName ?? '',
      positionX: x,
      positionY: y,
      bodyView: 'front',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Sample blacklisted point
  static BlacklistedPoint createBlacklistedPoint({
    int id = 1,
    int zoneId = 1,
    int pointNumber = 1,
    String reason = 'Test reason',
  }) {
    final now = DateTime.now();
    return BlacklistedPoint(
      id: id,
      pointCode: 'CD-$pointNumber',
      pointLabel: 'Coscia Dx · $pointNumber',
      zoneId: zoneId,
      pointNumber: pointNumber,
      reason: reason,
      notes: '',
      blacklistedAt: now,
      createdAt: now,
    );
  }

  // Weekly injection schedule
  static List<int> defaultWeeklyDays = [1, 3, 5]; // Mon, Wed, Fri

  // Default therapy plan values
  static const defaultInjectionsPerWeek = 3;
  static const defaultReminderMinutes = 30;
}
