import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/settings/diagnostic_screen.dart';

void main() {
  testWidgets('mostra il titolo Diagnostica', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DiagnosticScreen())));
    await tester.pump();
    expect(find.text('Diagnostica'), findsOneWidget);
  });
}
