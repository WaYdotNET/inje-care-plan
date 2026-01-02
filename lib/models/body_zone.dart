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
  });

  final int id;
  final String code;
  final String name;
  final String type; // thigh, arm, abdomen, buttock
  final String side; // left, right
  final int numberOfPoints;
  final bool isEnabled;
  final int sortOrder;

  /// Alias for numberOfPoints
  int get pointCount => numberOfPoints;

  /// Get emoji for zone type
  String get emoji => switch (type) {
    'thigh' => '🦵',
    'arm' => '💪',
    'abdomen' => '💧', // Drop icon representing injection
    'buttock' => '🍑',
    _ => '📍',
  };

  /// Whether this zone uses the app logo instead of emoji
  /// (Currently disabled - logo file not yet added)
  bool get usesLogoIcon => false; // Was: type == 'abdomen'

  /// Get full label (e.g., "Coscia Dx · 3")
  String pointLabel(int pointNumber) => '$name · $pointNumber';

  /// Get point code (e.g., "CD-3")
  String pointCode(int pointNumber) => '$code-$pointNumber';

  /// Get type from code
  static String typeFromCode(String code) => switch (code) {
    'CD' || 'CS' => 'thigh',
    'BD' || 'BS' => 'arm',
    'AD' || 'AS' => 'abdomen',
    'GD' || 'GS' => 'buttock',
    _ => 'unknown',
  };

  /// Get side from code
  static String sideFromCode(String code) => code.endsWith('D') ? 'right' : 'left';

  /// Default body zones configuration
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
      type: json['type'] as String,
      side: json['side'] as String,
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
    String? type,
    String? side,
    int? numberOfPoints,
    bool? isEnabled,
    int? sortOrder,
  }) => BodyZone(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    side: side ?? this.side,
    numberOfPoints: numberOfPoints ?? this.numberOfPoints,
    isEnabled: isEnabled ?? this.isEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}
