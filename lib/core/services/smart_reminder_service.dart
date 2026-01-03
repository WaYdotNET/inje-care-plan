import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/body_zone.dart' as models;
import '../database/app_database.dart';

/// Servizio per promemoria intelligenti
class SmartReminderService {
  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  SmartReminderService(this._db, this._notificationsPlugin);

  /// ID base per le notifiche smart
  static const int _missedInjectionNotificationId = 5000;
  static const int _zoneSuggestionNotificationId = 5100;

  /// Controlla a fine giornata se ci sono iniezioni mancate
  Future<void> scheduleDailyMissedCheck() async {
    // Schedula notifica alle 21:00 per controllare iniezioni mancate
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, // 21:00
    );

    // Se sono già passate le 21, schedula per domani
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      _missedInjectionNotificationId,
      'Iniezione dimenticata?',
      'Controlla se hai fatto la tua iniezione di oggi',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_reminders',
          'Promemoria Intelligenti',
          channelDescription: 'Notifiche per iniezioni dimenticate',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              'skip',
              'Salta',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'record',
              'Registra ora',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'missed_injection',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Ripete ogni giorno
    );
  }

  /// Controlla se ci sono iniezioni mancate oggi
  Future<bool> checkTodayMissedInjection() async {
    final therapyPlan = await _db.getCurrentTherapyPlan();
    if (therapyPlan == null) return false;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Trova iniezioni per oggi
    final todayInjections = await _db.getInjectionsByDateRange(todayStart, todayEnd);

    // Se non ci sono iniezioni programmate per oggi, verifica dal piano terapia
    if (todayInjections.isEmpty) {
      // Verifica se oggi era un giorno di iniezione secondo il piano
      final isInjectionDay = _isScheduledDay(now, therapyPlan.injectionsPerWeek);
      if (isInjectionDay) {
        return true; // Iniezione mancata
      }
    }

    // Se ci sono iniezioni programmate ma non completate
    final hasPending = todayInjections.any((i) => i.status == 'scheduled');
    return hasPending;
  }

  bool _isScheduledDay(DateTime date, int daysPerWeek) {
    // Logica semplificata: distribuisce uniformemente i giorni nella settimana
    final scheduledDays = _getScheduledWeekdays(daysPerWeek);
    return scheduledDays.contains(date.weekday);
  }

  List<int> _getScheduledWeekdays(int daysPerWeek) {
    switch (daysPerWeek) {
      case 1:
        return [DateTime.monday];
      case 2:
        return [DateTime.monday, DateTime.thursday];
      case 3:
        return [DateTime.monday, DateTime.wednesday, DateTime.friday];
      case 4:
        return [DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday];
      case 5:
        return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday];
      case 6:
        return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday];
      case 7:
        return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday];
      default:
        return [DateTime.monday];
    }
  }

  /// Invia notifica per iniezione mancata
  Future<void> sendMissedInjectionNotification() async {
    await _notificationsPlugin.show(
      _missedInjectionNotificationId,
      '💉 Iniezione dimenticata',
      'Non hai ancora registrato l\'iniezione di oggi. Ricorda di farla!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_reminders',
          'Promemoria Intelligenti',
          channelDescription: 'Notifiche per iniezioni dimenticate',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              'skip_today',
              'Salta oggi',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'record_now',
              'Registra',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'missed_injection',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Suggerisce la zona meno utilizzata di recente
  Future<ZoneSuggestion?> getBestZoneSuggestion() async {
    final zones = await _db.getAllZones();
    if (zones.isEmpty) return null;

    final injections = await _db.getAllInjections();
    final blacklisted = await _db.getAllBlacklistedPoints();

    // Mappa zona -> ultima iniezione
    final lastInjectionByZone = <int, DateTime>{};
    for (final injection in injections.where((i) => i.status == 'completed' && i.completedAt != null)) {
      final existing = lastInjectionByZone[injection.zoneId];
      if (existing == null || injection.completedAt!.isAfter(existing)) {
        lastInjectionByZone[injection.zoneId] = injection.completedAt!;
      }
    }

    // Converti a modelli
    final bodyZones = zones.map((z) => models.BodyZone.fromDatabase(z)).toList();

    // Ordina zone per data ultima iniezione (le meno usate di recente prima)
    final sortedZones = bodyZones.toList()
      ..sort((models.BodyZone a, models.BodyZone b) {
        final aLast = lastInjectionByZone[a.id];
        final bLast = lastInjectionByZone[b.id];

        // Zone mai usate hanno priorità
        if (aLast == null && bLast == null) return 0;
        if (aLast == null) return -1;
        if (bLast == null) return 1;

        return aLast.compareTo(bLast); // Più vecchia = prima
      });

    // Trova la zona migliore (prima non completamente blacklistata)
    for (final zone in sortedZones) {
      final zoneBlacklist = blacklisted.where((b) => b.zoneId == zone.id).toList();
      final totalPoints = zone.totalPoints;

      // Se non tutti i punti sono in blacklist
      if (zoneBlacklist.length < totalPoints) {
        final daysSinceUse = lastInjectionByZone[zone.id] != null
            ? DateTime.now().difference(lastInjectionByZone[zone.id]!).inDays
            : null;

        return ZoneSuggestion(
          zone: zone,
          reason: daysSinceUse == null
              ? 'Mai utilizzata'
              : 'Non utilizzata da $daysSinceUse giorni',
          daysSinceLastUse: daysSinceUse,
        );
      }
    }

    return null;
  }

  /// Invia notifica con suggerimento zona
  Future<void> sendZoneSuggestionNotification(ZoneSuggestion suggestion) async {
    await _notificationsPlugin.show(
      _zoneSuggestionNotificationId,
      '💡 Suggerimento zona',
      '${suggestion.zone.emoji} ${suggestion.zone.displayName}: ${suggestion.reason}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zone_suggestions',
          'Suggerimenti Zone',
          channelDescription: 'Suggerimenti per la rotazione delle zone',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancella tutti i promemoria smart
  Future<void> cancelAllSmartReminders() async {
    await _notificationsPlugin.cancel(_missedInjectionNotificationId);
    await _notificationsPlugin.cancel(_zoneSuggestionNotificationId);
  }
}

/// Suggerimento zona
class ZoneSuggestion {
  final models.BodyZone zone;
  final String reason;
  final int? daysSinceLastUse;

  const ZoneSuggestion({
    required this.zone,
    required this.reason,
    this.daysSinceLastUse,
  });
}
