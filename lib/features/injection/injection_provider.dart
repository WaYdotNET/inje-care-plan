import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import 'injection_repository.dart';

/// Injection repository provider
final injectionRepositoryProvider = Provider<InjectionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InjectionRepository(database: db);
});

/// All injections provider
final injectionsProvider = StreamProvider<List<Injection>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjections();
});

/// Injections for a date range provider
final injectionsInRangeProvider = StreamProvider.family<
    List<Injection>,
    ({DateTime start, DateTime end})>((ref, range) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsInRange(range.start, range.end);
});

/// Injections by zone provider
final injectionsByZoneProvider =
    StreamProvider.family<List<Injection>, int>((ref, zoneId) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsByZone(zoneId);
});

/// Blacklisted points provider
final blacklistedPointsProvider = StreamProvider<List<BlacklistedPoint>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPoints();
});

/// Blacklisted points by zone provider
final blacklistedPointsByZoneProvider =
    StreamProvider.family<List<BlacklistedPoint>, int>((ref, zoneId) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPointsByZone(zoneId);
});

/// Body zones provider
final bodyZonesProvider = StreamProvider<List<BodyZone>>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBodyZones();
});

/// Therapy plan provider
final therapyPlanProvider = StreamProvider<TherapyPlan?>((ref) {
  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchTherapyPlan();
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

/// Selected day provider for calendar
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Focused day provider for calendar
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
