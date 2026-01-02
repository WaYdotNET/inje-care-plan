import 'package:cloud_firestore/cloud_firestore.dart';

/// Injection status enum
enum InjectionStatus { scheduled, completed, skipped, delayed }

/// Injection record model
class InjectionRecord {
  const InjectionRecord({
    this.id,
    required this.zoneId,
    required this.pointNumber,
    required this.scheduledAt,
    this.completedAt,
    required this.status,
    this.notes,
    this.sideEffects = const [],
    this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final int zoneId;
  final int pointNumber;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final InjectionStatus status;
  final String? notes;
  final List<String> sideEffects;
  final String? calendarEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  /// Get emoji for zone
  String get emoji => switch (zoneId) {
    1 || 2 => '🦵',
    3 || 4 => '💪',
    5 || 6 => '🫁',
    7 || 8 => '🍑',
    _ => '📍',
  };

  /// Create from Firestore document
  factory InjectionRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return InjectionRecord(
      id: doc.id,
      zoneId: data['zoneId'] as int,
      pointNumber: data['pointNumber'] as int,
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      status: InjectionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InjectionStatus.scheduled,
      ),
      notes: data['notes'] as String?,
      sideEffects: (data['sideEffects'] as List<dynamic>?)?.cast<String>() ?? [],
      calendarEventId: data['calendarEventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
    'zoneId': zoneId,
    'pointNumber': pointNumber,
    'pointCode': pointCode,
    'pointLabel': pointLabel,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'status': status.name,
    'notes': notes,
    'sideEffects': sideEffects,
    'calendarEventId': calendarEventId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Copy with modifications
  InjectionRecord copyWith({
    String? id,
    int? zoneId,
    int? pointNumber,
    DateTime? scheduledAt,
    DateTime? completedAt,
    InjectionStatus? status,
    String? notes,
    List<String>? sideEffects,
    String? calendarEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InjectionRecord(
    id: id ?? this.id,
    zoneId: zoneId ?? this.zoneId,
    pointNumber: pointNumber ?? this.pointNumber,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    completedAt: completedAt ?? this.completedAt,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    sideEffects: sideEffects ?? this.sideEffects,
    calendarEventId: calendarEventId ?? this.calendarEventId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Create a new scheduled injection
  factory InjectionRecord.scheduled({
    required int zoneId,
    required int pointNumber,
    required DateTime scheduledAt,
  }) => InjectionRecord(
    zoneId: zoneId,
    pointNumber: pointNumber,
    scheduledAt: scheduledAt,
    status: InjectionStatus.scheduled,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
