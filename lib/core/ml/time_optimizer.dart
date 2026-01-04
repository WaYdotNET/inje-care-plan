import 'ml_data_collector.dart';

/// Ottimizzatore per suggerire l'orario ideale per le iniezioni
class TimeOptimizer {
  /// Analizza i pattern temporali e suggerisce l'orario ottimale
  TimeRecommendation analyze(TimePatternData timeData, AdherenceData adherenceData) {
    // Se non ci sono dati sufficienti, usa valori predefiniti
    if (timeData.preferredHours.isEmpty) {
      return const TimeRecommendation(
        suggestedHour: 9,
        suggestedMinute: 0,
        confidence: 0.3,
        reason: 'Orario consigliato basato su pratiche standard',
        alternativeHours: [8, 10, 20],
        factors: {},
      );
    }

    // Trova l'ora con più completamenti
    final bestHour = timeData.preferredHours.first;
    
    // Calcola la confidenza basata sulla coerenza
    final confidence = _calculateConfidence(timeData);
    
    // Genera spiegazione
    final reason = _generateReason(timeData, bestHour);
    
    // Orari alternativi
    final alternatives = timeData.preferredHours.skip(1).take(2).toList();

    return TimeRecommendation(
      suggestedHour: bestHour,
      suggestedMinute: 0, // Arrotondiamo all'ora
      confidence: confidence,
      reason: reason,
      alternativeHours: alternatives,
      factors: {
        'preferredHour': bestHour.toDouble(),
        'averageHour': timeData.averageCompletionHour ?? bestHour.toDouble(),
        'dataPoints': timeData.completionByHour.values.fold<int>(0, (a, b) => a + b).toDouble(),
      },
    );
  }

  /// Suggerisce il giorno migliore della settimana
  DayRecommendation analyzeBestDay(TimePatternData timeData, SkipPatternData skipData) {
    // Trova il giorno con meno skip
    final safeDays = <int>[];
    for (var day = 1; day <= 7; day++) {
      if (!skipData.riskWeekdays.contains(day)) {
        safeDays.add(day);
      }
    }

    // Se tutti i giorni sono sicuri, prendi il più frequente per completamenti
    int bestDay = DateTime.monday;
    if (timeData.completionByWeekday.isNotEmpty) {
      final sorted = timeData.completionByWeekday.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      bestDay = sorted.first.key;
    }

    final dayNames = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];

    return DayRecommendation(
      suggestedDay: bestDay,
      suggestedDayName: dayNames[bestDay],
      riskDays: skipData.riskWeekdays,
      confidence: skipData.riskWeekdays.isEmpty ? 0.5 : 0.7,
      reason: skipData.riskWeekdays.isNotEmpty
          ? 'Evita ${skipData.highestRiskDay ?? "i giorni a rischio"} se possibile'
          : 'Tutti i giorni sono buoni per te',
    );
  }

  /// Calcola la finestra temporale ottimale
  TimeWindow calculateOptimalWindow(TimePatternData data) {
    if (data.averageCompletionHour == null) {
      // Default: mattina o sera
      return const TimeWindow(
        startHour: 8,
        endHour: 10,
        label: 'Mattina',
        confidence: 0.3,
      );
    }

    final avgHour = data.averageCompletionHour!.round();
    
    // Crea una finestra di 2 ore centrata sull'ora media
    final startHour = (avgHour - 1).clamp(6, 22);
    final endHour = (avgHour + 1).clamp(7, 23);

    // Determina il label
    String label;
    if (avgHour >= 6 && avgHour < 12) {
      label = 'Mattina';
    } else if (avgHour >= 12 && avgHour < 18) {
      label = 'Pomeriggio';
    } else {
      label = 'Sera';
    }

    return TimeWindow(
      startHour: startHour,
      endHour: endHour,
      label: label,
      confidence: _calculateConfidence(data),
    );
  }

  double _calculateConfidence(TimePatternData data) {
    final totalCompletions = data.completionByHour.values.fold<int>(0, (a, b) => a + b);
    
    if (totalCompletions < 5) return 0.3;
    if (totalCompletions < 10) return 0.5;
    if (totalCompletions < 20) return 0.7;
    return 0.9;
  }

  String _generateReason(TimePatternData data, int hour) {
    final completions = data.completionByHour[hour] ?? 0;
    final total = data.completionByHour.values.fold<int>(0, (a, b) => a + b);
    
    if (total == 0) return 'Orario suggerito';
    
    final percentage = (completions / total * 100).round();
    
    if (percentage > 50) {
      return 'Completi il $percentage% delle iniezioni alle ore $hour:00';
    } else if (percentage > 30) {
      return 'Orario frequente per te (ore $hour:00)';
    } else {
      return 'Basato sui tuoi pattern di completamento';
    }
  }
}

/// Raccomandazione per l'orario
class TimeRecommendation {
  final int suggestedHour;
  final int suggestedMinute;
  final double confidence;
  final String reason;
  final List<int> alternativeHours;
  final Map<String, double> factors;

  const TimeRecommendation({
    required this.suggestedHour,
    required this.suggestedMinute,
    required this.confidence,
    required this.reason,
    required this.alternativeHours,
    required this.factors,
  });

  /// Orario formattato (es. "09:00")
  String get formattedTime => 
      '${suggestedHour.toString().padLeft(2, '0')}:${suggestedMinute.toString().padLeft(2, '0')}';

  /// Livello di confidenza testuale
  String get confidenceLevel {
    if (confidence >= 0.75) return 'Alta';
    if (confidence >= 0.50) return 'Media';
    return 'Bassa';
  }
}

/// Raccomandazione per il giorno
class DayRecommendation {
  final int suggestedDay;
  final String suggestedDayName;
  final List<int> riskDays;
  final double confidence;
  final String reason;

  const DayRecommendation({
    required this.suggestedDay,
    required this.suggestedDayName,
    required this.riskDays,
    required this.confidence,
    required this.reason,
  });
}

/// Finestra temporale ottimale
class TimeWindow {
  final int startHour;
  final int endHour;
  final String label;
  final double confidence;

  const TimeWindow({
    required this.startHour,
    required this.endHour,
    required this.label,
    required this.confidence,
  });

  /// Range formattato (es. "08:00 - 10:00")
  String get formattedRange => 
      '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
}

