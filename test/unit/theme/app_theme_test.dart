import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';

void main() {
  test('light usa Plus Jakarta Sans e accento Pop Gradient', () {
    final t = AppTheme.light;
    expect(t.brightness, Brightness.light);
    expect(t.textTheme.bodyMedium!.fontFamily, 'Plus Jakarta Sans');
    expect(t.colorScheme.primary, AppTokens.accent);
  });

  test('dark usa surface scura coerente', () {
    final t = AppTheme.dark;
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.surface, AppTokens.darkSurface);
    expect(t.textTheme.bodyMedium!.fontFamily, 'Plus Jakarta Sans');
  });

  test('scaffold con sfondo solido (no flash bianco nelle transizioni)', () {
    // Lo sfondo è solido (non trasparente) per evitare il flash bianco durante
    // le transizioni di schermata. Il gradiente resta dipinto a livello app.
    expect(AppTheme.light.scaffoldBackgroundColor, AppTokens.lightBgTop);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppTokens.darkBg);
  });
}
