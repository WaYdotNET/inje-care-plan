// test/unit/services/reminder_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/reminder_settings_provider.dart';
import 'package:injecare_plan/models/reminder_rule.dart';

void main() {
  test('round-trip JSON di ReminderSettings', () {
    const s = ReminderSettings(
      calendarEnabled: true,
      channel: ReminderChannel.calendar,
      completionBehavior: CompletionBehavior.remove,
      includeFeedback: false,
      rules: [ReminderRule(minutesBefore: 0, enabled: true)],
    );
    final back = ReminderSettings.fromJson(s.toJson());
    expect(back.calendarEnabled, isTrue);
    expect(back.channel, ReminderChannel.calendar);
    expect(back.completionBehavior, CompletionBehavior.remove);
    expect(back.includeFeedback, isFalse);
    expect(back.rules.single.minutesBefore, 0);
  });

  test('default: calendario off, canale notifiche app, regole di default', () {
    const s = ReminderSettings();
    expect(s.calendarEnabled, isFalse);
    expect(s.channel, ReminderChannel.appNotifications);
    expect(s.includeFeedback, isTrue);
    expect(s.rules, ReminderRule.defaults);
  });

  test('migrazione: un vecchio minutesBefore diventa una regola attiva', () {
    final rules = ReminderSettings.rulesFromLegacyMinutes(45);
    expect(rules.any((r) => r.minutesBefore == 45 && r.enabled), isTrue);
  });
}
