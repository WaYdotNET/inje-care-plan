import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/status_chip.dart';

void main() {
  testWidgets('mostra la label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: StatusChip(label: 'Consigliato', status: InjectionVisualStatus.completed),
      ),
    ));
    expect(find.text('Consigliato'), findsOneWidget);
  });

  testWidgets('lo stato "today" usa il gradiente accento', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: StatusChip(label: 'Oggi', status: InjectionVisualStatus.today),
      ),
    ));
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(StatusChip), matching: find.byType(Container)).first,
    );
    final deco = container.decoration! as BoxDecoration;
    expect(deco.gradient, isNotNull);
  });
}
