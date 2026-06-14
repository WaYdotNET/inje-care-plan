import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/status_chip.dart';
import 'package:injecare_plan/features/home/widgets/week_agenda_view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  // startOfWeek = Monday 2026-06-01
  final startOfWeek = DateTime(2026, 6, 1);

  // One completed injection on Wednesday 2026-06-03
  final wedInjection = AgendaInjection(
    id: 42,
    scheduledAt: DateTime(2026, 6, 3, 20, 30),
    pointLabel: 'Coscia Dx · 3',
    status: 'completed',
  );

  testWidgets('renders exactly 7 day rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeekAgendaView(
            startOfWeek: startOfWeek,
            injections: const [],
            onTapInjection: (_) {},
          ),
        ),
      ),
    );
    // There is exactly 1 StatusChip per injection (0 injections = 0 chips).
    // We verify 7 rows by looking for the 7 weekday texts Mon–Sun.
    // WeekAgendaView exposes a Key('day_row_$i') for i in 0..6.
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('day_row_$i')), findsOneWidget);
    }
  });

  testWidgets('renders pointLabel for a completed injection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeekAgendaView(
            startOfWeek: startOfWeek,
            injections: [wedInjection],
            onTapInjection: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Coscia Dx · 3'), findsOneWidget);
  });

  testWidgets('renders exactly one StatusChip for one injection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeekAgendaView(
            startOfWeek: startOfWeek,
            injections: [wedInjection],
            onTapInjection: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(StatusChip), findsOneWidget);
  });

  testWidgets('tapping injection row calls onTapInjection with correct injection',
      (tester) async {
    AgendaInjection? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeekAgendaView(
            startOfWeek: startOfWeek,
            injections: [wedInjection],
            onTapInjection: (a) => tapped = a,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Coscia Dx · 3'));
    expect(tapped, isNotNull);
    expect(tapped!.id, 42);
    expect(tapped!.pointLabel, 'Coscia Dx · 3');
    expect(tapped!.status, 'completed');
  });

  testWidgets('empty injection days are NOT tappable (no callback)', (tester) async {
    AgendaInjection? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeekAgendaView(
            startOfWeek: startOfWeek,
            injections: const [],
            onTapInjection: (a) => tapped = a,
          ),
        ),
      ),
    );
    // Tap the first day row — no injection, so callback must NOT fire.
    await tester.tap(find.byKey(const Key('day_row_0')));
    expect(tapped, isNull);
  });
}
