import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';

void main() {
  test('accentGradient ha i due stop attesi', () {
    expect(AppTokens.accentGradient.colors, [AppTokens.accent, AppTokens.accentEnd]);
  });

  test('softShadow è più intensa in dark', () {
    final light = AppTokens.softShadow();
    final dark = AppTokens.softShadow(dark: true);
    expect(light.first.color.a, lessThan(dark.first.color.a));
  });

  test('raggi e spaziatura coerenti', () {
    expect(AppRadius.card, 20);
    expect(AppRadius.button, 14);
    expect(AppSpacing.l, 16);
  });

  test('token stati Accent-led definiti', () {
    expect(AppTokens.accentSoft, const Color(0xFFC3B2F2));
    expect(AppTokens.skipBg, const Color(0xFFFBE4EC));
    expect(AppTokens.skipFg, const Color(0xFFC2638A));
    expect(AppTokens.dotEmpty, const Color(0xFFDDD6EA));
  });
}
