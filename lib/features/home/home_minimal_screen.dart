import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/completion_time_dialog.dart';
import '../../core/widgets/next_injection_hero_card.dart';
import '../../core/widgets/status_legend.dart';
import '../../core/widgets/week_dots.dart';
import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart' as model;
import '../../models/injection_record.dart' as inj;
import '../../models/therapy_plan.dart';
import '../../app/router.dart';
import '../../core/services/diagnostic_log_service.dart';
import '../../core/services/missed_injection_service.dart';
import '../../core/services/notification_settings_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_settings_provider.dart';
import '../../core/ml/rotation_pattern_engine.dart';
import '../../core/utils/schedule_utils.dart';
import '../injection/injection_provider.dart' hide bodyZonesProvider;
import '../injection/injection_repository.dart';
import '../injection/zone_provider.dart';
import '../injection/widgets/body_silhouette_editor.dart';
import 'home_layout_provider.dart';

/// Home minimalista con focus sulla prossima iniezione
class HomeMinimalScreen extends ConsumerStatefulWidget {
  const HomeMinimalScreen({super.key});

  @override
  ConsumerState<HomeMinimalScreen> createState() => _HomeMinimalScreenState();
}

class _HomeMinimalScreenState extends ConsumerState<HomeMinimalScreen>
    with WidgetsBindingObserver {
  bool _weekFillPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Re-check sistema permessi all'avvio (l'utente potrebbe averli revocati
    // manualmente nelle impostazioni Android tra una sessione e l'altra).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSettingsProvider.notifier).refreshPermissionStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationSettingsProvider.notifier).refreshPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // zonesAsync and nextScheduled are watched in _silhouetteBody; watch here
    // only the providers needed by the fill-week prompt (always active).
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    ref.watch(zonesProvider); // keep subscription alive for cache warming
    ref.watch(nextScheduledInjectionProvider); // same

    // Controlla iniezioni mancate all'avvio (una volta per sessione container)
    ref.watch(checkMissedInjectionsProvider);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
    final weekInjectionsAsync = ref.watch(
      injectionsInRangeProvider((start: startOfWeek, end: endOfWeek)),
    );
    final homeLayout = ref.watch(homeLayoutProvider);

    // Fill-week prompt: triggered regardless of active layout (once per session).
    final plan = therapyPlanAsync.asData?.value;
    final weekEmpty = weekInjectionsAsync.asData?.value.isEmpty ?? false;
    if (!_weekFillPromptShown && plan != null && weekEmpty) {
      _weekFillPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showFillWeekDialog(context, plan);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('InjeCare Plan'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsDuotone.calendarPlus),
            tooltip: 'Pianifica iniezioni',
            onPressed: () {
              final plan = ref.read(therapyPlanProvider).asData?.value ??
                  TherapyPlan.defaults;
              _showFillWeekDialog(context, plan);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _NotificationPermissionBanner(),
            _LayoutToggle(
              current: homeLayout,
              onSelect: (l) => ref.read(homeLayoutProvider.notifier).setLayout(l),
            ),
            Expanded(
              child: homeLayout == HomeLayout.week
                  ? _weekBody(context)
                  : _silhouetteBody(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, {bool fill = false}) {
    final next = ref.watch(nextScheduledInjectionProvider);
    final allInjections =
        ref.watch(injectionsProvider).asData?.value ?? const <db.Injection>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasCompletedToday = allInjections.any(
      (i) =>
          i.status == 'completed' &&
          DateTime(
                i.scheduledAt.year,
                i.scheduledAt.month,
                i.scheduledAt.day,
              ) ==
              today,
    );
    final state = heroStateFor(
      nextScheduledAt: next?.scheduledAt,
      now: now,
      hasCompletedToday: hasCompletedToday,
    );

    switch (state) {
      case HeroState.allDone:
        return _HeroMessageCard(
          gradient: AppTokens.successGradient,
          icon: PhosphorIconsDuotone.checkCircle,
          text: 'Per oggi è tutto',
          fill: fill,
        );
      case HeroState.none:
        return _HeroMessageCard.neutral(
          icon: PhosphorIconsDuotone.calendarBlank,
          text: 'Nessuna iniezione programmata · tocca per pianificare',
          fill: fill,
          onTap: () {
            final plan = ref.read(therapyPlanProvider).asData?.value ??
                TherapyPlan.defaults;
            _showFillWeekDialog(context, plan);
          },
        );
      case HeroState.upcoming:
      case HeroState.overdue:
      case HeroState.future:
        final completable = canCompleteNow(next!.scheduledAt);
        return NextInjectionHeroCard(
          state: state,
          pointLabel: next.pointLabel,
          scheduledAt: next.scheduledAt,
          ctaLabel: completable ? 'Completa' : 'Dettagli',
          onCta: () => context.push('/injection/${next.id}'),
        );
    }
  }

  ({List<DayStatus> statuses, List<int?> ids, List<int> counts}) _weekData(
    List<db.Injection> injections,
    DateTime startOfWeek,
  ) {
    final statuses = List<DayStatus>.filled(7, DayStatus.none);
    final ids = List<int?>.filled(7, null);
    final counts = List<int>.filled(7, 0);
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    for (final inj in injections) {
      final d = inj.scheduledAt;
      final key = DateTime(d.year, d.month, d.day);
      final i = key.difference(start).inDays;
      if (i < 0 || i > 6) continue;
      statuses[i] = dayStatusFromString(inj.status);
      ids[i] = inj.id;
      counts[i]++;
    }
    return (statuses: statuses, ids: ids, counts: counts);
  }

  /// Renders the original silhouette view (next/suggested injection body map).
  Widget _silhouetteBody(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final zonesAsync = ref.watch(zonesProvider);
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final nextScheduled = ref.watch(nextScheduledInjectionProvider);

    return zonesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorView(message: e.toString()),
      data: (zones) {
        final plan = therapyPlanAsync.asData?.value;
        final resolvedPlan = plan ?? TherapyPlan.defaults;
        final displayDate = nextScheduled?.scheduledAt ??
            ScheduleUtils.nextTherapySlot(
              from: DateTime.now(),
              plan: resolvedPlan,
            );

        // Suggerimento coerente con rotazione e data
        final suggestedForDateAsync = ref.watch(
          suggestedPointForDateProvider(
            (scheduledAt: displayDate, ignoreInjectionId: null),
          ),
        );

        return suggestedForDateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _ErrorView(message: e.toString()),
          data: (suggestedForDate) {
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
            final canComplete = canCompleteNow(displayDate);
            final view = _getViewForZone(zone?.type);
            final displayTime = DateFormat('HH:mm').format(displayDate);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: _buildHero(context),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: zone != null
                        ? () {
                            if (isScheduled && scheduledInjectionId != null) {
                              if (!canComplete) {
                                context.push('/injection/$scheduledInjectionId');
                                return;
                              }
                              _showCompleteDialog(
                                context,
                                scheduledInjectionId,
                                zone!,
                                pointNumber ?? 1,
                                scheduledAt: displayDate,
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
                              isScheduled
                                  ? (canComplete
                                      ? 'Tocca per completare'
                                      : 'Tocca per vedere il dettaglio')
                                  : 'Tocca per registrare',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Renders the week view with WeekDots and StatusLegend.
  Widget _weekBody(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek =
        startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
    final weekInjectionsAsync = ref.watch(
      injectionsInRangeProvider((start: startOfWeek, end: endOfWeek)),
    );

    return weekInjectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorView(message: e.toString()),
      data: (injections) {
        final wd = _weekData(injections, startOfWeek);
        // L'hero riempie l'altezza disponibile (Expanded); i pallini settimana
        // e la legenda restano ancorati in basso. Su viewport larghe (web)
        // il contenuto è centrato e vincolato a una larghezza massima.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildHero(context, fill: true)),
                  const SizedBox(height: 16),
                  Text('QUESTA SETTIMANA',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  AppCard(
                    child: WeekDots(
                      weekStart: startOfWeek,
                      statuses: wd.statuses,
                      counts: wd.counts,
                      onTapDay: (i) {
                        final id = wd.ids[i];
                        if (id != null) context.push('/injection/$id');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const StatusLegend(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BodyView _getViewForZone(String? zoneType) =>
      defaultBodyViewForZoneType(zoneType);

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
    int pointNumber, {
    DateTime? scheduledAt,
  }) async {
    final repository = ref.read(injectionRepositoryProvider);
    final resolvedLabel = await repository.resolvePointLabel(zone.id, pointNumber);

    if (!context.mounted) return;

    if (scheduledAt != null && !canCompleteNow(scheduledAt)) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Disponibile dal ${DateFormat('d MMM yyyy', 'it_IT').format(scheduledAt)}',
            ),
          ),
        );
      return;
    }

    final at = await showCompletionTimeDialog(context, pointLabel: resolvedLabel);

    if (at != null && context.mounted) {
      // Cancella le notifiche pre-iniezione e schedula side-effects reminder
      // usando l'id stabile dell'iniezione (no più id derivato da timestamp).
      await NotificationService.instance.cancelNotification(injectionId);

      await repository.completeInjection(injectionId, at: at);

      final notifSettings = ref.read(notificationSettingsProvider);
      if (notifSettings.enabled && notifSettings.permissionsGranted) {
        await NotificationService.instance.scheduleSideEffectsReminder(
          id: injectionId,
          completedAt: at,
          pointLabel: resolvedLabel,
          hoursAfter: notifSettings.sideEffectsReminderHours,
        );
      }

      // Refresh dei providers
      ref.invalidate(nextScheduledInjectionProvider);
      ref.invalidate(weeklyEventsProvider);
      ref.invalidate(injectionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('✓ $resolvedLabel completata!'),
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
  ) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Finestra mobile ancorata a OGGI (non al mese di calendario): così la
    // pianificazione crea sempre le prossime iniezioni, indipendentemente da
    // quanto si è avanti nella settimana/mese.
    final end7 = startOfToday.add(const Duration(days: 7, hours: 23, minutes: 59));
    final end30 =
        startOfToday.add(const Duration(days: 30, hours: 23, minutes: 59));

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pianificare le iniezioni?'),
        content: const Text(
          'Vuoi creare automaticamente le prossime iniezioni programmate, a '
          'partire da oggi, secondo il tuo piano e il pattern di rotazione?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'week'),
            child: const Text('Prossimi 7 giorni'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'month'),
            child: const Text('Prossimi 30 giorni'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choice == 'week') {
      await _fillRangeFromPlan(plan, startOfToday, end7);
    } else if (choice == 'month') {
      await _fillRangeFromPlan(plan, startOfToday, end30);
    }
  }

  Future<void> _fillRangeFromPlan(
    TherapyPlan plan,
    DateTime start,
    DateTime end,
  ) async {
    try {
      DiagnosticLogService.instance.logEvent('planning', 'avviata ${start.toIso8601String()}..${end.toIso8601String()}');
      final repository = ref.read(injectionRepositoryProvider);
      final notificationSettings = ref.read(notificationSettingsProvider);
      final dbi = ref.read(databaseProvider);
      final now = DateTime.now();

      // Query DB diretta (NON il provider .future): un StreamProvider.future
      // può non completare in alcuni contesti e appendere la pianificazione.
      final existing = await dbi.getInjectionsByDateRange(start, end);
      final alreadyPlanned = existing
          .map(
            (i) => DateTime(
              i.scheduledAt.year,
              i.scheduledAt.month,
              i.scheduledAt.day,
            ),
          )
          .toSet();

      final daysToPlan = ScheduleUtils.daysToPlan(
        plan: plan,
        start: start,
        end: end,
        now: now,
        alreadyPlanned: alreadyPlanned,
      );

      if (daysToPlan.isEmpty) {
        _showSnack('Nessuna nuova iniezione da pianificare');
        return;
      }

      // Punto di partenza del pattern: se NON esiste alcuno storico (di
      // qualsiasi stato), chiediamo all'utente da dove partire. Se lo storico
      // c'è, la suggestion segue già dall'ultima iniezione registrata.
      final history = await dbi.getAllInjections();
      ({int zoneId, int pointNumber})? seed;
      if (history.isEmpty) {
        seed = await _askStartPoint();
        if (!mounted) return;
        if (seed == null) {
          _showSnack('Pianificazione annullata');
          return;
        }
      }

      final parts = plan.preferredTime.split(':');
      final hour = parts.length >= 2 ? int.tryParse(parts[0]) ?? 20 : 20;
      final minute = parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;

      // Log granulare: conferma che siamo arrivati oltre gli await pre-loop.
      DiagnosticLogService.instance.logEvent(
        'planning',
        'pre-loop esistenti=${existing.length} daysToPlan=${daysToPlan.length} storico=${history.length}',
      );

      // Zone lette UNA volta (query DB diretta, non provider.future) per
      // advancePattern: evita un await per iterazione e rischi di hang.
      final allZones = await dbi.getAllZones();
      final patternService = RotationPatternService(dbi);

      var created = 0;
      var skipped = 0;
      // Record creati (con id) per schedulare notifiche + calendario in BACKGROUND
      // dopo il loop. Il loop fa solo operazioni DB veloci → non si blocca mai
      // su plugin lenti (notifiche/calendario).
      final createdRecords = <inj.InjectionRecord>[];
      for (final day in daysToPlan) {
        final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);

        // Primo giorno senza storico: usa il punto scelto dall'utente.
        // Altrimenti chiedi la suggestion (che considera ogni iniezione prima
        // di questa data, di qualsiasi stato).
        final ({int zoneId, int pointNumber})? point;
        if (seed != null) {
          point = seed;
          seed = null;
        } else {
          point = await ref.read(
            suggestedPointForDateProvider(
              (scheduledAt: scheduledAt, ignoreInjectionId: null),
            ).future,
          );
        }
        if (point == null) {
          skipped++;
          continue;
        }
        final pt = point; // non-nullable: evita problemi di promozione in closure

        final resolvedLabel =
            await repository.resolvePointLabel(pt.zoneId, pt.pointNumber);

        final record = inj.InjectionRecord(
          zoneId: pt.zoneId,
          pointNumber: pt.pointNumber,
          scheduledAt: scheduledAt,
          status: inj.InjectionStatus.scheduled,
          customPointLabel: resolvedLabel,
          createdAt: now,
          updatedAt: now,
        );

        // syncCalendar: false — calendario E notifiche vengono sincronizzati in
        // background DOPO il loop, così il batch è solo DB e non si appende.
        final newId = await repository.createInjection(record, syncCalendar: false);
        createdRecords.add(record.copyWith(id: newId));
        created++;

        final usedZones = allZones.where((z) => z.id == pt.zoneId).toList();
        final usedZone = usedZones.isEmpty ? null : usedZones.first;
        if (usedZone != null) {
          await patternService.advancePattern(usedZone.id, usedZone.side);
        }
      }
      ref.invalidate(currentRotationPatternProvider);
      ref.invalidate(rotationPatternEngineProvider);
      ref.invalidate(injectionsProvider);
      ref.invalidate(weeklyEventsProvider);
      ref.invalidate(nextScheduledInjectionProvider);

      DiagnosticLogService.instance.logEvent('planning', 'create $created, saltate $skipped');
      if (created > 0) {
        _showSnack('Pianificate $created iniezioni');
      } else if (skipped > 0) {
        _showSnack(
          'Nessun punto suggerito: verifica zone e pattern di rotazione',
        );
      }

      // Side-effects (calendario + notifiche) in BACKGROUND: non bloccano la UI
      // né la percezione di immediatezza della pianificazione. Ogni operazione
      // è best-effort e con timeout, così un plugin lento/bloccato non ha effetti.
      if (createdRecords.isNotEmpty) {
        final notifEnabled = notificationSettings.enabled &&
            notificationSettings.permissionsGranted;
        final suppress = ref.read(reminderSettingsProvider).suppressAppPreReminders;
        final minutesBefore = notificationSettings.minutesBefore;
        final missedDose = notificationSettings.missedDoseReminder;
        // ignore: unawaited_futures
        Future(() async {
          for (final rec in createdRecords) {
            try {
              await repository.syncInjectionToCalendar(rec.id!);
            } catch (_) {/* best-effort */}
            if (notifEnabled) {
              try {
                await NotificationService.instance
                    .scheduleInjectionNotifications(
                      injection: rec,
                      minutesBefore: minutesBefore,
                      missedDoseReminder: missedDose,
                      skipPreReminders: suppress,
                    )
                    .timeout(const Duration(seconds: 8));
              } catch (_) {/* best-effort: notifica non deve bloccare */}
            }
          }
          DiagnosticLogService.instance
              .logEvent('planning', 'background side-effects completati');
          ref.invalidate(nextScheduledInjectionProvider);
        });
      }
    } catch (e, st) {
      DiagnosticLogService.instance.logError('planning', e, st);
      _showSnack('Errore durante la pianificazione: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  /// Dialog per scegliere la zona/punto da cui far partire il pattern quando
  /// non esiste alcuno storico. Ritorna null se annullato.
  Future<({int zoneId, int pointNumber})?> _askStartPoint() async {
    // Attende le zone (await), invece di leggere uno stato che potrebbe non
    // essere ancora caricato (asData null) e far uscire silenziosamente.
    List<model.BodyZone> zones;
    try {
      zones = await ref.read(zonesProvider.future);
    } catch (_) {
      zones = const <model.BodyZone>[];
    }
    if (zones.isEmpty || !mounted) return null;

    // Nome della rotazione attiva, mostrato nel dialog per dare contesto.
    String? rotationName;
    try {
      final activePlan = await ref.read(databaseProvider).getCurrentTherapyPlan();
      rotationName = activePlan?.name;
    } catch (_) {/* best-effort */}
    if (!mounted) return null;

    return showDialog<({int zoneId, int pointNumber})>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Da quale punto partire?'),
            if (rotationName != null && rotationName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Rotazione: $rotationName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppTokens.darkMuted
                      : AppTokens.lightMuted,
                ),
              ),
            ],
          ],
        ),
        children: [
          for (final z in zones)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(ctx, (zoneId: z.id, pointNumber: 1)),
              child: Row(
                children: [
                  Text(z.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(z.displayName)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Card hero per stati allDone (gradiente) e none (neutro).
class _HeroMessageCard extends StatelessWidget {
  const _HeroMessageCard({
    required this.gradient,
    required this.icon,
    required this.text,
    this.fill = false,
  })  : _neutral = false,
        onTap = null;

  const _HeroMessageCard.neutral({
    required this.icon,
    required this.text,
    this.fill = false,
    this.onTap,
  })  : gradient = null,
        _neutral = true;

  final Gradient? gradient;
  final IconData icon;
  final String text;
  final bool _neutral;

  /// Quando true la card riempie l'altezza disponibile e centra il contenuto
  /// (vista Settimana). Quando false resta dimensionata sul contenuto (banner).
  final bool fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_neutral) {
      final muted = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;
      final row = Row(
        mainAxisSize: fill ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      );
      return AppCard(
        onTap: onTap,
        child: fill ? Center(child: row) : row,
      );
    }

    final row = Row(
      mainAxisSize: fill ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppTokens.softShadow(),
      ),
      child: fill ? Center(child: row) : row,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Card principale con silhouette e info iniezione
class _MainCard extends StatefulWidget {
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
  State<_MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<_MainCard> {
  late BodyView _currentView;

  @override
  void initState() {
    super.initState();
    _currentView = widget.view;
  }

  @override
  void didUpdateWidget(_MainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view != widget.view) {
      setState(() => _currentView = widget.view);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zone = widget.zone;
    final isDark = widget.isDark;

    if (zone == null) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsDuotone.syringe,
                  size: 64,
                  color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
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
                    color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayPointNumber = widget.pointNumber ?? 1;
    final isFront = _currentView == BodyView.front;
    final frontColor = isDark ? AppTokens.accentEnd : AppTokens.accentEnd;
    final backColor = isDark ? AppTokens.darkIris : AppTokens.accent;
    final activeColor = isFront ? frontColor : backColor;

    return Column(
      children: [
        // Toggle fronte/retro sopra la card
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HomeViewToggle(
              icon: PhosphorIconsDuotone.user,
              label: 'Fronte',
              isSelected: isFront,
              activeColor: frontColor,
              isDark: isDark,
              onTap: () => setState(() => _currentView = BodyView.front),
            ),
            const SizedBox(width: 16),
            _HomeViewToggle(
              icon: PhosphorIconsDuotone.user,
              label: 'Retro',
              isSelected: !isFront,
              activeColor: backColor,
              isDark: isDark,
              onTap: () => setState(() => _currentView = BodyView.back),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Card con silhouette colorata in base alla vista
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scale =
                            (constraints.maxHeight / 400).clamp(0.5, 0.6);

                        final allPoints = generateDefaultPointPositions(
                          zone.numberOfPoints,
                          zone.type,
                          zone.side,
                        );

                        final targetPoint = allPoints.firstWhere(
                          (p) => p.pointNumber == displayPointNumber,
                          orElse: () => allPoints.isNotEmpty
                              ? allPoints.first
                              : const PositionedPoint(
                                  pointNumber: 1,
                                  x: 0.5,
                                  y: 0.5,
                                ),
                        );

                        return BodySilhouetteEditor(
                          points: [targetPoint],
                          onPointMoved: (p, x, y, v) {},
                          onPointTapped: (p) {},
                          selectedPointNumber: displayPointNumber,
                          editable: false,
                          zoneType: zone.type,
                          pointScale: scale,
                          currentView: _currentView,
                          onViewChanged: (v) =>
                              setState(() => _currentView = v),
                          silhouetteColor: activeColor,
                        );
                      },
                    ),
                  ),

                  const Divider(),

                  // Info zona
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          zone.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTokens.accent
                                : AppTokens.accent,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIconsDuotone.clock,
                              size: 18,
                              color: activeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('EEEE d MMM', 'it_IT').format(widget.displayDate)} alle ${widget.displayTime}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.isScheduled ? 'Programmata' : 'Suggerita',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: activeColor,
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
          ),
        ),
      ],
    );
  }
}

/// Toggle per vista fronte/retro con colore dedicato
class _HomeViewToggle extends StatelessWidget {
  const _HomeViewToggle({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? activeColor
        : (isDark ? AppTokens.darkMuted : AppTokens.lightMuted);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
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
            const Icon(PhosphorIconsDuotone.warningCircle, size: 48),
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

/// Compact pill toggle for switching between Home layouts.
class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({
    required this.current,
    required this.onSelect,
  });

  final HomeLayout current;
  final void Function(HomeLayout) onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s,
        horizontal: AppSpacing.l,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Pill(
            label: 'Settimana',
            selected: current == HomeLayout.week,
            mutedColor: mutedColor,
            onTap: () => onSelect(HomeLayout.week),
          ),
          const SizedBox(width: AppSpacing.s),
          _Pill(
            label: 'Silhouette',
            selected: current == HomeLayout.silhouette,
            mutedColor: mutedColor,
            onTap: () => onSelect(HomeLayout.silhouette),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTokens.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppTokens.accent : mutedColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : mutedColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Banner non bloccante mostrato in cima alla home quando le notifiche
/// sono abilitate dall'utente ma il sistema non ha concesso il permesso.
/// Cliccando si tenta una nuova richiesta esplicita di permesso.
class _NotificationPermissionBanner extends ConsumerWidget {
  const _NotificationPermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    if (!settings.enabled || settings.permissionsGranted) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = (isDark ? AppTokens.warnDark : AppTokens.warnLight)
        .withValues(alpha: 0.15);
    final fg = isDark ? AppTokens.warnDark : AppTokens.warnLight;

    return Material(
      color: bg,
      child: InkWell(
        onTap: () =>
            ref.read(notificationSettingsProvider.notifier).requestPermissions(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(PhosphorIconsDuotone.bellSlash, color: fg, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I promemoria sono disattivati. Tocca per concedere il permesso.',
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
              ),
              Icon(PhosphorIconsDuotone.caretRight, color: fg, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
