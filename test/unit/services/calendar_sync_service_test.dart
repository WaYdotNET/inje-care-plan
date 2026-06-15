import 'dart:collection';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/calendar_sync_service.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/models/reminder_rule.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPlugin extends Mock implements DeviceCalendarPlugin {}

// Helper per costruire un Result di tipo T con data = value e nessun errore.
Result<T> _resultOk<T>(T value) {
  final r = Result<T>();
  r.data = value;
  return r;
}

// Helper per costruire un Result di tipo T con nessun dato (errore / non concesso).
Result<T> _resultFail<T>() => Result<T>();

/// Helper per costruire un'Injection minimale per i test.
Injection _inj({
  int id = 1,
  String pointLabel = 'Coscia Dx · 1',
  DateTime? scheduledAt,
  String calendarEventId = '',
  String status = 'scheduled',
  String sideEffects = '',
  String notes = '',
}) {
  final now = scheduledAt ?? DateTime(2026, 6, 15, 20);
  return Injection(
    id: id,
    zoneId: 1,
    pointNumber: 1,
    pointCode: 'CD-1',
    pointLabel: pointLabel,
    scheduledAt: now,
    completedAt: null,
    status: status,
    notes: notes,
    sideEffects: sideEffects,
    calendarEventId: calendarEventId,
    createdAt: now,
    updatedAt: now,
  );
}

/// ReminderSettingsView minimale: calendar abilitato, nessuna regola.
const _noReminders = ReminderSettingsView(
  channelIncludesCalendar: true,
  includeFeedback: false,
  activeRules: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Permessi ────────────────────────────────────────────────────────────────

  test('ensureCalendarPermission ritorna false quando permessi negati, senza throw', () async {
    final plugin = _MockPlugin();
    when(() => plugin.hasPermissions()).thenAnswer((_) async => _resultFail<bool>());
    when(() => plugin.requestPermissions()).thenAnswer((_) async => _resultFail<bool>());

    final svc = CalendarSyncService(plugin: plugin);
    expect(await svc.ensureCalendarPermission(), isFalse);
  });

  test('ensureCalendarPermission ritorna true quando hasPermissions già concesso', () async {
    final plugin = _MockPlugin();
    when(() => plugin.hasPermissions()).thenAnswer((_) async => _resultOk<bool>(true));

    final svc = CalendarSyncService(plugin: plugin);
    expect(await svc.ensureCalendarPermission(), isTrue);
  });

  test('ensureCalendarPermission ritorna true dopo requestPermissions concesso', () async {
    final plugin = _MockPlugin();
    when(() => plugin.hasPermissions()).thenAnswer((_) async => _resultOk<bool>(false));
    when(() => plugin.requestPermissions()).thenAnswer((_) async => _resultOk<bool>(true));

    final svc = CalendarSyncService(plugin: plugin);
    expect(await svc.ensureCalendarPermission(), isTrue);
  });

  // ── Calendario dedicato ──────────────────────────────────────────────────────

  test('ensureInjeCareCalendar crea il calendario se non esiste in prefs', () async {
    final plugin = _MockPlugin();
    // Non ci sono calendari esistenti.
    final emptyList = UnmodifiableListView<Calendar>([]);
    when(() => plugin.retrieveCalendars())
        .thenAnswer((_) async => _resultOk(emptyList));
    when(() => plugin.createCalendar(any(), calendarColor: any(named: 'calendarColor'), localAccountName: any(named: 'localAccountName')))
        .thenAnswer((_) async => _resultOk<String>('cal-42'));

    final svc = CalendarSyncService(plugin: plugin);
    final id = await svc.ensureInjeCareCalendar();
    expect(id, 'cal-42');
  });

  test('ensureInjeCareCalendar riutilizza id salvato in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'stored-id'});
    final plugin = _MockPlugin();
    // retrieveCalendars NON deve essere chiamato se l'id è già in prefs.
    final svc = CalendarSyncService(plugin: plugin);
    final id = await svc.ensureInjeCareCalendar();
    expect(id, 'stored-id');
    verifyNever(() => plugin.retrieveCalendars());
  });

  // ── teardown ─────────────────────────────────────────────────────────────────

  test('teardown senza calendario salvato non lancia', () async {
    final plugin = _MockPlugin();
    final svc = CalendarSyncService(plugin: plugin);
    await expectLater(() => svc.teardown(), returnsNormally);
  });

  test('teardown con calendario salvato chiama deleteCalendar e pulisce prefs', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-99'});
    final plugin = _MockPlugin();
    when(() => plugin.deleteCalendar('cal-99'))
        .thenAnswer((_) async => _resultOk<bool>(true));

    final svc = CalendarSyncService(plugin: plugin);
    await svc.teardown();

    verify(() => plugin.deleteCalendar('cal-99')).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('injecare_calendar_id'), isNull);
  });

  // ── removeEvent ───────────────────────────────────────────────────────────────

  test('removeEvent salta se calendarEventId è vuoto', () async {
    final plugin = _MockPlugin();
    final svc = CalendarSyncService(plugin: plugin);
    await svc.removeEvent(_inj(calendarEventId: ''));
    verifyNever(() => plugin.deleteEvent(any(), any()));
  });

  test('removeEvent chiama deleteEvent quando calendarEventId è impostato', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-1'});
    final plugin = _MockPlugin();
    when(() => plugin.deleteEvent(any(), any()))
        .thenAnswer((_) async => _resultOk<bool>(true));

    final svc = CalendarSyncService(plugin: plugin);
    await svc.removeEvent(_inj(calendarEventId: 'evt-123'));

    verify(() => plugin.deleteEvent(any(), 'evt-123')).called(1);
  });

  // ── upsertEvent ───────────────────────────────────────────────────────────────

  test('upsertEvent ritorna null se createOrUpdateEvent restituisce null', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-1'});
    final plugin = _MockPlugin();
    when(() => plugin.createOrUpdateEvent(any())).thenAnswer((_) async => null);

    final svc = CalendarSyncService(plugin: plugin);
    final result = await svc.upsertEvent(_inj(), null, _noReminders);
    expect(result, isNull);
  });

  test('upsertEvent ritorna eventId in caso di successo', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-1'});
    final plugin = _MockPlugin();
    when(() => plugin.createOrUpdateEvent(any()))
        .thenAnswer((_) async => _resultOk<String>('new-evt'));

    final svc = CalendarSyncService(plugin: plugin);
    final result = await svc.upsertEvent(_inj(), null, _noReminders);
    expect(result, 'new-evt');
  });

  // ── markDone ──────────────────────────────────────────────────────────────────

  test('markDone con behavior=remove chiama removeEvent senza throw', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-1'});
    final plugin = _MockPlugin();
    when(() => plugin.deleteEvent(any(), any()))
        .thenAnswer((_) async => _resultOk<bool>(true));

    final svc = CalendarSyncService(plugin: plugin);
    await svc.markDone(
      _inj(calendarEventId: 'evt-1'),
      CompletionBehavior.remove,
    );
    verify(() => plugin.deleteEvent(any(), 'evt-1')).called(1);
  });

  test('markDone con behavior=markDone riscrive il titolo con segno spunta', () async {
    SharedPreferences.setMockInitialValues({'injecare_calendar_id': 'cal-1'});
    final plugin = _MockPlugin();

    Event? capturedEvent;
    when(() => plugin.createOrUpdateEvent(any())).thenAnswer((inv) async {
      capturedEvent = inv.positionalArguments.first as Event;
      return _resultOk<String>('evt-1');
    });

    final svc = CalendarSyncService(plugin: plugin);
    await svc.markDone(
      _inj(calendarEventId: 'evt-1', pointLabel: 'Coscia Dx · 1'),
      CompletionBehavior.markDone,
    );

    expect(capturedEvent?.title, startsWith('✓'));
    // Nessun reminder per evento "done"
    expect(capturedEvent?.reminders, anyOf(isNull, isEmpty));
  });
}

