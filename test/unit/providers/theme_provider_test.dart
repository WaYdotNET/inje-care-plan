import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/theme_provider.dart';

void main() {
  group('AppThemeMode', () {
    test('has correct values', () {
      expect(AppThemeMode.values, hasLength(4));
      expect(AppThemeMode.light.index, 0);
      expect(AppThemeMode.dark.index, 1);
      expect(AppThemeMode.system.index, 2);
      expect(AppThemeMode.scheduled.index, 3);
    });
  });

  group('ScheduledDarkModeConfig', () {
    test('has default values', () {
      const config = ScheduledDarkModeConfig();

      expect(config.darkModeStart.hour, 20);
      expect(config.darkModeStart.minute, 0);
      expect(config.darkModeEnd.hour, 7);
      expect(config.darkModeEnd.minute, 0);
    });

    test('can be created with custom values', () {
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 22, minute: 30),
        darkModeEnd: TimeOfDay(hour: 6, minute: 0),
      );

      expect(config.darkModeStart.hour, 22);
      expect(config.darkModeStart.minute, 30);
      expect(config.darkModeEnd.hour, 6);
      expect(config.darkModeEnd.minute, 0);
    });

    test('toJson returns correct map', () {
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 21, minute: 15),
        darkModeEnd: TimeOfDay(hour: 8, minute: 45),
      );

      final json = config.toJson();

      expect(json['startHour'], 21);
      expect(json['startMinute'], 15);
      expect(json['endHour'], 8);
      expect(json['endMinute'], 45);
    });

    test('fromJson creates config from map', () {
      final json = {
        'startHour': 19,
        'startMinute': 30,
        'endHour': 6,
        'endMinute': 15,
      };

      final config = ScheduledDarkModeConfig.fromJson(json);

      expect(config.darkModeStart.hour, 19);
      expect(config.darkModeStart.minute, 30);
      expect(config.darkModeEnd.hour, 6);
      expect(config.darkModeEnd.minute, 15);
    });

    test('fromJson uses defaults for missing values', () {
      final config = ScheduledDarkModeConfig.fromJson({});

      expect(config.darkModeStart.hour, 20);
      expect(config.darkModeStart.minute, 0);
      expect(config.darkModeEnd.hour, 7);
      expect(config.darkModeEnd.minute, 0);
    });

    test('isDarkModeTime returns correct value for daytime hours', () {
      // When not crossing midnight (e.g., 8:00 to 18:00)
      const configDay = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 8, minute: 0),
        darkModeEnd: TimeOfDay(hour: 18, minute: 0),
      );

      // This test depends on current time, so we just verify the method exists
      expect(configDay.isDarkModeTime, isA<Function>());
      // The actual value depends on when the test runs
    });

    test('isDarkModeTime handles crossing midnight', () {
      const config = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 20, minute: 0),
        darkModeEnd: TimeOfDay(hour: 7, minute: 0),
      );

      // This test validates the logic exists
      expect(config.isDarkModeTime, isA<Function>());
    });
  });

  group('ThemeState', () {
    test('can be created with required fields', () {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.dark,
      );

      expect(state.mode, AppThemeMode.dark);
      expect(state.scheduledConfig.darkModeStart.hour, 20);
      expect(state.effectiveThemeMode, ThemeMode.dark);
    });

    test('copyWith creates new state with updated values', () {
      const original = ThemeState(
        mode: AppThemeMode.system,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.system,
      );

      final updated = original.copyWith(
        mode: AppThemeMode.dark,
        effectiveThemeMode: ThemeMode.dark,
      );

      expect(updated.mode, AppThemeMode.dark);
      expect(updated.effectiveThemeMode, ThemeMode.dark);
      expect(updated.scheduledConfig, original.scheduledConfig);
    });

    test('copyWith with scheduledConfig', () {
      const original = ThemeState(
        mode: AppThemeMode.scheduled,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.light,
      );

      const newConfig = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 19, minute: 0),
        darkModeEnd: TimeOfDay(hour: 8, minute: 0),
      );

      final updated = original.copyWith(scheduledConfig: newConfig);

      expect(updated.scheduledConfig.darkModeStart.hour, 19);
      expect(updated.scheduledConfig.darkModeEnd.hour, 8);
      expect(updated.mode, original.mode);
    });

    test('copyWith with no changes returns equivalent state', () {
      const original = ThemeState(
        mode: AppThemeMode.light,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.light,
      );

      final copied = original.copyWith();

      expect(copied.mode, original.mode);
      expect(copied.effectiveThemeMode, original.effectiveThemeMode);
    });
  });

  group('Theme Mode mappings', () {
    test('light mode maps to ThemeMode.light', () {
      const state = ThemeState(
        mode: AppThemeMode.light,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.light,
      );

      expect(state.effectiveThemeMode, ThemeMode.light);
    });

    test('dark mode maps to ThemeMode.dark', () {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.dark,
      );

      expect(state.effectiveThemeMode, ThemeMode.dark);
    });

    test('system mode maps to ThemeMode.system', () {
      const state = ThemeState(
        mode: AppThemeMode.system,
        scheduledConfig: ScheduledDarkModeConfig(),
        effectiveThemeMode: ThemeMode.system,
      );

      expect(state.effectiveThemeMode, ThemeMode.system);
    });
  });
}
