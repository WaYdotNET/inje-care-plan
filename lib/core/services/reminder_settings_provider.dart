// lib/core/services/reminder_settings_provider.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/reminder_rule.dart';

class ReminderSettings {
  const ReminderSettings({
    this.calendarEnabled = false,
    this.channel = ReminderChannel.appNotifications,
    this.completionBehavior = CompletionBehavior.markDone,
    this.includeFeedback = true,
    this.rules = ReminderRule.defaults,
  });

  final bool calendarEnabled;
  final ReminderChannel channel;
  final CompletionBehavior completionBehavior;
  final bool includeFeedback;
  final List<ReminderRule> rules;

  Iterable<ReminderRule> get activeRules => rules.where((r) => r.enabled);

  /// True quando le notifiche app pre-iniezione vanno sospese (canale=solo calendario).
  bool get suppressAppPreReminders =>
      calendarEnabled && channel == ReminderChannel.calendar;

  ReminderSettings copyWith({
    bool? calendarEnabled,
    ReminderChannel? channel,
    CompletionBehavior? completionBehavior,
    bool? includeFeedback,
    List<ReminderRule>? rules,
  }) =>
      ReminderSettings(
        calendarEnabled: calendarEnabled ?? this.calendarEnabled,
        channel: channel ?? this.channel,
        completionBehavior: completionBehavior ?? this.completionBehavior,
        includeFeedback: includeFeedback ?? this.includeFeedback,
        rules: rules ?? this.rules,
      );

  Map<String, dynamic> toJson() => {
        'calendarEnabled': calendarEnabled,
        'channel': channel.name,
        'completionBehavior': completionBehavior.name,
        'includeFeedback': includeFeedback,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      ReminderSettings(
        calendarEnabled: json['calendarEnabled'] as bool? ?? false,
        channel: ReminderChannel.fromName(json['channel'] as String? ?? ''),
        completionBehavior: CompletionBehavior.fromName(
          json['completionBehavior'] as String? ?? '',
        ),
        includeFeedback: json['includeFeedback'] as bool? ?? true,
        rules: (json['rules'] as List<dynamic>?)
                ?.map((e) => ReminderRule.fromJson(e as Map<String, dynamic>))
                .toList() ??
            ReminderRule.defaults,
      );

  /// Migrazione del vecchio singolo `minutesBefore` (notifiche) nelle regole.
  static List<ReminderRule> rulesFromLegacyMinutes(int minutes) {
    final base = [...ReminderRule.defaults];
    if (base.any((r) => r.minutesBefore == minutes)) return base;
    return [...base, ReminderRule(minutesBefore: minutes, enabled: true)]
      ..sort((a, b) => a.minutesBefore.compareTo(b.minutesBefore));
  }
}

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _key = 'reminder_settings_v1';
  static const _legacyMinutesKey = 'notification_minutes_before';
  static const _migratedKey = 'reminder_settings_migrated';

  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = ReminderSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return;
    }
    if (prefs.getBool(_migratedKey) != true) {
      final legacy = prefs.getInt(_legacyMinutesKey);
      final rules = legacy != null
          ? ReminderSettings.rulesFromLegacyMinutes(legacy)
          : ReminderRule.defaults;
      state = ReminderSettings(rules: rules);
      await prefs.setBool(_migratedKey, true);
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> update(ReminderSettings next) async {
    state = next;
    await _persist();
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);
