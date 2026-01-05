import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'notification_settings_provider.dart';

/// Servizio per gestire le iniezioni mancate
/// All'avvio dell'app, controlla gli eventi passati e li marca come missed
class MissedInjectionService {
  final AppDatabase _db;

  MissedInjectionService({
    required AppDatabase database,
  }) : _db = database;

  /// Controlla e marca come skipped le iniezioni mancate
  /// Chiamare all'avvio dell'app
  Future<int> checkAndMarkMissedInjections({
    required Duration grace,
  }) async {
    final now = DateTime.now();
    final threshold = now.subtract(grace);

    int markedCount = 0;

    // Marca eventi scheduled scaduti come missed (se oltre la tolleranza)
    // Nota: usiamo un range ampio per coprire anche appuntamenti vecchi.
    final allInjections = await _db.getInjectionsByDateRange(
      threshold.subtract(const Duration(days: 90)),
      threshold,
    );
    final overdueScheduled = allInjections.where(
      (inj) => inj.status == 'scheduled' && inj.scheduledAt.isBefore(threshold),
    );

    for (final injection in overdueScheduled) {
      await _db.updateInjection(InjectionsCompanion(
        id: Value(injection.id),
        status: const Value('missed'),
        updatedAt: Value(now),
      ));
      markedCount++;
    }

    return markedCount;
  }
}

/// Provider per il servizio missed injections
final missedInjectionServiceProvider = Provider<MissedInjectionService>((ref) {
  final database = ref.watch(databaseProvider);
  return MissedInjectionService(
    database: database,
  );
});

/// Provider che esegue il check all'avvio e restituisce il numero di eventi marcati
final checkMissedInjectionsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(missedInjectionServiceProvider);
  final settings = ref.watch(notificationSettingsProvider);
  return service.checkAndMarkMissedInjections(
    grace: Duration(minutes: settings.overdueGraceMinutes),
  );
});
