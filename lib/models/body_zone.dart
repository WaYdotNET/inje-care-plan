/// Body zone model
class BodyZone {
  const BodyZone({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.side,
    required this.numberOfPoints,
    required this.isEnabled,
    required this.sortOrder,
    this.customName,
    this.icon,
  });

  final int id;
  final String code;
  final String name;
  final String? customName; // User-customizable name
  final String? icon; // User-customizable emoji/icon
  final String type; // thigh, arm, abdomen, buttock, custom
  final String side; // left, right, none
  final int numberOfPoints;
  final bool isEnabled;
  final int sortOrder;

  /// Alias for numberOfPoints
  int get pointCount => numberOfPoints;

  /// Get display name (customName if set, otherwise name)
  String get displayName => customName?.isNotEmpty == true ? customName! : name;

  /// Get emoji for zone (custom icon if set, otherwise based on type)
  String get emoji => icon ?? switch (type) {
    'thigh' => '🦵',
    'arm' => '💪',
    'abdomen' => '💧',
    'buttock' => '🍑',
    _ => '📍',
  };

  /// Get full label (e.g., "Coscia Dx · 3")
  String pointLabel(int pointNumber) => '$displayName · $pointNumber';

  /// Get point code (e.g., "CD-3")
  String pointCode(int pointNumber) => '$code-$pointNumber';

  /// Get type from code
  static String typeFromCode(String code) => switch (code) {
    'CD' || 'CS' => 'thigh',
    'BD' || 'BS' => 'arm',
    'AD' || 'AS' => 'abdomen',
    'GD' || 'GS' => 'buttock',
    _ => 'custom',
  };

  /// Get side from code
  static String sideFromCode(String code) {
    if (code.endsWith('D')) return 'right';
    if (code.endsWith('S')) return 'left';
    return 'none';
  }

  /// Default body zones configuration (used for seeding database)
  static List<BodyZone> get defaults => const [
    BodyZone(
      id: 1, code: 'CD', name: 'Coscia Dx',
      type: 'thigh', side: 'right', numberOfPoints: 6,
      isEnabled: true, sortOrder: 1,
    ),
    BodyZone(
      id: 2, code: 'CS', name: 'Coscia Sx',
      type: 'thigh', side: 'left', numberOfPoints: 6,
      isEnabled: true, sortOrder: 2,
    ),
    BodyZone(
      id: 3, code: 'BD', name: 'Braccio Dx',
      type: 'arm', side: 'right', numberOfPoints: 4,
      isEnabled: true, sortOrder: 3,
    ),
    BodyZone(
      id: 4, code: 'BS', name: 'Braccio Sx',
      type: 'arm', side: 'left', numberOfPoints: 4,
      isEnabled: true, sortOrder: 4,
    ),
    BodyZone(
      id: 5, code: 'AD', name: 'Addome Dx',
      type: 'abdomen', side: 'right', numberOfPoints: 4,
      isEnabled: true, sortOrder: 5,
    ),
    BodyZone(
      id: 6, code: 'AS', name: 'Addome Sx',
      type: 'abdomen', side: 'left', numberOfPoints: 4,
      isEnabled: true, sortOrder: 6,
    ),
    BodyZone(
      id: 7, code: 'GD', name: 'Gluteo Dx',
      type: 'buttock', side: 'right', numberOfPoints: 4,
      isEnabled: true, sortOrder: 7,
    ),
    BodyZone(
      id: 8, code: 'GS', name: 'Gluteo Sx',
      type: 'buttock', side: 'left', numberOfPoints: 4,
      isEnabled: true, sortOrder: 8,
    ),
  ];

  /// Create from JSON map
  factory BodyZone.fromJson(Map<String, dynamic> json) {
    return BodyZone(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      customName: json['customName'] as String?,
      icon: json['icon'] as String?,
      type: json['type'] as String? ?? 'custom',
      side: json['side'] as String? ?? 'none',
      numberOfPoints: json['numberOfPoints'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'customName': customName,
    'icon': icon,
    'type': type,
    'side': side,
    'numberOfPoints': numberOfPoints,
    'isEnabled': isEnabled,
    'sortOrder': sortOrder,
  };

  /// Copy with modifications
  BodyZone copyWith({
    int? id,
    String? code,
    String? name,
    String? customName,
    String? icon,
    String? type,
    String? side,
    int? numberOfPoints,
    bool? isEnabled,
    int? sortOrder,
  }) => BodyZone(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    customName: customName ?? this.customName,
    icon: icon ?? this.icon,
    type: type ?? this.type,
    side: side ?? this.side,
    numberOfPoints: numberOfPoints ?? this.numberOfPoints,
    isEnabled: isEnabled ?? this.isEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
