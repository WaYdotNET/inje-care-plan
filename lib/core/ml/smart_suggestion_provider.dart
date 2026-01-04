import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database_provider.dart';
import 'ml_data_collector.dart';
import 'zone_prediction_model.dart';
import 'time_optimizer.dart';
import 'adherence_scorer.dart';
import 'rotation_pattern_engine.dart';
import '../../models/rotation_pattern.dart';
import '../../models/body_zone.dart' as body_zone_model;

part 'smart_suggestion_provider.g.dart';

/// Provider per il MLDataCollector
@riverpod
MLDataCollector mlDataCollector(Ref ref) {
  final db = ref.watch(databaseProvider);
  return MLDataCollector(db);
}

/// Provider per i dati delle zone
@riverpod
Future<List<ZoneInjectionData>> zoneInjectionData(Ref ref) async {
  final collector = ref.watch(mlDataCollectorProvider);
  return collector.getZoneInjectionData();
}

/// Provider per i pattern temporali
@riverpod
Future<TimePatternData> timePatternData(Ref ref) async {
  final collector = ref.watch(mlDataCollectorProvider);
  return collector.getTimePatternData();
}

/// Provider per i dati di aderenza
@riverpod
Future<AdherenceData> adherenceData(Ref ref) async {
  final collector = ref.watch(mlDataCollectorProvider);
  return collector.getAdherenceData();
}

/// Provider per i pattern di skip
@riverpod
Future<SkipPatternData> skipPatternData(Ref ref) async {
  final collector = ref.watch(mlDataCollectorProvider);
  return collector.getSkipPatternData();
}

/// Provider per le predizioni di zona
@riverpod
Future<List<ZonePrediction>> zonePredictions(Ref ref) async {
  final zoneData = await ref.watch(zoneInjectionDataProvider.future);
  final model = ZonePredictionModel();
  return model.predict(zoneData);
}

/// Provider per la raccomandazione temporale
@riverpod
Future<TimeRecommendation> timeRecommendation(Ref ref) async {
  final timeData = await ref.watch(timePatternDataProvider.future);
  final adherenceData = await ref.watch(adherenceDataProvider.future);
  final optimizer = TimeOptimizer();
  return optimizer.analyze(timeData, adherenceData);
}

/// Provider per lo score di aderenza
@riverpod
Future<AdherenceScore> adherenceScore(Ref ref) async {
  final adherenceData = await ref.watch(adherenceDataProvider.future);
  final skipData = await ref.watch(skipPatternDataProvider.future);
  final scorer = AdherenceScorer();
  return scorer.analyze(adherenceData, skipData);
}

/// Provider principale che combina tutte le predizioni in un suggerimento smart
/// Usa il pattern di rotazione configurato dall'utente
@riverpod
Future<SmartSuggestion> smartSuggestion(Ref ref) async {
  try {
    // Ottieni il pattern configurato
    final pattern = await ref.watch(currentRotationPatternProvider.future);
    final timeRec = await ref.watch(timeRecommendationProvider.future);
    final adherenceScore = await ref.watch(adherenceScoreProvider.future);

    // In base al pattern, usa il motore appropriato
    ZonePrediction? topZone;
    List<ZonePrediction> allPredictions = [];

    if (pattern.type == RotationPatternType.smart) {
      // Usa il modello ML standard
      final zonePredictions = await ref.watch(zonePredictionsProvider.future);
      topZone = zonePredictions.isNotEmpty ? zonePredictions.first : null;
      allPredictions = zonePredictions;
    } else {
      // Usa il pattern engine configurato
      final patternSuggestion = await ref.watch(patternBasedZoneSuggestionProvider.future);
      if (patternSuggestion != null) {
        final zones = await ref.watch(bodyZonesProvider.future);
        final dbZone = zones.firstWhere(
          (z) => z.id == patternSuggestion.zoneId,
          orElse: () => zones.first,
        );
        // Converti il BodyZone del database in BodyZone del modello
        final modelZone = body_zone_model.BodyZone(
          id: dbZone.id,
          code: dbZone.code,
          name: dbZone.name,
          type: dbZone.type,
          side: dbZone.side,
          numberOfPoints: dbZone.numberOfPoints,
          isEnabled: dbZone.isEnabled,
          sortOrder: dbZone.sortOrder,
        );
        topZone = ZonePrediction(
          zone: modelZone,
          score: patternSuggestion.confidence,
          confidence: patternSuggestion.confidence,
          reason: patternSuggestion.reason,
        );
        allPredictions = [topZone];
      }
    }

    // Calcola la confidenza complessiva
    double overallConfidence = 0.5;
    if (topZone != null) {
      overallConfidence = (topZone.confidence + timeRec.confidence) / 2;
    }

    // Genera il messaggio principale
    String mainMessage;
    if (topZone != null) {
      mainMessage = 'Suggerisco ${topZone.zone.displayName}';
      if (timeRec.confidence > 0.5) {
        mainMessage += ' alle ${timeRec.formattedTime}';
      }
      // Aggiungi info sul pattern
      if (pattern.type != RotationPatternType.smart) {
        mainMessage += ' (${pattern.type.displayName})';
      }
    } else {
      mainMessage = 'Nessun suggerimento disponibile';
    }

    // Genera suggerimenti secondari
    final secondarySuggestions = <String>[];
    
    // Mostra il motivo del pattern
    if (topZone != null && pattern.type != RotationPatternType.smart) {
      secondarySuggestions.add(topZone.reason);
    } else if (allPredictions.length > 1) {
      secondarySuggestions.add(
        'Alternative: ${allPredictions.skip(1).take(2).map((z) => z.zone.displayName).join(", ")}'
      );
    }

    if (adherenceScore.recommendations.isNotEmpty) {
      secondarySuggestions.addAll(adherenceScore.recommendations.take(2));
    }

    return SmartSuggestion(
      topZonePrediction: topZone,
      timeRecommendation: timeRec,
      adherenceScore: adherenceScore,
      allZonePredictions: allPredictions,
      overallConfidence: overallConfidence,
      mainMessage: mainMessage,
      secondarySuggestions: secondarySuggestions,
      hasEnoughData: allPredictions.isNotEmpty,
      patternType: pattern.type,
    );
  } catch (e) {
    // In caso di errore, ritorna un suggerimento vuoto
    return SmartSuggestion.empty();
  }
}

/// Suggerimento smart completo
class SmartSuggestion {
  final ZonePrediction? topZonePrediction;
  final TimeRecommendation? timeRecommendation;
  final AdherenceScore? adherenceScore;
  final List<ZonePrediction> allZonePredictions;
  final double overallConfidence;
  final String mainMessage;
  final List<String> secondarySuggestions;
  final bool hasEnoughData;
  final RotationPatternType patternType;

  const SmartSuggestion({
    this.topZonePrediction,
    this.timeRecommendation,
    this.adherenceScore,
    this.allZonePredictions = const [],
    required this.overallConfidence,
    required this.mainMessage,
    this.secondarySuggestions = const [],
    required this.hasEnoughData,
    this.patternType = RotationPatternType.smart,
  });

  factory SmartSuggestion.empty() {
    return const SmartSuggestion(
      overallConfidence: 0,
      mainMessage: 'Inizia a registrare iniezioni per ricevere suggerimenti personalizzati',
      hasEnoughData: false,
    );
  }

  /// Nome del pattern attivo
  String get patternName => patternType.displayName;

  /// Confidenza in percentuale
  int get confidencePercentage => (overallConfidence * 100).round();

  /// Ha un suggerimento di zona valido
  bool get hasZoneSuggestion => topZonePrediction != null;

  /// Ha un suggerimento temporale valido
  bool get hasTimeSuggestion => 
      timeRecommendation != null && timeRecommendation!.confidence > 0.3;

  /// Livello di confidenza complessivo
  String get confidenceLevel {
    if (overallConfidence >= 0.75) return 'Alta';
    if (overallConfidence >= 0.50) return 'Media';
    if (overallConfidence >= 0.30) return 'Bassa';
    return 'Insufficiente';
  }

  /// Icona per la confidenza
  String get confidenceIcon {
    if (overallConfidence >= 0.75) return '🎯';
    if (overallConfidence >= 0.50) return '💡';
    if (overallConfidence >= 0.30) return '🤔';
    return '📊';
  }
}

