import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// Notification settings state
class NotificationSettings {
  final bool enabled;
  final int minutesBefore;
  final bool missedDoseReminder;
  final bool permissionsGranted;

  const NotificationSettings({
    this.enabled = true,
    this.minutesBefore = 30,
    this.missedDoseReminder = true,
    this.permissionsGranted = false,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    bool? missedDoseReminder,
    bool? permissionsGranted,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      missedDoseReminder: missedDoseReminder ?? this.missedDoseReminder,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    );
  }
}

/// Notification settings notifier
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _keyEnabled = 'notification_enabled';
  static const _keyMinutesBefore = 'notification_minutes_before';
  static const _keyMissedDose = 'notification_missed_dose';
  static const _keyPermissionsGranted = 'notification_permissions_granted';

  @override
  NotificationSettings build() {
    _loadSettings();
    return const NotificationSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_keyEnabled) ?? true,
      minutesBefore: prefs.getInt(_keyMinutesBefore) ?? 30,
      missedDoseReminder: prefs.getBool(_keyMissedDose) ?? true,
      permissionsGranted: prefs.getBool(_keyPermissionsGranted) ?? false,
    );
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    state = state.copyWith(enabled: value);
  }

  Future<void> setMinutesBefore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinutesBefore, value);
    state = state.copyWith(minutesBefore: value);
  }

  Future<void> setMissedDoseReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMissedDose, value);
    state = state.copyWith(missedDoseReminder: value);
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final granted = await NotificationService.instance.requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionsGranted, granted);
    state = state.copyWith(permissionsGranted: granted);

    return granted;
  }

  /// Check if we should request permissions (first time or not granted)
  Future<bool> shouldRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyPermissionsGranted) ?? false);
  }
}

/// Provider for notification settings
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
