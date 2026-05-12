import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_colors.dart';

void main() {
  group('InjectionStatusColors (Bug 3 — semaforo verde/giallo/rosso)', () {
    test('completed = verde Success (sia light che dark)', () {
      expect(
        InjectionStatusColors.getStatusColorLight('completed'),
        AppColors.dawnSuccess,
      );
      expect(
        InjectionStatusColors.getStatusColorDark('completed'),
        AppColors.darkSuccess,
      );
    });

    test('scheduled = giallo Gold', () {
      expect(
        InjectionStatusColors.getStatusColorLight('scheduled'),
        AppColors.dawnGold,
      );
    });

    test('skipped/missed = rosso Love', () {
      expect(
        InjectionStatusColors.getStatusColorLight('skipped'),
        AppColors.dawnLove,
      );
      expect(
        InjectionStatusColors.getStatusColorLight('missed'),
        AppColors.dawnLove,
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
