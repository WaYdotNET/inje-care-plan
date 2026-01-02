import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../models/injection_record.dart';

/// Notification service for scheduling injection reminders
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // Request iOS permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request Android permissions
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (iosResult ?? true) && (androidResult ?? true);
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    // TODO: Navigate to relevant screen based on payload
  }

  /// Schedule an injection reminder
  Future<void> scheduleInjectionReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
    int minutesBefore = 30,
  }) async {
    final reminderTime = scheduledTime.subtract(Duration(minutes: minutesBefore));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'injection_reminders',
      'Promemoria iniezioni',
      channelDescription: 'Notifiche per le iniezioni programmate',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Iniezione programmata',
      'Tra $minutesBefore minuti: $pointLabel',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule a missed dose reminder
  Future<void> scheduleMissedDoseReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
    int hoursAfter = 2,
  }) async {
    final reminderTime = scheduledTime.add(Duration(hours: hoursAfter));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'missed_dose_reminders',
      'Promemoria dosi saltate',
      channelDescription: 'Notifiche per le dosi non registrate',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id + 10000, // Offset to avoid ID conflicts
      'Iniezione non registrata',
      'Hai completato: $pointLabel?',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 10000); // Cancel missed dose reminder too
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notifiche generali',
      channelDescription: 'Notifiche generali dell\'app',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  /// Schedule notifications for an injection
  Future<void> scheduleInjectionNotifications({
    required InjectionRecord injection,
    required int minutesBefore,
    required bool missedDoseReminder,
  }) async {
    // Generate a unique ID from the injection
    final id = injection.scheduledAt.millisecondsSinceEpoch ~/ 1000;

    // Schedule pre-injection reminder
    await scheduleInjectionReminder(
      id: id,
      scheduledTime: injection.scheduledAt,
      pointLabel: injection.pointLabel,
      minutesBefore: minutesBefore,
    );

    // Schedule missed dose reminder if enabled
    if (missedDoseReminder) {
      await scheduleMissedDoseReminder(
        id: id,
        scheduledTime: injection.scheduledAt,
        pointLabel: injection.pointLabel,
      );
    }
  }
}
