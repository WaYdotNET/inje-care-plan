import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/calendar_event_content.dart';

Injection _inj({
  required int id,
  required String pointLabel,
  required DateTime scheduledAt,
  String sideEffects = '',
  String notes = '',
  String status = 'scheduled',
}) {
  return Injection(
    id: id,
    zoneId: 1,
    pointNumber: 1,
    pointCode: 'CD-1',
    pointLabel: pointLabel,
    scheduledAt: scheduledAt,
    completedAt: null,
    status: status,
    notes: notes,
    sideEffects: sideEffects,
    calendarEventId: '',
    createdAt: scheduledAt,
    updatedAt: scheduledAt,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
  });

  test('titolo con siringa e label punto', () {
    final t = buildEventTitle(
      _inj(id: 1, pointLabel: 'Coscia Dx · 3', scheduledAt: DateTime(2026, 6, 15, 20)),
    );
    expect(t, '💉 Coscia Dx · 3');
  });

  test('note senza precedente: solo riga corrente', () {
    final notes = buildEventNotes(
      _inj(id: 2, pointLabel: 'Coscia Dx · 3', scheduledAt: DateTime(2026, 6, 15, 20)),
      null,
    );
    expect(notes, contains('Iniezione programmata — Coscia Dx · 3'));
    expect(notes, isNot(contains('Ultima volta')));
  });

  test('note con precedente che ha feedback', () {
    final prev = _inj(
      id: 1,
      pointLabel: 'Coscia Sx · 2',
      scheduledAt: DateTime(2026, 6, 12, 20),
      sideEffects: 'rossore,dolore lieve',
      notes: 'passato in 10 min',
      status: 'completed',
    );
    final notes = buildEventNotes(
      _inj(id: 2, pointLabel: 'Coscia Dx · 3', scheduledAt: DateTime(2026, 6, 15, 20)),
      prev,
    );
    expect(notes, contains('Ultima volta'));
    expect(notes, contains('Coscia Sx · 2'));
    expect(notes, contains('rossore, dolore lieve'));
    expect(notes, contains('passato in 10 min'));
  });

  test('precedente senza feedback: ometti il blocco', () {
    final prev = _inj(
      id: 1,
      pointLabel: 'Coscia Sx · 2',
      scheduledAt: DateTime(2026, 6, 12, 20),
      status: 'completed',
    );
    final notes = buildEventNotes(
      _inj(id: 2, pointLabel: 'Coscia Dx · 3', scheduledAt: DateTime(2026, 6, 15, 20)),
      prev,
    );
    expect(notes, isNot(contains('Ultima volta')));
  });
}
