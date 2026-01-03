import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/theme/theme_provider.dart';

void main() {
  group('AppThemeMode', () {
    test('should have all expected values', () {
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.scheduled));
      expect(AppThemeMode.values.length, 4);
    });
  });

  group('ScheduledDarkModeConfig', () {
    test('should have default values', () {
      const config = ScheduledDarkModeConfig();

      expect(config.darkModeStart.hour, 20);
      expect(config.darkModeStart.minute, 0);
      expect(config.darkModeEnd.hour, 7);
      expect(config.darkModeEnd.minute, 0);
    });

    test('should accept custom values', () {
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 18, minute: 30),
        darkModeEnd: TimeOfDay(hour: 6, minute: 0),
      );

      expect(config.darkModeStart.hour, 18);
      expect(config.darkModeStart.minute, 30);
      expect(config.darkModeEnd.hour, 6);
      expect(config.darkModeEnd.minute, 0);
    });

    test('isDarkModeTime should return true during dark mode hours', () {
      // This test is time-dependent, so we test the logic indirectly
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 0, minute: 0),
        darkModeEnd: TimeOfDay(hour: 23, minute: 59),
      );

      // Should always be dark mode with these settings
      expect(config.isDarkModeTime(), isTrue);
    });

    test('toJson should serialize correctly', () {
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 21, minute: 30),
        darkModeEnd: TimeOfDay(hour: 6, minute: 15),
      );

      final json = config.toJson();

      expect(json['startHour'], 21);
      expect(json['startMinute'], 30);
      expect(json['endHour'], 6);
      expect(json['endMinute'], 15);
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'startHour': 22,
        'startMinute': 45,
        'endHour': 5,
        'endMinute': 30,
      };

      final config = ScheduledDarkModeConfig.fromJson(json);

      expect(config.darkModeStart.hour, 22);
      expect(config.darkModeStart.minute, 45);
      expect(config.darkModeEnd.hour, 5);
      expect(config.darkModeEnd.minute, 30);
    });

    test('fromJson should use defaults for missing values', () {
      final json = <String, dynamic>{};

      final config = ScheduledDarkModeConfig.fromJson(json);

      expect(config.darkModeStart.hour, 20);
      expect(config.darkModeStart.minute, 0);
      expect(config.darkModeEnd.hour, 7);
      expect(config.darkModeEnd.minute, 0);
    });
  });

  group('ThemeState', () {
    test('should create with required values', () {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.dark,
      );

      expect(state.mode, AppThemeMode.dark);
      expect(state.effectiveThemeMode, ThemeMode.dark);
    });

    test('copyWith should preserve unchanged values', () {
      const original = ThemeState(
        mode: AppThemeMode.light,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.light,
      );

      final updated = original.copyWith(mode: AppThemeMode.dark);

      expect(updated.mode, AppThemeMode.dark);
      expect(updated.effectiveThemeMode, ThemeMode.light); // Unchanged
    });

    test('copyWith should update specified values', () {
      const original = ThemeState(
        mode: AppThemeMode.system,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.system,
      );

      final updated = original.copyWith(
        mode: AppThemeMode.scheduled,
        effectiveThemeMode: ThemeMode.dark,
      );

      expect(updated.mode, AppThemeMode.scheduled);
      expect(updated.effectiveThemeMode, ThemeMode.dark);
    });
  });
}
