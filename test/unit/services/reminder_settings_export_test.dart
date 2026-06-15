import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/reminder_settings_provider.dart';
import 'package:injecare_plan/models/reminder_rule.dart';

void main() {
  test('export/import round-trip delle impostazioni promemoria', () {
    const s = ReminderSettings(
      calendarEnabled: true,
      channel: ReminderChannel.both,
      completionBehavior: CompletionBehavior.remove,
      includeFeedback: false,
      rules: [
        ReminderRule(minutesBefore: 0, enabled: true),
        ReminderRule(minutesBefore: 120, enabled: false),
      ],
    );
    final json = s.toJson();
    final back = ReminderSettings.fromJson(json);
    expect(back.channel, ReminderChannel.both);
    expect(back.rules.length, 2);
    expect(back.rules[1].enabled, isFalse);
  });
}
