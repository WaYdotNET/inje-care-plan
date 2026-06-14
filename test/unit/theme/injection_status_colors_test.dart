import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';
import 'package:injecare_plan/core/theme/injection_status_colors.dart';

void main() {
  group('InjectionStatusColors (Bug 3 — semaforo verde/giallo/rosso)', () {
    test('completed = verde Success (sia light che dark)', () {
      expect(
        InjectionStatusColors.getStatusColorLight('completed'),
        AppTokens.successLight,
      );
      expect(
        InjectionStatusColors.getStatusColorDark('completed'),
        AppTokens.successDark,
      );
    });

    test('scheduled = giallo Gold', () {
      expect(
        InjectionStatusColors.getStatusColorLight('scheduled'),
        AppTokens.warnLight,
      );
    });

    test('skipped/missed = rosso Love', () {
      expect(
        InjectionStatusColors.getStatusColorLight('skipped'),
        AppTokens.dangerLight,
      );
      expect(
        InjectionStatusColors.getStatusColorLight('missed'),
        AppTokens.dangerLight,
      );
    });

    test('i tre colori principali sono ben distinti tra loro (light)', () {
      final completed = InjectionStatusColors.getStatusColorLight('completed');
      final scheduled = InjectionStatusColors.getStatusColorLight('scheduled');
      final skipped = InjectionStatusColors.getStatusColorLight('skipped');
      expect(completed, isNot(scheduled));
      expect(completed, isNot(skipped));
      expect(scheduled, isNot(skipped));
    });
  });
}
