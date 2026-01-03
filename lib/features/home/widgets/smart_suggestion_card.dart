import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/ml/smart_suggestion_provider.dart';
import '../../../core/ml/adherence_scorer.dart';
import '../../../core/theme/app_colors.dart';

/// Card che mostra suggerimenti ML intelligenti
class SmartSuggestionCard extends ConsumerWidget {
  const SmartSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(smartSuggestionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return suggestionAsync.when(
      loading: () => _buildLoadingCard(context, isDark),
      error: (error, stack) => _buildErrorCard(context, isDark, error),
      data: (suggestion) => _buildSuggestionCard(context, isDark, suggestion, ref),
    );
  }

  Widget _buildLoadingCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.dawnSurface,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Analisi in corso...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, bool isDark, Object error) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.dawnSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: isDark ? AppColors.darkRose : AppColors.dawnRose,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Impossibile generare suggerimenti',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    bool isDark,
    SmartSuggestion suggestion,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.dawnSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (isDark ? AppColors.darkHighlightMed : AppColors.dawnHighlightMed)
              .withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: suggestion.hasZoneSuggestion
            ? () => _navigateToInjection(context, suggestion)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icona AI
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkIris : AppColors.dawnIris)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: isDark ? AppColors.darkIris : AppColors.dawnIris,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggerimento AI',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Confidenza: ${suggestion.confidenceLevel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    suggestion.confidenceIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Messaggio principale
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPine : AppColors.dawnPine)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? AppColors.darkPine : AppColors.dawnPine)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (suggestion.hasZoneSuggestion) ...[
                      Text(
                        suggestion.topZonePrediction!.zone.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.mainMessage,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (suggestion.hasZoneSuggestion)
                            Text(
                              suggestion.topZonePrediction!.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (suggestion.hasZoneSuggestion)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                  ],
                ),
              ),
              
              // Dettagli aggiuntivi
              if (suggestion.hasEnoughData) ...[
                const SizedBox(height: 12),
                
                // Predizioni zona alternative
                if (suggestion.allZonePredictions.length > 1)
                  _buildAlternativeZones(context, isDark, suggestion),
                
                // Score aderenza
                if (suggestion.adherenceScore != null)
                  _buildAdherenceInsights(context, isDark, suggestion.adherenceScore!),
                
                // Raccomandazione orario
                if (suggestion.hasTimeSuggestion)
                  _buildTimeRecommendation(context, isDark, suggestion),
              ],
              
              // Suggerimenti secondari
              if (suggestion.secondarySuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...suggestion.secondarySuggestions.take(2).map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeZones(
    BuildContext context,
    bool isDark,
    SmartSuggestion suggestion,
  ) {
    final alternatives = suggestion.allZonePredictions.skip(1).take(3).toList();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: alternatives.map((pred) => Chip(
          avatar: Text(pred.zone.emoji, style: const TextStyle(fontSize: 14)),
          label: Text(
            pred.zone.displayName,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: (isDark ? AppColors.darkOverlay : AppColors.dawnOverlay),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }

  Widget _buildAdherenceInsights(
    BuildContext context,
    bool isDark,
    AdherenceScore score,
  ) {
    final insights = score.insights.take(2);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: insights.map((insight) => Expanded(
          child: Row(
            children: [
              Text(insight.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  insight.title,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTimeRecommendation(
    BuildContext context,
    bool isDark,
    SmartSuggestion suggestion,
  ) {
    final time = suggestion.timeRecommendation!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
          ),
          const SizedBox(width: 6),
          Text(
            'Orario consigliato: ${time.formattedTime}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToInjection(BuildContext context, SmartSuggestion suggestion) {
    if (!suggestion.hasZoneSuggestion) return;
    
    context.push(
      AppRoutes.selectPoint,
      extra: {
        'mode': 'injection',
        'suggestedZoneId': suggestion.topZonePrediction!.zone.id,
      },
    );
  }
}

