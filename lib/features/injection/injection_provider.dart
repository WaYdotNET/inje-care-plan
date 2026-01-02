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
