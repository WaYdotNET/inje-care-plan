import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
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

  // Ottieni il piano terapeutico
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
      // Giorno del piano senza evento - genera suggerimento
      final suggestion = await repository.getSuggestedNextPoint();
      events.add(WeeklyEventData(
        date: day,
        suggestion: suggestion,
        isTherapyDay: isTherapyDay,
        preferredTime: therapyPlan.preferredTime,
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
