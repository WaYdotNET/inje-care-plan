import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injecare_plan/core/database/app_database.dart';

/// Crea un database in-memory per i test
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(
    NativeDatabase.memory(),
  );
}

/// Dati di test predefiniti
class TestData {
  TestData._();

  /// DateTime base per i test
  static final now = DateTime(2024, 7, 15, 20, 0);

  /// Crea una iniezione di test
  static InjectionsCompanion createInjection({
    int zoneId = 1,
    int pointNumber = 1,
    String status = 'scheduled',
    DateTime? scheduledAt,
    DateTime? completedAt,
  }) {
    return InjectionsCompanion.insert(
      zoneId: zoneId,
      pointNumber: pointNumber,
      pointCode: 'CD-$pointNumber',
      pointLabel: 'Coscia Dx · $pointNumber',
      scheduledAt: scheduledAt ?? now,
      completedAt: Value(completedAt),
      status: Value(status),
    );
  }

  /// Crea un piano terapeutico di test
  static TherapyPlansCompanion createTherapyPlan({
    int injectionsPerWeek = 3,
    String weekDays = '1,3,5',
    String preferredTime = '20:00',
    DateTime? startDate,
  }) {
    return TherapyPlansCompanion.insert(
      injectionsPerWeek: Value(injectionsPerWeek),
      weekDays: Value(weekDays),
      preferredTime: Value(preferredTime),
      startDate: startDate ?? now,
    );
  }

  /// Crea un punto blacklistato di test
  static BlacklistedPointsCompanion createBlacklistedPoint({
    int zoneId = 1,
    int pointNumber = 1,
    String reason = 'test_reason',
  }) {
    return BlacklistedPointsCompanion.insert(
      pointCode: 'CD-$pointNumber',
      pointLabel: 'Coscia Dx · $pointNumber',
      zoneId: zoneId,
      pointNumber: pointNumber,
      reason: Value(reason),
    );
  }
}
