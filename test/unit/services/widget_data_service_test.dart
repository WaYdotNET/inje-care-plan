import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/widget_data_service.dart';

void main() {
  group('WidgetData', () {
    test('can be created with required fields only', () {
      const widgetData = WidgetData(weeklyAdherence: 85.5);

      expect(widgetData.nextInjection, isNull);
      expect(widgetData.weeklyAdherence, 85.5);
      expect(widgetData.lastUpdate, isNull);
    });

    test('can be created with all fields', () {
      final nextInjection = NextInjectionData(
        date: DateTime(2024, 7, 15, 20, 0),
        zoneId: 1,
        zoneName: 'Coscia Destra',
        zoneEmoji: '🦵',
        pointNumber: 3,
      );
      final lastUpdate = DateTime(2024, 7, 15, 10, 0);

      final widgetData = WidgetData(
        nextInjection: nextInjection,
        weeklyAdherence: 100.0,
        lastUpdate: lastUpdate,
      );

      expect(widgetData.nextInjection, isNotNull);
      expect(widgetData.nextInjection!.zoneName, 'Coscia Destra');
      expect(widgetData.weeklyAdherence, 100.0);
      expect(widgetData.lastUpdate, lastUpdate);
    });
  });

  group('NextInjectionData', () {
    test('can be created with required fields', () {
      final data = NextInjectionData(
        date: DateTime(2024, 7, 15, 20, 0),
        zoneId: 1,
        zoneName: 'Coscia Destra',
        zoneEmoji: '🦵',
        pointNumber: 3,
      );

      expect(data.date, DateTime(2024, 7, 15, 20, 0));
      expect(data.zoneId, 1);
      expect(data.zoneName, 'Coscia Destra');
      expect(data.zoneEmoji, '🦵');
      expect(data.pointNumber, 3);
    });

    test('formattedDate returns Oggi for today', () {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day, 20, 0);
      // We need a date that's in the future but same day
      final futureToday = DateTime(now.year, now.month, now.day, 23, 59);

      final data = NextInjectionData(
        date: futureToday,
        zoneId: 1,
        zoneName: 'Test',
        zoneEmoji: '💉',
        pointNumber: 1,
      );

      expect(data.formattedDate, 'Oggi');
    });

    test('formattedDate returns Domani for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        20,
        0,
      );

      final data = NextInjectionData(
        date: tomorrowDate,
        zoneId: 1,
        zoneName: 'Test',
        zoneEmoji: '💉',
        pointNumber: 1,
      );

      expect(data.formattedDate, 'Domani');
    });

    test('formattedDate returns Tra N giorni for 2-6 days', () {
      final inThreeDays = DateTime.now().add(const Duration(days: 3));
      final futureDate = DateTime(
        inThreeDays.year,
        inThreeDays.month,
        inThreeDays.day,
        20,
        0,
      );

      final data = NextInjectionData(
        date: futureDate,
        zoneId: 1,
        zoneName: 'Test',
        zoneEmoji: '💉',
        pointNumber: 1,
      );

      expect(data.formattedDate, contains('Tra'));
      expect(data.formattedDate, contains('giorni'));
    });

    test('formattedDate returns date format for >= 7 days', () {
      final inTenDays = DateTime.now().add(const Duration(days: 10));
      final futureDate = DateTime(
        inTenDays.year,
        inTenDays.month,
        inTenDays.day,
        20,
        0,
      );

      final data = NextInjectionData(
        date: futureDate,
        zoneId: 1,
        zoneName: 'Test',
        zoneEmoji: '💉',
        pointNumber: 1,
      );

      // Format should be "day/month"
      expect(data.formattedDate, contains('/'));
      expect(data.formattedDate, contains('${futureDate.day}'));
      expect(data.formattedDate, contains('${futureDate.month}'));
    });
  });
}

