import '../database/app_database.dart';
import '../../models/body_zone.dart' as models;

/// Raccoglie e prepara i dati per i modelli ML
class MLDataCollector {
  final AppDatabase _db;

  MLDataCollector(this._db);

  /// Dati di iniezione per zona
  Future<List<ZoneInjectionData>> getZoneInjectionData() async {
    final zones = await _db.getAllZones();
    final injections = await _db.getAllInjections();
    final blacklisted = await _db.getAllBlacklistedPoints();

    final result = <ZoneInjectionData>[];

    for (final dbZone in zones) {
      final zone = models.BodyZone.fromDatabase(dbZone);
      
      // Iniezioni per questa zona
      final zoneInjections = injections.where((i) => i.zoneId == zone.id).toList();
      
      // Statistiche
      final completed = zoneInjections.where((i) => i.status == 'completed').toList();
      final skipped = zoneInjections.where((i) => i.status == 'skipped').toList();
      
      // Ultima iniezione completata
      DateTime? lastCompleted;
      if (completed.isNotEmpty) {
        completed.sort((a, b) => (b.completedAt ?? b.scheduledAt).compareTo(a.completedAt ?? a.scheduledAt));
        lastCompleted = completed.first.completedAt ?? completed.first.scheduledAt;
      }
      
      // Punti in blacklist
      final blacklistedPoints = blacklisted.where((b) => b.zoneId == zone.id).length;
      
      // Tasso di completamento
      final total = completed.length + skipped.length;
      final completionRate = total > 0 ? completed.length / total : 0.0;
      
      result.add(ZoneInjectionData(
        zone: zone,
        totalInjections: zoneInjections.length,
        completedCount: completed.length,
        skippedCount: skipped.length,
        lastInjectionDate: lastCompleted,
        daysSinceLastInjection: lastCompleted != null 
            ? DateTime.now().difference(lastCompleted).inDays 
            : null,
        completionRate: completionRate,
        blacklistedPointsCount: blacklistedPoints,
        availablePointsCount: zone.totalPoints - blacklistedPoints,
      ));
    }

    return result;
  }

  /// Pattern temporali delle iniezioni
  Future<TimePatternData> getTimePatternData() async {
    final injections = await _db.getAllInjections();
    final completed = injections.where((i) => 
      i.status == 'completed' && i.completedAt != null
    ).toList();

    if (completed.isEmpty) {
      return const TimePatternData(
        preferredHours: [],
        completionByWeekday: {},
        completionByHour: {},
        averageCompletionHour: null,
      );
    }

    // Conta per ora del giorno
    final byHour = <int, int>{};
    for (final inj in completed) {
      final hour = inj.completedAt!.hour;
      byHour[hour] = (byHour[hour] ?? 0) + 1;
    }

    // Conta per giorno della settimana
    final byWeekday = <int, int>{};
    for (final inj in completed) {
      final weekday = inj.completedAt!.weekday;
      byWeekday[weekday] = (byWeekday[weekday] ?? 0) + 1;
    }

    // Ore preferite (top 3)
    final sortedHours = byHour.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredHours = sortedHours.take(3).map((e) => e.key).toList();

    // Media ore
    double? avgHour;
    if (completed.isNotEmpty) {
      final sumHours = completed.fold<int>(0, (sum, i) => sum + i.completedAt!.hour);
      avgHour = sumHours / completed.length;
    }

    return TimePatternData(
      preferredHours: preferredHours,
      completionByWeekday: byWeekday,
      completionByHour: byHour,
      averageCompletionHour: avgHour,
    );
  }

  /// Statistiche di aderenza recenti
  Future<AdherenceData> getAdherenceData({int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final injections = await _db.getInjectionsByDateRange(startDate, now);
    
    final completed = injections.where((i) => i.status == 'completed').length;
    final skipped = injections.where((i) => i.status == 'skipped').length;
    final scheduled = injections.where((i) => i.status == 'scheduled').length;
    final total = completed + skipped;

    // Trend settimanale
    final weeklyTrend = <int, double>{};
    for (var week = 0; week < (days / 7).ceil(); week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weekInjections = injections.where((i) =>
        i.scheduledAt.isAfter(weekStart) && i.scheduledAt.isBefore(weekEnd)
      ).toList();
      
      final weekCompleted = weekInjections.where((i) => i.status == 'completed').length;
      final weekTotal = weekInjections.where((i) => 
        i.status == 'completed' || i.status == 'skipped'
      ).length;
      
      weeklyTrend[week] = weekTotal > 0 ? weekCompleted / weekTotal : 0.0;
    }

    // Calcola streak
    int currentStreak = 0;
    final sortedInjections = injections
      .where((i) => i.status == 'completed' || i.status == 'skipped')
      .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    
    for (final inj in sortedInjections) {
      if (inj.status == 'completed') {
        currentStreak++;
      } else {
        break;
      }
    }

    // Trend (miglioramento/peggioramento)
    double trend = 0;
    if (weeklyTrend.length >= 2) {
      final recentWeeks = weeklyTrend.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      if (recentWeeks.length >= 2) {
        trend = recentWeeks[0].value - recentWeeks[1].value;
      }
    }

    return AdherenceData(
      periodDays: days,
      totalCompleted: completed,
      totalSkipped: skipped,
      totalScheduled: scheduled,
      adherenceRate: total > 0 ? completed / total : 0.0,
      weeklyTrend: weeklyTrend,
      currentStreak: currentStreak,
      trendDirection: trend,
    );
  }

  /// Pattern di skip (giorni/orari più a rischio)
  Future<SkipPatternData> getSkipPatternData() async {
    final injections = await _db.getAllInjections();
    final skipped = injections.where((i) => i.status == 'skipped').toList();

    if (skipped.isEmpty) {
      return const SkipPatternData(
        riskWeekdays: [],
        riskHours: [],
        skipsByWeekday: {},
        commonReasons: {},
      );
    }

    // Skip per giorno della settimana
    final byWeekday = <int, int>{};
    for (final inj in skipped) {
      final weekday = inj.scheduledAt.weekday;
      byWeekday[weekday] = (byWeekday[weekday] ?? 0) + 1;
    }

    // Giorni più a rischio
    final sortedWeekdays = byWeekday.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final riskWeekdays = sortedWeekdays.take(2).map((e) => e.key).toList();

    return SkipPatternData(
      riskWeekdays: riskWeekdays,
      riskHours: [], // Non abbiamo l'ora schedulata
      skipsByWeekday: byWeekday,
      commonReasons: {}, // TODO: analizzare note se disponibili
    );
  }
}

/// Dati di iniezione per una singola zona
class ZoneInjectionData {
  final models.BodyZone zone;
  final int totalInjections;
  final int completedCount;
  final int skippedCount;
  final DateTime? lastInjectionDate;
  final int? daysSinceLastInjection;
  final double completionRate;
  final int blacklistedPointsCount;
  final int availablePointsCount;

  const ZoneInjectionData({
    required this.zone,
    required this.totalInjections,
    required this.completedCount,
    required this.skippedCount,
    this.lastInjectionDate,
    this.daysSinceLastInjection,
    required this.completionRate,
    required this.blacklistedPointsCount,
    required this.availablePointsCount,
  });

  /// Zone mai usata
  bool get neverUsed => totalInjections == 0;

  /// Zona con tutti punti in blacklist
  bool get fullyBlacklisted => availablePointsCount <= 0;
}

/// Pattern temporali
class TimePatternData {
  final List<int> preferredHours;
  final Map<int, int> completionByWeekday;
  final Map<int, int> completionByHour;
  final double? averageCompletionHour;

  const TimePatternData({
    required this.preferredHours,
    required this.completionByWeekday,
    required this.completionByHour,
    this.averageCompletionHour,
  });

  /// Orario suggerito come TimeOfDay
  (int hour, int minute)? get suggestedTime {
    if (averageCompletionHour == null) return null;
    final hour = averageCompletionHour!.floor();
    final minute = ((averageCompletionHour! - hour) * 60).round();
    return (hour, minute);
  }
}

/// Dati di aderenza
class AdherenceData {
  final int periodDays;
  final int totalCompleted;
  final int totalSkipped;
  final int totalScheduled;
  final double adherenceRate;
  final Map<int, double> weeklyTrend;
  final int currentStreak;
  final double trendDirection; // Positivo = miglioramento, Negativo = peggioramento

  const AdherenceData({
    required this.periodDays,
    required this.totalCompleted,
    required this.totalSkipped,
    required this.totalScheduled,
    required this.adherenceRate,
    required this.weeklyTrend,
    required this.currentStreak,
    required this.trendDirection,
  });

  /// Aderenza in percentuale
  double get adherencePercentage => adherenceRate * 100;

  /// Trend interpretato
  String get trendDescription {
    if (trendDirection > 0.1) return 'In miglioramento';
    if (trendDirection < -0.1) return 'In calo';
    return 'Stabile';
  }
}

/// Pattern di skip
class SkipPatternData {
  final List<int> riskWeekdays;
  final List<int> riskHours;
  final Map<int, int> skipsByWeekday;
  final Map<String, int> commonReasons;

  const SkipPatternData({
    required this.riskWeekdays,
    required this.riskHours,
    required this.skipsByWeekday,
    required this.commonReasons,
  });

  /// Nome del giorno più a rischio
  String? get highestRiskDay {
    if (riskWeekdays.isEmpty) return null;
    const days = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
    return days[riskWeekdays.first];
  }
}

