import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/injection_record.dart';
import '../../models/blacklisted_point.dart';
import '../../models/body_zone.dart';
import '../../models/therapy_plan.dart';
import '../auth/auth_provider.dart';
import 'injection_repository.dart';

/// Injection repository provider
final injectionRepositoryProvider = Provider<InjectionRepository>((ref) {
  return InjectionRepository();
});

/// All injections provider
final injectionsProvider = StreamProvider<List<InjectionRecord>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjections(user.uid);
});

/// Injections for a date range provider
final injectionsInRangeProvider = StreamProvider.family<
    List<InjectionRecord>,
    ({DateTime start, DateTime end})>((ref, range) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsInRange(user.uid, range.start, range.end);
});

/// Injections by zone provider
final injectionsByZoneProvider =
    StreamProvider.family<List<InjectionRecord>, int>((ref, zoneId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchInjectionsByZone(user.uid, zoneId);
});

/// Blacklisted points provider
final blacklistedPointsProvider = StreamProvider<List<BlacklistedPoint>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPoints(user.uid);
});

/// Blacklisted points by zone provider
final blacklistedPointsByZoneProvider =
    StreamProvider.family<List<BlacklistedPoint>, int>((ref, zoneId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBlacklistedPointsByZone(user.uid, zoneId);
});

/// Body zones provider
final bodyZonesProvider = StreamProvider<List<BodyZone>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchBodyZones(user.uid);
});

/// Therapy plan provider
final therapyPlanProvider = StreamProvider<TherapyPlan>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(TherapyPlan.defaults);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.watchTherapyPlan(user.uid);
});

/// Adherence stats provider
final adherenceStatsProvider = FutureProvider<({int completed, int total, double percentage})>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return (completed: 0, total: 0, percentage: 0.0);

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.getAdherenceStats(user.uid);
});

/// Suggested next point provider
final suggestedNextPointProvider =
    FutureProvider<({int zoneId, int pointNumber})?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(injectionRepositoryProvider);
  return repository.getSuggestedNextPoint(user.uid);
});

/// Selected day provider for calendar
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Focused day provider for calendar
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
