import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/status_legend.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets('mostra le voci della legenda', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: StatusLegend()),
    ));
    expect(find.text('Fatta'), findsOneWidget);
    expect(find.text('Da fare'), findsOneWidget);
    expect(find.text('Saltata/Persa'), findsOneWidget);
    expect(find.text('Nessuna'), findsOneWidget);
  });

  testWidgets('gli stati sono distinguibili anche per icona (✓ / ✕)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: StatusLegend()),
    ));
    expect(find.byIcon(PhosphorIconsDuotone.check), findsOneWidget);
    expect(find.byIcon(PhosphorIconsDuotone.x), findsOneWidget);
  });
}
