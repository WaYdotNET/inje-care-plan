import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';
import 'package:injecare_plan/core/widgets/app_card.dart';

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(AppCard), matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renderizza il child e usa la surface light', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: AppCard(child: Text('contenuto'))),
    ));
    expect(find.text('contenuto'), findsOneWidget);
    expect(_decorationOf(tester).color, AppTokens.lightSurface);
  });

  testWidgets('in dark usa la surface scura', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: AppCard(child: Text('x'))),
    ));
    expect(_decorationOf(tester).color, AppTokens.darkSurface);
  });

  testWidgets('onTap viene invocato', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: AppCard(onTap: () => tapped = true, child: const Text('t'))),
    ));
    await tester.tap(find.text('t'));
    expect(tapped, isTrue);
  });

  testWidgets('quando ha onTap espone semantica di bottone', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: AppCard(onTap: () {}, child: const Text('tap'))),
    ));
    expect(
      tester.getSemantics(find.byType(AppCard)),
      isSemantics(isButton: true),
    );
  });
}
