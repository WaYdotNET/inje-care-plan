import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  BodyZones,
  TherapyPlans,
  Injections,
  BlacklistedPoints,
  AppSettings,
  UserProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor per testing con database in-memory
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Inserisci le zone predefinite
          await _seedDefaultZones();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations
        },
      );

  /// Inserisce le 8 zone predefinite
  Future<void> _seedDefaultZones() async {
    final zones = [
      BodyZonesCompanion.insert(
        code: 'CD',
        name: 'Coscia Dx',
        numberOfPoints: const Value(6),
      ),
      BodyZonesCompanion.insert(
        code: 'CS',
        name: 'Coscia Sx',
        numberOfPoints: const Value(6),
      ),
      BodyZonesCompanion.insert(
        code: 'BD',
        name: 'Braccio Dx',
        numberOfPoints: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'BS',
        name: 'Braccio Sx',
        numberOfPoints: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'AD',
        name: 'Addome Dx',
        numberOfPoints: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'AS',
        name: 'Addome Sx',
        numberOfPoints: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'GD',
        name: 'Gluteo Dx',
        numberOfPoints: const Value(4),
      ),
      BodyZonesCompanion.insert(
        code: 'GS',
        name: 'Gluteo Sx',
        numberOfPoints: const Value(4),
      ),
    ];

    await batch((b) {
      b.insertAll(bodyZones, zones);
    });
  }

  // ============ DAO Methods ============

  // --- Body Zones ---
  Future<List<BodyZone>> getAllZones() => select(bodyZones).get();

  Future<List<BodyZone>> getEnabledZones() =>
      (select(bodyZones)..where((z) => z.isEnabled)).get();

  Future<BodyZone?> getZoneById(int id) =>
      (select(bodyZones)..where((z) => z.id.equals(id))).getSingleOrNull();

  Future<BodyZone?> getZoneByCode(String code) =>
      (select(bodyZones)..where((z) => z.code.equals(code))).getSingleOrNull();

  Future<int> updateZone(BodyZonesCompanion zone) =>
      (update(bodyZones)..where((z) => z.id.equals(zone.id.value)))
          .write(zone);

  // --- Therapy Plans ---
  Future<TherapyPlan?> getCurrentTherapyPlan() =>
      (select(therapyPlans)..limit(1)).getSingleOrNull();

  Future<int> insertTherapyPlan(TherapyPlansCompanion plan) =>
      into(therapyPlans).insert(plan);

  Future<int> updateTherapyPlan(TherapyPlansCompanion plan) =>
      (update(therapyPlans)..where((p) => p.id.equals(plan.id.value)))
          .write(plan);

  // --- Injections ---
  Future<List<Injection>> getAllInjections() =>
      (select(injections)..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
          .get();

  Future<List<Injection>> getInjectionsByZone(int zoneId) => (select(injections)
        ..where((i) => i.zoneId.equals(zoneId))
        ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
      .get();

  Future<List<Injection>> getInjectionsByDateRange(
          DateTime start, DateTime end) =>
      (select(injections)
            ..where(
                (i) => i.scheduledAt.isBetweenValues(start, end))
            ..orderBy([(i) => OrderingTerm.asc(i.scheduledAt)]))
          .get();

  Future<Injection?> getLastInjectionForPoint(int zoneId, int pointNumber) =>
      (select(injections)
            ..where((i) =>
                i.zoneId.equals(zoneId) &
                i.pointNumber.equals(pointNumber) &
                i.status.equals('completed'))
            ..orderBy([(i) => OrderingTerm.desc(i.completedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertInjection(InjectionsCompanion injection) =>
      into(injections).insert(injection);

  Future<int> updateInjection(InjectionsCompanion injection) =>
      (update(injections)..where((i) => i.id.equals(injection.id.value)))
          .write(injection);

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

    final recentInjections = await (select(injections)
          ..where((i) =>
              i.zoneId.equals(zoneId) &
              i.status.equals('completed') &
              i.completedAt.isBiggerOrEqualValue(cutoffDate))
          ..orderBy([(i) => OrderingTerm.desc(i.completedAt)]))
        .get();

    for (final inj in recentInjections) {
      if (pointUsage.containsKey(inj.pointNumber) &&
          pointUsage[inj.pointNumber] == null) {
        pointUsage[inj.pointNumber] = inj.completedAt;
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

  Future<List<BlacklistedPoint>> getBlacklistedPointsForZone(int zoneId) =>
      (select(blacklistedPoints)..where((b) => b.zoneId.equals(zoneId))).get();

  Future<bool> isPointBlacklisted(String pointCode) async {
    final result = await (select(blacklistedPoints)
          ..where((b) => b.pointCode.equals(pointCode)))
        .getSingleOrNull();
    return result != null;
  }

  Future<int> insertBlacklistedPoint(BlacklistedPointsCompanion point) =>
      into(blacklistedPoints).insert(point);

  Future<int> removeBlacklistedPoint(String pointCode) =>
      (delete(blacklistedPoints)..where((b) => b.pointCode.equals(pointCode)))
          .go();

  // --- App Settings ---
  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
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

  Future<int> updateUserProfile(UserProfilesCompanion profile) =>
      (update(userProfiles)..where((p) => p.id.equals(profile.id.value)))
          .write(profile);

  Future<void> updateLastBackupTime(DateTime time) async {
    final profile = await getUserProfile();
    if (profile != null) {
      await (update(userProfiles)..where((p) => p.id.equals(profile.id)))
          .write(UserProfilesCompanion(lastBackupAt: Value(time)));
    }
  }

  // --- Utilities ---
  Future<void> deleteAllData() async {
    await delete(injections).go();
    await delete(blacklistedPoints).go();
    await delete(therapyPlans).go();
    await delete(appSettings).go();
    await delete(userProfiles).go();
    // Non cancellare bodyZones - sono predefinite
  }

  /// Restituisce il path del database file
  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'injecare.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = File(await AppDatabase.getDatabasePath());
    return NativeDatabase.createInBackground(file);
  });
}

