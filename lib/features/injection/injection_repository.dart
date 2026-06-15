import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/services/calendar_sync_service.dart';
import '../../models/injection_record.dart' as models;
import '../../models/blacklisted_point.dart' as models;
import '../../models/reminder_rule.dart';
import '../../models/therapy_plan.dart' as models;

/// Returns true if an injection scheduled at [scheduledAt] can be completed now.
/// Rule: same calendar day or earlier — future days are blocked.
bool canCompleteNow(DateTime scheduledAt, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final scheduledDay =
      DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  return !scheduledDay.isAfter(today);
}

/// Injection repository per operazioni Drift (offline-first)
class InjectionRepository {
  InjectionRepository({
    required AppDatabase database,
    CalendarSyncService? calendarSync,
    bool Function()? isCalendarEnabled,
    ReminderSettingsView Function()? calendarSettings,
    CompletionBehavior Function()? completionBehaviorOf,
  })  : _db = database,
        _calendarSync = calendarSync,
        _isCalendarEnabled = isCalendarEnabled ?? (() => false),
        _calendarSettings = calendarSettings,
        _completionBehaviorOf =
            completionBehaviorOf ?? (() => CompletionBehavior.markDone);

  final AppDatabase _db;
  final CalendarSyncService? _calendarSync;
  final bool Function() _isCalendarEnabled;
  final ReminderSettingsView Function()? _calendarSettings;
  final CompletionBehavior Function() _completionBehaviorOf;

  /// Sincronizza l'iniezione [injectionId] con il calendario del device.
  ///
  /// Best-effort: le eccezioni vengono silenziate per non bloccare il salvataggio.
  Future<void> _syncToCalendar(int injectionId) async {
    if (!_isCalendarEnabled() || _calendarSync == null) return;
    try {
      final inj = await _db.getInjectionById(injectionId);
      if (inj == null) return;
      final prev = await _db.getPreviousCompletedBefore(inj.scheduledAt);
      final view = _calendarSettings?.call() ??
          const ReminderSettingsView(
            channelIncludesCalendar: true,
            includeFeedback: true,
            activeRules: [],
          );
      final eventId = await _calendarSync.upsertEvent(inj, prev, view);
      if (eventId != null && eventId != inj.calendarEventId) {
        await _db.setCalendarEventId(injectionId, eventId);
      }
    } catch (_) {
      // best-effort: il calendario non deve mai bloccare il salvataggio
    }
  }

  /// Ri-sincronizza l'evento dopo una modifica (note/effetti), rispettando lo
  /// stato: una iniezione completata mantiene il ✓ (markDone), le altre usano
  /// l'upsert standard. Best-effort.
  Future<void> _resyncCalendar(int injectionId) async {
    if (!_isCalendarEnabled() || _calendarSync == null) return;
    try {
      final inj = await _db.getInjectionById(injectionId);
      if (inj == null || inj.calendarEventId.isEmpty) return;
      if (inj.status == 'completed') {
        await _calendarSync.markDone(inj, _completionBehaviorOf());
      } else {
        await _syncToCalendar(injectionId);
      }
    } catch (_) {
      // best-effort
    }
  }

  /// Resolve the display label for a point, using custom names if configured.
  /// Format: "ZoneName · CustomName (N)" when custom name exists,
  /// otherwise "ZoneName · N" (default format).
  Future<String> resolvePointLabel(int zoneId, int pointNumber) async {
    final zone = await _db.getZoneById(zoneId);
    if (zone == null) return 'Punto $pointNumber';

    final zoneName = (zone.customName != null && zone.customName!.isNotEmpty)
        ? zone.customName!
        : zone.name;

    final config = await _db.getPointConfig(zoneId, pointNumber);
    if (config != null && config.customName.isNotEmpty) {
      return '$zoneName · ${config.customName} ($pointNumber)';
    }
    return '$zoneName · $pointNumber';
  }

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

  /// Create a new injection record.
  ///
  /// Se [syncCalendar] è `true` (default) sincronizza immediatamente il
  /// calendario del device. Passa `syncCalendar: false` per le operazioni
  /// di pianificazione batch che sincronizzano il calendario in background
  /// dopo aver creato tutte le iniezioni, evitando di bloccare la UI.
  Future<int> createInjection(
    models.InjectionRecord record, {
    bool syncCalendar = true,
  }) async {
    final id = await _db.insertInjection(InjectionsCompanion.insert(
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
    if (syncCalendar) await _syncToCalendar(id);
    return id;
  }

  /// Sincronizza l'iniezione [injectionId] con il calendario del device.
  ///
  /// Esposto pubblicamente per consentire la sincronizzazione in background
  /// dopo operazioni batch (es. pianificazione) che usano
  /// `createInjection(record, syncCalendar: false)`.
  Future<void> syncInjectionToCalendar(int injectionId) =>
      _syncToCalendar(injectionId);

  /// Update an injection record
  Future<int> updateInjection(int id, models.InjectionRecord record) async {
    final rows = await _db.updateInjection(InjectionsCompanion(
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
    await _syncToCalendar(id);
    return rows;
  }

  /// Complete an injection at [at] (defaults to now). Records the actual time
  /// in BOTH completedAt and scheduledAt (scheduledAt is the app's reference
  /// for "when the injection was done"). Throws [StateError] if the injection
  /// is scheduled for a future calendar day (defensive guard against UI bypass).
  Future<void> completeInjection(
    int injectionId, {
    DateTime? at,
    String? notes,
    List<String> sideEffects = const [],
  }) async {
    final injection = await _db.getInjectionById(injectionId);
    if (injection != null && !canCompleteNow(injection.scheduledAt)) {
      throw StateError(
        'Cannot complete an injection scheduled for a future day',
      );
    }
    final when = at ?? DateTime.now();
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      status: const Value('completed'),
      scheduledAt: Value(when),
      completedAt: Value(when),
      notes: Value(notes ?? ''),
      sideEffects: Value(sideEffects.join(',')),
      updatedAt: Value(DateTime.now()),
    ));
    if (_isCalendarEnabled() && _calendarSync != null) {
      try {
        final inj = await _db.getInjectionById(injectionId);
        if (inj != null) {
          await _calendarSync.markDone(inj, _completionBehaviorOf());
        }
      } catch (_) {
        // best-effort: il calendario non deve mai bloccare il completamento
      }
    }
  }

  /// Update side effects for an existing injection
  Future<void> updateSideEffects(int injectionId, List<String> sideEffects) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      sideEffects: Value(sideEffects.join(',')),
      updatedAt: Value(DateTime.now()),
    ));
    await _resyncCalendar(injectionId);
  }

  /// Update notes for an existing injection (editable at any time)
  Future<void> updateNotes(int injectionId, String? notes) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      notes: Value(notes ?? ''),
      updatedAt: Value(DateTime.now()),
    ));
    await _resyncCalendar(injectionId);
  }

  /// Skip an injection
  Future<void> skipInjection(int injectionId) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Restore an injection to scheduled status
  Future<void> restoreInjection(int injectionId) async {
    await _db.updateInjection(InjectionsCompanion(
      id: Value(injectionId),
      status: const Value('scheduled'),
      completedAt: const Value(null),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete an injection
  Future<int> deleteInjection(int injectionId) async {
    if (_isCalendarEnabled() && _calendarSync != null) {
      try {
        final inj = await _db.getInjectionById(injectionId);
        if (inj != null) {
          await _calendarSync.removeEvent(inj);
        }
      } catch (_) {
        // best-effort: il calendario non deve mai bloccare la cancellazione
      }
    }
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

  /// Get last completed injection without side effects logged
  Future<Injection?> getLastCompletedInjectionWithoutSideEffects() {
    return _db.getLastCompletedInjectionWithoutSideEffects();
  }
}
