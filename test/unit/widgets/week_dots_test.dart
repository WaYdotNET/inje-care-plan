import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/week_dots.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  setUpAll(() async { await initializeDateFormatting('it'); });

  final monday = DateTime(2026, 6, 8);
  Widget host(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

  testWidgets('mostra 7 giorni', (tester) async {
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [DayStatus.none, DayStatus.done, DayStatus.scheduled, DayStatus.none, DayStatus.done, DayStatus.skipped, DayStatus.none],
    )));
    expect(find.byType(GestureDetector), findsNWidgets(7));
  });

  testWidgets('done mostra check, skipped mostra close', (tester) async {
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [DayStatus.done, DayStatus.skipped, DayStatus.none, DayStatus.none, DayStatus.none, DayStatus.none, DayStatus.none],
    )));
    expect(find.byIcon(PhosphorIconsDuotone.check), findsOneWidget);
    expect(find.byIcon(PhosphorIconsDuotone.x), findsOneWidget);
  });

  testWidgets('onTapDay riceve l\'indice', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [DayStatus.done, DayStatus.none, DayStatus.none, DayStatus.none, DayStatus.none, DayStatus.none, DayStatus.none],
      onTapDay: (i) => tapped = i,
    )));
    await tester.tap(find.byType(GestureDetector).first);
    expect(tapped, 0);
  });

  test('dayStatusFromString mappa gli stati iniezione', () {
    expect(dayStatusFromString('completed'), DayStatus.done);
    expect(dayStatusFromString('skipped'), DayStatus.skipped);
    expect(dayStatusFromString('missed'), DayStatus.missed);
    expect(dayStatusFromString('scheduled'), DayStatus.scheduled);
    expect(dayStatusFromString('delayed'), DayStatus.scheduled);
    expect(dayStatusFromString('qualsiasi'), DayStatus.scheduled);
  });

  testWidgets('badge "2" appare sul giorno con count > 1', (tester) async {
    final counts = List<int>.filled(7, 0);
    counts[0] = 2; // lunedì: 2 iniezioni
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [
        DayStatus.done,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
      ],
      counts: counts,
    )));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('nessun badge quando count == 1', (tester) async {
    final counts = List<int>.filled(7, 0);
    counts[0] = 1;
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [
        DayStatus.done,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
      ],
      counts: counts,
    )));
    expect(find.text('1'), findsNothing);
  });

  testWidgets('badge non appare quando counts è null', (tester) async {
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [
        DayStatus.done,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
        DayStatus.none,
      ],
    )));
    // nessun testo numerico atteso nei pallini
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('badge "3" su due giorni distinti', (tester) async {
    final counts = List<int>.filled(7, 0);
    counts[1] = 3; // martedì
    counts[4] = 3; // venerdì
    await tester.pumpWidget(host(WeekDots(
      weekStart: monday,
      statuses: const [
        DayStatus.none,
        DayStatus.done,
        DayStatus.none,
        DayStatus.none,
        DayStatus.done,
        DayStatus.none,
        DayStatus.none,
      ],
      counts: counts,
    )));
    expect(find.text('3'), findsNWidgets(2));
  });
}
