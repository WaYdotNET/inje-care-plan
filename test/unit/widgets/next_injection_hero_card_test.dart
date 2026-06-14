import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/widgets/next_injection_hero_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async { await initializeDateFormatting('it'); });

  testWidgets('mostra punto, ora, CTA; il tap sulla CTA chiama onCta', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: NextInjectionHeroCard(
          pointLabel: 'Addome Dx · 4',
          scheduledAt: DateTime(2026, 6, 14, 20, 30),
          ctaLabel: 'Completa',
          onCta: () => tapped = true,
        ),
      ),
    ));
    expect(find.text('Addome Dx · 4'), findsOneWidget);
    expect(find.textContaining('20:30'), findsWidgets);
    expect(find.text('Completa'), findsOneWidget);
    await tester.tap(find.text('Completa'));
    expect(tapped, isTrue);
  });
}
