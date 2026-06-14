import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/rotation_pattern.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

/// Provider per le zone del corpo
final bodyZonesProvider = FutureProvider<List<BodyZone>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllZones();
});

/// Risultato del suggerimento zona
class ZoneSuggestion {
  const ZoneSuggestion({
    required this.zoneId,
    required this.zoneName,
    required this.reason,
    this.confidence = 1.0,
  });

  final int zoneId;
  final String zoneName;
  final String reason;
  final double confidence;
}

/// Engine per la gestione dei pattern di rotazione
class RotationPatternEngine {
  const RotationPatternEngine({
    required this.db,
    required this.zones,
    required this.currentPattern,
  });

  final AppDatabase db;
  final List<BodyZone> zones;
  final RotationPattern currentPattern;

  /// Drift `BodyZone` non ha `displayName`: usa `customName` se presente,
  /// altrimenti il nome di default. Vedi CLAUDE.md ("Two BodyZone types").
  static String _displayName(BodyZone zone) =>
      zone.customName?.isNotEmpty == true ? zone.customName! : zone.name;

  /// Sceglie la zona partendo dalla posizione [index] della sequenza
  /// DICHIARATA (lo stesso spazio di indici scritto da advancePattern):
  /// cammina in avanti finché trova una zona presente e abilitata, saltando
  /// quelle disabilitate/assenti senza disallineare l'indice memorizzato.
  /// Niente fallback silenzioso su zone fuori sequenza.
  ZoneSuggestion? _pickFromSequence(
    List<int> sequence,
    int index,
    String reasonPrefix,
  ) {
    if (sequence.isEmpty) return null;
    final byId = {for (final z in zones) z.id: z};

    final start = index % sequence.length;
    for (var i = 0; i < sequence.length; i++) {
      final candidateId = sequence[(start + i) % sequence.length];
      final zone = byId[candidateId];
      if (zone != null && zone.isEnabled) {
        return ZoneSuggestion(
          zoneId: zone.id,
          zoneName: _displayName(zone),
          reason: reasonPrefix,
        );
      }
    }

    // Nessuna zona della sequenza è disponibile: ripiego su una qualsiasi abilitata.
    final enabled = zones.where((z) => z.isEnabled).toList();
    if (enabled.isEmpty) return null;
    final zone = enabled[index % enabled.length];
    return ZoneSuggestion(
      zoneId: zone.id,
      zoneName: _displayName(zone),
      reason: '$reasonPrefix (zona di ripiego)',
    );
  }

  /// Ottiene il prossimo suggerimento in base al pattern configurato
  Future<ZoneSuggestion?> getNextSuggestion() async {
    if (zones.isEmpty) return null;

    return switch (currentPattern.type) {
      RotationPatternType.smart => _getSmartSuggestion(),
      RotationPatternType.sequential => _getSequentialSuggestion(),
      RotationPatternType.alternateSides => _getAlternateSidesSuggestion(),
      RotationPatternType.weeklyRotation => _getWeeklyRotationSuggestion(),
      RotationPatternType.clockwise => _getClockwiseSuggestion(),
      RotationPatternType.counterClockwise => _getCounterClockwiseSuggestion(),
      RotationPatternType.custom => _getCustomSuggestion(),
    };
  }

  /// Suggerimento "smart": tra le zone abilitate sceglie una zona mai usata,
  /// altrimenti quella il cui uso più recente è il più vecchio (meno usata
  /// di recente). Usa lo storico completo delle iniezioni completate.
  Future<ZoneSuggestion?> _getSmartSuggestion() async {
    final enabled = zones.where((z) => z.isEnabled).toList();
    if (enabled.isEmpty) return null;

    BodyZone? bestZone;
    DateTime? bestZoneLastUse; // uso più recente della zona scelta finora

    for (final zone in enabled) {
      final usage = await db.getPointUsageHistory(zone.id);
      final dates = usage.values.whereType<DateTime>().toList();

      if (dates.isEmpty) {
        // Zona mai usata: scelta ottimale, fermati subito.
        bestZone = zone;
        bestZoneLastUse = null;
        break;
      }

      dates.sort();
      final zoneLastUse = dates.last; // uso più recente della zona
      if (bestZone == null ||
          (bestZoneLastUse != null && zoneLastUse.isBefore(bestZoneLastUse))) {
        bestZone = zone;
        bestZoneLastUse = zoneLastUse;
      }
    }

    bestZone ??= enabled.first;

    return ZoneSuggestion(
      zoneId: bestZone.id,
      zoneName: _displayName(bestZone),
      reason: bestZoneLastUse == null
          ? 'Zona mai usata di recente'
          : 'Zona meno usata di recente',
    );
  }

  /// Suggerimento sequenziale
  Future<ZoneSuggestion?> _getSequentialSuggestion() async {
    return _pickFromSequence(
      DefaultZoneSequence.standard,
      currentPattern.currentIndex,
      'Prossimo nella sequenza',
    );
  }

  /// Suggerimento con alternanza lati
  Future<ZoneSuggestion?> _getAlternateSidesSuggestion() async {
    final lastSide = currentPattern.lastSide;
    final nextSide = (lastSide == 'left') ? 'right' : 'left';

    final sideZones = zones.where((z) => z.side == nextSide).toList();

    if (sideZones.isEmpty) {
      final zone = zones.first;
      return ZoneSuggestion(
        zoneId: zone.id,
        zoneName: _displayName(zone),
        reason: 'Nessuna zona per lato $nextSide',
      );
    }

    final lastZoneId = currentPattern.lastZoneId;
    BodyZone selectedZone;

    if (lastZoneId != null) {
      final otherZones = sideZones.where((z) => z.id != lastZoneId).toList();
      selectedZone = otherZones.isNotEmpty ? otherZones.first : sideZones.first;
    } else {
      selectedZone = sideZones.first;
    }

    final sideLabel = nextSide == 'left' ? 'sinistra' : 'destra';
    return ZoneSuggestion(
      zoneId: selectedZone.id,
      zoneName: _displayName(selectedZone),
      reason: 'Alternanza lato $sideLabel',
    );
  }

  /// Suggerimento con rotazione settimanale
  Future<ZoneSuggestion?> _getWeeklyRotationSuggestion() async {
    final now = DateTime.now();
    final weekStart = currentPattern.weekStartDate ?? now;

    final weeksPassed = now.difference(weekStart).inDays ~/ 7;

    final groupOrder = DefaultZoneSequence.weeklyOrder;
    final currentGroupIndex = weeksPassed % groupOrder.length;
    final currentGroup = groupOrder[currentGroupIndex];
    final groupZoneIds = DefaultZoneSequence.weeklyGroups[currentGroup] ?? [];

    final groupZones = zones.where((z) => groupZoneIds.contains(z.id)).toList();

    if (groupZones.isEmpty) {
      final zone = zones.first;
      return ZoneSuggestion(
        zoneId: zone.id,
        zoneName: _displayName(zone),
        reason: 'Nessuna zona per gruppo $currentGroup',
      );
    }

    final lastZoneId = currentPattern.lastZoneId;
    BodyZone selectedZone;

    if (lastZoneId != null && groupZones.length > 1) {
      final currentIdx = groupZones.indexWhere((z) => z.id == lastZoneId);
      final nextIdx = (currentIdx + 1) % groupZones.length;
      selectedZone = groupZones[nextIdx];
    } else {
      selectedZone = groupZones.first;
    }

    return ZoneSuggestion(
      zoneId: selectedZone.id,
      zoneName: _displayName(selectedZone),
      reason: 'Settimana ${_capitalizeFirst(currentGroup)} (settimana ${weeksPassed + 1})',
    );
  }

  /// Suggerimento con rotazione oraria del corpo
  Future<ZoneSuggestion?> _getClockwiseSuggestion() async {
    return _pickFromSequence(
      DefaultZoneSequence.clockwise,
      currentPattern.currentIndex,
      'Rotazione oraria',
    );
  }

  /// Suggerimento con rotazione antioraria del corpo (inverso di oraria)
  Future<ZoneSuggestion?> _getCounterClockwiseSuggestion() async {
    return _pickFromSequence(
      DefaultZoneSequence.counterClockwise,
      currentPattern.currentIndex,
      'Rotazione antioraria',
    );
  }

  /// Suggerimento con sequenza personalizzata
  Future<ZoneSuggestion?> _getCustomSuggestion() async {
    final customSequence = currentPattern.customSequence;
    if (customSequence == null || customSequence.isEmpty) {
      return _getSequentialSuggestion();
    }
    return _pickFromSequence(
      customSequence,
      currentPattern.currentIndex,
      'Sequenza personalizzata',
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Provider per il pattern di rotazione corrente (dal piano attivo)
final currentRotationPatternProvider = FutureProvider<RotationPattern>((ref) async {
  final db = ref.watch(databaseProvider);

  // Ottieni il piano terapeutico attivo
  final activePlan = await db.getCurrentTherapyPlan();
  if (activePlan == null) {
    return RotationPattern.defaults;
  }

  return RotationPattern(
    type: RotationPatternTypeExtension.fromDatabaseValue(
      activePlan.rotationPatternType,
    ),
    customSequence: activePlan.customPatternSequence.isNotEmpty
        ? activePlan.customPatternSequence
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s.trim()))
            .toList()
        : null,
    currentIndex: activePlan.patternCurrentIndex,
    lastZoneId: activePlan.patternLastZoneId,
    lastSide: activePlan.patternLastSide.isNotEmpty
        ? activePlan.patternLastSide
        : null,
    weekStartDate: activePlan.patternWeekStartDate,
  );
});

/// Provider per tutti i piani terapeutici disponibili
final allTherapyPlansProvider = FutureProvider<List<TherapyPlan>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllTherapyPlans();
});

/// Provider per il rotation engine
final rotationPatternEngineProvider = FutureProvider<RotationPatternEngine>((ref) async {
  final db = ref.watch(databaseProvider);
  final zones = await ref.watch(bodyZonesProvider.future);
  final pattern = await ref.watch(currentRotationPatternProvider.future);

  return RotationPatternEngine(
    db: db,
    zones: zones,
    currentPattern: pattern,
  );
});

/// Provider per il suggerimento zona basato sul pattern
final patternBasedZoneSuggestionProvider = FutureProvider<ZoneSuggestion?>((ref) async {
  final engine = await ref.watch(rotationPatternEngineProvider.future);
  return engine.getNextSuggestion();
});

/// Servizio per aggiornare il pattern
class RotationPatternService {
  RotationPatternService(this.db);

  final AppDatabase db;

  /// Attiva un piano specifico tramite ID
  Future<void> activatePlan(int planId) async {
    await db.activateTherapyPlan(planId);
  }

  /// Attiva il piano con un certo tipo di pattern
  Future<void> activatePlanByType(RotationPatternType type) async {
    final allPlans = await db.getAllTherapyPlans();
    final planToActivate = allPlans.firstWhere(
      (p) => RotationPatternTypeExtension.fromDatabaseValue(p.rotationPatternType) == type,
      orElse: () => allPlans.first,
    );
    await db.activateTherapyPlan(planToActivate.id);
  }

  /// Imposta sequenza personalizzata sul piano custom
  Future<void> setCustomSequence(List<int> zoneIds) async {
    final allPlans = await db.getAllTherapyPlans();
    final customPlan = allPlans.firstWhere(
      (p) => p.rotationPatternType == 'custom',
      orElse: () => allPlans.last,
    );

    await (db.update(db.therapyPlans)..where((t) => t.id.equals(customPlan.id)))
        .write(TherapyPlansCompanion(
          customPatternSequence: Value(zoneIds.join(',')),
          patternCurrentIndex: const Value(0),
          updatedAt: Value(DateTime.now()),
        ));

    // Attiva il piano custom
    await db.activateTherapyPlan(customPlan.id);
  }

  /// Avanza al prossimo elemento nella sequenza
  Future<void> advancePattern(int usedZoneId, String side) async {
    final currentPlan = await db.getCurrentTherapyPlan();
    if (currentPlan == null) return;

    final patternType = RotationPatternTypeExtension.fromDatabaseValue(
      currentPlan.rotationPatternType,
    );

    // Per pattern che non usano un indice lineare, manteniamo l'indice stabile
    // e aggiorniamo solo lastZone/lastSide.
    if (patternType == RotationPatternType.weeklyRotation ||
        patternType == RotationPatternType.alternateSides) {
      await (db.update(db.therapyPlans)..where((t) => t.id.equals(currentPlan.id)))
          .write(TherapyPlansCompanion(
            patternLastZoneId: Value(usedZoneId),
            patternLastSide: Value(side),
            updatedAt: Value(DateTime.now()),
          ));
      return;
    }

    // Sequenza lineare effettiva per il pattern corrente.
    final List<int> sequence = switch (patternType) {
      RotationPatternType.clockwise => DefaultZoneSequence.clockwise,
      RotationPatternType.counterClockwise =>
        DefaultZoneSequence.counterClockwise,
      RotationPatternType.custom
          when currentPlan.customPatternSequence.isNotEmpty =>
        currentPlan.customPatternSequence
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => int.parse(s.trim()))
            .toList(),
      _ => DefaultZoneSequence.standard,
    };

    final effectiveSequence =
        sequence.isEmpty ? DefaultZoneSequence.standard : sequence;

    // Self-healing: l'indice segue la posizione della zona EFFETTIVAMENTE
    // usata; se non è in sequenza, avanza linearmente da quello corrente.
    final usedPos = effectiveSequence.indexOf(usedZoneId);
    final base = usedPos >= 0
        ? usedPos + 1
        : currentPlan.patternCurrentIndex + 1;
    final newIndex = base % effectiveSequence.length;

    await (db.update(db.therapyPlans)..where((t) => t.id.equals(currentPlan.id)))
        .write(TherapyPlansCompanion(
          patternCurrentIndex: Value(newIndex),
          patternLastZoneId: Value(usedZoneId),
          patternLastSide: Value(side),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Inizializza rotazione settimanale e attiva il piano
  Future<void> initWeeklyRotation() async {
    final allPlans = await db.getAllTherapyPlans();
    final weeklyPlan = allPlans.firstWhere(
      (p) => p.rotationPatternType == 'weeklyRotation',
      orElse: () => allPlans.first,
    );

    await (db.update(db.therapyPlans)..where((t) => t.id.equals(weeklyPlan.id)))
        .write(TherapyPlansCompanion(
          patternWeekStartDate: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));

    await db.activateTherapyPlan(weeklyPlan.id);
  }

  /// Metodo di compatibilità (deprecato)
  @Deprecated('Use activatePlanByType instead')
  Future<void> setPatternType(RotationPatternType type) async {
    await activatePlanByType(type);
  }
}

/// Provider per il servizio pattern
final rotationPatternServiceProvider = Provider<RotationPatternService>((ref) {
  final db = ref.watch(databaseProvider);
  return RotationPatternService(db);
});
