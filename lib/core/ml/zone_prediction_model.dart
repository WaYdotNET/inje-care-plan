import 'ml_data_collector.dart';
import '../../models/body_zone.dart' as models;

/// Modello per predire la zona di iniezione ottimale
class ZonePredictionModel {
  /// Pesi per il calcolo dello score
  static const double _weightDaysSinceLastUse = 0.40;
  static const double _weightCompletionRate = 0.30;
  static const double _weightRotation = 0.20;
  static const double _weightAvailablePoints = 0.10;


  /// Genera predizioni per tutte le zone
  List<ZonePrediction> predict(List<ZoneInjectionData> data) {
    if (data.isEmpty) return [];

    // Filtra zone non utilizzabili
    final usableZones = data.where((z) => 
      z.zone.isEnabled && !z.fullyBlacklisted
    ).toList();

    if (usableZones.isEmpty) return [];

    // Calcola statistiche per normalizzazione
    final maxDays = usableZones
      .map((z) => z.daysSinceLastInjection ?? 365)
      .fold<int>(1, (max, d) => d > max ? d : max);

    // Calcola score per ogni zona
    final predictions = <ZonePrediction>[];
    
    for (final zoneData in usableZones) {
      final score = _calculateScore(zoneData, maxDays, usableZones.length);
      final reason = _generateReason(zoneData, score);
      final confidence = _calculateConfidence(zoneData, score);

      predictions.add(ZonePrediction(
        zone: zoneData.zone,
        score: score,
        reason: reason,
        confidence: confidence,
        factors: _getScoreFactors(zoneData, maxDays),
      ));
    }

    // Ordina per score decrescente
    predictions.sort((a, b) => b.score.compareTo(a.score));

    return predictions;
  }

  /// Calcola lo score complessivo per una zona
  double _calculateScore(ZoneInjectionData data, int maxDays, int totalZones) {
    double score = 0;

    // 1. Giorni dall'ultima iniezione (più giorni = score più alto)
    final daysFactor = _normalizeDaysSinceLastUse(data, maxDays);
    score += daysFactor * _weightDaysSinceLastUse;

    // 2. Tasso di completamento storico (più alto = meglio)
    score += data.completionRate * _weightCompletionRate;

    // 3. Rotazione uniforme (penalizza zone usate molto più delle altre)
    final rotationFactor = _calculateRotationFactor(data, totalZones);
    score += rotationFactor * _weightRotation;

    // 4. Punti disponibili (più punti = più flessibilità)
    final availabilityFactor = data.availablePointsCount / data.zone.totalPoints;
    score += availabilityFactor * _weightAvailablePoints;

    return score.clamp(0.0, 1.0);
  }

  /// Normalizza i giorni dall'ultimo uso (0-1)
  double _normalizeDaysSinceLastUse(ZoneInjectionData data, int maxDays) {
    if (data.neverUsed) return 1.0; // Priorità massima se mai usata
    if (data.daysSinceLastInjection == null) return 0.5;
    
    final days = data.daysSinceLastInjection!;
    
    // Scala logaritmica per dare più peso ai primi giorni
    if (days <= 0) return 0.0;
    if (days >= maxDays) return 1.0;
    
    return (days / maxDays).clamp(0.0, 1.0);
  }

  /// Calcola il fattore di rotazione
  double _calculateRotationFactor(ZoneInjectionData data, int totalZones) {
    if (data.neverUsed) return 1.0;
    
    // Idealmente ogni zona dovrebbe avere ~1/totalZones del totale
    // Se ha meno, score più alto
    final idealShare = 1.0 / totalZones;
    
    // Questo è semplificato - in produzione confronteremmo con le altre zone
    return data.completionRate < idealShare ? 1.0 : 0.5;
  }

  /// Genera una spiegazione per il suggerimento
  String _generateReason(ZoneInjectionData data, double score) {
    if (data.neverUsed) {
      return 'Zona mai utilizzata, ottima per iniziare la rotazione';
    }

    if (data.daysSinceLastInjection != null) {
      final days = data.daysSinceLastInjection!;
      
      if (days >= 14) {
        return 'Non usata da $days giorni, tempo ideale per la rotazione';
      } else if (days >= 7) {
        return 'Non usata da $days giorni';
      } else if (days >= 3) {
        return 'Usata $days giorni fa, buon recupero';
      } else {
        return 'Usata recentemente ($days giorni fa)';
      }
    }

    if (data.completionRate > 0.9) {
      return 'Zona con alto tasso di completamento (${(data.completionRate * 100).toInt()}%)';
    }

    if (data.availablePointsCount > data.zone.totalPoints * 0.8) {
      return 'Molti punti disponibili (${data.availablePointsCount} su ${data.zone.totalPoints})';
    }

    return 'Buona opzione per la rotazione';
  }

  /// Calcola il livello di confidenza
  double _calculateConfidence(ZoneInjectionData data, double score) {
    // La confidenza aumenta con più dati storici
    double confidence = 0.5; // Base

    // Più iniezioni = più confidenza
    if (data.totalInjections >= 10) {
      confidence += 0.3;
    } else if (data.totalInjections >= 5) {
      confidence += 0.2;
    } else if (data.totalInjections >= 1) {
      confidence += 0.1;
    }

    // Score alto aumenta confidenza
    if (score > 0.8) {
      confidence += 0.2;
    } else if (score > 0.6) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Ottiene i fattori di score dettagliati
  Map<String, double> _getScoreFactors(ZoneInjectionData data, int maxDays) {
    return {
      'daysSinceLastUse': _normalizeDaysSinceLastUse(data, maxDays),
      'completionRate': data.completionRate,
      'availablePoints': data.availablePointsCount / data.zone.totalPoints,
    };
  }
}

/// Risultato della predizione per una zona
class ZonePrediction {
  final models.BodyZone zone;
  final double score;          // 0.0 - 1.0
  final String reason;         // Spiegazione leggibile
  final double confidence;     // 0.0 - 1.0
  final Map<String, double> factors; // Fattori dettagliati

  const ZonePrediction({
    required this.zone,
    required this.score,
    required this.reason,
    required this.confidence,
    this.factors = const {},
  });

  /// Score in percentuale
  int get scorePercentage => (score * 100).round();

  /// Confidenza in percentuale
  int get confidencePercentage => (confidence * 100).round();

  /// Livello di confidenza testuale
  String get confidenceLevel {
    if (confidence >= 0.75) return 'Alta';
    if (confidence >= 0.50) return 'Media';
    return 'Bassa';
  }

  /// Icona per il livello di score
  String get scoreIcon {
    if (score >= 0.8) return '🟢';
    if (score >= 0.6) return '🟡';
    if (score >= 0.4) return '🟠';
    return '🔴';
  }

  @override
  String toString() => 'ZonePrediction(${zone.displayName}: $scorePercentage%, $reason)';
}

