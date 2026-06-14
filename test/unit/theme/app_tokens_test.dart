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
}
