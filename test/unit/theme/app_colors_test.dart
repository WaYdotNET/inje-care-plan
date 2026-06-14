import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_colors.dart';
import 'package:injecare_plan/core/theme/app_tokens.dart';

void main() {
  group('AppColors', () {
    group('Pop Gradient light aliases (ex Rosé Pine Dawn)', () {
      test('dawnBase → AppTokens.lightBgTop', () {
        expect(AppColors.dawnBase, AppTokens.lightBgTop);
      });

      test('dawnSurface → AppTokens.lightSurface', () {
        expect(AppColors.dawnSurface, AppTokens.lightSurface);
      });

      test('dawnOverlay → AppTokens.lightBgBottom', () {
        expect(AppColors.dawnOverlay, AppTokens.lightBgBottom);
      });

      test('dawnMuted → AppTokens.lightMuted', () {
        expect(AppColors.dawnMuted, AppTokens.lightMuted);
      });

      test('dawnSubtle → AppTokens.lightSubtle', () {
        expect(AppColors.dawnSubtle, AppTokens.lightSubtle);
      });

      test('dawnText → AppTokens.lightInk', () {
        expect(AppColors.dawnText, AppTokens.lightInk);
      });

      test('dawnLove → AppTokens.dangerLight', () {
        expect(AppColors.dawnLove, AppTokens.dangerLight);
      });

      test('dawnGold → AppTokens.warnLight', () {
        expect(AppColors.dawnGold, AppTokens.warnLight);
      });

      test('dawnRose → AppTokens.pink', () {
        expect(AppColors.dawnRose, AppTokens.pink);
      });

      test('dawnPine → AppTokens.accent', () {
        expect(AppColors.dawnPine, AppTokens.accent);
      });

      test('dawnFoam → AppTokens.accentEnd', () {
        expect(AppColors.dawnFoam, AppTokens.accentEnd);
      });

      test('dawnIris → AppTokens.accent', () {
        expect(AppColors.dawnIris, AppTokens.accent);
      });

      test('dawnHighlightLow is correct Pop Gradient value', () {
        expect(AppColors.dawnHighlightLow, const Color(0xFFF3EEFB));
      });

      test('dawnHighlightMed → AppTokens.lightBorder', () {
        expect(AppColors.dawnHighlightMed, AppTokens.lightBorder);
      });

      test('dawnHighlightHigh is correct Pop Gradient value', () {
        expect(AppColors.dawnHighlightHigh, const Color(0xFFD9CFEC));
      });

      test('dawnSuccess → AppTokens.successLight', () {
        expect(AppColors.dawnSuccess, AppTokens.successLight);
      });
    });

    group('Pop Gradient dark aliases (ex Rosé Pine Dark Mode)', () {
      test('darkBase → AppTokens.darkBg', () {
        expect(AppColors.darkBase, AppTokens.darkBg);
      });

      test('darkSurface → AppTokens.darkSurface', () {
        expect(AppColors.darkSurface, AppTokens.darkSurface);
      });

      test('darkOverlay is correct Pop Gradient value', () {
        expect(AppColors.darkOverlay, const Color(0xFF241B3A));
      });

      test('darkMuted → AppTokens.darkMuted', () {
        expect(AppColors.darkMuted, AppTokens.darkMuted);
      });

      test('darkSubtle is correct Pop Gradient value', () {
        expect(AppColors.darkSubtle, const Color(0xFFA79EC4));
      });

      test('darkText → AppTokens.darkInk', () {
        expect(AppColors.darkText, AppTokens.darkInk);
      });

      test('darkLove → AppTokens.dangerDark', () {
        expect(AppColors.darkLove, AppTokens.dangerDark);
      });

      test('darkGold → AppTokens.warnDark', () {
        expect(AppColors.darkGold, AppTokens.warnDark);
      });

      test('darkRose is correct Pop Gradient value', () {
        expect(AppColors.darkRose, const Color(0xFFF0A7C9));
      });

      test('darkPine → AppTokens.accent', () {
        expect(AppColors.darkPine, AppTokens.accent);
      });

      test('darkFoam → AppTokens.accentEnd', () {
        expect(AppColors.darkFoam, AppTokens.accentEnd);
      });

      test('darkIris is correct Pop Gradient value', () {
        expect(AppColors.darkIris, const Color(0xFFC9B6FF));
      });

      test('darkHighlightLow is correct Pop Gradient value', () {
        expect(AppColors.darkHighlightLow, const Color(0xFF181226));
      });

      test('darkHighlightMed → AppTokens.darkBorder', () {
        expect(AppColors.darkHighlightMed, AppTokens.darkBorder);
      });

      test('darkHighlightHigh is correct Pop Gradient value', () {
        expect(AppColors.darkHighlightHigh, const Color(0xFF3A2F58));
      });

      test('darkSuccess → AppTokens.successDark', () {
        expect(AppColors.darkSuccess, AppTokens.successDark);
      });
    });
  });

  group('InjectionStatusColors', () {
    group('getStatusColorLight', () {
      test('returns dawnSuccess (green) for completed', () {
        expect(
          InjectionStatusColors.getStatusColorLight('completed'),
          AppColors.dawnSuccess,
        );
      });

      test('returns dawnGold (yellow) for scheduled', () {
        expect(
          InjectionStatusColors.getStatusColorLight('scheduled'),
          AppColors.dawnGold,
        );
      });

      test('returns dawnGold for delayed', () {
        expect(
          InjectionStatusColors.getStatusColorLight('delayed'),
          AppColors.dawnGold,
        );
      });

      test('returns dawnLove for skipped', () {
        expect(
          InjectionStatusColors.getStatusColorLight('skipped'),
          AppColors.dawnLove,
        );
      });

      test('returns dawnMuted for blacklisted', () {
        expect(
          InjectionStatusColors.getStatusColorLight('blacklisted'),
          AppColors.dawnMuted,
        );
      });

      test('returns dawnSubtle for unknown status', () {
        expect(
          InjectionStatusColors.getStatusColorLight('unknown'),
          AppColors.dawnSubtle,
        );
      });
    });

    group('getStatusColorDark', () {
      test('returns darkSuccess (green) for completed', () {
        expect(
          InjectionStatusColors.getStatusColorDark('completed'),
          AppColors.darkSuccess,
        );
      });

      test('returns darkGold (yellow) for scheduled', () {
        expect(
          InjectionStatusColors.getStatusColorDark('scheduled'),
          AppColors.darkGold,
        );
      });

      test('returns darkGold for delayed', () {
        expect(
          InjectionStatusColors.getStatusColorDark('delayed'),
          AppColors.darkGold,
        );
      });

      test('returns darkLove for skipped', () {
        expect(
          InjectionStatusColors.getStatusColorDark('skipped'),
          AppColors.darkLove,
        );
      });

      test('returns darkMuted for blacklisted', () {
        expect(
          InjectionStatusColors.getStatusColorDark('blacklisted'),
          AppColors.darkMuted,
        );
      });

      test('returns darkSubtle for unknown status', () {
        expect(
          InjectionStatusColors.getStatusColorDark('unknown'),
          AppColors.darkSubtle,
        );
      });
    });
  });
}
