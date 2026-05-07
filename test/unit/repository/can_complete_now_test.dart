import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/injection/injection_repository.dart';

void main() {
  group('canCompleteNow (Bug E — block completing future-day injections)', () {
    final now = DateTime(2026, 5, 7, 14, 30);

    test('allows completing injection scheduled earlier today', () {
      final scheduled = DateTime(2026, 5, 7, 8, 0);
      expect(canCompleteNow(scheduled, now: now), isTrue);
    });

    test('allows completing injection scheduled later today', () {
      final scheduled = DateTime(2026, 5, 7, 22, 0);
      expect(canCompleteNow(scheduled, now: now), isTrue);
    });

    test('allows completing injection scheduled in the past', () {
      final scheduled = DateTime(2026, 5, 1, 10, 0);
      expect(canCompleteNow(scheduled, now: now), isTrue);
    });

    test('blocks completing injection scheduled tomorrow', () {
      final scheduled = DateTime(2026, 5, 8, 8, 0);
      expect(canCompleteNow(scheduled, now: now), isFalse);
    });

    test('blocks completing injection scheduled next week', () {
      final scheduled = DateTime(2026, 5, 14, 14, 0);
      expect(canCompleteNow(scheduled, now: now), isFalse);
    });

    test('handles midnight boundary (exactly tomorrow at 00:00 is blocked)',
        () {
      final scheduled = DateTime(2026, 5, 8, 0, 0);
      expect(canCompleteNow(scheduled, now: now), isFalse);
    });
  });
}
