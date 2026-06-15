import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../../models/reminder_rule.dart';
import 'calendar_event_content.dart';
import 'diagnostic_log_service.dart';
import 'reminder_settings_provider.dart';

/// Parametri di configurazione promemoria necessari a [CalendarSyncService].
/// Derivato dalla sorgente di verità (es. ReminderSettings provider) dal
/// chiamante, in modo che il servizio rimanga stateless rispetto alla UI.
class ReminderSettingsView {
  const ReminderSettingsView({
    required this.channelIncludesCalendar,
    required this.includeFeedback,
    required this.activeRules,
  });

  /// true se il canale scelto dall'utente include il calendario del device.
  final bool channelIncludesCalendar;

  /// true se le note evento devono includere il feedback dell'iniezione
  /// precedente completata.
  final bool includeFeedback;

  /// Regole attive (minutesBefore ≥ 0) da tradurre in [Reminder].
  final List<ReminderRule> activeRules;

  /// Costruisce un [ReminderSettingsView] a partire da [ReminderSettings].
  factory ReminderSettingsView.from(ReminderSettings s) => ReminderSettingsView(
        channelIncludesCalendar:
            s.channel == ReminderChannel.calendar || s.channel == ReminderChannel.both,
        includeFeedback: s.includeFeedback,
        activeRules: s.activeRules.toList(),
      );
}

/// Wraps [DeviceCalendarPlugin] con logica best-effort.
///
/// Tutte le operazioni pubbliche catturano le eccezioni e non rilanciano
/// mai al chiamante: un problema con il calendario non deve mai bloccare
/// il salvataggio di un'iniezione.
///
/// L'id del calendario dedicato "InjeCare" è persistito in [SharedPreferences]
/// sotto la chiave [_calendarIdKey].
class CalendarSyncService {
  CalendarSyncService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  static const _calendarIdKey = 'injecare_calendar_id';
  static const _calendarName = 'InjeCare';

  // ── Timeout helper ────────────────────────────────────────────────────────────

  /// Applica un timeout di 8 secondi a qualsiasi chiamata al plugin del
  /// dispositivo. La [TimeoutException] viene catturata dai try/catch esistenti
  /// (best-effort) e il metodo restituisce null/false come in caso di errore.
  Future<T> _withTimeout<T>(Future<T> future) =>
      future.timeout(const Duration(seconds: 8));

  // ── Permessi ─────────────────────────────────────────────────────────────────

  /// Verifica (e richiede se necessario) i permessi del calendario.
  ///
  /// Restituisce `true` se i permessi sono stati concessi, `false` altrimenti
  /// (incluso in caso di errore).
  Future<bool> ensureCalendarPermission() async {
    try {
      final has = await _withTimeout(_plugin.hasPermissions());
      if (has.data == true) return true;

      final req = await _withTimeout(_plugin.requestPermissions());
      return req.data == true;
    } catch (e) {
      debugPrint('[CalendarSyncService] ensureCalendarPermission error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
      return false;
    }
  }

  // ── Calendario dedicato ───────────────────────────────────────────────────────

  /// Restituisce l'id del calendario dedicato "InjeCare".
  ///
  /// Se l'id è già in [SharedPreferences] lo riutilizza.
  /// Altrimenti cerca un calendario esistente di nome "InjeCare"; se non lo
  /// trova, ne crea uno nuovo.
  /// Come fallback finale usa il primo calendario scrivibile disponibile.
  /// Restituisce `null` in caso di errore.
  Future<String?> ensureInjeCareCalendar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_calendarIdKey);
      if (saved != null && saved.isNotEmpty) return saved;

      // Recupera calendari esistenti.
      final calResult = await _withTimeout(_plugin.retrieveCalendars());
      final calendars = calResult.data;

      if (calendars != null) {
        // Cerca un calendario già chiamato "InjeCare".
        final existing = calendars.cast<Calendar?>().firstWhere(
          (c) => c?.name == _calendarName && c?.isReadOnly != true,
          orElse: () => null,
        );
        if (existing?.id != null) {
          await prefs.setString(_calendarIdKey, existing!.id!);
          return existing.id;
        }
      }

      // Crea un nuovo calendario.
      final createResult = await _withTimeout(
        _plugin.createCalendar(
          _calendarName,
          localAccountName: 'InjeCare',
        ),
      );
      if (createResult.isSuccess && createResult.data != null) {
        await prefs.setString(_calendarIdKey, createResult.data!);
        return createResult.data;
      }

      // Fallback: primo calendario scrivibile disponibile.
      if (calendars != null) {
        final writable = calendars.cast<Calendar?>().firstWhere(
          (c) => c?.isReadOnly != true && c?.id != null,
          orElse: () => null,
        );
        if (writable?.id != null) {
          await prefs.setString(_calendarIdKey, writable!.id!);
          return writable.id;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[CalendarSyncService] ensureInjeCareCalendar error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
      return null;
    }
  }

  // ── Evento ────────────────────────────────────────────────────────────────────

  /// Crea o aggiorna l'evento del calendario per l'iniezione [injection].
  ///
  /// - Il titolo è prodotto da [buildEventTitle].
  /// - La descrizione è prodotta da [buildEventNotes]; [previousCompleted] è
  ///   incluso solo se [settings.includeFeedback] è `true`.
  /// - Durata fissa di 15 minuti.
  /// - I [Reminder] sono allegati solo se [settings.channelIncludesCalendar].
  /// - Il campo [Event.url] viene impostato al deeplink
  ///   `injecare://injection/<id>` per consentire l'apertura diretta
  ///   dell'iniezione dal calendario del device.
  ///
  /// Restituisce l'eventId (nuovo o esistente), oppure `null` in caso di
  /// errore o se il risultato non è disponibile.
  Future<String?> upsertEvent(
    Injection injection,
    Injection? previousCompleted,
    ReminderSettingsView settings,
  ) async {
    try {
      final calendarId = await ensureInjeCareCalendar();
      if (calendarId == null) return null;

      final title = buildEventTitle(injection);
      final description = buildEventNotes(
        injection,
        settings.includeFeedback ? previousCompleted : null,
      );

      final start = tz.TZDateTime.from(injection.scheduledAt, tz.local);
      final end = start.add(const Duration(minutes: 15));

      List<Reminder>? reminders;
      if (settings.channelIncludesCalendar && settings.activeRules.isNotEmpty) {
        reminders = settings.activeRules
            .where((r) => r.enabled && r.minutesBefore >= 0)
            .map((r) => Reminder(minutes: r.minutesBefore))
            .toList();
      }

      final event = Event(
        calendarId,
        eventId: injection.calendarEventId.isNotEmpty
            ? injection.calendarEventId
            : null,
        title: title,
        description: description,
        start: start,
        end: end,
        reminders: reminders,
        url: Uri.parse('injecare://injection/${injection.id}'),
      );

      final result = await _withTimeout(_plugin.createOrUpdateEvent(event));
      if (result == null) return null;
      return result.isSuccess ? result.data : null;
    } catch (e) {
      debugPrint('[CalendarSyncService] upsertEvent error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
      return null;
    }
  }

  // ── Rimozione evento ──────────────────────────────────────────────────────────

  /// Elimina l'evento associato a [injection] se [Injection.calendarEventId]
  /// non è vuoto. Best-effort: ignora gli errori.
  Future<void> removeEvent(Injection injection) async {
    if (injection.calendarEventId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarId = prefs.getString(_calendarIdKey);
      await _withTimeout(_plugin.deleteEvent(calendarId, injection.calendarEventId));
    } catch (e) {
      debugPrint('[CalendarSyncService] removeEvent error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
    }
  }

  // ── Completamento ─────────────────────────────────────────────────────────────

  /// Gestisce la transizione "iniezione completata" sull'evento del calendario.
  ///
  /// - [CompletionBehavior.remove]: elimina l'evento.
  /// - [CompletionBehavior.markDone]: riscrive il titolo con prefisso "✓",
  ///   aggiorna la descrizione senza feedback precedente e svuota i reminder.
  ///
  /// Best-effort: ignora gli errori.
  Future<void> markDone(Injection injection, CompletionBehavior behavior) async {
    try {
      if (behavior == CompletionBehavior.remove) {
        await removeEvent(injection);
        return;
      }

      // markDone: riscrivi evento con segno spunta.
      final calendarId = await ensureInjeCareCalendar();
      if (calendarId == null) return;

      final originalTitle = buildEventTitle(injection);
      final doneTitle = '✓ $originalTitle';
      final description = buildEventNotes(injection, null);

      final start = tz.TZDateTime.from(injection.scheduledAt, tz.local);
      final end = start.add(const Duration(minutes: 15));

      final event = Event(
        calendarId,
        eventId: injection.calendarEventId.isNotEmpty
            ? injection.calendarEventId
            : null,
        title: doneTitle,
        description: description,
        start: start,
        end: end,
        reminders: const [],
        url: Uri.parse('injecare://injection/${injection.id}'),
      );

      await _withTimeout(_plugin.createOrUpdateEvent(event));
    } catch (e) {
      debugPrint('[CalendarSyncService] markDone error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
    }
  }

  // ── Teardown ──────────────────────────────────────────────────────────────────

  /// Elimina il calendario dedicato (se presente) e rimuove l'id salvato.
  /// Best-effort: ignora gli errori.
  Future<void> teardown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarId = prefs.getString(_calendarIdKey);
      if (calendarId != null && calendarId.isNotEmpty) {
        await _withTimeout(_plugin.deleteCalendar(calendarId));
        await prefs.remove(_calendarIdKey);
      }
    } catch (e) {
      debugPrint('[CalendarSyncService] teardown error: $e');
      DiagnosticLogService.instance.logError('calendar', e);
    }
  }
}
