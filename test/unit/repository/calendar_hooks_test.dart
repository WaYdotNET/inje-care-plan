// test/unit/repository/calendar_hooks_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/calendar_sync_service.dart';
import 'package:injecare_plan/features/injection/injection_repository.dart';
import 'package:injecare_plan/models/injection_record.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_database.dart';

class _MockSync extends Mock implements CalendarSyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Injection(
        id: 0,
        zoneId: 1,
        pointNumber: 1,
        pointCode: 'CD-1',
        pointLabel: 'x',
        scheduledAt: DateTime(2026),
        completedAt: null,
        status: 'scheduled',
        notes: '',
        sideEffects: '',
        calendarEventId: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      const ReminderSettingsView(
        channelIncludesCalendar: true,
        includeFeedback: true,
        activeRules: [],
      ),
    );
  });

  test('createInjection sincronizza il calendario quando attivo', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();
    when(() => sync.upsertEvent(any(), any(), any()))
        .thenAnswer((_) async => 'evt-1');

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => true,
    );
    await repo.createInjection(
      InjectionRecord(
        zoneId: 1,
        pointNumber: 1,
        scheduledAt: DateTime(2026, 6, 20, 20),
        status: InjectionStatus.scheduled,
        customPointLabel: 'Coscia Dx · 1',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
    );

    verify(() => sync.upsertEvent(any(), any(), any())).called(1);
  });

  test('non sincronizza quando il calendario è disattivato', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => false,
    );
    await repo.createInjection(
      InjectionRecord(
        zoneId: 1,
        pointNumber: 1,
        scheduledAt: DateTime(2026, 6, 20, 20),
        status: InjectionStatus.scheduled,
        customPointLabel: 'Coscia Dx · 1',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
    );

    verifyNever(() => sync.upsertEvent(any(), any(), any()));
  });

  test('createInjection non-blocking: errore calendario non blocca il salvataggio', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();
    when(() => sync.upsertEvent(any(), any(), any()))
        .thenThrow(Exception('calendar down'));

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => true,
    );

    // Non deve lanciare eccezione nonostante il calendario sia down
    await expectLater(
      repo.createInjection(
        InjectionRecord(
          zoneId: 1,
          pointNumber: 1,
          scheduledAt: DateTime(2026, 6, 20, 20),
          status: InjectionStatus.scheduled,
          customPointLabel: 'Coscia Dx · 1',
          createdAt: DateTime(2026, 6, 15),
          updatedAt: DateTime(2026, 6, 15),
        ),
      ),
      completes,
    );

    // L'iniezione deve essere salvata nel DB nonostante l'errore del calendario
    final saved = await db.getAllInjections();
    expect(saved, hasLength(1));
    expect(saved.first.pointLabel, 'Coscia Dx · 1');
  });

  test('createInjection(syncCalendar: false) non chiama upsertEvent', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => true,
    );
    await repo.createInjection(
      InjectionRecord(
        zoneId: 1,
        pointNumber: 1,
        scheduledAt: DateTime(2026, 6, 20, 20),
        status: InjectionStatus.scheduled,
        customPointLabel: 'Coscia Dx · 1',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
      syncCalendar: false,
    );

    verifyNever(() => sync.upsertEvent(any(), any(), any()));
  });

  test('syncInjectionToCalendar chiama upsertEvent', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();
    when(() => sync.upsertEvent(any(), any(), any()))
        .thenAnswer((_) async => 'evt-sync');

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => true,
    );

    // Prima crea senza sync calendario.
    final id = await repo.createInjection(
      InjectionRecord(
        zoneId: 1,
        pointNumber: 1,
        scheduledAt: DateTime(2026, 6, 20, 20),
        status: InjectionStatus.scheduled,
        customPointLabel: 'Coscia Dx · 1',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
      syncCalendar: false,
    );

    verifyNever(() => sync.upsertEvent(any(), any(), any()));

    // Poi sincronizza esplicitamente.
    await repo.syncInjectionToCalendar(id);

    verify(() => sync.upsertEvent(any(), any(), any())).called(1);
  });

  test('deleteInjection non-blocking: errore removeEvent non blocca la cancellazione', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final sync = _MockSync();
    when(() => sync.upsertEvent(any(), any(), any()))
        .thenAnswer((_) async => 'evt-1');
    when(() => sync.removeEvent(any()))
        .thenThrow(Exception('calendar down'));

    final repo = InjectionRepository(
      database: db,
      calendarSync: sync,
      isCalendarEnabled: () => true,
    );

    final id = await repo.createInjection(
      InjectionRecord(
        zoneId: 1,
        pointNumber: 1,
        scheduledAt: DateTime(2026, 6, 20, 20),
        status: InjectionStatus.scheduled,
        customPointLabel: 'Coscia Dx · 1',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
    );

    // Non deve lanciare eccezione nonostante il calendario sia down
    await expectLater(repo.deleteInjection(id), completes);

    // L'iniezione deve essere rimossa dal DB nonostante l'errore del calendario
    final remaining = await db.getAllInjections();
    expect(remaining, isEmpty);
  });
}
