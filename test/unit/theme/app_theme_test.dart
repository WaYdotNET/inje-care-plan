import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    group('light theme', () {
      test('returns a valid ThemeData', () {
        final theme = AppTheme.light;
        expect(theme, isA<ThemeData>());
      });

      test('has correct brightness', () {
        final theme = AppTheme.light;
        expect(theme.brightness, Brightness.light);
      });

      test('uses Material3', () {
        final theme = AppTheme.light;
        expect(theme.useMaterial3, true);
      });

      test('has correct scaffold background color', () {
        final theme = AppTheme.light;
        expect(theme.scaffoldBackgroundColor, AppColors.dawnBase);
      });

      test('has correct card color', () {
        final theme = AppTheme.light;
        expect(theme.cardColor, AppColors.dawnSurface);
      });

      test('has correct divider color', () {
        final theme = AppTheme.light;
        expect(theme.dividerColor, AppColors.dawnHighlightMed);
      });

      test('has correct color scheme primary', () {
        final theme = AppTheme.light;
        expect(theme.colorScheme.primary, AppColors.dawnPine);
      });

      test('has correct color scheme secondary', () {
        final theme = AppTheme.light;
        expect(theme.colorScheme.secondary, AppColors.dawnIris);
      });

      test('has correct color scheme error', () {
        final theme = AppTheme.light;
        expect(theme.colorScheme.error, AppColors.dawnLove);
      });

      test('appBarTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.appBarTheme.backgroundColor, AppColors.dawnSurface);
        expect(theme.appBarTheme.foregroundColor, AppColors.dawnText);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.centerTitle, true);
      });

      test('cardTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.cardTheme.color, AppColors.dawnSurface);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('elevatedButtonTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.elevatedButtonTheme.style, isNotNull);
      });

      test('outlinedButtonTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.outlinedButtonTheme.style, isNotNull);
      });

      test('textButtonTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.textButtonTheme.style, isNotNull);
      });

      test('inputDecorationTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.inputDecorationTheme.filled, true);
        expect(theme.inputDecorationTheme.fillColor, AppColors.dawnHighlightLow);
      });

      test('bottomNavigationBarTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.bottomNavigationBarTheme.backgroundColor, AppColors.dawnSurface);
        expect(theme.bottomNavigationBarTheme.selectedItemColor, AppColors.dawnPine);
        expect(theme.bottomNavigationBarTheme.unselectedItemColor, AppColors.dawnMuted);
      });

      test('floatingActionButtonTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.dawnPine);
        expect(theme.floatingActionButtonTheme.foregroundColor, Colors.white);
      });

      test('chipTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.chipTheme.backgroundColor, AppColors.dawnHighlightLow);
        expect(theme.chipTheme.selectedColor, AppColors.dawnPine);
      });

      test('snackBarTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.snackBarTheme.backgroundColor, AppColors.dawnOverlay);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });

      test('dialogTheme has correct configuration', () {
        final theme = AppTheme.light;
        expect(theme.dialogTheme.backgroundColor, AppColors.dawnSurface);
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('textTheme has all text styles', () {
        final theme = AppTheme.light;
        expect(theme.textTheme.displayLarge, isNotNull);
        expect(theme.textTheme.displayMedium, isNotNull);
        expect(theme.textTheme.displaySmall, isNotNull);
        expect(theme.textTheme.headlineLarge, isNotNull);
        expect(theme.textTheme.headlineMedium, isNotNull);
        expect(theme.textTheme.headlineSmall, isNotNull);
        expect(theme.textTheme.titleLarge, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
        expect(theme.textTheme.titleSmall, isNotNull);
        expect(theme.textTheme.bodyLarge, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.bodySmall, isNotNull);
        expect(theme.textTheme.labelLarge, isNotNull);
        expect(theme.textTheme.labelMedium, isNotNull);
        expect(theme.textTheme.labelSmall, isNotNull);
      });
    });

    group('dark theme', () {
      test('returns a valid ThemeData', () {
        final theme = AppTheme.dark;
        expect(theme, isA<ThemeData>());
      });

      test('has correct brightness', () {
        final theme = AppTheme.dark;
        expect(theme.brightness, Brightness.dark);
      });

      test('uses Material3', () {
        final theme = AppTheme.dark;
        expect(theme.useMaterial3, true);
      });

      test('has correct scaffold background color', () {
        final theme = AppTheme.dark;
        expect(theme.scaffoldBackgroundColor, AppColors.darkBase);
      });

      test('has correct card color', () {
        final theme = AppTheme.dark;
        expect(theme.cardColor, AppColors.darkSurface);
      });

      test('has correct divider color', () {
        final theme = AppTheme.dark;
        expect(theme.dividerColor, AppColors.darkHighlightMed);
      });

      test('has correct color scheme primary', () {
        final theme = AppTheme.dark;
        expect(theme.colorScheme.primary, AppColors.darkPine);
      });

      test('has correct color scheme secondary', () {
        final theme = AppTheme.dark;
        expect(theme.colorScheme.secondary, AppColors.darkIris);
      });

      test('has correct color scheme error', () {
        final theme = AppTheme.dark;
        expect(theme.colorScheme.error, AppColors.darkLove);
      });

      test('appBarTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.appBarTheme.backgroundColor, AppColors.darkSurface);
        expect(theme.appBarTheme.foregroundColor, AppColors.darkText);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.centerTitle, true);
      });

      test('cardTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.cardTheme.color, AppColors.darkSurface);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('elevatedButtonTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.elevatedButtonTheme.style, isNotNull);
      });

      test('outlinedButtonTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.outlinedButtonTheme.style, isNotNull);
      });

      test('textButtonTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.textButtonTheme.style, isNotNull);
      });

      test('inputDecorationTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.inputDecorationTheme.filled, true);
        expect(theme.inputDecorationTheme.fillColor, AppColors.darkHighlightLow);
      });

      test('bottomNavigationBarTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.bottomNavigationBarTheme.backgroundColor, AppColors.darkSurface);
        expect(theme.bottomNavigationBarTheme.selectedItemColor, AppColors.darkFoam);
        expect(theme.bottomNavigationBarTheme.unselectedItemColor, AppColors.darkMuted);
      });

      test('floatingActionButtonTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.darkPine);
        expect(theme.floatingActionButtonTheme.foregroundColor, Colors.white);
      });

      test('chipTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.chipTheme.backgroundColor, AppColors.darkHighlightLow);
        expect(theme.chipTheme.selectedColor, AppColors.darkPine);
      });

      test('snackBarTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.snackBarTheme.backgroundColor, AppColors.darkOverlay);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });

      test('dialogTheme has correct configuration', () {
        final theme = AppTheme.dark;
        expect(theme.dialogTheme.backgroundColor, AppColors.darkSurface);
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('textTheme has all text styles', () {
        final theme = AppTheme.dark;
        expect(theme.textTheme.displayLarge, isNotNull);
        expect(theme.textTheme.displayMedium, isNotNull);
        expect(theme.textTheme.displaySmall, isNotNull);
        expect(theme.textTheme.headlineLarge, isNotNull);
        expect(theme.textTheme.headlineMedium, isNotNull);
        expect(theme.textTheme.headlineSmall, isNotNull);
        expect(theme.textTheme.titleLarge, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
        expect(theme.textTheme.titleSmall, isNotNull);
        expect(theme.textTheme.bodyLarge, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.bodySmall, isNotNull);
        expect(theme.textTheme.labelLarge, isNotNull);
        expect(theme.textTheme.labelMedium, isNotNull);
        expect(theme.textTheme.labelSmall, isNotNull);
      });
    });

    group('theme consistency', () {
      test('light and dark themes have same structure', () {
        final light = AppTheme.light;
        final dark = AppTheme.dark;

        // Both have app bar themes
        expect(light.appBarTheme, isNotNull);
        expect(dark.appBarTheme, isNotNull);

        // Both have card themes
        expect(light.cardTheme, isNotNull);
        expect(dark.cardTheme, isNotNull);

        // Both have text themes with same styles
        expect(light.textTheme.displayLarge?.fontSize,
               dark.textTheme.displayLarge?.fontSize);
        expect(light.textTheme.bodyMedium?.fontSize,
               dark.textTheme.bodyMedium?.fontSize);
      });

      test('text theme font sizes are consistent', () {
        final lightText = AppTheme.light.textTheme;
        final darkText = AppTheme.dark.textTheme;

        expect(lightText.displayLarge?.fontSize, 32);
        expect(darkText.displayLarge?.fontSize, 32);

        expect(lightText.displayMedium?.fontSize, 28);
        expect(darkText.displayMedium?.fontSize, 28);

        expect(lightText.bodyMedium?.fontSize, 14);
        expect(darkText.bodyMedium?.fontSize, 14);
      });
    });
  });
}
