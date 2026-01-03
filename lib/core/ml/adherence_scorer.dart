import 'ml_data_collector.dart';

/// Valuta e predice l'aderenza dell'utente
class AdherenceScorer {
  /// Soglie per i livelli di rischio
  static const double _lowRiskThreshold = 0.80;
  static const double _mediumRiskThreshold = 0.60;

  /// Analizza i dati di aderenza e genera uno score
  AdherenceScore analyze(AdherenceData data, SkipPatternData skipData) {
    final riskLevel = _calculateRiskLevel(data);
    final prediction = _predictNextWeekAdherence(data);
    final recommendations = _generateRecommendations(data, skipData, riskLevel);
    final insights = _generateInsights(data, skipData);

    return AdherenceScore(
      currentRate: data.adherenceRate,
      riskLevel: riskLevel,
      trendDirection: _interpretTrend(data.trendDirection),
      currentStreak: data.currentStreak,
      predictedNextWeek: prediction,
      recommendations: recommendations,
      insights: insights,
      factors: {
        'adherenceRate': data.adherenceRate,
        'streak': data.currentStreak.toDouble(),
        'trend': data.trendDirection,
        'riskScore': _riskLevelToScore(riskLevel),
      },
    );
  }

  /// Determina il livello di rischio
  RiskLevel _calculateRiskLevel(AdherenceData data) {
    // Considera sia l'aderenza attuale che il trend
    final adherence = data.adherenceRate;
    final trend = data.trendDirection;

    // Aderenza molto bassa = alto rischio
    if (adherence < _mediumRiskThreshold) {
      return RiskLevel.high;
    }

    // Aderenza media con trend negativo = rischio medio-alto
    if (adherence < _lowRiskThreshold && trend < -0.1) {
      return RiskLevel.mediumHigh;
    }

    // Aderenza media = rischio medio
    if (adherence < _lowRiskThreshold) {
      return RiskLevel.medium;
    }

    // Aderenza alta con trend negativo = rischio basso-medio
    if (trend < -0.1) {
      return RiskLevel.lowMedium;
    }

    // Tutto bene
    return RiskLevel.low;
  }

  /// Predice l'aderenza per la prossima settimana
  double _predictNextWeekAdherence(AdherenceData data) {
    // Modello semplice: media pesata delle ultime settimane + trend
    if (data.weeklyTrend.isEmpty) {
      return data.adherenceRate;
    }

    final recentWeeks = data.weeklyTrend.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (recentWeeks.isEmpty) return data.adherenceRate;

    // Media delle ultime 3 settimane (se disponibili)
    final lastThree = recentWeeks.take(3).map((e) => e.value).toList();
    final average = lastThree.fold<double>(0, (sum, v) => sum + v) / lastThree.length;

    // Aggiusta con il trend
    final prediction = average + (data.trendDirection * 0.5);

    return prediction.clamp(0.0, 1.0);
  }

  /// Interpreta la direzione del trend
  TrendDirection _interpretTrend(double trend) {
    if (trend > 0.15) return TrendDirection.improving;
    if (trend > 0.05) return TrendDirection.slightlyImproving;
    if (trend < -0.15) return TrendDirection.declining;
    if (trend < -0.05) return TrendDirection.slightlyDeclining;
    return TrendDirection.stable;
  }

  /// Genera raccomandazioni personalizzate
  List<String> _generateRecommendations(
    AdherenceData data,
    SkipPatternData skipData,
    RiskLevel riskLevel,
  ) {
    final recommendations = <String>[];

    // Raccomandazioni basate sul rischio
    switch (riskLevel) {
      case RiskLevel.high:
        recommendations.add('Imposta promemoria più frequenti');
        recommendations.add('Considera di semplificare la rotazione delle zone');
        break;
      case RiskLevel.mediumHigh:
        recommendations.add('Rivedi i tuoi orari di iniezione');
        if (skipData.highestRiskDay != null) {
          recommendations.add('Presta attenzione il ${skipData.highestRiskDay}');
        }
        break;
      case RiskLevel.medium:
        if (data.currentStreak > 0) {
          recommendations.add('Ottimo! Mantieni la serie di ${data.currentStreak} iniezioni');
        } else {
          recommendations.add('Prova a stabilire una routine regolare');
        }
        break;
      case RiskLevel.lowMedium:
        recommendations.add('Buon lavoro! Il trend è leggermente negativo, resta attento');
        break;
      case RiskLevel.low:
        recommendations.add('Eccellente! Continua così');
        if (data.currentStreak >= 7) {
          recommendations.add('Serie attuale: ${data.currentStreak} giorni 🔥');
        }
        break;
    }

    // Raccomandazioni specifiche sui pattern di skip
    if (skipData.riskWeekdays.isNotEmpty) {
      final dayNames = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
      final riskDayNames = skipData.riskWeekdays.map((d) => dayNames[d]).join(', ');
      recommendations.add('Giorni più difficili: $riskDayNames');
    }

    return recommendations;
  }

  /// Genera insight sui pattern
  List<AdherenceInsight> _generateInsights(AdherenceData data, SkipPatternData skipData) {
    final insights = <AdherenceInsight>[];

    // Streak
    if (data.currentStreak > 0) {
      insights.add(AdherenceInsight(
        type: InsightType.positive,
        title: 'Serie attiva',
        description: '${data.currentStreak} iniezioni consecutive completate',
        icon: '🔥',
      ));
    }

    // Trend
    if (data.trendDirection > 0.1) {
      insights.add(AdherenceInsight(
        type: InsightType.positive,
        title: 'In miglioramento',
        description: 'L\'aderenza sta migliorando rispetto alle settimane precedenti',
        icon: '📈',
      ));
    } else if (data.trendDirection < -0.1) {
      insights.add(AdherenceInsight(
        type: InsightType.warning,
        title: 'In calo',
        description: 'L\'aderenza è diminuita recentemente',
        icon: '📉',
      ));
    }

    // Pattern di skip
    if (skipData.highestRiskDay != null) {
      insights.add(AdherenceInsight(
        type: InsightType.info,
        title: 'Giorno critico',
        description: '${skipData.highestRiskDay} è il giorno con più iniezioni saltate',
        icon: '📅',
      ));
    }

    // Aderenza alta
    if (data.adherenceRate >= 0.9) {
      insights.add(AdherenceInsight(
        type: InsightType.positive,
        title: 'Ottima aderenza',
        description: '${(data.adherenceRate * 100).round()}% di completamento!',
        icon: '⭐',
      ));
    }

    return insights;
  }

  double _riskLevelToScore(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 1.0;
      case RiskLevel.lowMedium:
        return 0.8;
      case RiskLevel.medium:
        return 0.6;
      case RiskLevel.mediumHigh:
        return 0.4;
      case RiskLevel.high:
        return 0.2;
    }
  }
}

/// Risultato dell'analisi di aderenza
class AdherenceScore {
  final double currentRate;
  final RiskLevel riskLevel;
  final TrendDirection trendDirection;
  final int currentStreak;
  final double predictedNextWeek;
  final List<String> recommendations;
  final List<AdherenceInsight> insights;
  final Map<String, double> factors;

  const AdherenceScore({
    required this.currentRate,
    required this.riskLevel,
    required this.trendDirection,
    required this.currentStreak,
    required this.predictedNextWeek,
    required this.recommendations,
    required this.insights,
    required this.factors,
  });

  /// Aderenza in percentuale
  int get currentRatePercentage => (currentRate * 100).round();

  /// Predizione in percentuale
  int get predictedPercentage => (predictedNextWeek * 100).round();

  /// Colore per il livello di rischio
  String get riskColor {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'green';
      case RiskLevel.lowMedium:
        return 'lightGreen';
      case RiskLevel.medium:
        return 'orange';
      case RiskLevel.mediumHigh:
        return 'deepOrange';
      case RiskLevel.high:
        return 'red';
    }
  }

  /// Icona per il trend
  String get trendIcon {
    switch (trendDirection) {
      case TrendDirection.improving:
        return '📈';
      case TrendDirection.slightlyImproving:
        return '↗️';
      case TrendDirection.stable:
        return '➡️';
      case TrendDirection.slightlyDeclining:
        return '↘️';
      case TrendDirection.declining:
        return '📉';
    }
  }
}

/// Livelli di rischio
enum RiskLevel {
  low,
  lowMedium,
  medium,
  mediumHigh,
  high,
}

/// Direzione del trend
enum TrendDirection {
  improving,
  slightlyImproving,
  stable,
  slightlyDeclining,
  declining,
}

/// Insight sull'aderenza
class AdherenceInsight {
  final InsightType type;
  final String title;
  final String description;
  final String icon;

  const AdherenceInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Tipo di insight
enum InsightType {
  positive,
  warning,
  info,
}

