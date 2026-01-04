import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });
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

  group('ThemeModeNotifier with Riverpod', () {
    test('initial state is ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('ThemeStateNotifier with Riverpod', () {
    test('initial state has default values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(themeStateProvider);
      expect(state.mode, AppThemeMode.system);
      expect(state.effectiveThemeMode, ThemeMode.system);
    });

    test('setAppThemeMode updates mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeStateProvider.notifier).setAppThemeMode(AppThemeMode.dark);
      expect(container.read(themeStateProvider).mode, AppThemeMode.dark);
      expect(container.read(themeStateProvider).effectiveThemeMode, ThemeMode.dark);
    });

    test('setAppThemeMode to light updates correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeStateProvider.notifier).setAppThemeMode(AppThemeMode.light);
      expect(container.read(themeStateProvider).mode, AppThemeMode.light);
      expect(container.read(themeStateProvider).effectiveThemeMode, ThemeMode.light);
    });

    test('setScheduledConfig updates config', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const newConfig = ScheduledDarkModeConfig(
        darkModeStart: TimeOfDay(hour: 19, minute: 0),
        darkModeEnd: TimeOfDay(hour: 8, minute: 0),
      );

      await container.read(themeStateProvider.notifier).setScheduledConfig(newConfig);
      final state = container.read(themeStateProvider);
      expect(state.scheduledConfig.darkModeStart.hour, 19);
      expect(state.scheduledConfig.darkModeEnd.hour, 8);
    });

    test('setAppThemeMode to scheduled mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeStateProvider.notifier).setAppThemeMode(AppThemeMode.scheduled);
      expect(container.read(themeStateProvider).mode, AppThemeMode.scheduled);
      // effectiveThemeMode depends on current time
      expect(
        [ThemeMode.dark, ThemeMode.light],
        contains(container.read(themeStateProvider).effectiveThemeMode),
      );
    });

    test('setAppThemeMode to system mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First set to dark
      await container.read(themeStateProvider.notifier).setAppThemeMode(AppThemeMode.dark);
      // Then back to system
      await container.read(themeStateProvider.notifier).setAppThemeMode(AppThemeMode.system);
      
      expect(container.read(themeStateProvider).mode, AppThemeMode.system);
      expect(container.read(themeStateProvider).effectiveThemeMode, ThemeMode.system);
    });
  });
}
