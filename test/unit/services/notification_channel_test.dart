import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/reminder_settings_provider.dart';
import 'package:injecare_plan/models/reminder_rule.dart';

void main() {
  group('suppressAppPreReminders', () {
    test('vero solo con calendario attivo e canale=calendar', () {
      expect(
        const ReminderSettings(calendarEnabled: true, channel: ReminderChannel.calendar)
            .suppressAppPreReminders,
        isTrue,
      );
      expect(
        const ReminderSettings(calendarEnabled: true, channel: ReminderChannel.both)
            .suppressAppPreReminders,
        isFalse,
      );
      expect(
        const ReminderSettings(calendarEnabled: true, channel: ReminderChannel.appNotifications)
            .suppressAppPreReminders,
        isFalse,
      );
      expect(
        const ReminderSettings(calendarEnabled: false, channel: ReminderChannel.calendar)
            .suppressAppPreReminders,
        isFalse,
      );
    });
  });
}
