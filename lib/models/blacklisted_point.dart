import 'package:cloud_firestore/cloud_firestore.dart';

/// Blacklist reason enum
enum BlacklistReason {
  skinReaction,
  scar,
  hardToReach,
  other,
}

/// Blacklisted injection point model
class BlacklistedPoint {
  const BlacklistedPoint({
    this.id,
    required this.zoneId,
    required this.pointNumber,
    required this.reason,
    this.notes,
    required this.blacklistedAt,
  });

  final String? id;
  final int zoneId;
  final int pointNumber;
  final BlacklistReason reason;
  final String? notes;
  final DateTime blacklistedAt;

  /// Get zone code from zoneId
  String get zoneCode => switch (zoneId) {
    1 => 'CD', 2 => 'CS',
    3 => 'BD', 4 => 'BS',
    5 => 'AD', 6 => 'AS',
    7 => 'GD', 8 => 'GS',
    _ => '??',
  };

  /// Get zone name from zoneId
  String get zoneName => switch (zoneId) {
    1 => 'Coscia Dx', 2 => 'Coscia Sx',
    3 => 'Braccio Dx', 4 => 'Braccio Sx',
    5 => 'Addome Dx', 6 => 'Addome Sx',
    7 => 'Gluteo Dx', 8 => 'Gluteo Sx',
    _ => 'Sconosciuto',
  };

  /// Get point code (e.g., "CD-3")
  String get pointCode => '$zoneCode-$pointNumber';

  /// Get point label (e.g., "Coscia Dx · 3")
  String get pointLabel => '$zoneName · $pointNumber';

  /// Get human-readable reason
  String get reasonLabel => switch (reason) {
    BlacklistReason.skinReaction => 'Reazione cutanea',
    BlacklistReason.scar => 'Cicatrice / lesione',
    BlacklistReason.hardToReach => 'Difficile da raggiungere',
    BlacklistReason.other => 'Altro',
  };

  /// Create from Firestore document
  factory BlacklistedPoint.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BlacklistedPoint(
      id: doc.id,
      zoneId: data['zoneId'] as int,
      pointNumber: data['pointNumber'] as int,
      reason: BlacklistReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => BlacklistReason.other,
      ),
      notes: data['notes'] as String?,
      blacklistedAt: (data['blacklistedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
    'zoneId': zoneId,
    'pointNumber': pointNumber,
    'pointCode': pointCode,
    'pointLabel': pointLabel,
    'reason': reason.name,
    'notes': notes,
    'blacklistedAt': Timestamp.fromDate(blacklistedAt),
  };

  /// Copy with modifications
  BlacklistedPoint copyWith({
    String? id,
    int? zoneId,
    int? pointNumber,
    BlacklistReason? reason,
    String? notes,
    DateTime? blacklistedAt,
  }) => BlacklistedPoint(
    id: id ?? this.id,
    zoneId: zoneId ?? this.zoneId,
    pointNumber: pointNumber ?? this.pointNumber,
    reason: reason ?? this.reason,
    notes: notes ?? this.notes,
    blacklistedAt: blacklistedAt ?? this.blacklistedAt,
  );
}
