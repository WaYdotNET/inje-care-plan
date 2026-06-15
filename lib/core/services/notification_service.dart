import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../models/injection_record.dart';

/// Notification service for scheduling injection reminders
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  final _responseController = StreamController<NotificationResponse>.broadcast();
  AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Stream di risposte alle notifiche (tap dell'utente)
  Stream<NotificationResponse> get onNotificationTapped => _responseController.stream;

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
      if (canExact != true) {
        debugPrint(
          '[NotificationService] exact alarm permission not granted — '
          'falling back to inexactAllowWhileIdle (delivery may be delayed)',
        );
      }
      return (canExact ?? false)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (e) {
      debugPrint('[NotificationService] _androidScheduleMode error: $e');
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Request notification permissions. Logs each platform result so silent
  /// permission denials are visible in debug builds.
  Future<bool> requestPermissions() async {
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    if (iosResult == false) {
      debugPrint('[NotificationService] iOS notification permission DENIED');
    }
    if (androidResult == false) {
      debugPrint('[NotificationService] Android notification permission DENIED');
    }

    return (iosResult ?? true) && (androidResult ?? true);
  }

  /// Whether Android notifications are currently enabled by the OS.
  /// Returns null on iOS (permission state queried via the plugin elsewhere).
  Future<bool?> areAndroidNotificationsEnabled() async {
    try {
      return await _android?.areNotificationsEnabled();
    } catch (e) {
      debugPrint('[NotificationService] areNotificationsEnabled error: $e');
      return null;
    }
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    _responseController.add(response);
  }

  /// Schedule an injection reminder
  Future<void> scheduleInjectionReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
    int minutesBefore = 30,
    String? payload,
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
      payload: payload,
    );
  }

  /// Schedule a missed dose reminder
  Future<void> scheduleMissedDoseReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
    int hoursAfter = 2,
    String? payload,
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
      payload: payload,
    );
  }

  /// Schedule a 1-minute pre-injection reminder
  Future<void> scheduleOneMinuteReminder({
    required int id,
    required DateTime scheduledTime,
    required String pointLabel,
    String? payload,
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
      payload: payload,
    );
  }

  /// Schedule a side effects reminder after injection completion
  Future<void> scheduleSideEffectsReminder({
    required int id,
    required DateTime completedAt,
    required String pointLabel,
    int hoursAfter = 2,
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

  /// Cancella solo le notifiche app pre-iniezione (promemoria anticipato e
  /// 1-minuto) per le iniezioni indicate, senza toccare i promemoria
  /// dose-mancata (+10000) e effetti-collaterali (+30000).
  ///
  /// Usato quando l'utente passa al canale "Solo calendario": le notifiche
  /// già schedulate prima del cambio vengono rimosse evitando duplicati con
  /// l'allarme del calendario.
  Future<void> cancelPreInjectionReminders(List<int> injectionIds) async {
    for (final id in injectionIds) {
      await _notifications.cancel(id);           // promemoria X min prima
      await _notifications.cancel(id + 20000);   // promemoria 1 min prima
    }
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

  /// Schedule notifications for an injection. Idempotent: cancels any
  /// previously scheduled notifications for the same injection id before
  /// scheduling the new ones, so repeated calls don't duplicate.
  ///
  /// The injection's primary key (`injection.id`) is used as the stable
  /// notification id, so editing `scheduledAt` will replace — not duplicate —
  /// the existing reminders.
  Future<void> scheduleInjectionNotifications({
    required InjectionRecord injection,
    required int minutesBefore,
    required bool missedDoseReminder,
    bool skipPreReminders = false,
  }) async {
    final injectionId = injection.id;
    if (injectionId == null) {
      debugPrint(
        '[NotificationService] scheduleInjectionNotifications called without '
        'an injection.id — skipping (cannot dedupe).',
      );
      return;
    }

    // Cancel any previously-scheduled reminders for this injection so a
    // re-schedule (e.g. after editing scheduledAt) does not stack duplicates.
    await cancelNotification(injectionId);

    final payload = 'injection:$injectionId';

    // Le notifiche pre-iniezione vengono omesse quando il canale è solo
    // calendario: l'allarme del calendario le sostituisce. Il promemoria dose
    // mancata rimane sempre attivo perché il calendario non può sostituirlo.
    if (!skipPreReminders) {
      await scheduleInjectionReminder(
        id: injectionId,
        scheduledTime: injection.scheduledAt,
        pointLabel: injection.pointLabel,
        minutesBefore: minutesBefore,
        payload: payload,
      );

      await scheduleOneMinuteReminder(
        id: injectionId,
        scheduledTime: injection.scheduledAt,
        pointLabel: injection.pointLabel,
        payload: payload,
      );
    }

    if (missedDoseReminder) {
      await scheduleMissedDoseReminder(
        id: injectionId,
        scheduledTime: injection.scheduledAt,
        pointLabel: injection.pointLabel,
        payload: payload,
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
