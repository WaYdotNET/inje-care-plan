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

    return Scaffold(
      appBar: AppBar(
        title: const Text('InjeCare Plan'),
        actions: [
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
        child: suggestionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _ErrorView(message: e.toString()),
          data: (suggestion) {
            return zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => _ErrorView(message: e.toString()),
              data: (zones) {
                final topZone = suggestion.topZonePrediction;
                final zone = topZone != null
                    ? zones.firstWhere(
                        (z) => z.id == topZone.zone.id,
                        orElse: () => zones.first,
                      )
                    : null;

                // Determina la vista (front/back) in base alla zona
                final view = _getViewForZone(zone?.type);

                // Ottieni l'orario preferito dal piano terapeutico
                final therapyPlan = therapyPlanAsync.value;
                final preferredTime = therapyPlan?.preferredTime ?? '20:00';

                return GestureDetector(
                  onTap: zone != null
                      ? () => _navigateToRecord(context, zone.id)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header con data
                        _DateHeader(isDark: isDark),

                        const SizedBox(height: 24),

                        // Card principale con silhouette
                        Expanded(
                          child: _MainCard(
                            zone: zone,
                            suggestion: suggestion,
                            preferredTime: preferredTime,
                            view: view,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hint per registrare
                        if (zone != null)
                          Text(
                            'Tocca per registrare',
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
}

/// Header con la data corrente
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.isDark});

  final bool isDark;

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
          'Prossima iniezione',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
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
  });

  final model.BodyZone? zone;
  final SmartSuggestion suggestion;
  final String preferredTime;
  final BodyView view;
  final bool isDark;

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
    const pointNumber = 1; // Default al primo punto

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Silhouette con punto evidenziato
            Expanded(
              child: BodySilhouetteEditor(
                points: [
                  PositionedPoint(
                    pointNumber: pointNumber,
                    x: _getDefaultX(zone!.type, zone!.side),
                    y: _getDefaultY(zone!.type),
                  ),
                ],
                onPointMoved: (p, x, y, v) {},
                onPointTapped: (p) {},
                selectedPointNumber: pointNumber,
                initialView: view,
                editable: false,
                zoneType: zone!.type,
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

  double _getDefaultX(String zoneType, String side) {
    final baseX = switch (zoneType) {
      'thigh' => 0.35,
      'arm' => 0.2,
      'abdomen' => 0.4,
      'buttock' => 0.4,
      _ => 0.5,
    };
    final offset = switch (side) {
      'left' => -0.1,
      'right' => 0.1,
      _ => 0.0,
    };
    return baseX + offset;
  }

  double _getDefaultY(String zoneType) {
    return switch (zoneType) {
      'thigh' => 0.58,
      'arm' => 0.28,
      'abdomen' => 0.38,
      'buttock' => 0.52,
      _ => 0.5,
    };
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

