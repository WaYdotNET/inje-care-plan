import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/app_bottom_nav.dart';

void main() {
  Widget host(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(bottomNavigationBar: child));

  testWidgets('mostra le 4 etichette tab', (tester) async {
    await tester.pumpWidget(host(AppBottomNav(currentIndex: 0, onTap: (_) {}, onAdd: () {})));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendario'), findsOneWidget);
    expect(find.text('Statistiche'), findsOneWidget);
    expect(find.text('Impostazioni'), findsOneWidget);
  });

  testWidgets('onTap riceve l\'indice della tab', (tester) async {
    var idx = -1;
    await tester.pumpWidget(host(AppBottomNav(currentIndex: 0, onTap: (i) => idx = i, onAdd: () {})));
    await tester.tap(find.text('Statistiche'));
    expect(idx, 2);
  });

  testWidgets('il pulsante ＋ chiama onAdd', (tester) async {
    var added = false;
    await tester.pumpWidget(host(AppBottomNav(currentIndex: 0, onTap: (_) {}, onAdd: () => added = true)));
    await tester.tap(find.byKey(const Key('app_bottom_nav_add')));
    expect(added, isTrue);
  });
}
