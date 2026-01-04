import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/models/rotation_pattern.dart';

void main() {
  group('RotationPatternType', () {
    test('displayName returns correct names', () {
      expect(RotationPatternType.smart.displayName, 'Suggerimento AI');
      expect(RotationPatternType.sequential.displayName, 'Sequenza zone');
      expect(RotationPatternType.alternateSides.displayName, 'Alternanza Sx/Dx');
      expect(RotationPatternType.weeklyRotation.displayName, 'Rotazione settimanale');
      expect(RotationPatternType.custom.displayName, 'Personalizzato');
    });

    test('description returns non-empty strings', () {
      for (final type in RotationPatternType.values) {
        expect(type.description.isNotEmpty, true);
      }
    });

    test('icon returns emoji strings', () {
      expect(RotationPatternType.smart.icon, '🤖');
      expect(RotationPatternType.sequential.icon, '🔄');
      expect(RotationPatternType.alternateSides.icon, '↔️');
      expect(RotationPatternType.weeklyRotation.icon, '📅');
      expect(RotationPatternType.custom.icon, '✏️');
    });

    test('databaseValue returns correct values', () {
      expect(RotationPatternType.smart.databaseValue, 'smart');
      expect(RotationPatternType.sequential.databaseValue, 'sequential');
      expect(RotationPatternType.custom.databaseValue, 'custom');
    });

    test('fromDatabaseValue parses correctly', () {
      expect(
        RotationPatternTypeExtension.fromDatabaseValue('smart'),
        RotationPatternType.smart,
      );
      expect(
        RotationPatternTypeExtension.fromDatabaseValue('sequential'),
        RotationPatternType.sequential,
      );
      expect(
        RotationPatternTypeExtension.fromDatabaseValue(null),
        RotationPatternType.smart, // default
      );
      expect(
        RotationPatternTypeExtension.fromDatabaseValue('unknown'),
        RotationPatternType.smart, // fallback
      );
    });
  });

  group('RotationPattern', () {
    test('defaults returns smart pattern', () {
      final pattern = RotationPattern.defaults;
      expect(pattern.type, RotationPatternType.smart);
      expect(pattern.currentIndex, 0);
      expect(pattern.customSequence, isNull);
    });

    test('fromJson parses correctly', () {
      final json = {
        'type': 'sequential',
        'customSequence': '1,2,3',
        'currentIndex': 5,
        'lastZoneId': 2,
        'lastSide': 'left',
        'weekStartDate': '2025-01-01T00:00:00.000',
      };

      final pattern = RotationPattern.fromJson(json);
      expect(pattern.type, RotationPatternType.sequential);
      expect(pattern.customSequence, [1, 2, 3]);
      expect(pattern.currentIndex, 5);
      expect(pattern.lastZoneId, 2);
      expect(pattern.lastSide, 'left');
      expect(pattern.weekStartDate, DateTime(2025, 1, 1));
    });

    test('toJson converts correctly', () {
      final pattern = RotationPattern(
        type: RotationPatternType.custom,
        customSequence: [3, 2, 1],
        currentIndex: 2,
        lastZoneId: 5,
        lastSide: 'right',
        weekStartDate: DateTime(2025, 6, 15),
      );

      final json = pattern.toJson();
      expect(json['type'], 'custom');
      expect(json['customSequence'], '3,2,1');
      expect(json['currentIndex'], 2);
      expect(json['lastZoneId'], 5);
      expect(json['lastSide'], 'right');
      expect(json['weekStartDate'], contains('2025-06-15'));
    });

    test('copyWith creates modified copy', () {
      final original = RotationPattern.defaults;
      final modified = original.copyWith(
        type: RotationPatternType.sequential,
        currentIndex: 3,
      );

      expect(modified.type, RotationPatternType.sequential);
      expect(modified.currentIndex, 3);
      expect(modified.customSequence, isNull); // unchanged
    });

    test('toString returns readable string', () {
      final pattern = RotationPattern(
        type: RotationPatternType.smart,
        currentIndex: 5,
      );
      expect(pattern.toString(), 'RotationPattern(type: RotationPatternType.smart, index: 5)');
    });
  });

  group('DefaultZoneSequence', () {
    test('standard contains 8 zones', () {
      expect(DefaultZoneSequence.standard.length, 8);
    });

    test('weeklyGroups contains all expected groups', () {
      expect(DefaultZoneSequence.weeklyGroups.containsKey('cosce'), true);
      expect(DefaultZoneSequence.weeklyGroups.containsKey('braccia'), true);
      expect(DefaultZoneSequence.weeklyGroups.containsKey('addome'), true);
      expect(DefaultZoneSequence.weeklyGroups.containsKey('glutei'), true);
    });

    test('weeklyOrder has correct order', () {
      expect(DefaultZoneSequence.weeklyOrder, ['cosce', 'braccia', 'addome', 'glutei']);
    });
  });
}

