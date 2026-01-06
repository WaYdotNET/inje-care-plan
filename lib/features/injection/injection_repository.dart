import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../models/injection_record.dart' as models;
import '../../models/blacklisted_point.dart' as models;
import '../../models/therapy_plan.dart' as models;

/// Injection repository per operazioni Drift (offline-first)
class InjectionRepository {
  InjectionRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  // ============================================================================
  // Injections
  // ============================================================================

  /// Watch all injections
  Stream<List<Injection>> watchInjections() {
    return _db.select(_db.injections)
        .watch()
        .map((rows) => rows.toList());
  }

  /// Get all injections
  Future<List<Injection>> getInjections() {
    return _db.getAllInjections();
  }

  /// Get injections for a specific date range
  Future<List<Injection>> getInjectionsInRange(DateTime start, DateTime end) {
    return _db.getInjectionsByDateRange(start, end);
  }

  /// Watch injections for a specific date range
  Stream<List<Injection>> watchInjectionsInRange(DateTime start, DateTime end) {
    return (_db.select(_db.injections)
          ..where((i) => i.scheduledAt.isBetweenValues(start, end))
          ..orderBy([(i) => OrderingTerm.asc(i.scheduledAt)]))
        .watch();
  }

  /// Get injections for a specific zone
  Future<List<Injection>> getInjectionsByZone(int zoneId) {
    return _db.getInjectionsByZone(zoneId);
  }

  /// Watch injections for a specific zone
  Stream<List<Injection>> watchInjectionsByZone(int zoneId) {
    return (_db.select(_db.injections)
          ..where((i) => i.zoneId.equals(zoneId))
          ..orderBy([(i) => OrderingTerm.desc(i.scheduledAt)]))
        .watch();
  }

  /// Get last injection for a specific point
  Future<Injection?> getLastInjectionForPoint(int zoneId, int pointNumber) {
    return _db.getLastInjectionForPoint(zoneId, pointNumber);
  }

  /// Create a new injection record
  Future<int> createInjection(models.InjectionRecord record) {
    return _db.insertInjection(InjectionsCompanion.insert(
      zoneId: record.zoneId,
      pointNumber: record.pointNumber,
      pointCode: record.pointCode,
      pointLabel: record.pointLabel,
      scheduledAt: record.scheduledAt,
      completedAt: Value(record.completedAt),
      status: Value(record.status.name),
      notes: Value(record.notes),
      sideEffects: Value(record.sideEffects.join(',')),
      calendarEventId: Value(record.calendarEventId),
    ));
  }

  /// Update an injection record
  Future<int> updateInjection(int id, models.InjectionRecord record) {
    return _db.updateInjection(InjectionsCompanion(
      id: Value(id),
      zoneId: Value(record.zoneId),
      pointNumber: Value(record.pointNumber),
      pointCode: Value(record.pointCode),
      pointLabel: Value(record.pointLabel),
      scheduledAt: Value(record.scheduledAt),
      completedAt: Value(record.completedAt),
      status: Value(record.status.name),
      notes: Value(record.notes),
      sideEffects: Value(record.sideEffects.join(',')),
      calendarEventId: Value(record.calendarEventId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Complete an injection
  Future<void> completeInjection(
    int injectionId, {
    String? notes,
    List<String> sideEffects = const [],
  }) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      status: const Value('completed'),
      completedAt: Value(DateTime.now()),
      notes: Value(notes ?? ''),
      sideEffects: Value(sideEffects.join(',')),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Skip an injection
  Future<void> skipInjection(int injectionId) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete an injection
  Future<int> deleteInjection(int injectionId) {
    return _db.deleteInjection(injectionId);
  }

  // ============================================================================
  // Blacklisted Points
  // ============================================================================

  /// Watch all blacklisted points
  Stream<List<BlacklistedPoint>> watchBlacklistedPoints() {
    return _db.select(_db.blacklistedPoints).watch();
  }

  /// Get all blacklisted points
  Future<List<BlacklistedPoint>> getBlacklistedPoints() {
    return _db.getAllBlacklistedPoints();
  }

  /// Watch blacklisted points for a specific zone
  Stream<List<BlacklistedPoint>> watchBlacklistedPointsByZone(int zoneId) {
    return (_db.select(_db.blacklistedPoints)
          ..where((b) => b.zoneId.equals(zoneId)))
        .watch();
  }

  /// Check if a point is blacklisted
  Future<bool> isPointBlacklisted(String pointCode) {
    return _db.isPointBlacklisted(pointCode);
  }

  /// Add a point to blacklist
  Future<int> blacklistPoint(models.BlacklistedPoint point) {
    return _db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
      pointCode: point.pointCode,
      pointLabel: point.pointLabel,
      zoneId: point.zoneId,
      pointNumber: point.pointNumber,
      reason: Value(point.reason),
      notes: Value(point.notes),
    ));
  }

  /// Remove a point from blacklist
  Future<int> unblacklistPoint(String pointCode) {
    return _db.removeBlacklistedPoint(pointCode);
  }

  // ============================================================================
  // Body Zones
  // ============================================================================

  /// Watch all body zones
  Stream<List<BodyZone>> watchBodyZones() {
    return _db.select(_db.bodyZones).watch();
  }

  /// Get all body zones
  Future<List<BodyZone>> getBodyZones() {
    return _db.getAllZones();
  }

  /// Get enabled body zones
  Future<List<BodyZone>> getEnabledZones() {
    return _db.getEnabledZones();
  }

  /// Get zone by ID
  Future<BodyZone?> getZoneById(int id) {
    return _db.getZoneById(id);
  }

  /// Get zone by code
  Future<BodyZone?> getZoneByCode(String code) {
    return _db.getZoneByCode(code);
  }

  /// Update body zone
  Future<int> updateBodyZone(int id, {bool? isEnabled}) {
    return _db.updateZone(BodyZonesCompanion(
      id: Value(id),
      isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ============================================================================
  // Therapy Plan
  // ============================================================================

  /// Watch therapy plan
  Stream<TherapyPlan?> watchTherapyPlan() {
    return (_db.select(_db.therapyPlans)
          ..where((p) => p.isActive.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Get therapy plan
  Future<TherapyPlan?> getTherapyPlan() {
    return _db.getCurrentTherapyPlan();
  }

  /// Create or update therapy plan
  Future<int> saveTherapyPlan(models.TherapyPlan plan) async {
    final existing = await _db.getCurrentTherapyPlan();

    if (existing != null) {
      return _db.updateTherapyPlan(TherapyPlansCompanion(
        id: Value(existing.id),
        injectionsPerWeek: Value(plan.injectionsPerWeek),
        weekDays: Value(plan.weekDays.join(',')),
        preferredTime: Value(plan.preferredTime),
        startDate: Value(plan.startDate),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      return _db.insertTherapyPlan(TherapyPlansCompanion.insert(
        injectionsPerWeek: Value(plan.injectionsPerWeek),
        weekDays: Value(plan.weekDays.join(',')),
        preferredTime: Value(plan.preferredTime),
        startDate: plan.startDate,
      ));
    }
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// Get adherence statistics for last N days
  Future<({int completed, int total, double percentage})> getAdherenceStats({
    int days = 30,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final injections = await _db.getInjectionsByDateRange(startDate, now);

    final total = injections.length;
    final completed = injections.where((i) => i.status == 'completed').length;
    final percentage = total > 0 ? (completed / total) * 100 : 0.0;

    return (completed: completed, total: total, percentage: percentage);
  }

  /// Get suggested next point based on history
  Future<({int zoneId, int pointNumber})?> getSuggestedNextPoint() async {
    final zones = await _db.getEnabledZones();
    final blacklist = await _db.getAllBlacklistedPoints();

    ({int zoneId, int pointNumber})? bestPoint;
    DateTime? oldestUsage;

    for (final zone in zones) {
      for (var point = 1; point <= zone.numberOfPoints; point++) {
        // Skip blacklisted points
        final isBlacklisted = blacklist.any(
          (bp) => bp.zoneId == zone.id && bp.pointNumber == point,
        );
        if (isBlacklisted) continue;

        // Get last usage for this point
        final lastInjection = await _db.getLastInjectionForPoint(
          zone.id,
          point,
        );

        if (lastInjection == null) {
          // Never used point - suggest this one
          return (zoneId: zone.id, pointNumber: point);
        }

        final usageDate = lastInjection.completedAt ?? lastInjection.scheduledAt;
        if (oldestUsage == null || usageDate.isBefore(oldestUsage)) {
          oldestUsage = usageDate;
          bestPoint = (zoneId: zone.id, pointNumber: point);
        }
      }
    }

    return bestPoint;
  }

  /// Find least used point for a specific zone
  Future<int?> findLeastUsedPoint(int zoneId, {int days = 30}) {
    return _db.findLeastUsedPoint(zoneId, days: days);
  }

  /// Get point usage history for a zone
  /// Returns a map of pointNumber -> last usage date (null if never used)
  Future<Map<int, DateTime?>> getLastUsageForZone(int zoneId) {
    return _db.getPointUsageHistory(zoneId);
  }

  /// Get injection by ID
  Future<Injection?> getInjectionById(int id) {
    return _db.getInjectionById(id);
  }
}
