import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';
import 'package:injecare_plan/core/widgets/app_scaffold.dart';

void main() {
  testWidgets('light usa il gradiente di sfondo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const AppScaffold(body: Text('home')),
    ));
    expect(find.text('home'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(AppScaffold), matching: find.byType(Container)).first,
    );
    final deco = container.decoration! as BoxDecoration;
    expect(deco.gradient, AppTokens.lightBgGradient);
  });

  testWidgets('dark usa lo sfondo pieno scuro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const AppScaffold(body: Text('x')),
    ));
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(AppScaffold), matching: find.byType(Container)).first,
    );
    final deco = container.decoration! as BoxDecoration;
    expect(deco.color, AppTokens.darkBg);
    expect(deco.gradient, isNull);
  });
}
