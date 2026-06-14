import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/utils/schedule_utils.dart';
import 'package:injecare_plan/models/therapy_plan.dart';

void main() {
  // Piano: Lun(1), Mer(3), Ven(5), ore 20:00
  final plan = TherapyPlan.defaults.copyWith(
    weekDays: const [1, 3, 5],
    preferredTime: '20:00',
  );

  test('pianifica i giorni del piano nel range, futuri e non già pianificati', () {
    // now = mar 2 giu 2026 10:00; range = lun 1 giu .. dom 7 giu
    final now = DateTime(2026, 6, 2, 10);
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 7, 23, 59);
    final days = ScheduleUtils.daysToPlan(
      plan: plan,
      start: start,
      end: end,
      now: now,
      alreadyPlanned: const {},
    );
    // Lun 1 è passato (20:00 dell'1 < now del 2)? 1 giu 20:00 < 2 giu 10:00 → escluso.
    // Mer 3 e Ven 5 → inclusi.
    expect(days, [DateTime(2026, 6, 3), DateTime(2026, 6, 5)]);
  });

  test('salta i giorni già pianificati', () {
    final now = DateTime(2026, 6, 2, 10);
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 7, 23, 59);
    final days = ScheduleUtils.daysToPlan(
      plan: plan,
      start: start,
      end: end,
      now: now,
      alreadyPlanned: {DateTime(2026, 6, 3)},
    );
    expect(days, [DateTime(2026, 6, 5)]);
  });

  test('finestra mobile da oggi trova giorni anche a fine mese', () {
    // Bug 4.10.2: ancorando al mese di calendario, a fine mese non creava
    // nulla. Con la finestra mobile (oggi .. oggi+30) deve sempre trovare i
    // prossimi giorni del piano, anche se oggi è l'ultimo giorno del mese.
    final now = DateTime(2026, 6, 30, 21); // martedì, ultimo del mese, sera
    final startOfToday = DateTime(now.year, now.month, now.day);
    final end30 =
        startOfToday.add(const Duration(days: 30, hours: 23, minutes: 59));
    final days = ScheduleUtils.daysToPlan(
      plan: plan,
      start: startOfToday,
      end: end30,
      now: now,
      alreadyPlanned: const {},
    );
    expect(days, isNotEmpty);
    expect(days.first, DateTime(2026, 7, 1)); // mer 1 lug
    expect(days.every((d) => [1, 3, 5].contains(d.weekday)), isTrue);
  });

  test('copre l\'intero mese', () {
    final now = DateTime(2026, 6, 2, 10);
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 30, 23, 59);
    final days = ScheduleUtils.daysToPlan(
      plan: plan,
      start: start,
      end: end,
      now: now,
      alreadyPlanned: const {},
    );
    // Mer/Ven da 3 giu in poi + i lun/mer/ven restanti del mese
    expect(days.length, greaterThan(8));
    expect(days.every((d) => [1, 3, 5].contains(d.weekday)), isTrue);
    expect(days.first, DateTime(2026, 6, 3));
  });
}
