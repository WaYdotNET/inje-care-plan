import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
import '../../core/utils/schedule_utils.dart';
import '../../models/rotation_pattern.dart';
import '../../models/therapy_plan.dart';
import 'injection_repository.dart';

/// Injection repository provider
final injectionRepositoryProvider = Provider<InjectionRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return InjectionRepository(database: database);
});

/// All injections provider
final injectionsProvider = StreamProvider<List<db.Injection>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjections();
});

/// Injections for a date range provider
final injectionsInRangeProvider = StreamProvider.family<
    List<db.Injection>,
    ({DateTime start, DateTime end})>((ref, range) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsInRange(range.start, range.end);
});

/// Injections by zone provider
final injectionsByZoneProvider =
    StreamProvider.family<List<db.Injection>, int>((ref, zoneId) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsByZone(zoneId);
});

/// Blacklisted points provider
final blacklistedPointsProvider = StreamProvider<List<db.BlacklistedPoint>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPoints();
});

/// Blacklisted points by zone provider
final blacklistedPointsByZoneProvider =
    StreamProvider.family<List<db.BlacklistedPoint>, int>((ref, zoneId) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPointsByZone(zoneId);
});

/// Body zones provider (raw from database)
final bodyZonesProvider = StreamProvider<List<db.BodyZone>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBodyZones();
});

/// Therapy plan provider (converts db.TherapyPlan to models.TherapyPlan)
final therapyPlanProvider = StreamProvider<TherapyPlan?>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchTherapyPlan().map((dbPlan) {
    if (dbPlan == null) return null;
    return TherapyPlan(
      injectionsPerWeek: dbPlan.injectionsPerWeek,
      weekDays: dbPlan.weekDays.split(',').map((s) => int.parse(s.trim())).toList(),
      preferredTime: dbPlan.preferredTime,
      startDate: dbPlan.startDate,
      // Default values for notification settings
      notificationMinutesBefore: 30,
      missedDoseReminderEnabled: true,
    );
  });
});

/// Adherence stats provider
final adherenceStatsProvider = FutureProvider<({int completed, int total, double percentage})>((ref) async {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.getAdherenceStats();
});

/// Suggested next point provider
final suggestedNextPointProvider =
    FutureProvider<({int zoneId, int pointNumber})?>((ref) async {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.getSuggestedNextPoint();
});

/// Point usage history provider for a specific zone
/// Returns map of pointNumber -> last usage date (null if never used)
final pointUsageHistoryProvider =
    FutureProvider.family<Map<int, DateTime?>, int>((ref, zoneId) async {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.getLastUsageForZone(zoneId);
});

/// Selected day notifier for calendar
class SelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime?>(SelectedDayNotifier.new);

/// Focused day notifier for calendar
class FocusedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void focus(DateTime day) => state = day;
}

final focusedDayProvider = NotifierProvider<FocusedDayNotifier, DateTime>(FocusedDayNotifier.new);

/// Weekly events provider - combina eventi reali + suggerimenti AI
final weeklyEventsProvider = FutureProvider<List<WeeklyEventData>>((ref) async {
  final repository = ref.watch(injectionRepositoryProvider);
  final therapyPlanAsync = ref.watch(therapyPlanProvider);

  final now = DateTime.now();
  // Inizio settimana (lunedì)
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
  // Fine settimana (domenica)
  final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

  // Ottieni eventi esistenti per la settimana
  final existingInjections = await repository.getInjectionsInRange(startOfWeek, endOfWeek);

  // Ottieni il piano terapeutico (active)
  final therapyPlan = therapyPlanAsync.value ?? TherapyPlan.defaults;

  // Genera lista eventi
  final events = <WeeklyEventData>[];

  for (var i = 0; i < 7; i++) {
    final day = startOfWeek.add(Duration(days: i));
    final dayOfWeek = day.weekday; // 1 = Mon, 7 = Sun

    // Controlla se questo giorno è nel piano terapeutico
    final isTherapyDay = therapyPlan.weekDays.contains(dayOfWeek);

    // Cerca evento esistente per questo giorno
    final existingEvent = existingInjections.where((inj) {
      return inj.scheduledAt.year == day.year &&
             inj.scheduledAt.month == day.month &&
             inj.scheduledAt.day == day.day;
    }).firstOrNull;

    if (existingEvent != null) {
      // Evento confermato
      events.add(WeeklyEventData(
        date: day,
        confirmedEvent: existingEvent,
        isTherapyDay: isTherapyDay,
      ));
    } else if (isTherapyDay) {
      // Giorno del piano senza evento - genera suggerimento coerente con rotazione e data
      final slot = ScheduleUtils.combinePreferredTime(day, therapyPlan.preferredTime);
      final suggestion = await ref.read(
        suggestedPointForDateProvider((scheduledAt: slot, ignoreInjectionId: null)).future,
      );
      events.add(WeeklyEventData(
        date: day,
        suggestion: suggestion,
        isTherapyDay: isTherapyDay,
        preferredTime: therapyPlan.preferredTime,
      ));
    } else {
      // Giorno di riposo (non nel piano terapeutico)
      events.add(WeeklyEventData(
        date: day,
        isTherapyDay: false,
      ));
    }
  }

  return events;
});

/// Dati per un evento settimanale
class WeeklyEventData {
  final DateTime date;
  final db.Injection? confirmedEvent;
  final ({int zoneId, int pointNumber})? suggestion;
  final bool isTherapyDay;
  final String? preferredTime;

  WeeklyEventData({
    required this.date,
    this.confirmedEvent,
    this.suggestion,
    this.isTherapyDay = false,
    this.preferredTime,
  });

  bool get isSuggested => confirmedEvent == null && suggestion != null;
  bool get isConfirmed => confirmedEvent != null;
  bool get isPast {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  String get status {
    if (confirmedEvent != null) return confirmedEvent!.status;
    if (isPast) return 'missed';
    return 'suggested';
  }
}

/// Provider per la prossima iniezione programmata (scheduled) oggi o in futuro
final nextScheduledInjectionProvider = Provider<db.Injection?>((ref) {
  final plan = ref.watch(therapyPlanProvider).asData?.value ?? TherapyPlan.defaults;
  final injections =
      ref.watch(injectionsProvider).asData?.value ?? const <db.Injection>[];
  final now = DateTime.now();

  final scheduled = injections
      .where((db.Injection i) =>
          i.status == 'scheduled' &&
          !i.scheduledAt.isBefore(now) &&
          plan.weekDays.contains(i.scheduledAt.weekday))
      .toList()
    ..sort((db.Injection a, db.Injection b) => a.scheduledAt.compareTo(b.scheduledAt));

  return scheduled.isNotEmpty ? scheduled.first : null;
});

typedef SuggestedForDateParams = ({DateTime scheduledAt, int? ignoreInjectionId});

/// Suggerimento coerente con pattern di rotazione e con la data selezionata.
/// Tiene conto delle iniezioni già presenti (di qualsiasi stato) ordinate per scheduledAt.
final suggestedPointForDateProvider =
    FutureProvider.family<({int zoneId, int pointNumber})?, SuggestedForDateParams>(
  (ref, params) async {
    final scheduledAt = params.scheduledAt;
    final ignoreId = params.ignoreInjectionId;

    final repository = ref.watch(injectionRepositoryProvider);
    final dbi = ref.watch(databaseProvider);

    final zones = await repository.getEnabledZones();
    if (zones.isEmpty) return null;

    final blacklist = await repository.getBlacklistedPoints();
    final blacklistedByZone = <int, Set<int>>{};
    for (final bp in blacklist) {
      (blacklistedByZone[bp.zoneId] ??= <int>{}).add(bp.pointNumber);
    }

    final injections = await repository.getInjectionsInRange(
      DateTime(2020, 1, 1),
      scheduledAt,
    );

    final prior = injections
        .where((i) => (ignoreId == null || i.id != ignoreId) && i.scheduledAt.isBefore(scheduledAt))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final activePlan = await dbi.getCurrentTherapyPlan();
    final patternType = activePlan != null
        ? RotationPatternTypeExtension.fromDatabaseValue(activePlan.rotationPatternType)
        : RotationPatternType.smart;

    final customSeq = (activePlan?.customPatternSequence ?? '').isNotEmpty
        ? activePlan!.customPatternSequence
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => int.parse(s.trim()))
            .toList()
        : null;

    final enabledZoneIds = zones.map((z) => z.id).toSet();

    int? pickZoneFromSequence(List<int> seq, int idx) {
      if (seq.isEmpty) return null;
      for (var step = 0; step < seq.length; step++) {
        final candidate = seq[(idx + step) % seq.length];
        if (enabledZoneIds.contains(candidate)) return candidate;
      }
      return zones.first.id;
    }

    int leastRecentlyUsedPoint(int zoneId) {
      final zone = zones.firstWhere((z) => z.id == zoneId, orElse: () => zones.first);
      final black = blacklistedByZone[zoneId] ?? <int>{};
      final lastUse = <int, DateTime?>{};
      for (var p = 1; p <= zone.numberOfPoints; p++) {
        if (black.contains(p)) continue;
        lastUse[p] = null;
      }
      for (final inj in prior.where((i) => i.zoneId == zoneId)) {
        if (!lastUse.containsKey(inj.pointNumber)) continue;
        // Keep latest usage (prior is sorted asc)
        lastUse[inj.pointNumber] = inj.scheduledAt;
      }
      int chosen = lastUse.keys.isNotEmpty ? lastUse.keys.first : 1;
      DateTime? oldest;
      for (final e in lastUse.entries) {
        if (e.value == null) return e.key;
        if (oldest == null || e.value!.isBefore(oldest)) {
          oldest = e.value;
          chosen = e.key;
        }
      }
      return chosen;
    }

    // SMART: punto mai usato o meno recente (considera scheduledAt di qualsiasi stato)
    if (patternType == RotationPatternType.smart) {
      ({int zoneId, int pointNumber})? best;
      DateTime? oldest;
      for (final zone in zones) {
        final black = blacklistedByZone[zone.id] ?? <int>{};
        for (var p = 1; p <= zone.numberOfPoints; p++) {
          if (black.contains(p)) continue;
          DateTime? last;
          for (final inj in prior.where((i) => i.zoneId == zone.id && i.pointNumber == p)) {
            // Keep latest usage (prior is sorted asc)
            last = inj.scheduledAt;
          }
          if (last == null) return (zoneId: zone.id, pointNumber: p);
          if (oldest == null || last.isBefore(oldest)) {
            oldest = last;
            best = (zoneId: zone.id, pointNumber: p);
          }
        }
      }
      return best;
    }

    // Simulazione consumo rotazione: ogni iniezione prima della data consuma 1 step.
    final consumed = prior.length;

    int? zoneId;
    switch (patternType) {
      case RotationPatternType.sequential:
        zoneId = pickZoneFromSequence(DefaultZoneSequence.standard, consumed);
        break;
      case RotationPatternType.clockwise:
        zoneId = pickZoneFromSequence(DefaultZoneSequence.clockwise, consumed);
        break;
      case RotationPatternType.counterClockwise:
        zoneId = pickZoneFromSequence(DefaultZoneSequence.counterClockwise, consumed);
        break;
      case RotationPatternType.custom:
        zoneId = pickZoneFromSequence(customSeq ?? DefaultZoneSequence.standard, consumed);
        break;
      case RotationPatternType.alternateSides:
        final last = prior.isNotEmpty ? prior.last : null;
        final lastZone = last == null
            ? null
            : zones.firstWhere(
                (z) => z.id == last.zoneId,
                orElse: () => zones.first,
              );
        final lastSide = lastZone?.side;
        final nextSide = (lastSide == 'left') ? 'right' : 'left';
        final sideZones = zones.where((z) => z.side == nextSide).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (sideZones.isEmpty) {
          zoneId = zones.first.id;
        } else {
          // If we previously injected a zone on the same side and there are multiple,
          // rotate within that side list.
          final lastZoneId = lastZone?.id;
          if (lastZoneId != null && sideZones.length > 1) {
            final idx = sideZones.indexWhere((z) => z.id == lastZoneId);
            zoneId = sideZones[(idx + 1) % sideZones.length].id;
          } else {
            zoneId = sideZones.first.id;
          }
        }
        break;
      case RotationPatternType.weeklyRotation:
        final weekStart = activePlan?.patternWeekStartDate ?? activePlan?.startDate ?? scheduledAt;
        final weeksPassed = scheduledAt.difference(weekStart).inDays ~/ 7;
        final groupOrder = DefaultZoneSequence.weeklyOrder;
        final group = groupOrder[weeksPassed % groupOrder.length];
        final groupZoneIds = DefaultZoneSequence.weeklyGroups[group] ?? const <int>[];
        final groupZones = zones.where((z) => groupZoneIds.contains(z.id)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (groupZones.isEmpty) {
          zoneId = zones.first.id;
        } else {
          db.Injection? lastInGroup;
          for (var i = prior.length - 1; i >= 0; i--) {
            final inj = prior[i];
            if (groupZoneIds.contains(inj.zoneId)) {
              lastInGroup = inj;
              break;
            }
          }
          if (lastInGroup != null) {
            final lastZoneId = lastInGroup.zoneId;
            final idx = groupZones.indexWhere((z) => z.id == lastZoneId);
            zoneId = groupZones[(idx + 1) % groupZones.length].id;
          } else {
            zoneId = groupZones.first.id;
          }
        }
        break;
      case RotationPatternType.smart:
        // Already handled above
        break;
    }

    if (zoneId == null) return null;
    final point = leastRecentlyUsedPoint(zoneId);
    return (zoneId: zoneId, pointNumber: point);
  },
);
