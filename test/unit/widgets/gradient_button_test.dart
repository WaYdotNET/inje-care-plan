import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/widgets/gradient_button.dart';

void main() {
  testWidgets('mostra la label e risponde al tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GradientButton(label: 'Registra', onPressed: () => tapped = true),
      ),
    ));
    expect(find.text('Registra'), findsOneWidget);
    await tester.tap(find.text('Registra'));
    expect(tapped, isTrue);
  });

  testWidgets('disabilitato (onPressed null) non è interattivo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GradientButton(label: 'X', onPressed: null)),
    ));
    await tester.tap(find.text('X'));
    final inkwell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkwell.onTap, isNull);
  });

  testWidgets('in loading mostra un indicatore e non chiama il callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GradientButton(label: 'Y', loading: true, onPressed: () => tapped = true),
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Y'));
    expect(tapped, isFalse);
  });
}
