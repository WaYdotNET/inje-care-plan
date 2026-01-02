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
    this.notes = '',
    required this.blacklistedAt,
  });

  final int? id;
  final int zoneId;
  final int pointNumber;
  final String reason;
  final String notes;
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
    'skinReaction' => 'Reazione cutanea',
    'scar' => 'Cicatrice / lesione',
    'hardToReach' => 'Difficile da raggiungere',
    'other' => 'Altro',
    _ => reason,
  };

  /// Create from JSON map
  factory BlacklistedPoint.fromJson(Map<String, dynamic> json) {
    return BlacklistedPoint(
      id: json['id'] as int?,
      zoneId: json['zoneId'] as int,
      pointNumber: json['pointNumber'] as int,
      reason: json['reason'] as String,
      notes: json['notes'] as String? ?? '',
      blacklistedAt: DateTime.parse(json['blacklistedAt'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'zoneId': zoneId,
    'pointNumber': pointNumber,
    'pointCode': pointCode,
    'pointLabel': pointLabel,
    'reason': reason,
    'notes': notes,
    'blacklistedAt': blacklistedAt.toIso8601String(),
  };

  /// Copy with modifications
  BlacklistedPoint copyWith({
    int? id,
    int? zoneId,
    int? pointNumber,
    String? reason,
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
