import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/notification_service.dart';
import 'package:injecare_plan/core/services/export_service.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

class MockNotificationService extends Mock implements NotificationService {}

class MockExportService extends Mock implements ExportService {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

// Fake classes for registerFallbackValue
class FakeInjection extends Fake implements Injection {}

class FakePointConfig extends Fake implements PointConfig {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

class FakeDateTime extends Fake implements DateTime {}

// Setup function to register fallback values
void setUpMocks() {
  registerFallbackValue(FakeInjection());
  registerFallbackValue(FakePointConfig());
  registerFallbackValue(FakeNotificationDetails());
  registerFallbackValue(FakeDateTime());
  registerFallbackValue(DateTime.now());
  registerFallbackValue(const Duration(days: 1));
}

