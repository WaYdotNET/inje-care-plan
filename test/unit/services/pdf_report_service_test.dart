import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:injecare_plan/core/services/pdf_report_service.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/models/body_zone.dart' as models;
import 'package:injecare_plan/features/statistics/statistics_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it', null);
  });

  group('PdfReportService', () {
    test('creates instance', () {
      final service = PdfReportService();
      expect(service, isA<PdfReportService>());
    });

    // Note: Full generateReport tests require loading fonts from assets
    // which is not available in unit tests without TestWidgetsFlutterBinding
    // See widget tests for full PDF generation testing
  });

  group('InjectionStats for PDF', () {
    test('creates valid stats for empty data', () {
      final stats = InjectionStats(
        totalInjections: 0,
        totalExpected: 0,
        adherenceRate: 0.0,
        zoneUsage: [],
        monthlyTrend: [],
        weeklyTrend: [],
        currentStreak: 0,
        longestStreak: 0,
        completedCount: 0,
        skippedCount: 0,
        scheduledCount: 0,
      );

      expect(stats.totalInjections, 0);
      expect(stats.adherenceRate, 0.0);
      expect(stats.zoneUsage, isEmpty);
      expect(stats.monthlyTrend, isEmpty);
    });

    test('creates valid stats with data', () {
      final zoneUsage = [
        ZoneUsage(
          zoneId: 1,
          zoneName: 'Coscia Destra',
          emoji: '🦵',
          count: 10,
          percentage: 50.0,
        ),
        ZoneUsage(
          zoneId: 2,
          zoneName: 'Coscia Sinistra',
          emoji: '🦵',
          count: 10,
          percentage: 50.0,
        ),
      ];

      final monthlyTrend = [
        MonthlyData(
          month: DateTime(2024, 1),
          injections: 8,
          expected: 10,
          adherenceRate: 80.0,
        ),
        MonthlyData(
          month: DateTime(2024, 2),
          injections: 9,
          expected: 10,
          adherenceRate: 90.0,
        ),
      ];

      final weeklyTrend = [
        WeeklyData(
          weekStart: DateTime(2024, 1, 1),
          injections: 3,
          expected: 3,
          adherenceRate: 100.0,
        ),
      ];

      final stats = InjectionStats(
        totalInjections: 20,
        totalExpected: 25,
        adherenceRate: 85.0,
        zoneUsage: zoneUsage,
        monthlyTrend: monthlyTrend,
        weeklyTrend: weeklyTrend,
        currentStreak: 5,
        longestStreak: 10,
        completedCount: 17,
        skippedCount: 3,
        scheduledCount: 5,
      );

      expect(stats.totalInjections, 20);
      expect(stats.totalExpected, 25);
      expect(stats.completedCount, 17);
      expect(stats.skippedCount, 3);
      expect(stats.adherenceRate, 85.0);
      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 10);
      expect(stats.zoneUsage.length, 2);
      expect(stats.monthlyTrend.length, 2);
    });
  });

  group('ZoneUsage', () {
    test('creates with all properties', () {
      final usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Coscia Destra',
        emoji: '🦵',
        count: 15,
        percentage: 37.5,
      );

      expect(usage.zoneId, 1);
      expect(usage.zoneName, 'Coscia Destra');
      expect(usage.emoji, '🦵');
      expect(usage.count, 15);
      expect(usage.percentage, 37.5);
    });

    test('creates with lastUsed', () {
      final usage = ZoneUsage(
        zoneId: 1,
        zoneName: 'Addome',
        emoji: '🫃',
        count: 5,
        percentage: 25.0,
        lastUsed: DateTime(2024, 7, 15),
      );

      expect(usage.lastUsed, DateTime(2024, 7, 15));
    });
  });

  group('MonthlyData', () {
    test('creates with all properties', () {
      final data = MonthlyData(
        month: DateTime(2024, 3),
        injections: 10,
        expected: 12,
        adherenceRate: 83.3,
      );

      expect(data.month, DateTime(2024, 3));
      expect(data.injections, 10);
      expect(data.expected, 12);
      expect(data.adherenceRate, 83.3);
    });
  });

  group('WeeklyData', () {
    test('creates with all properties', () {
      final data = WeeklyData(
        weekStart: DateTime(2024, 7, 1),
        injections: 3,
        expected: 3,
        adherenceRate: 100.0,
      );

      expect(data.weekStart, DateTime(2024, 7, 1));
      expect(data.injections, 3);
      expect(data.expected, 3);
      expect(data.adherenceRate, 100.0);
    });
  });

  group('Injection model for PDF', () {
    test('creates injection with all required fields', () {
      final injection = Injection(
        id: 1,
        zoneId: 1,
        pointNumber: 3,
        pointCode: 'CD-03',
        pointLabel: 'Coscia Destra - Punto 3',
        scheduledAt: DateTime(2024, 7, 15, 20, 0),
        completedAt: DateTime(2024, 7, 15, 20, 5),
        status: 'completed',
        notes: 'Test note',
        sideEffects: '',
        calendarEventId: '',
        createdAt: DateTime(2024, 7, 15),
        updatedAt: DateTime(2024, 7, 15),
      );

      expect(injection.id, 1);
      expect(injection.zoneId, 1);
      expect(injection.pointNumber, 3);
      expect(injection.status, 'completed');
      expect(injection.completedAt, isNotNull);
    });

    test('creates scheduled injection', () {
      final injection = Injection(
        id: 2,
        zoneId: 2,
        pointNumber: 1,
        pointCode: 'CS-01',
        pointLabel: 'Coscia Sinistra - Punto 1',
        scheduledAt: DateTime(2024, 7, 20, 20, 0),
        completedAt: null,
        status: 'scheduled',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: DateTime(2024, 7, 15),
        updatedAt: DateTime(2024, 7, 15),
      );

      expect(injection.status, 'scheduled');
      expect(injection.completedAt, isNull);
    });

    test('creates skipped injection', () {
      final injection = Injection(
        id: 3,
        zoneId: 3,
        pointNumber: 2,
        pointCode: 'AD-02',
        pointLabel: 'Addome Destro - Punto 2',
        scheduledAt: DateTime(2024, 7, 10, 20, 0),
        completedAt: null,
        status: 'skipped',
        notes: 'Was sick',
        sideEffects: '',
        calendarEventId: '',
        createdAt: DateTime(2024, 7, 10),
        updatedAt: DateTime(2024, 7, 10),
      );

      expect(injection.status, 'skipped');
      expect(injection.notes, 'Was sick');
    });
  });

  group('BodyZone for PDF', () {
    test('provides displayName for PDF', () {
      final zone = models.BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(zone.displayName, 'Coscia Destra');
      expect(zone.emoji, '🦵');
    });

    test('provides emoji for different zone types', () {
      final abdomen = models.BodyZone(
        id: 2,
        code: 'AD',
        name: 'Addome Destro',
        type: 'abdomen',
        side: 'right',
        numberOfPoints: 4,
        isEnabled: true,
        sortOrder: 2,
      );

      expect(abdomen.emoji, '💧');
    });
  });
}
