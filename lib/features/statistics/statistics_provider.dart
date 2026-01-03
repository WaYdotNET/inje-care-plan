import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/database_provider.dart';
import '../../core/database/app_database.dart';
import '../injection/zone_provider.dart';

part 'statistics_provider.g.dart';

/// Dati mensili per il trend
class MonthlyData {
  final DateTime month;
  final int injections;
  final int expected;
  final double adherenceRate;

  const MonthlyData({
    required this.month,
    required this.injections,
    required this.expected,
    required this.adherenceRate,
  });
}

/// Dati settimanali per il trend
class WeeklyData {
  final DateTime weekStart;
  final int injections;
  final int expected;
  final double adherenceRate;

  const WeeklyData({
    required this.weekStart,
    required this.injections,
    required this.expected,
    required this.adherenceRate,
  });
}

/// Utilizzo di una zona
class ZoneUsage {
  final int zoneId;
  final String zoneName;
  final String emoji;
  final int count;
  final double percentage;
  final DateTime? lastUsed;

  const ZoneUsage({
    required this.zoneId,
    required this.zoneName,
    required this.emoji,
    required this.count,
    required this.percentage,
    this.lastUsed,
  });
}

/// Statistiche complete delle iniezioni
class InjectionStats {
  final int totalInjections;
  final int totalExpected;
  final double adherenceRate;
  final List<ZoneUsage> zoneUsage;
  final List<MonthlyData> monthlyTrend;
  final List<WeeklyData> weeklyTrend;
  final int currentStreak;
  final int longestStreak;
  final DateTime? firstInjection;
  final DateTime? lastInjection;
  final int completedCount;
  final int skippedCount;
  final int scheduledCount;

  const InjectionStats({
    required this.totalInjections,
    required this.totalExpected,
    required this.adherenceRate,
    required this.zoneUsage,
    required this.monthlyTrend,
    required this.weeklyTrend,
    required this.currentStreak,
    required this.longestStreak,
    this.firstInjection,
    this.lastInjection,
    required this.completedCount,
    required this.skippedCount,
    required this.scheduledCount,
  });

  static const empty = InjectionStats(
    totalInjections: 0,
    totalExpected: 0,
    adherenceRate: 0,
    zoneUsage: [],
    monthlyTrend: [],
    weeklyTrend: [],
    currentStreak: 0,
    longestStreak: 0,
    completedCount: 0,
    skippedCount: 0,
    scheduledCount: 0,
  );
}

/// Periodo per il filtro statistiche
enum StatsPeriod {
  week,
  month,
  quarter,
  year,
  all,
}

/// Provider per il periodo selezionato
@riverpod
class StatsPeriodNotifier extends _$StatsPeriodNotifier {
  @override
  StatsPeriod build() => StatsPeriod.month;

  void setPeriod(StatsPeriod period) {
    state = period;
  }
}

/// Provider principale per le statistiche
@riverpod
Future<InjectionStats> injectionStats(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final zones = await ref.watch(zonesProvider.future);
  final period = ref.watch(statsPeriodProvider);

  // Calcola date di inizio/fine in base al periodo
  final now = DateTime.now();
  late final DateTime startDate;

  switch (period) {
    case StatsPeriod.week:
      startDate = now.subtract(const Duration(days: 7));
    case StatsPeriod.month:
      startDate = DateTime(now.year, now.month - 1, now.day);
    case StatsPeriod.quarter:
      startDate = DateTime(now.year, now.month - 3, now.day);
    case StatsPeriod.year:
      startDate = DateTime(now.year - 1, now.month, now.day);
    case StatsPeriod.all:
      startDate = DateTime(2000);
  }

  // Ottieni tutte le iniezioni nel periodo
  final allInjections = await db.getAllInjections();
  final injections = allInjections.where((i) =>
    i.scheduledAt.isAfter(startDate) || i.scheduledAt.isAtSameMomentAs(startDate)
  ).toList();

  // Conta per stato
  final completedCount = injections.where((i) => i.status == 'completed').length;
  final skippedCount = injections.where((i) => i.status == 'skipped').length;
  final scheduledCount = injections.where((i) => i.status == 'scheduled').length;

  // Calcola aderenza
  final totalDone = completedCount;
  final totalExpected = completedCount + skippedCount;
  final adherenceRate = totalExpected > 0 ? (totalDone / totalExpected) * 100 : 0.0;

  // Calcola utilizzo zone
  final zoneCountMap = <int, int>{};
  final zoneLastUsed = <int, DateTime>{};

  for (final injection in injections.where((i) => i.status == 'completed')) {
    zoneCountMap[injection.zoneId] = (zoneCountMap[injection.zoneId] ?? 0) + 1;
    final existing = zoneLastUsed[injection.zoneId];
    if (existing == null || injection.completedAt!.isAfter(existing)) {
      zoneLastUsed[injection.zoneId] = injection.completedAt!;
    }
  }

  final totalZoneUsage = zoneCountMap.values.fold(0, (a, b) => a + b);
  final zoneUsage = zones.map((zone) {
    final count = zoneCountMap[zone.id] ?? 0;
    return ZoneUsage(
      zoneId: zone.id,
      zoneName: zone.displayName,
      emoji: zone.emoji,
      count: count,
      percentage: totalZoneUsage > 0 ? (count / totalZoneUsage) * 100 : 0,
      lastUsed: zoneLastUsed[zone.id],
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  // Calcola trend mensile
  final monthlyTrend = _calculateMonthlyTrend(injections, startDate, now);

  // Calcola trend settimanale
  final weeklyTrend = _calculateWeeklyTrend(injections, startDate, now);

  // Calcola streak
  final streaks = _calculateStreaks(allInjections);

  // Date prima/ultima iniezione
  final completedInjections = injections.where((i) => i.status == 'completed').toList();
  completedInjections.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

  return InjectionStats(
    totalInjections: totalDone,
    totalExpected: totalExpected,
    adherenceRate: adherenceRate,
    zoneUsage: zoneUsage,
    monthlyTrend: monthlyTrend,
    weeklyTrend: weeklyTrend,
    currentStreak: streaks.$1,
    longestStreak: streaks.$2,
    firstInjection: completedInjections.isNotEmpty ? completedInjections.first.completedAt : null,
    lastInjection: completedInjections.isNotEmpty ? completedInjections.last.completedAt : null,
    completedCount: completedCount,
    skippedCount: skippedCount,
    scheduledCount: scheduledCount,
  );
}

List<MonthlyData> _calculateMonthlyTrend(
  List<Injection> injections,
  DateTime startDate,
  DateTime endDate,
) {
  final result = <MonthlyData>[];
  var current = DateTime(startDate.year, startDate.month);

  while (current.isBefore(endDate) || current.month == endDate.month && current.year == endDate.year) {
    final monthStart = current;
    final monthEnd = DateTime(current.year, current.month + 1, 0);

    final monthInjections = injections.where((i) =>
      i.scheduledAt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
      i.scheduledAt.isBefore(monthEnd.add(const Duration(days: 1)))
    ).toList();

    final completed = monthInjections.where((i) => i.status == 'completed').length;
    final expected = monthInjections.where((i) =>
      i.status == 'completed' || i.status == 'skipped'
    ).length;

    result.add(MonthlyData(
      month: monthStart,
      injections: completed,
      expected: expected,
      adherenceRate: expected > 0 ? (completed / expected) * 100 : 0,
    ));

    current = DateTime(current.year, current.month + 1);
  }

  return result;
}

List<WeeklyData> _calculateWeeklyTrend(
  List<Injection> injections,
  DateTime startDate,
  DateTime endDate,
) {
  final result = <WeeklyData>[];

  // Trova il lunedì della settimana di inizio
  var current = startDate.subtract(Duration(days: startDate.weekday - 1));

  while (current.isBefore(endDate)) {
    final weekStart = current;
    final weekEnd = current.add(const Duration(days: 6));

    final weekInjections = injections.where((i) =>
      i.scheduledAt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
      i.scheduledAt.isBefore(weekEnd.add(const Duration(days: 1)))
    ).toList();

    final completed = weekInjections.where((i) => i.status == 'completed').length;
    final expected = weekInjections.where((i) =>
      i.status == 'completed' || i.status == 'skipped'
    ).length;

    result.add(WeeklyData(
      weekStart: weekStart,
      injections: completed,
      expected: expected,
      adherenceRate: expected > 0 ? (completed / expected) * 100 : 0,
    ));

    current = current.add(const Duration(days: 7));
  }

  return result;
}

(int currentStreak, int longestStreak) _calculateStreaks(List<Injection> injections) {
  // Ordina per data schedulata
  final sorted = injections
    .where((i) => i.status == 'completed' || i.status == 'skipped')
    .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  if (sorted.isEmpty) return (0, 0);

  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  for (final injection in sorted) {
    if (injection.status == 'completed') {
      tempStreak++;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
    } else {
      tempStreak = 0;
    }
  }

  // Calcola streak corrente (dall'ultima iniezione ad oggi)
  final now = DateTime.now();
  final recentInjections = sorted.where((i) =>
    i.scheduledAt.isBefore(now.add(const Duration(days: 1)))
  ).toList();

  if (recentInjections.isNotEmpty) {
    // Conta da oggi all'indietro
    for (var i = recentInjections.length - 1; i >= 0; i--) {
      if (recentInjections[i].status == 'completed') {
        currentStreak++;
      } else {
        break;
      }
    }
  }

  return (currentStreak, longestStreak);
}

/// Provider per le statistiche della zona specifica
@riverpod
Future<ZoneUsage?> zoneStats(Ref ref, int zoneId) async {
  final stats = await ref.watch(injectionStatsProvider.future);
  return stats.zoneUsage.where((z) => z.zoneId == zoneId).firstOrNull;
}
