/// Tipi di pattern di rotazione disponibili
enum RotationPatternType {
  /// Suggerimento AI basato su ML (comportamento attuale)
  smart,

  /// Sequenza fissa delle zone (Coscia Sx -> Coscia Dx -> Braccio Sx -> ...)
  sequential,

  /// Alternanza laterale (Sinistra -> Destra -> Sinistra -> ...)
  alternateSides,

  /// Rotazione settimanale per tipo di zona
  weeklyRotation,

  /// Sequenza personalizzata definita dall'utente
  custom,
}

/// Estensione per ottenere informazioni sul pattern
extension RotationPatternTypeExtension on RotationPatternType {
  /// Nome visualizzato del pattern
  String get displayName => switch (this) {
    RotationPatternType.smart => 'Suggerimento AI',
    RotationPatternType.sequential => 'Sequenza zone',
    RotationPatternType.alternateSides => 'Alternanza Sx/Dx',
    RotationPatternType.weeklyRotation => 'Rotazione settimanale',
    RotationPatternType.custom => 'Personalizzato',
  };

  /// Descrizione del pattern
  String get description => switch (this) {
    RotationPatternType.smart =>
      'L\'AI suggerisce la zona migliore in base allo storico e al tempo trascorso',
    RotationPatternType.sequential =>
      'Segue un ordine fisso: Coscia Sx → Coscia Dx → Braccio Sx → Braccio Dx → ...',
    RotationPatternType.alternateSides =>
      'Alterna sempre tra lato sinistro e destro del corpo',
    RotationPatternType.weeklyRotation =>
      'Cambia tipo di zona ogni settimana (es. cosce questa settimana, braccia la prossima)',
    RotationPatternType.custom =>
      'Definisci tu l\'ordine delle zone da seguire',
  };

  /// Icona del pattern
  String get icon => switch (this) {
    RotationPatternType.smart => '🤖',
    RotationPatternType.sequential => '🔄',
    RotationPatternType.alternateSides => '↔️',
    RotationPatternType.weeklyRotation => '📅',
    RotationPatternType.custom => '✏️',
  };

  /// Converte in stringa per il database
  String get databaseValue => name;

  /// Crea da stringa del database
  static RotationPatternType fromDatabaseValue(String? value) {
    if (value == null) return RotationPatternType.smart;
    return RotationPatternType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RotationPatternType.smart,
    );
  }
}

/// Configurazione del pattern di rotazione
class RotationPattern {
  const RotationPattern({
    required this.type,
    this.customSequence,
    this.currentIndex = 0,
    this.lastZoneId,
    this.lastSide,
    this.weekStartDate,
  });

  /// Tipo di pattern
  final RotationPatternType type;

  /// Sequenza personalizzata di zone IDs (solo per type = custom)
  final List<int>? customSequence;

  /// Indice corrente nella sequenza
  final int currentIndex;

  /// Ultimo ID zona utilizzato
  final int? lastZoneId;

  /// Ultimo lato utilizzato ('left' o 'right')
  final String? lastSide;

  /// Data di inizio della settimana corrente (per weeklyRotation)
  final DateTime? weekStartDate;

  /// Pattern di default
  static RotationPattern get defaults => const RotationPattern(
    type: RotationPatternType.smart,
  );

  /// Crea da JSON
  factory RotationPattern.fromJson(Map<String, dynamic> json) {
    return RotationPattern(
      type: RotationPatternTypeExtension.fromDatabaseValue(
        json['type'] as String?,
      ),
      customSequence: json['customSequence'] != null
          ? (json['customSequence'] as String)
              .split(',')
              .map((s) => int.parse(s.trim()))
              .toList()
          : null,
      currentIndex: json['currentIndex'] as int? ?? 0,
      lastZoneId: json['lastZoneId'] as int?,
      lastSide: json['lastSide'] as String?,
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.parse(json['weekStartDate'] as String)
          : null,
    );
  }

  /// Converte in JSON
  Map<String, dynamic> toJson() => {
    'type': type.databaseValue,
    if (customSequence != null) 'customSequence': customSequence!.join(','),
    'currentIndex': currentIndex,
    if (lastZoneId != null) 'lastZoneId': lastZoneId,
    if (lastSide != null) 'lastSide': lastSide,
    if (weekStartDate != null) 'weekStartDate': weekStartDate!.toIso8601String(),
  };

  /// Copia con modifiche
  RotationPattern copyWith({
    RotationPatternType? type,
    List<int>? customSequence,
    int? currentIndex,
    int? lastZoneId,
    String? lastSide,
    DateTime? weekStartDate,
  }) => RotationPattern(
    type: type ?? this.type,
    customSequence: customSequence ?? this.customSequence,
    currentIndex: currentIndex ?? this.currentIndex,
    lastZoneId: lastZoneId ?? this.lastZoneId,
    lastSide: lastSide ?? this.lastSide,
    weekStartDate: weekStartDate ?? this.weekStartDate,
  );

  @override
  String toString() => 'RotationPattern(type: $type, index: $currentIndex)';
}

/// Sequenza di zone di default per il pattern sequenziale
class DefaultZoneSequence {
  /// Ordine standard delle zone (IDs)
  /// Coscia Sx, Coscia Dx, Braccio Sx, Braccio Dx, Addome Sx, Addome Dx, Gluteo Sx, Gluteo Dx
  static const List<int> standard = [1, 2, 3, 4, 5, 6, 7, 8];

  /// Gruppi di zone per rotazione settimanale
  static const Map<String, List<int>> weeklyGroups = {
    'cosce': [1, 2],     // Coscia Sx, Coscia Dx
    'braccia': [3, 4],   // Braccio Sx, Braccio Dx
    'addome': [5, 6],    // Addome Sx, Addome Dx
    'glutei': [7, 8],    // Gluteo Sx, Gluteo Dx
  };

  /// Ordine dei gruppi per rotazione settimanale
  static const List<String> weeklyOrder = ['cosce', 'braccia', 'addome', 'glutei'];
}
