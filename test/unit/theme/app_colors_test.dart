import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Rosé Pine Dawn (Light Mode)', () {
      test('dawnBase is correct color', () {
        expect(AppColors.dawnBase, const Color(0xFFfaf4ed));
      });

      test('dawnSurface is correct color', () {
        expect(AppColors.dawnSurface, const Color(0xFFfffaf3));
      });

      test('dawnOverlay is correct color', () {
        expect(AppColors.dawnOverlay, const Color(0xFFf2e9e1));
      });

      test('dawnMuted is correct color', () {
        expect(AppColors.dawnMuted, const Color(0xFF9893a5));
      });

      test('dawnSubtle is correct color', () {
        expect(AppColors.dawnSubtle, const Color(0xFF797593));
      });

      test('dawnText is correct color', () {
        expect(AppColors.dawnText, const Color(0xFF575279));
      });

      test('dawnLove is correct color', () {
        expect(AppColors.dawnLove, const Color(0xFFb4637a));
      });

      test('dawnGold is correct color', () {
        expect(AppColors.dawnGold, const Color(0xFFea9d34));
      });

      test('dawnRose is correct color', () {
        expect(AppColors.dawnRose, const Color(0xFFd7827e));
      });

      test('dawnPine is correct color', () {
        expect(AppColors.dawnPine, const Color(0xFF286983));
      });

      test('dawnFoam is correct color', () {
        expect(AppColors.dawnFoam, const Color(0xFF56949f));
      });

      test('dawnIris is correct color', () {
        expect(AppColors.dawnIris, const Color(0xFF907aa9));
      });

      test('dawnHighlightLow is correct color', () {
        expect(AppColors.dawnHighlightLow, const Color(0xFFf4ede8));
      });

      test('dawnHighlightMed is correct color', () {
        expect(AppColors.dawnHighlightMed, const Color(0xFFdfdad9));
      });

      test('dawnHighlightHigh is correct color', () {
        expect(AppColors.dawnHighlightHigh, const Color(0xFFcecacd));
      });
    });

    group('Rosé Pine (Dark Mode)', () {
      test('darkBase is correct color', () {
        expect(AppColors.darkBase, const Color(0xFF191724));
      });

      test('darkSurface is correct color', () {
        expect(AppColors.darkSurface, const Color(0xFF1f1d2e));
      });

      test('darkOverlay is correct color', () {
        expect(AppColors.darkOverlay, const Color(0xFF26233a));
      });

      test('darkMuted is correct color', () {
        expect(AppColors.darkMuted, const Color(0xFF6e6a86));
      });

      test('darkSubtle is correct color', () {
        expect(AppColors.darkSubtle, const Color(0xFF908caa));
      });

      test('darkText is correct color', () {
        expect(AppColors.darkText, const Color(0xFFe0def4));
      });

      test('darkLove is correct color', () {
        expect(AppColors.darkLove, const Color(0xFFeb6f92));
      });

      test('darkGold is correct color', () {
        expect(AppColors.darkGold, const Color(0xFFf6c177));
      });

      test('darkRose is correct color', () {
        expect(AppColors.darkRose, const Color(0xFFebbcba));
      });

      test('darkPine is correct color', () {
        expect(AppColors.darkPine, const Color(0xFF31748f));
      });

      test('darkFoam is correct color', () {
        expect(AppColors.darkFoam, const Color(0xFF9ccfd8));
      });

      test('darkIris is correct color', () {
        expect(AppColors.darkIris, const Color(0xFFc4a7e7));
      });

      test('darkHighlightLow is correct color', () {
        expect(AppColors.darkHighlightLow, const Color(0xFF21202e));
      });

      test('darkHighlightMed is correct color', () {
        expect(AppColors.darkHighlightMed, const Color(0xFF403d52));
      });

      test('darkHighlightHigh is correct color', () {
        expect(AppColors.darkHighlightHigh, const Color(0xFF524f67));
      });
    });
  });

  group('InjectionStatusColors', () {
    group('getStatusColorLight', () {
      test('returns dawnPine for completed', () {
        expect(
          InjectionStatusColors.getStatusColorLight('completed'),
          AppColors.dawnPine,
        );
      });

      test('returns dawnFoam for scheduled', () {
        expect(
          InjectionStatusColors.getStatusColorLight('scheduled'),
          AppColors.dawnFoam,
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
      test('returns darkPine for completed', () {
        expect(
          InjectionStatusColors.getStatusColorDark('completed'),
          AppColors.darkPine,
        );
      });

      test('returns darkFoam for scheduled', () {
        expect(
          InjectionStatusColors.getStatusColorDark('scheduled'),
          AppColors.darkFoam,
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
