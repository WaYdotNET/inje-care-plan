import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../models/therapy_plan.dart' as models;
import '../../models/injection_record.dart';
import '../../features/injection/injection_repository.dart';

/// Servizio per gestire le iniezioni mancate
/// All'avvio dell'app, controlla gli eventi passati e li marca come skipped
class MissedInjectionService {
  final AppDatabase _db;
  final InjectionRepository _repository;

  MissedInjectionService({
    required AppDatabase database,
    required InjectionRepository repository,
  })  : _db = database,
        _repository = repository;

  /// Controlla e marca come skipped le iniezioni mancate
  /// Chiamare all'avvio dell'app
  Future<int> checkAndMarkMissedInjections() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Inizio settimana corrente (lunedì)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int markedCount = 0;

    // 1. Marca eventi pending passati come skipped
    final allInjections = await _db.getInjectionsByDateRange(weekStartDate, todayStart);
    final pendingPastInjections = allInjections.where((inj) =>
        inj.status == 'pending' &&
        inj.scheduledAt.isBefore(todayStart));

    for (final injection in pendingPastInjections) {
      await _db.updateInjection(InjectionsCompanion(
        id: Value(injection.id),
        status: const Value('skipped'),
        updatedAt: Value(now),
      ));
      markedCount++;
    }

    // 2. Ottieni il piano terapeutico
    final dbPlan = await _db.getCurrentTherapyPlan();
    final therapyPlan = dbPlan != null
        ? models.TherapyPlan(
            injectionsPerWeek: dbPlan.injectionsPerWeek,
            weekDays: dbPlan.weekDays.split(',').map((s) => int.parse(s.trim())).toList(),
            preferredTime: dbPlan.preferredTime,
            startDate: dbPlan.startDate,
          )
        : models.TherapyPlan.defaults;

    // 3. Controlla ogni giorno della settimana passata per giorni del piano senza eventi
    for (var i = 0; i < now.weekday - 1; i++) {
      final day = weekStartDate.add(Duration(days: i));
      final dayOfWeek = day.weekday;

      // Se è un giorno del piano terapeutico
      if (therapyPlan.weekDays.contains(dayOfWeek)) {
        // Controlla se esiste già un evento per questo giorno
        final dayEnd = day.add(const Duration(hours: 23, minutes: 59));
        final existingInjections = await _db.getInjectionsByDateRange(day, dayEnd);

        if (existingInjections.isEmpty) {
          // Crea un evento skipped per questo giorno
          final suggestedPoint = await _repository.getSuggestedNextPoint();
          if (suggestedPoint != null) {
            final zone = await _db.getZoneById(suggestedPoint.zoneId);
            if (zone != null) {
              await _repository.createInjection(InjectionRecord(
                zoneId: suggestedPoint.zoneId,
                pointNumber: suggestedPoint.pointNumber,
                scheduledAt: day.add(Duration(
                  hours: int.tryParse(therapyPlan.preferredTime.split(':')[0]) ?? 20,
                  minutes: int.tryParse(therapyPlan.preferredTime.split(':')[1]) ?? 0,
                )),
                status: InjectionStatus.skipped,
                notes: 'Auto-marcata come mancata',
                sideEffects: [],
                createdAt: now,
                updatedAt: now,
              ));
              markedCount++;
            }
          }
        }
      }
    }

    return markedCount;
  }
}

/// Provider per il servizio missed injections
final missedInjectionServiceProvider = Provider<MissedInjectionService>((ref) {
  final database = ref.watch(databaseProvider);
  final repository = InjectionRepository(database: database);
  return MissedInjectionService(
    database: database,
    repository: repository,
  );
});

/// Provider che esegue il check all'avvio e restituisce il numero di eventi marcati
final checkMissedInjectionsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(missedInjectionServiceProvider);
  return service.checkAndMarkMissedInjections();
});
