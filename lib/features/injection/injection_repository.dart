import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/injection_record.dart';
import '../../models/blacklisted_point.dart';
import '../../models/body_zone.dart';
import '../../models/therapy_plan.dart';

/// Injection repository for Firestore operations
class InjectionRepository {
  InjectionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ============================================================================
  // Injections
  // ============================================================================

  /// Get injections collection reference
  CollectionReference<Map<String, dynamic>> _injectionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('injections');
  }

  /// Get all injections for user
  Stream<List<InjectionRecord>> watchInjections(String userId) {
    return _injectionsRef(userId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InjectionRecord.fromFirestore(doc))
            .toList());
  }

  /// Get injections for a specific date range
  Stream<List<InjectionRecord>> watchInjectionsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _injectionsRef(userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InjectionRecord.fromFirestore(doc))
            .toList());
  }

  /// Get injections for a specific zone
  Stream<List<InjectionRecord>> watchInjectionsByZone(
    String userId,
    int zoneId,
  ) {
    return _injectionsRef(userId)
        .where('zoneId', isEqualTo: zoneId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InjectionRecord.fromFirestore(doc))
            .toList());
  }

  /// Get last injection for a specific point
  Future<InjectionRecord?> getLastInjectionForPoint(
    String userId,
    int zoneId,
    int pointNumber,
  ) async {
    final snapshot = await _injectionsRef(userId)
        .where('zoneId', isEqualTo: zoneId)
        .where('pointNumber', isEqualTo: pointNumber)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InjectionRecord.fromFirestore(snapshot.docs.first);
  }

  /// Create a new injection record
  Future<String> createInjection(String userId, InjectionRecord record) async {
    final docRef = await _injectionsRef(userId).add(record.toFirestore());
    return docRef.id;
  }

  /// Update an injection record
  Future<void> updateInjection(
    String userId,
    String injectionId,
    InjectionRecord record,
  ) async {
    await _injectionsRef(userId)
        .doc(injectionId)
        .update(record.toFirestore());
  }

  /// Complete an injection
  Future<void> completeInjection(
    String userId,
    String injectionId, {
    String? notes,
    List<String> sideEffects = const [],
  }) async {
    await _injectionsRef(userId).doc(injectionId).update({
      'status': InjectionStatus.completed.name,
      'completedAt': Timestamp.now(),
      'notes': notes,
      'sideEffects': sideEffects,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Skip an injection
  Future<void> skipInjection(String userId, String injectionId) async {
    await _injectionsRef(userId).doc(injectionId).update({
      'status': InjectionStatus.skipped.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete an injection
  Future<void> deleteInjection(String userId, String injectionId) async {
    await _injectionsRef(userId).doc(injectionId).delete();
  }

  // ============================================================================
  // Blacklisted Points
  // ============================================================================

  /// Get blacklisted points collection reference
  CollectionReference<Map<String, dynamic>> _blacklistRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('blacklistedPoints');
  }

  /// Watch all blacklisted points
  Stream<List<BlacklistedPoint>> watchBlacklistedPoints(String userId) {
    return _blacklistRef(userId)
        .orderBy('blacklistedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlacklistedPoint.fromFirestore(doc))
            .toList());
  }

  /// Watch blacklisted points for a specific zone
  Stream<List<BlacklistedPoint>> watchBlacklistedPointsByZone(
    String userId,
    int zoneId,
  ) {
    return _blacklistRef(userId)
        .where('zoneId', isEqualTo: zoneId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlacklistedPoint.fromFirestore(doc))
            .toList());
  }

  /// Check if a point is blacklisted
  Future<bool> isPointBlacklisted(
    String userId,
    int zoneId,
    int pointNumber,
  ) async {
    final snapshot = await _blacklistRef(userId)
        .where('zoneId', isEqualTo: zoneId)
        .where('pointNumber', isEqualTo: pointNumber)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Add a point to blacklist
  Future<String> blacklistPoint(String userId, BlacklistedPoint point) async {
    final docRef = await _blacklistRef(userId).add(point.toFirestore());
    return docRef.id;
  }

  /// Remove a point from blacklist
  Future<void> unblacklistPoint(String userId, String blacklistId) async {
    await _blacklistRef(userId).doc(blacklistId).delete();
  }

  // ============================================================================
  // Body Zones
  // ============================================================================

  /// Get body zones collection reference
  CollectionReference<Map<String, dynamic>> _zonesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('bodyZones');
  }

  /// Watch all body zones
  Stream<List<BodyZone>> watchBodyZones(String userId) {
    return _zonesRef(userId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BodyZone.fromFirestore(doc))
            .toList());
  }

  /// Update body zone
  Future<void> updateBodyZone(String userId, BodyZone zone) async {
    await _zonesRef(userId).doc(zone.id.toString()).update(zone.toFirestore());
  }

  // ============================================================================
  // Therapy Plan
  // ============================================================================

  /// Get therapy plan document reference
  DocumentReference<Map<String, dynamic>> _therapyPlanRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('therapyPlan');
  }

  /// Watch therapy plan
  Stream<TherapyPlan> watchTherapyPlan(String userId) {
    return _therapyPlanRef(userId).snapshots().map((doc) {
      if (!doc.exists) return TherapyPlan.defaults;
      return TherapyPlan.fromFirestore(doc);
    });
  }

  /// Get therapy plan
  Future<TherapyPlan> getTherapyPlan(String userId) async {
    final doc = await _therapyPlanRef(userId).get();
    if (!doc.exists) return TherapyPlan.defaults;
    return TherapyPlan.fromFirestore(doc);
  }

  /// Update therapy plan
  Future<void> updateTherapyPlan(String userId, TherapyPlan plan) async {
    await _therapyPlanRef(userId).set(plan.toFirestore());
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// Get adherence statistics for last N days
  Future<({int completed, int total, double percentage})> getAdherenceStats(
    String userId, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final snapshot = await _injectionsRef(userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .get();

    final total = snapshot.docs.length;
    final completed = snapshot.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;

    final percentage = total > 0 ? (completed / total) * 100 : 0.0;

    return (completed: completed, total: total, percentage: percentage);
  }

  /// Get suggested next point based on history
  Future<({int zoneId, int pointNumber})?> getSuggestedNextPoint(
    String userId,
  ) async {
    // Get all body zones
    final zonesSnapshot = await _zonesRef(userId).where('isEnabled', isEqualTo: true).get();
    final zones = zonesSnapshot.docs.map((doc) => BodyZone.fromFirestore(doc)).toList();

    // Get all blacklisted points
    final blacklistSnapshot = await _blacklistRef(userId).get();
    final blacklist = blacklistSnapshot.docs
        .map((doc) => BlacklistedPoint.fromFirestore(doc))
        .toList();

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
        final lastInjection = await getLastInjectionForPoint(
          userId,
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
}
