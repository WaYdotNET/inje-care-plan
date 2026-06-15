// test/unit/models/reminder_rule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/models/reminder_rule.dart';

void main() {
  group('ReminderRule', () {
    test('round-trip JSON', () {
      const rule = ReminderRule(minutesBefore: 30, enabled: true);
      final json = rule.toJson();
      final back = ReminderRule.fromJson(json);
      expect(back.minutesBefore, 30);
      expect(back.enabled, isTrue);
    });

    test('le regole di default coprono all\'orario, 30m, 24h', () {
      final defaults = ReminderRule.defaults;
      expect(defaults.map((r) => r.minutesBefore), containsAll(<int>[0, 30, 1440]));
      expect(defaults.every((r) => r.enabled), isTrue);
    });

    test('i preset sono ordinati e includono 48h', () {
      expect(ReminderRule.presetMinutes, contains(2880));
      final sorted = [...ReminderRule.presetMinutes]..sort();
      expect(ReminderRule.presetMinutes, sorted);
    });
  });

  group('ReminderChannel', () {
    test('serializzazione per nome stabile', () {
      for (final c in ReminderChannel.values) {
        expect(ReminderChannel.fromName(c.name), c);
      }
    });

    test('fallback su nome sconosciuto', () {
      expect(ReminderChannel.fromName('boh'), ReminderChannel.appNotifications);
    });
  });

  group('CompletionBehavior', () {
    test('serializzazione e fallback', () {
      expect(CompletionBehavior.fromName('remove'), CompletionBehavior.remove);
      expect(CompletionBehavior.fromName('x'), CompletionBehavior.markDone);
    });
  });
}
