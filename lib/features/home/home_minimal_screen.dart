import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart' as model;
import '../../models/injection_record.dart' as inj;
import '../../models/therapy_plan.dart';
import '../../app/router.dart';
import '../../core/services/missed_injection_service.dart';
import '../../core/services/notification_settings_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/ml/rotation_pattern_engine.dart';
import '../../core/utils/schedule_utils.dart';
import '../injection/injection_provider.dart' hide bodyZonesProvider;
import '../injection/zone_provider.dart';
import '../injection/widgets/body_silhouette_editor.dart';

/// Home minimalista con focus sulla prossima iniezione
class HomeMinimalScreen extends ConsumerStatefulWidget {
  const HomeMinimalScreen({super.key});

  @override
  ConsumerState<HomeMinimalScreen> createState() => _HomeMinimalScreenState();
}

class _HomeMinimalScreenState extends ConsumerState<HomeMinimalScreen> {
  bool _weekFillPromptShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(zonesProvider);
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final nextScheduled = ref.watch(nextScheduledInjectionProvider);

    // Controlla iniezioni mancate all'avvio (una volta per sessione container)
    ref.watch(checkMissedInjectionsProvider);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
    final weekInjectionsAsync = ref.watch(
      injectionsInRangeProvider((start: startOfWeek, end: endOfWeek)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('InjeCare Plan'),
        actions: [
          // Menu con link rapidi
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              switch (value) {
                case 'history':
                  context.go(AppRoutes.history);
                case 'statistics':
                  context.push(AppRoutes.statistics);
                case 'guide':
                  context.push(AppRoutes.help);
                case 'info':
                  context.push(AppRoutes.info);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Storico'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Statistiche'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'guide',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Guida'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Info'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          // Settings
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.settings, size: 18),
            ),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: zonesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _ErrorView(message: e.toString()),
          data: (zones) {
            final plan = therapyPlanAsync.asData?.value;
            final weekEmpty = weekInjectionsAsync.asData?.value.isEmpty ?? false;
            if (!_weekFillPromptShown && plan != null && weekEmpty) {
              _weekFillPromptShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showFillWeekDialog(context, plan, startOfWeek);
              });
            }

            final resolvedPlan = plan ?? TherapyPlan.defaults;
            final displayDate = nextScheduled?.scheduledAt ??
                ScheduleUtils.nextTherapySlot(from: DateTime.now(), plan: resolvedPlan);

            // Suggerimento coerente con rotazione e data (solo se non c'è già una scheduled valida)
            final suggestedForDateAsync = ref.watch(
              suggestedPointForDateProvider((scheduledAt: displayDate, ignoreInjectionId: null)),
            );

            return suggestedForDateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => _ErrorView(message: e.toString()),
              data: (suggestedForDate) {
                // Se c'è un'iniezione schedulata valida (coerente con giorni piano), mostra quella
                model.BodyZone? zone;
                int? pointNumber;
                int? scheduledInjectionId;

                if (nextScheduled != null) {
                  scheduledInjectionId = nextScheduled.id;
                  pointNumber = nextScheduled.pointNumber;
                  zone = zones.firstWhere(
                    (z) => z.id == nextScheduled.zoneId,
                    orElse: () => zones.first,
                  );
                } else if (suggestedForDate != null) {
                  zone = zones.firstWhere(
                    (z) => z.id == suggestedForDate.zoneId,
                    orElse: () => zones.first,
                  );
                  pointNumber = suggestedForDate.pointNumber;
                }

                final isScheduled = nextScheduled != null;
                final view = _getViewForZone(zone?.type);

                final displayTime = DateFormat('HH:mm').format(displayDate);

                return GestureDetector(
                  onTap: zone != null
                      ? () {
                          if (isScheduled && scheduledInjectionId != null) {
                            _showCompleteDialog(
                              context,
                              scheduledInjectionId,
                              zone!,
                              pointNumber ?? 1,
                            );
                          } else {
                            _navigateToRecord(context, zone!.id, displayDate);
                          }
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _DateHeader(
                          isDark: isDark,
                          isScheduled: isScheduled,
                          displayDate: displayDate,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _MainCard(
                            zone: zone,
                            displayDate: displayDate,
                            displayTime: displayTime,
                            view: view,
                            isDark: isDark,
                            isScheduled: isScheduled,
                            pointNumber: pointNumber,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (zone != null)
                          Text(
                            isScheduled ? 'Tocca per completare' : 'Tocca per registrare',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  BodyView _getViewForZone(String? zoneType) {
    if (zoneType == null) return BodyView.front;
    // Zone posteriori
    if (zoneType == 'buttock') return BodyView.back;
    // Zone frontali
    return BodyView.front;
  }

  void _navigateToRecord(BuildContext context, int zoneId, DateTime scheduledAt) {
    context.push(
      AppRoutes.bodyMap,
      extra: {
        'zoneId': zoneId,
        'scheduledDate': scheduledAt,
      },
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    int injectionId,
    model.BodyZone zone,
    int pointNumber,
  ) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma iniezione'),
        content: Text(
          'Vuoi segnare ${zone.pointLabel(pointNumber)} come completata?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sì, completata'),
          ),
        ],
      ),
    );

    if (shouldComplete == true && context.mounted) {
      final repository = ref.read(injectionRepositoryProvider);

      await repository.completeInjection(injectionId);

      // Refresh dei providers
      ref.invalidate(nextScheduledInjectionProvider);
      ref.invalidate(weeklyEventsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('✓ ${zone.pointLabel(pointNumber)} completata!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
      }
    }
  }

  Future<void> _showFillWeekDialog(
    BuildContext context,
    TherapyPlan plan,
    DateTime startOfWeek,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pianificare questa settimana?'),
        content: const Text(
          'Questa settimana è vuota.\n\nVuoi creare automaticamente le iniezioni '
          'programmate secondo il tuo piano e il pattern di rotazione?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sì, pianifica'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _fillWeekFromPlan(plan, startOfWeek);
    }
  }

  Future<void> _fillWeekFromPlan(
    TherapyPlan plan,
    DateTime startOfWeek,
  ) async {
    final repository = ref.read(injectionRepositoryProvider);
    final notificationSettings = ref.read(notificationSettingsProvider);
    final now = DateTime.now();

    // Evita doppie pianificazioni: ricontrolla la settimana
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
    final existing = await ref
        .read(injectionsInRangeProvider((start: startOfWeek, end: endOfWeek)).future);
    if (existing.isNotEmpty) return;

    final parts = plan.preferredTime.split(':');
    final hour = parts.length >= 2 ? int.tryParse(parts[0]) ?? 20 : 20;
    final minute = parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;

    // Pianifica solo i giorni del piano che sono ancora nel futuro
    final daysToPlan = <DateTime>[];
    for (var i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (!plan.weekDays.contains(day.weekday)) continue;
      final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);
      if (scheduledAt.isBefore(now)) continue;
      daysToPlan.add(day);
    }

    if (daysToPlan.isEmpty) return;

    int created = 0;
    for (final day in daysToPlan) {
      final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);
      final suggested = await ref.read(
        suggestedPointForDateProvider((scheduledAt: scheduledAt, ignoreInjectionId: null)).future,
      );
      if (suggested == null) continue;

      final record = inj.InjectionRecord(
        zoneId: suggested.zoneId,
        pointNumber: suggested.pointNumber,
        scheduledAt: scheduledAt,
        status: inj.InjectionStatus.scheduled,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createInjection(record);
      created++;

      // Avanza il pattern (persistente) per la prossima proposta
      final zones = await ref.read(bodyZonesProvider.future);
      final usedZone = zones.firstWhere((z) => z.id == suggested.zoneId);
      final dbi = ref.read(databaseProvider);
      final patternService = RotationPatternService(dbi);
      await patternService.advancePattern(usedZone.id, usedZone.side);
      ref.invalidate(currentRotationPatternProvider);
      ref.invalidate(rotationPatternEngineProvider);

      if (notificationSettings.enabled &&
          notificationSettings.permissionsGranted) {
        await NotificationService.instance.scheduleInjectionNotifications(
          injection: record,
          minutesBefore: notificationSettings.minutesBefore,
          missedDoseReminder: notificationSettings.missedDoseReminder,
        );
      }
    }

    // Refresh UI
    ref.invalidate(injectionsProvider);
    ref.invalidate(weeklyEventsProvider);
    ref.invalidate(nextScheduledInjectionProvider);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Pianificate $created iniezioni per questa settimana'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }
}

/// Header con la data corrente
class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.isDark,
    required this.displayDate,
    this.isScheduled = false,
  });

  final bool isDark;
  final bool isScheduled;
  final DateTime displayDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM', 'it_IT');

    return Column(
      children: [
        Text(
          dateFormat.format(displayDate),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isScheduled ? 'Iniezione programmata' : 'Prossima iniezione',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isScheduled
                ? (isDark ? AppColors.darkGold : AppColors.dawnGold)
                : (isDark ? AppColors.darkMuted : AppColors.dawnMuted),
          ),
        ),
      ],
    );
  }
}

/// Card principale con silhouette e info iniezione
class _MainCard extends StatelessWidget {
  const _MainCard({
    required this.zone,
    required this.displayDate,
    required this.displayTime,
    required this.view,
    required this.isDark,
    this.isScheduled = false,
    this.pointNumber,
  });

  final model.BodyZone? zone;
  final DateTime displayDate;
  final String displayTime;
  final BodyView view;
  final bool isDark;
  final bool isScheduled;
  final int? pointNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (zone == null) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nessuna iniezione programmata',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configura il tuo piano terapeutico nelle impostazioni',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayPointNumber = pointNumber ?? 1; // Usa il punto schedulato o default

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Silhouette con punto evidenziato (scala proporzionale)
            // Usa le stesse coordinate di generateDefaultPointPositions
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Scala i punti in base all'altezza disponibile
                  // Base: 400px = scala 1.0, più piccolo = scala ridotta
                  final scale = (constraints.maxHeight / 400).clamp(0.5, 1.0);

                  // Usa le coordinate esatte da generateDefaultPointPositions
                  final allPoints = generateDefaultPointPositions(
                    zone!.numberOfPoints,
                    zone!.type,
                    zone!.side,
                  );

                  // Trova il punto corretto o usa il primo
                  final targetPoint = allPoints.firstWhere(
                    (p) => p.pointNumber == displayPointNumber,
                    orElse: () => allPoints.isNotEmpty
                        ? allPoints.first
                        : PositionedPoint(pointNumber: 1, x: 0.5, y: 0.5),
                  );

                  return BodySilhouetteEditor(
                    points: [targetPoint],
                    onPointMoved: (p, x, y, v) {},
                    onPointTapped: (p) {},
                    selectedPointNumber: displayPointNumber,
                    initialView: view,
                    editable: false,
                    zoneType: zone!.type,
                    pointScale: scale,
                  );
                },
              ),
            ),

            const Divider(),

            // Info zona suggerita
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  // Nome zona
                  Text(
                    zone!.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Orario suggerito
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('EEEE d MMM', 'it_IT').format(displayDate)} alle $displayTime',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pattern indicator (minimal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isScheduled ? 'Programmata' : 'Suggerita',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Vista errore
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
