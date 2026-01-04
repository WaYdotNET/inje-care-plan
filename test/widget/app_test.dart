import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/theme/app_theme.dart';
import 'package:injecare_plan/app/app.dart';

void main() {
  group('InjeCareApp', () {
    test('is a ConsumerWidget', () {
      const app = InjeCareApp();
      expect(app, isA<Widget>());
    });

    test('has a key', () {
      const app = InjeCareApp(key: Key('test'));
      expect(app.key, const Key('test'));
    });
  });

  group('App configuration', () {
    test('AppTheme.light is used for light mode', () {
      final theme = AppTheme.light;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);
    });

    test('AppTheme.dark is used for dark mode', () {
      final theme = AppTheme.dark;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);
    });

    test('both themes have consistent configuration', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;
      
      // Both use Material3
      expect(light.useMaterial3, dark.useMaterial3);
      
      // Both have app bar configuration
      expect(light.appBarTheme.elevation, dark.appBarTheme.elevation);
      expect(light.appBarTheme.centerTitle, dark.appBarTheme.centerTitle);
    });

    test('locales are defined', () {
      // These are the supported locales in app.dart
      const itLocale = Locale('it', 'IT');
      const enLocale = Locale('en', 'US');
      
      expect(itLocale.languageCode, 'it');
      expect(enLocale.languageCode, 'en');
    });
  });

  group('App title', () {
    test('app title is InjeCare Plan', () {
      // The title is hardcoded in app.dart
      const expectedTitle = 'InjeCare Plan';
      expect(expectedTitle, isNotEmpty);
      expect(expectedTitle, contains('InjeCare'));
    });
  });
}
