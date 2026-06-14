import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/week_dots.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
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
}
