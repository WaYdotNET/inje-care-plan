import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/body_zone.dart' as model;
import '../../app/router.dart';
import '../../core/ml/smart_suggestion_provider.dart';
import '../injection/injection_provider.dart';
import '../injection/zone_provider.dart';
import '../injection/widgets/body_silhouette_editor.dart';

/// Home minimalista con focus sulla prossima iniezione
class HomeMinimalScreen extends ConsumerWidget {
  const HomeMinimalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestionAsync = ref.watch(smartSuggestionProvider);
    final zonesAsync = ref.watch(zonesProvider);
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final nextScheduledAsync = ref.watch(nextScheduledInjectionProvider);

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
            // Prima controlla se c'è un'iniezione programmata
            final nextScheduled = nextScheduledAsync.value;

            return suggestionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => _ErrorView(message: e.toString()),
              data: (suggestion) {
                // Se c'è un'iniezione schedulata, mostra quella
                model.BodyZone? zone;
                String displayTime;
                bool isScheduled = false;
                int? scheduledInjectionId;
                int? pointNumber;

                if (nextScheduled != null) {
                  // Mostra l'iniezione programmata
                  isScheduled = true;
                  scheduledInjectionId = nextScheduled.id;
                  pointNumber = nextScheduled.pointNumber;
                  zone = zones.firstWhere(
                    (z) => z.id == nextScheduled.zoneId,
                    orElse: () => zones.first,
                  );
                  displayTime = DateFormat('HH:mm').format(nextScheduled.scheduledAt);
                } else {
                  // Fallback a suggerimento AI
                  final topZone = suggestion.topZonePrediction;
                  zone = topZone != null
                      ? zones.firstWhere(
                          (z) => z.id == topZone.zone.id,
                          orElse: () => zones.first,
                        )
                      : null;
                  final therapyPlan = therapyPlanAsync.value;
                  displayTime = therapyPlan?.preferredTime ?? '20:00';
                }

                // Determina la vista (front/back) in base alla zona
                final view = _getViewForZone(zone?.type);

                return GestureDetector(
                  onTap: zone != null
                      ? () {
                          if (isScheduled && scheduledInjectionId != null) {
                            // Naviga per completare l'iniezione
                            _showCompleteDialog(
                              context,
                              ref,
                              scheduledInjectionId,
                              zone!,
                              pointNumber ?? 1,
                            );
                          } else {
                            _navigateToRecord(context, zone!.id);
                          }
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header con data
                        _DateHeader(
                          isDark: isDark,
                          isScheduled: isScheduled,
                        ),

                        const SizedBox(height: 24),

                        // Card principale con silhouette
                        Expanded(
                          child: _MainCard(
                            zone: zone,
                            suggestion: suggestion,
                            preferredTime: displayTime,
                            view: view,
                            isDark: isDark,
                            isScheduled: isScheduled,
                            pointNumber: pointNumber,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hint per azione
                        if (zone != null)
                          Text(
                            isScheduled
                                ? 'Tocca per completare'
                                : 'Tocca per registrare',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.dawnMuted,
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

  void _navigateToRecord(BuildContext context, int zoneId) {
    context.push(
      AppRoutes.bodyMap,
      extra: {
        'zoneId': zoneId,
        'scheduledDate': DateTime.now(),
      },
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
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
}

/// Header con la data corrente
class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.isDark,
    this.isScheduled = false,
  });

  final bool isDark;
  final bool isScheduled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM', 'it_IT');

    return Column(
      children: [
        Text(
          dateFormat.format(now),
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
    required this.suggestion,
    required this.preferredTime,
    required this.view,
    required this.isDark,
    this.isScheduled = false,
    this.pointNumber,
  });

  final model.BodyZone? zone;
  final SmartSuggestion suggestion;
  final String preferredTime;
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

    // Calcola la posizione del punto suggerito
    final suggestedPoint = suggestion.topZonePrediction;
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
                        'Oggi alle $preferredTime',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Confidenza e pattern
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suggestion.confidenceIcon,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${suggestion.patternName} • ${suggestion.confidencePercentage}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Motivo suggerimento
                  if (suggestedPoint != null && suggestedPoint.reason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        suggestedPoint.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                        ),
                        textAlign: TextAlign.center,
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
