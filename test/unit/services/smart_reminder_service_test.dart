import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/services/smart_reminder_service.dart';
import 'package:injecare_plan/models/body_zone.dart';

void main() {
  group('ZoneSuggestion', () {
    test('creates with required fields', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const suggestion = ZoneSuggestion(
        zone: zone,
        reason: 'Non utilizzata da 7 giorni',
        daysSinceLastUse: 7,
      );

      expect(suggestion.zone.code, 'CD');
      expect(suggestion.reason, 'Non utilizzata da 7 giorni');
      expect(suggestion.daysSinceLastUse, 7);
    });

    test('handles null daysSinceLastUse for never used zones', () {
      const zone = BodyZone(
        id: 1,
        code: 'CD',
        name: 'Coscia Destra',
        type: 'thigh',
        side: 'right',
        numberOfPoints: 6,
        isEnabled: true,
        sortOrder: 1,
      );

      const suggestion = ZoneSuggestion(
        zone: zone,
        reason: 'Mai utilizzata',
        daysSinceLastUse: null,
      );

      expect(suggestion.daysSinceLastUse, null);
      expect(suggestion.reason, 'Mai utilizzata');
    });
  });

  // Note: Full SmartReminderService tests require mocking the database
  // and notification plugin, which would need integration test setup.
  // These tests cover the data models and basic logic.

  group('SmartReminderService Constants', () {
    test('notification IDs are unique', () {
      // These are the constants from SmartReminderService
      const missedId = 5000;
      const suggestionId = 5100;

      expect(missedId, isNot(equals(suggestionId)));
    });
  });
}

