import '../database/app_database.dart';
import 'package:drift/drift.dart';

/// Service per generare dati demo nell'applicazione
class DemoDataService {
  /// Genera ~12 iniezioni negli ultimi 30 giorni (3/settimana x 4 settimane)
  static Future<void> generateDemoData(AppDatabase db) async {
    final now = DateTime.now();
    final zones = await db.getAllZones();

    if (zones.isEmpty) return;

    // Giorni delle settimane: Lunedì, Mercoledì, Venerdì (1, 3, 5 in DateTime.weekday)
    // 3 iniezioni a settimana per 4 settimane = 12 iniezioni
    for (int week = 0; week < 4; week++) {
      // Calcola i giorni di quella settimana nel passato
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));

      // Trova Lunedì, Mercoledì, Venerdì di quella settimana
      final targetDays = [1, 3, 5]; // Mon, Wed, Fri

      for (int i = 0; i < targetDays.length; i++) {
        final targetWeekday = targetDays[i];
        final daysToAdd = (targetWeekday - weekStart.weekday + 7) % 7;
        final injectionDate = weekStart.add(Duration(days: daysToAdd));

        // Se la data è nel futuro, skip
        if (injectionDate.isAfter(now)) continue;

        // Seleziona zona e punto
        final zone = zones[(week + i) % zones.length];
        final pointNumber = ((week + i) % zone.numberOfPoints) + 1;

        // Imposta orario (20:00)
        final scheduledAt = DateTime(
          injectionDate.year,
          injectionDate.month,
          injectionDate.day,
          20,
          0,
        );

        // Inserisci iniezione completata
        await db.insertInjection(InjectionsCompanion.insert(
          zoneId: zone.id,
          pointNumber: pointNumber,
          pointCode: '${zone.code}-$pointNumber',
          pointLabel: '${zone.name} · $pointNumber',
          scheduledAt: scheduledAt,
          completedAt: Value(scheduledAt.add(const Duration(minutes: 5))),
          status: const Value('completed'),
          notes: const Value(''),
          sideEffects: const Value(''),
          calendarEventId: const Value(''),
        ));
      }
    }
  }

  /// Verifica se ci sono iniezioni nel database
  static Future<bool> hasDemoData(AppDatabase db) async {
    final injections = await db.getAllInjections();
    return injections.isNotEmpty;
  }

  /// Elimina tutti i dati demo (tutte le iniezioni)
  static Future<void> clearDemoData(AppDatabase db) async {
    await db.deleteAllData();
  }
}
