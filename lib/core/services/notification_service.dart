import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../models/injection_record.dart';

/// Notification service for scheduling injection reminders
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    try {
      final canExact = await _android?.canScheduleExactNotifications();
      // Se non possiamo schedulare "exact", fallback a inexact (meno preciso ma affidabile)
      return (canExact ?? false)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // Request iOS permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request Android permissions
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
    final reminderTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

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
      androidScheduleMode: await _androidScheduleMode(),
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
      androidScheduleMode: await _androidScheduleMode(),
    );
  }

  /// Schedule a 1-minute pre-injection reminder
  Future<void> scheduleOneMinuteReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
  }) async {
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 1));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'injection_reminders',
      'Promemoria iniezioni',
      channelDescription: 'Notifiche per le iniezioni programmate',
      importance: Importance.max,
      priority: Priority.max,
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
      id + 20000, // Offset to avoid ID conflicts
      'Iniezione tra 1 minuto',
      'Preparati: $pointLabel',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: await _androidScheduleMode(),
    );
  }

  /// Schedule a side effects reminder after injection completion
  Future<void> scheduleSideEffectsReminder({
    required int id,
    required DateTime completedAt,
    required String pointLabel,
    int hoursAfter = 4,
  }) async {
    final reminderTime = completedAt.add(Duration(hours: hoursAfter));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'side_effects_reminders',
      'Promemoria effetti collaterali',
      channelDescription: 'Notifiche per registrare effetti collaterali post-iniezione',
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

    await _notifications.zonedSchedule(
      id + 30000, // Offset to avoid ID conflicts
      'Come è andata l\'iniezione?',
      'Registra eventuali effetti collaterali: $pointLabel',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: await _androidScheduleMode(),
      payload: 'side_effects:$id',
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 10000); // Cancel missed dose reminder
    await _notifications.cancel(id + 20000); // Cancel 1-minute reminder
    await _notifications.cancel(id + 30000); // Cancel side effects reminder
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

    // Schedule 1-minute pre-injection reminder
    await scheduleOneMinuteReminder(
      id: id,
      scheduledTime: injection.scheduledAt,
      pointLabel: injection.pointLabel,
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

  /// Schedule weekly reminder for Sunday to approve proposals
  /// Called every Sunday at the specified time
  Future<void> scheduleWeeklyProposalsReminder({
    int hour = 10,
    int minute = 0,
  }) async {
    // ID fisso per la notifica domenicale
    const id = 99999;

    // Cancel existing weekly reminder
    await _notifications.cancel(id);

    // Calculate next Sunday at the specified time
    final now = DateTime.now();
    var nextSunday = now;

    // Find next Sunday
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    nextSunday = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      hour,
      minute,
    );

    // If it's already past today's Sunday time, schedule for next week
    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_proposals',
      'Proposte settimanali',
      channelDescription:
          'Promemoria domenicale per confermare le iniezioni della settimana',
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

    // Schedule weekly notification (repeating)
    await _notifications.zonedSchedule(
      id,
      'Pianifica la tua settimana',
      'Hai proposte di iniezione da confermare. Tocca per approvare.',
      tz.TZDateTime.from(nextSunday, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_proposals',
    );
  }

  /// Cancel the weekly proposals reminder
  Future<void> cancelWeeklyProposalsReminder() async {
    await _notifications.cancel(99999);
  }
}
