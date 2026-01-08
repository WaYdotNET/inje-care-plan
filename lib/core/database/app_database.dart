import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BodyZones,
    TherapyPlans,
    Injections,
    BlacklistedPoints,
    AppSettings,
    UserProfiles,
    PointConfigs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor per testing con database in-memory
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Inserisci le zone e i piani predefiniti
      await _seedDefaultZones();
      await _seedDefaultTherapyPlans();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Aggiungi nuove colonne alla tabella BodyZones
        await m.addColumn(bodyZones, bodyZones.customName);
        await m.addColumn(bodyZones, bodyZones.icon);
        await m.addColumn(bodyZones, bodyZones.type);
        await m.addColumn(bodyZones, bodyZones.side);
        await m.addColumn(bodyZones, bodyZones.sortOrder);

        // Aggiorna le zone esistenti con i valori corretti
        await customStatement('''
              UPDATE body_zones SET
                type = CASE code
                  WHEN 'CD' THEN 'thigh' WHEN 'CS' THEN 'thigh'
                  WHEN 'BD' THEN 'arm' WHEN 'BS' THEN 'arm'
                  WHEN 'AD' THEN 'abdomen' WHEN 'AS' THEN 'abdomen'
                  WHEN 'GD' THEN 'buttock' WHEN 'GS' THEN 'buttock'
                  ELSE 'custom'
                END,
                side = CASE
                  WHEN code LIKE '%D' THEN 'right'
                  WHEN code LIKE '%S' THEN 'left'
                  ELSE 'none'
                END,
                sort_order = id
            ''');
      }
      if (from < 3) {
        // Crea tabella PointConfigs per configurazione punti
        await m.createTable(pointConfigs);
      }
      if (from < 4) {
        // Aggiungi nuove colonne a TherapyPlans
        await m.addColumn(therapyPlans, therapyPlans.name);
        await m.addColumn(therapyPlans, therapyPlans.isActive);
        // Migra i piani esistenti e crea quelli mancanti
        await _migrateTherapyPlansToV4();
      }
      if (from < 5) {
        // Correggi le coordinate asimmetriche dei punti (Issue #3)
        await _fixIncorrectPointCoordinates();
      }
    },
  );

  /// Inserisce le 8 zone predefinite
  Future<void> _seedDefaultZones() async {
    final zones = [
      BodyZonesCompanion.insert(
        code: 'CD',
        name: 'Coscia Dx',
        type: const Value('thigh'),
        side: const Value('right'),
        numberOfPoints: const Value(6),
        sortOrder: const Value(1),
      ),
      BodyZonesCompanion.insert(
        code: 'CS',
        name: 'Coscia Sx',
        type: const Value('thigh'),
        side: const Value('left'),
        numberOfPoints: const Value(6),
        sortOrder: const Value(2),
      ),
      BodyZonesCompanion.insert(
        code: 'BD',
        name: 'Braccio Dx',
        type: const Value('arm'),
        side: const Value('right'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(3),
      ),
      BodyZonesCompanion.insert(
        code: 'BS',
        name: 'Braccio Sx',
        type: const Value('arm'),
        side: const Value('left'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'AD',
        name: 'Addome Dx',
        type: const Value('abdomen'),
        side: const Value('right'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(5),
      ),
      BodyZonesCompanion.insert(
        code: 'AS',
        name: 'Addome Sx',
        type: const Value('abdomen'),
        side: const Value('left'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(6),
      ),
      BodyZonesCompanion.insert(
        code: 'GD',
        name: 'Gluteo Dx',
        type: const Value('buttock'),
        side: const Value('right'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(7),
      ),
      BodyZonesCompanion.insert(
        code: 'GS',
        name: 'Gluteo Sx',
        type: const Value('buttock'),
        side: const Value('left'),
        numberOfPoints: const Value(4),
        sortOrder: const Value(8),
      ),
    ];

    await batch((b) {
      b.insertAll(bodyZones, zones);
    });
  }

  /// Mappa dei tipi di pattern ai nomi visualizzati
  static const _patternTypeNames = {
    'smart': 'Suggerimento AI',
    'sequential': 'Sequenza Zone',
    'alternateSides': 'Alternanza Sx/Dx',
    'weeklyRotation': 'Rotazione Settimanale',
    'clockwise': 'Rotazione Oraria',
    'counterClockwise': 'Rotazione Antioraria',
    'custom': 'Personalizzato',
  };

  /// Migrazione da v3 a v4: aggiorna piani esistenti e crea quelli mancanti
  Future<void> _migrateTherapyPlansToV4() async {
    final existingPlans = await (select(therapyPlans)).get();
    final now = DateTime.now();

    // Trova quali tipi di pattern esistono già
    final existingTypes = existingPlans
        .map((p) => p.rotationPatternType)
        .toSet();

    // Aggiorna i piani esistenti con nome corretto e imposta il primo come attivo
    bool hasActivePlan = false;
    for (final plan in existingPlans) {
      final correctName =
          _patternTypeNames[plan.rotationPatternType] ?? 'Piano Smart';
      final shouldBeActive = !hasActivePlan; // Il primo piano diventa attivo

      await (update(therapyPlans)..where((p) => p.id.equals(plan.id))).write(
        TherapyPlansCompanion(
          name: Value(correctName),
          isActive: Value(shouldBeActive),
          updatedAt: Value(now),
        ),
      );

      if (shouldBeActive) hasActivePlan = true;
    }

    // Crea i piani mancanti
    final missingTypes = _patternTypeNames.keys.where(
      (t) => !existingTypes.contains(t),
    );

    for (final patternType in missingTypes) {
      await into(therapyPlans).insert(
        TherapyPlansCompanion.insert(
          startDate: now,
          name: Value(_patternTypeNames[patternType]!),
          isActive: Value(
            !hasActivePlan,
          ), // Se non c'è ancora un piano attivo, attiva questo
          rotationPatternType: Value(patternType),
        ),
      );
      if (!hasActivePlan) hasActivePlan = true;
    }
  }

  /// Corregge le coordinate asimmetriche dei punti salvate nel database (v5)
  Future<void> _fixIncorrectPointCoordinates() async {
    // Braccio Sx: da 0.18 a 0.26 (per simmetria con 0.74 del Braccio Dx)
    await customStatement('''
      UPDATE point_configs
      SET position_x = 0.26
      WHERE zone_id IN (SELECT id FROM body_zones WHERE code = 'BS')
      AND position_x = 0.18
    ''');

    // Coscia Sx: da 0.28 a 0.36 (per simmetria con 0.64 della Coscia Dx)
    await customStatement('''
      UPDATE point_configs
      SET position_x = 0.36
      WHERE zone_id IN (SELECT id FROM body_zones WHERE code = 'CS')
      AND position_x = 0.28
    ''');

    // Addome Sx: da 0.32 a 0.40 (per simmetria con 0.60 dell'Addome Dx)
    await customStatement('''
      UPDATE point_configs
      SET position_x = 0.40
      WHERE zone_id IN (SELECT id FROM body_zones WHERE code = 'AS')
      AND position_x = 0.32
    ''');

    // Gluteo Sx: da 0.32 a 0.40 (per simmetria con 0.60 del Gluteo Dx)
    await customStatement('''
      UPDATE point_configs
      SET position_x = 0.40
      WHERE zone_id IN (SELECT id FROM body_zones WHERE code = 'GS')
      AND position_x = 0.32
    ''');
  }

  /// Inserisce i 7 piani terapeutici predefiniti (solo per nuove installazioni)
  Future<void> _seedDefaultTherapyPlans() async {
    // Verifica se esistono già piani
    final existingPlans = await (select(therapyPlans)).get();
    if (existingPlans.isNotEmpty) return;

    final now = DateTime.now();
    final plans = [
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Suggerimento AI'),
        isActive: const Value(true), // Piano attivo di default
        rotationPatternType: const Value('smart'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Sequenza Zone'),
        isActive: const Value(false),
        rotationPatternType: const Value('sequential'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Alternanza Sx/Dx'),
        isActive: const Value(false),
        rotationPatternType: const Value('alternateSides'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Rotazione Settimanale'),
        isActive: const Value(false),
        rotationPatternType: const Value('weeklyRotation'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Rotazione Oraria'),
        isActive: const Value(false),
        rotationPatternType: const Value('clockwise'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Rotazione Antioraria'),
        isActive: const Value(false),
        rotationPatternType: const Value('counterClockwise'),
      ),
      TherapyPlansCompanion.insert(
        startDate: now,
        name: const Value('Personalizzato'),
        isActive: const Value(false),
        rotationPatternType: const Value('custom'),
      ),
    ];

    await batch((b) {
      b.insertAll(therapyPlans, plans);
    });
  }

  // ============ DAO Methods ============

  // --- Body Zones ---
  Future<List<BodyZone>> getAllZones() => (select(
    bodyZones,
  )..orderBy([(z) => OrderingTerm.asc(z.sortOrder)])).get();

  Stream<List<BodyZone>> watchAllZones() => (select(
    bodyZones,
  )..orderBy([(z) => OrderingTerm.asc(z.sortOrder)])).watch();

  Future<List<BodyZone>> getEnabledZones() =>
      (select(bodyZones)
            ..where((z) => z.isEnabled)
            ..orderBy([(z) => OrderingTerm.asc(z.sortOrder)]))
          .get();

  Stream<List<BodyZone>> watchEnabledZones() =>
      (select(bodyZones)
            ..where((z) => z.isEnabled)
            ..orderBy([(z) => OrderingTerm.asc(z.sortOrder)]))
          .watch();

  Future<BodyZone?> getZoneById(int id) =>
      (select(bodyZones)..where((z) => z.id.equals(id))).getSingleOrNull();

  Future<BodyZone?> getZoneByCode(String code) =>
      (select(bodyZones)..where((z) => z.code.equals(code))).getSingleOrNull();

  Future<int> insertZone(BodyZonesCompanion zone) =>
      into(bodyZones).insert(zone);

  Future<int> updateZone(BodyZonesCompanion zone) =>
      (update(bodyZones)..where((z) => z.id.equals(zone.id.value))).write(zone);

  Future<int> deleteZone(int id) =>
      (delete(bodyZones)..where((z) => z.id.equals(id))).go();

  Future<void> updateZonePointCount(int zoneId, int count) =>
      (update(bodyZones)..where((z) => z.id.equals(zoneId))).write(
        BodyZonesCompanion(
          numberOfPoints: Value(count),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateZoneCustomName(int zoneId, String? customName) =>
      (update(bodyZones)..where((z) => z.id.equals(zoneId))).write(
        BodyZonesCompanion(
          customName: Value(customName),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateZoneIcon(int zoneId, String? icon) =>
      (update(bodyZones)..where((z) => z.id.equals(zoneId))).write(
        BodyZonesCompanion(icon: Value(icon), updatedAt: Value(DateTime.now())),
      );

  Future<void> toggleZoneEnabled(int zoneId, bool enabled) =>
      (update(bodyZones)..where((z) => z.id.equals(zoneId))).write(
        BodyZonesCompanion(
          isEnabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> reorderZones(List<int> zoneIdsInOrder) async {
    await batch((b) {
      for (var i = 0; i < zoneIdsInOrder.length; i++) {
        b.update(
          bodyZones,
          BodyZonesCompanion(
            sortOrder: Value(i + 1),
            updatedAt: Value(DateTime.now()),
          ),
          where: (z) => z.id.equals(zoneIdsInOrder[i]),
        );
      }
    });
  }

  // --- Therapy Plans ---
  /// Ottiene il piano terapeutico attivo
  Future<TherapyPlan?> getCurrentTherapyPlan() => (select(
    therapyPlans,
  )..where((p) => p.isActive.equals(true))).getSingleOrNull();

  /// Ottiene tutti i piani terapeutici
  Future<List<TherapyPlan>> getAllTherapyPlans() =>
      (select(therapyPlans)..orderBy([(p) => OrderingTerm.asc(p.id)])).get();

  /// Stream di tutti i piani terapeutici
  Stream<List<TherapyPlan>> watchAllTherapyPlans() =>
      (select(therapyPlans)..orderBy([(p) => OrderingTerm.asc(p.id)])).watch();

  /// Ottiene piano per ID
  Future<TherapyPlan?> getTherapyPlanById(int id) =>
      (select(therapyPlans)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> insertTherapyPlan(TherapyPlansCompanion plan) =>
      into(therapyPlans).insert(plan);

  Future<int> updateTherapyPlan(TherapyPlansCompanion plan) => (update(
    therapyPlans,
  )..where((p) => p.id.equals(plan.id.value))).write(plan);

  /// Attiva un piano specifico (disattiva gli altri)
  Future<void> activateTherapyPlan(int planId) async {
    await batch((b) {
      // Disattiva tutti i piani
      b.update(
        therapyPlans,
        const TherapyPlansCompanion(isActive: Value(false)),
      );
    });
    // Attiva il piano selezionato
    await (update(therapyPlans)..where((p) => p.id.equals(planId))).write(
      TherapyPlansCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Injections ---
  Future<List<Injection>> getAllInjections() => (select(
    injections,
  )..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)])).get();

  Future<List<Injection>> getInjectionsByZone(int zoneId) =>
      (select(injections)
            ..where((i) => i.zoneId.equals(zoneId))
            ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
          .get();

  Future<List<Injection>> getInjectionsByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(injections)
            ..where((i) => i.scheduledAt.isBetweenValues(start, end))
            ..orderBy([(i) => OrderingTerm.asc(i.scheduledAt)]))
          .get();

  /// Usa scheduledAt come data di riferimento (quando l'iniezione è stata fatta)
  Future<Injection?> getLastInjectionForPoint(int zoneId, int pointNumber) =>
      (select(injections)
            ..where(
              (i) =>
                  i.zoneId.equals(zoneId) &
                  i.pointNumber.equals(pointNumber) &
                  i.status.equals('completed'),
            )
            ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertInjection(InjectionsCompanion injection) =>
      into(injections).insert(injection);

  Future<int> updateInjection(InjectionsCompanion injection) => (update(
    injections,
  )..where((i) => i.id.equals(injection.id.value))).write(injection);

  Future<int> deleteInjection(int id) =>
      (delete(injections)..where((i) => i.id.equals(id))).go();

  /// Trova il punto meno usato per una zona negli ultimi N giorni
  Future<int?> findLeastUsedPoint(int zoneId, {int days = 30}) async {
    final zone = await getZoneById(zoneId);
    if (zone == null) return null;

    final blacklisted = await getBlacklistedPointsForZone(zoneId);
    final blacklistedNumbers = blacklisted.map((b) => b.pointNumber).toSet();

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    // Conta utilizzi per ogni punto
    final pointUsage = <int, DateTime?>{};
    for (var p = 1; p <= zone.numberOfPoints; p++) {
      if (blacklistedNumbers.contains(p)) continue;
      pointUsage[p] = null;
    }

    // Usa scheduledAt come data di riferimento (quando l'iniezione è stata fatta)
    final recentInjections =
        await (select(injections)
              ..where(
                (i) =>
                    i.zoneId.equals(zoneId) &
                    i.status.equals('completed') &
                    i.scheduledAt.isBiggerOrEqualValue(cutoffDate),
              )
              ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
            .get();

    for (final inj in recentInjections) {
      if (pointUsage.containsKey(inj.pointNumber) &&
          pointUsage[inj.pointNumber] == null) {
        pointUsage[inj.pointNumber] = inj.scheduledAt;
      }
    }

    // Trova il punto mai usato o usato meno di recente
    int? leastUsedPoint;
    DateTime? oldestDate;

    for (final entry in pointUsage.entries) {
      if (entry.value == null) {
        // Mai usato - ritorna subito
        return entry.key;
      }
      if (oldestDate == null || entry.value!.isBefore(oldestDate)) {
        oldestDate = entry.value;
        leastUsedPoint = entry.key;
      }
    }

    return leastUsedPoint;
  }

  // --- Blacklisted Points ---
  Future<List<BlacklistedPoint>> getAllBlacklistedPoints() =>
      select(blacklistedPoints).get();

  Stream<List<BlacklistedPoint>> watchAllBlacklistedPoints() =>
      select(blacklistedPoints).watch();

  Future<List<BlacklistedPoint>> getBlacklistedPointsForZone(int zoneId) =>
      (select(blacklistedPoints)..where((b) => b.zoneId.equals(zoneId))).get();

  Future<bool> isPointBlacklisted(String pointCode) async {
    final result = await (select(
      blacklistedPoints,
    )..where((b) => b.pointCode.equals(pointCode))).getSingleOrNull();
    return result != null;
  }

  Future<int> insertBlacklistedPoint(BlacklistedPointsCompanion point) =>
      into(blacklistedPoints).insert(point);

  Future<int> removeBlacklistedPoint(String pointCode) => (delete(
    blacklistedPoints,
  )..where((b) => b.pointCode.equals(pointCode))).go();

  // --- App Settings ---
  Future<String?> getSetting(String key) async {
    final result = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  // --- User Profile ---
  Future<UserProfile?> getUserProfile() =>
      (select(userProfiles)..limit(1)).getSingleOrNull();

  Future<int> insertUserProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insert(profile);

  Future<int> updateUserProfile(UserProfilesCompanion profile) => (update(
    userProfiles,
  )..where((p) => p.id.equals(profile.id.value))).write(profile);

  Future<void> updateLastBackupTime(DateTime time) async {
    final profile = await getUserProfile();
    if (profile != null) {
      await (update(userProfiles)..where((p) => p.id.equals(profile.id))).write(
        UserProfilesCompanion(lastBackupAt: Value(time)),
      );
    }
  }

  // --- Point Configs ---
  Future<List<PointConfig>> getPointConfigsForZone(int zoneId) =>
      (select(pointConfigs)
            ..where((p) => p.zoneId.equals(zoneId))
            ..orderBy([(p) => OrderingTerm.asc(p.pointNumber)]))
          .get();

  Stream<List<PointConfig>> watchPointConfigsForZone(int zoneId) =>
      (select(pointConfigs)
            ..where((p) => p.zoneId.equals(zoneId))
            ..orderBy([(p) => OrderingTerm.asc(p.pointNumber)]))
          .watch();

  Future<PointConfig?> getPointConfig(int zoneId, int pointNumber) =>
      (select(pointConfigs)..where(
            (p) => p.zoneId.equals(zoneId) & p.pointNumber.equals(pointNumber),
          ))
          .getSingleOrNull();

  Future<int> insertPointConfig(PointConfigsCompanion config) =>
      into(pointConfigs).insert(config);

  Future<int> upsertPointConfig(PointConfigsCompanion config) =>
      into(pointConfigs).insertOnConflictUpdate(config);

  Future<int> updatePointConfig(PointConfigsCompanion config) => (update(
    pointConfigs,
  )..where((p) => p.id.equals(config.id.value))).write(config);

  Future<void> updatePointPosition(
    int zoneId,
    int pointNumber,
    double x,
    double y,
    String bodyView,
  ) async {
    final existing = await getPointConfig(zoneId, pointNumber);
    if (existing != null) {
      await (update(
        pointConfigs,
      )..where((p) => p.id.equals(existing.id))).write(
        PointConfigsCompanion(
          positionX: Value(x),
          positionY: Value(y),
          bodyView: Value(bodyView),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(pointConfigs).insert(
        PointConfigsCompanion.insert(
          zoneId: zoneId,
          pointNumber: pointNumber,
          positionX: Value(x),
          positionY: Value(y),
          bodyView: Value(bodyView),
        ),
      );
    }
  }

  Future<void> updatePointName(int zoneId, int pointNumber, String name) async {
    final existing = await getPointConfig(zoneId, pointNumber);
    if (existing != null) {
      await (update(
        pointConfigs,
      )..where((p) => p.id.equals(existing.id))).write(
        PointConfigsCompanion(
          customName: Value(name),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(pointConfigs).insert(
        PointConfigsCompanion.insert(
          zoneId: zoneId,
          pointNumber: pointNumber,
          customName: Value(name),
        ),
      );
    }
  }

  Future<int> deletePointConfig(int id) =>
      (delete(pointConfigs)..where((p) => p.id.equals(id))).go();

  Future<int> deletePointConfigsForZone(int zoneId) =>
      (delete(pointConfigs)..where((p) => p.zoneId.equals(zoneId))).go();

  // --- Point Usage History ---
  /// Restituisce la mappa pointNumber -> ultima data di utilizzo per una zona
  Future<Map<int, DateTime?>> getPointUsageHistory(int zoneId) async {
    final zone = await getZoneById(zoneId);
    if (zone == null) return {};

    final result = <int, DateTime?>{};

    // Inizializza tutti i punti a null (mai usati)
    for (var p = 1; p <= zone.numberOfPoints; p++) {
      result[p] = null;
    }

    // Query per l'ultima iniezione completata per ogni punto
    // Usa scheduledAt come data di riferimento (quando l'iniezione è stata fatta)
    // invece di completedAt (quando è stata registrata nell'app)
    final allInjections =
        await (select(injections)
              ..where(
                (i) => i.zoneId.equals(zoneId) & i.status.equals('completed'),
              )
              ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
            .get();

    // Prendi solo la data più recente per ogni punto
    for (final inj in allInjections) {
      if (result.containsKey(inj.pointNumber) &&
          result[inj.pointNumber] == null) {
        // Usa sempre scheduledAt come data dell'iniezione effettiva
        result[inj.pointNumber] = inj.scheduledAt;
      }
    }

    return result;
  }

  /// Restituisce l'iniezione per ID
  Future<Injection?> getInjectionById(int id) =>
      (select(injections)..where((i) => i.id.equals(id))).getSingleOrNull();

  // --- Utilities ---
  Future<void> deleteAllData() async {
    await delete(injections).go();
    await delete(blacklistedPoints).go();
    await delete(therapyPlans).go();
    await delete(appSettings).go();
    await delete(userProfiles).go();
    await delete(pointConfigs).go();
    // Non cancellare bodyZones - sono predefinite
  }

  /// Restituisce il path del database file (solo per mobile/desktop)
  static Future<String> getDatabasePath() async {
    if (kIsWeb) {
      // Sul web non usiamo file path
      return 'injecare.db';
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'injecare.db');
  }
}

/// Crea la connessione al database.
/// Su mobile/desktop usa SQLite nativo, sul web usa IndexedDB/WASM.
QueryExecutor _openConnection() {
  // drift_flutter gestisce automaticamente la piattaforma:
  // - Mobile/Desktop: SQLite nativo (usando sqlite3_flutter_libs)
  // - Web: sqlite3 in WASM con persistenza in IndexedDB
  return driftDatabase(
    name: 'injecare',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        if (result.missingFeatures.isNotEmpty) {
          debugPrint(
            'Using ${result.chosenImplementation} due to missing '
            'browser features: ${result.missingFeatures}',
          );
        }
      },
    ),
  );
}
