import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modalità tema estese
enum AppThemeMode {
  light,
  dark,
  system,
  scheduled, // Dark mode automatica per orario
}

/// Configurazione orario dark mode automatica
class ScheduledDarkModeConfig {
  final TimeOfDay darkModeStart;
  final TimeOfDay darkModeEnd;

  const ScheduledDarkModeConfig({
    this.darkModeStart = const TimeOfDay(hour: 20, minute: 0),
    this.darkModeEnd = const TimeOfDay(hour: 7, minute: 0),
  });

  /// Verifica se è ora di usare la dark mode
  bool isDarkModeTime() {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = darkModeStart.hour * 60 + darkModeStart.minute;
    final endMinutes = darkModeEnd.hour * 60 + darkModeEnd.minute;

    // Se start > end, il periodo attraversa la mezzanotte
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toJson() => {
    'startHour': darkModeStart.hour,
    'startMinute': darkModeStart.minute,
    'endHour': darkModeEnd.hour,
    'endMinute': darkModeEnd.minute,
  };

  factory ScheduledDarkModeConfig.fromJson(Map<String, dynamic> json) {
    return ScheduledDarkModeConfig(
      darkModeStart: TimeOfDay(
        hour: json['startHour'] as int? ?? 20,
        minute: json['startMinute'] as int? ?? 0,
      ),
      darkModeEnd: TimeOfDay(
        hour: json['endHour'] as int? ?? 7,
        minute: json['endMinute'] as int? ?? 0,
      ),
    );
  }
}

/// Stato del tema
class ThemeState {
  final AppThemeMode mode;
  final ScheduledDarkModeConfig scheduledConfig;
  final ThemeMode effectiveThemeMode;

  const ThemeState({
    required this.mode,
    required this.scheduledConfig,
    required this.effectiveThemeMode,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    ScheduledDarkModeConfig? scheduledConfig,
    ThemeMode? effectiveThemeMode,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      scheduledConfig: scheduledConfig ?? this.scheduledConfig,
      effectiveThemeMode: effectiveThemeMode ?? this.effectiveThemeMode,
    );
  }
}

/// Provider per theme mode con persistence e scheduling
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Provider per la configurazione estesa del tema
final themeStateProvider =
    NotifierProvider<ThemeStateNotifier, ThemeState>(ThemeStateNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value != null) {
      state = _stringToThemeMode(value);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  String _themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _stringToThemeMode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

class ThemeStateNotifier extends Notifier<ThemeState> {
  static const _appThemeModeKey = 'app_theme_mode';
  static const _scheduledConfigKey = 'scheduled_dark_mode_config';

  Timer? _scheduledTimer;

  @override
  ThemeState build() {
    ref.onDispose(() {
      _scheduledTimer?.cancel();
    });

    _loadFromPrefs();

    return const ThemeState(
      mode: AppThemeMode.system,
      scheduledConfig: ScheduledDarkModeConfig(),
      effectiveThemeMode: ThemeMode.system,
    );
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Carica modalità
    final modeValue = prefs.getString(_appThemeModeKey);
    final mode = modeValue != null ? _stringToAppThemeMode(modeValue) : AppThemeMode.system;

    // Carica config scheduled
    final configJson = prefs.getString(_scheduledConfigKey);
    ScheduledDarkModeConfig config = const ScheduledDarkModeConfig();
    if (configJson != null) {
      try {
        final map = _parseConfigJson(configJson);
        config = ScheduledDarkModeConfig.fromJson(map);
      } catch (_) {}
    }

    state = ThemeState(
      mode: mode,
      scheduledConfig: config,
      effectiveThemeMode: _calculateEffectiveMode(mode, config),
    );

    if (mode == AppThemeMode.scheduled) {
      _startScheduledTimer();
    }
  }

  Map<String, dynamic> _parseConfigJson(String json) {
    // Simple JSON parsing for config
    final cleaned = json.replaceAll('{', '').replaceAll('}', '');
    final pairs = cleaned.split(',');
    final map = <String, dynamic>{};
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '');
        final value = int.tryParse(parts[1].trim());
        if (value != null) map[key] = value;
      }
    }
    return map;
  }

  Future<void> setAppThemeMode(AppThemeMode mode) async {
    _scheduledTimer?.cancel();

    state = state.copyWith(
      mode: mode,
      effectiveThemeMode: _calculateEffectiveMode(mode, state.scheduledConfig),
    );

    if (mode == AppThemeMode.scheduled) {
      _startScheduledTimer();
    }

    // Sincronizza con il provider legacy
    ref.read(themeModeProvider.notifier).setThemeMode(state.effectiveThemeMode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeModeKey, _appThemeModeToString(mode));
  }

  Future<void> setScheduledConfig(ScheduledDarkModeConfig config) async {
    state = state.copyWith(
      scheduledConfig: config,
      effectiveThemeMode: _calculateEffectiveMode(state.mode, config),
    );

    // Sincronizza con il provider legacy
    ref.read(themeModeProvider.notifier).setThemeMode(state.effectiveThemeMode);

    final prefs = await SharedPreferences.getInstance();
    final configJson = '{"startHour":${config.darkModeStart.hour},"startMinute":${config.darkModeStart.minute},"endHour":${config.darkModeEnd.hour},"endMinute":${config.darkModeEnd.minute}}';
    await prefs.setString(_scheduledConfigKey, configJson);
  }

  void _startScheduledTimer() {
    _scheduledTimer?.cancel();

    // Controlla ogni minuto
    _scheduledTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateScheduledTheme();
    });
  }

  void _updateScheduledTheme() {
    if (state.mode != AppThemeMode.scheduled) return;

    final newEffective = _calculateEffectiveMode(state.mode, state.scheduledConfig);
    if (newEffective != state.effectiveThemeMode) {
      state = state.copyWith(effectiveThemeMode: newEffective);
      ref.read(themeModeProvider.notifier).setThemeMode(newEffective);
    }
  }

  ThemeMode _calculateEffectiveMode(AppThemeMode mode, ScheduledDarkModeConfig config) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.scheduled:
        return config.isDarkModeTime() ? ThemeMode.dark : ThemeMode.light;
    }
  }

  String _appThemeModeToString(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.system => 'system',
    AppThemeMode.scheduled => 'scheduled',
  };

  AppThemeMode _stringToAppThemeMode(String value) => switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    'scheduled' => AppThemeMode.scheduled,
    _ => AppThemeMode.system,
  };
}
