import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/settings/reminder_calendar_screen.dart';

void main() {
  testWidgets('mostra il master toggle del calendario', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: ReminderCalendarScreen()),
    ));
    await tester.pump();
    expect(find.text('Aggiungi al calendario del telefono'), findsOneWidget);
  });
}
