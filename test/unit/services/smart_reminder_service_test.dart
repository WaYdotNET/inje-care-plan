import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/smart_reminder_service.dart';
import 'package:injecare_plan/models/body_zone.dart' as models;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/test_database.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}
class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  late AppDatabase db;
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late SmartReminderService service;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(DateTimeComponents.time);
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() async {
    db = createTestDatabase();
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    service = SmartReminderService(db, mockNotifications);
    await db.customStatement('SELECT 1');

    // Setup default mock behaviors
    when(() => mockNotifications.show(
      any(),
      any(),
      any(),
      any(),
    )).thenAnswer((_) async {});

    when(() => mockNotifications.zonedSchedule(
      any(),
      any(),
      any(),
      any(),
      any(),
      androidScheduleMode: any(named: 'androidScheduleMode'),
      matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
    )).thenAnswer((_) async {});

    when(() => mockNotifications.cancel(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  group('ZoneSuggestion', () {
    test('can be created with required fields', () {
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

      final suggestion = ZoneSuggestion(
        zone: zone,
        reason: 'Test reason',
        daysSinceLastUse: 10,
      );

      expect(suggestion.zone, zone);
      expect(suggestion.reason, 'Test reason');
      expect(suggestion.daysSinceLastUse, 10);
    });

    test('can be created without daysSinceLastUse', () {
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

      final suggestion = ZoneSuggestion(
        zone: zone,
        reason: 'Mai utilizzata',
      );

      expect(suggestion.daysSinceLastUse, isNull);
    });
  });

  group('SmartReminderService - getBestZoneSuggestion', () {
    test('returns null when no zones', () async {
      // Clear all zones
      await db.customStatement('DELETE FROM body_zones');

      final suggestion = await service.getBestZoneSuggestion();

      expect(suggestion, isNull);
    });

    test('returns never used zone first', () async {
      // Don't add any injections - all zones are never used
      final suggestion = await service.getBestZoneSuggestion();

      expect(suggestion, isNotNull);
      expect(suggestion!.daysSinceLastUse, isNull);
      expect(suggestion.reason, 'Mai utilizzata');
    });

    test('returns least recently used zone', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Use zone 1 today
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones[0].id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
        completedAt: Value(now),
        status: const Value('completed'),
      ));

      // Use zone 2 yesterday
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones[1].id,
        pointNumber: 1,
        pointCode: 'CS-1',
        pointLabel: 'Test',
        scheduledAt: now.subtract(const Duration(days: 1)),
        completedAt: Value(now.subtract(const Duration(days: 1))),
        status: const Value('completed'),
      ));

      final suggestion = await service.getBestZoneSuggestion();

      expect(suggestion, isNotNull);
      // Should suggest a zone that was never used (zones 3-8)
      expect(suggestion!.daysSinceLastUse, isNull);
    });

    test('skips fully blacklisted zones', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      // Blacklist all points of zone 1
      for (var i = 1; i <= zone.numberOfPoints; i++) {
        await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
          pointCode: '${zone.code}-$i',
          pointLabel: 'Test',
          zoneId: zone.id,
          pointNumber: i,
        ));
      }

      final suggestion = await service.getBestZoneSuggestion();

      expect(suggestion, isNotNull);
      // Should NOT suggest zone 1 (fully blacklisted)
      expect(suggestion!.zone.id, isNot(zone.id));
    });
  });

  group('SmartReminderService - checkTodayMissedInjection', () {
    test('returns false when no therapy plan', () async {
      final missed = await service.checkTodayMissedInjection();
      expect(missed, isFalse);
    });

    test('returns true when today injection is pending', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Create therapy plan
      await db.insertTherapyPlan(TherapyPlansCompanion.insert(
        injectionsPerWeek: const Value(3),
        weekDays: const Value('1,3,5'),
        preferredTime: const Value('20:00'),
        startDate: now.subtract(const Duration(days: 30)),
      ));

      // Create scheduled (not completed) injection for today
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
        status: const Value('scheduled'),
      ));

      final missed = await service.checkTodayMissedInjection();
      expect(missed, isTrue);
    });

    test('returns false when today injection is completed', () async {
      final zones = await db.getAllZones();
      final now = DateTime.now();

      // Create therapy plan
      await db.insertTherapyPlan(TherapyPlansCompanion.insert(
        injectionsPerWeek: const Value(3),
        weekDays: const Value('1,3,5'),
        preferredTime: const Value('20:00'),
        startDate: now.subtract(const Duration(days: 30)),
      ));

      // Create completed injection for today
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zones.first.id,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'Test',
        scheduledAt: now,
        completedAt: Value(now),
        status: const Value('completed'),
      ));

      final missed = await service.checkTodayMissedInjection();
      expect(missed, isFalse);
    });
  });

  group('SmartReminderService - notifications', () {
    test('sendMissedInjectionNotification calls show', () async {
      await service.sendMissedInjectionNotification();

      verify(() => mockNotifications.show(
        5000, // _missedInjectionNotificationId
        any(),
        any(),
        any(),
      )).called(1);
    });

    test('sendZoneSuggestionNotification calls show', () async {
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

      final suggestion = ZoneSuggestion(
        zone: zone,
        reason: 'Test reason',
      );

      await service.sendZoneSuggestionNotification(suggestion);

      verify(() => mockNotifications.show(
        5100, // _zoneSuggestionNotificationId
        any(),
        any(),
        any(),
      )).called(1);
    });

    test('cancelAllSmartReminders cancels both notification IDs', () async {
      await service.cancelAllSmartReminders();

      verify(() => mockNotifications.cancel(5000)).called(1);
      verify(() => mockNotifications.cancel(5100)).called(1);
    });

    test('scheduleDailyMissedCheck schedules notification', () async {
      await service.scheduleDailyMissedCheck();

      verify(() => mockNotifications.zonedSchedule(
        5000,
        any(),
        any(),
        any(),
        any(),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      )).called(1);
    });
  });
}
