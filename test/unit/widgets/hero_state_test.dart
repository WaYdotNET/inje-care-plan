import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/widgets/next_injection_hero_card.dart';

void main() {
  final now = DateTime(2026, 6, 14, 21, 0); // oggi 21:00

  test('oggi, orario futuro → upcoming', () {
    expect(
      heroStateFor(
        nextScheduledAt: DateTime(2026, 6, 14, 22, 0),
        now: now,
        hasCompletedToday: false,
      ),
      HeroState.upcoming,
    );
  });
  test('oggi, orario passato → overdue', () {
    expect(
      heroStateFor(
        nextScheduledAt: DateTime(2026, 6, 14, 20, 0),
        now: now,
        hasCompletedToday: false,
      ),
      HeroState.overdue,
    );
  });
  test('giorno seguente → future', () {
    expect(
      heroStateFor(
        nextScheduledAt: DateTime(2026, 6, 16, 20, 0),
        now: now,
        hasCompletedToday: false,
      ),
      HeroState.future,
    );
  });
  test('nessuna prossima ma oggi completata → allDone', () {
    expect(
      heroStateFor(
        nextScheduledAt: null,
        now: now,
        hasCompletedToday: true,
      ),
      HeroState.allDone,
    );
  });
  test('nessuna prossima e niente oggi → none', () {
    expect(
      heroStateFor(
        nextScheduledAt: null,
        now: now,
        hasCompletedToday: false,
      ),
      HeroState.none,
    );
  });
}
