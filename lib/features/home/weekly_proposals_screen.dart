import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../app/router.dart';
import '../../models/body_zone.dart';
import '../../models/injection_record.dart';
import '../injection/injection_provider.dart';
import '../injection/zone_provider.dart';

/// Schermata per approvare le proposte di iniezione settimanali
class WeeklyProposalsScreen extends ConsumerStatefulWidget {
  const WeeklyProposalsScreen({super.key});

  @override
  ConsumerState<WeeklyProposalsScreen> createState() =>
      _WeeklyProposalsScreenState();
}

class _WeeklyProposalsScreenState
    extends ConsumerState<WeeklyProposalsScreen> {
  final Set<int> _approvedProposals = {};
  final Set<int> _skippedProposals = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyEventsAsync = ref.watch(weeklyEventsProvider);
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposte Settimanali'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: weeklyEventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (weeklyEvents) {
          return zonesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (zones) {
              // Filtra solo le proposte (non confermate e future)
              final proposals = weeklyEvents.where((e) =>
                  e.isSuggested && !e.isPast).toList();

              if (proposals.isEmpty) {
                return _buildEmptyState(theme, isDark);
              }

              return _buildProposalsList(
                context,
                theme,
                isDark,
                proposals,
                zones,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: isDark ? AppColors.darkPine : AppColors.dawnPine,
            ),
            const SizedBox(height: 16),
            Text(
              'Tutto in ordine!',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Non ci sono proposte da approvare per questa settimana.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalsList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<WeeklyEventData> proposals,
    List<BodyZone> zones,
  ) {
    final dateFormat = DateFormat('EEEE d MMMM', 'it_IT');

    return Column(
      children: [
        // Intestazione con pulsante "Approva tutti"
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: isDark
                ? AppColors.darkHighlightLow
                : AppColors.dawnHighlightLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAiBadge(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Proposte intelligenti',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Queste iniezioni sono state suggerite in base alla rotazione ottimale dei punti.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _approveAll(proposals, zones),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(_isLoading
                          ? 'Approvazione...'
                          : 'Approva tutte (${proposals.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista proposte
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              final proposal = proposals[index];
              final zone = proposal.suggestion != null
                  ? zones.where((z) => z.id == proposal.suggestion!.zoneId).firstOrNull
                  : null;
              final isApproved = _approvedProposals.contains(index);
              final isSkipped = _skippedProposals.contains(index);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Data e stato
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(proposal.date),
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          if (isApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPine.withValues(alpha: 0.2)
                                    : AppColors.dawnPine.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkPine
                                        : AppColors.dawnPine,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Approvata',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkPine
                                          : AppColors.dawnPine,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isSkipped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkMuted
                                        : AppColors.dawnMuted)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Saltata',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.dawnMuted,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Zona e punto suggeriti
                      if (zone != null && proposal.suggestion != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkHighlightMed
                                    : AppColors.dawnHighlightMed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                zone.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.pointLabel(proposal.suggestion!.pointNumber),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Orario preferito: ${proposal.preferredTime ?? "20:00"}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.dawnMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // Azioni
                      if (!isApproved && !isSkipped) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _skipProposal(index),
                                child: const Text('Salta'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _modifyProposal(
                                  context,
                                  proposal,
                                ),
                                child: const Text('Modifica'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approveProposal(
                                  index,
                                  proposal,
                                  zone,
                                ),
                                child: const Text('Approva'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProposal(
    int index,
    WeeklyEventData proposal,
    BodyZone? zone,
  ) async {
    if (proposal.suggestion == null || zone == null) return;

    final repository = ref.read(injectionRepositoryProvider);
    final now = DateTime.now();

    // Crea l'evento nel database
    await repository.createInjection(InjectionRecord(
      zoneId: proposal.suggestion!.zoneId,
      pointNumber: proposal.suggestion!.pointNumber,
      scheduledAt: proposal.date.add(Duration(
        hours: int.tryParse(proposal.preferredTime?.split(':')[0] ?? '20') ?? 20,
        minutes: int.tryParse(proposal.preferredTime?.split(':')[1] ?? '0') ?? 0,
      )),
      status: InjectionStatus.scheduled,
      notes: '',
      sideEffects: [],
      createdAt: now,
      updatedAt: now,
    ));

    setState(() => _approvedProposals.add(index));
    ref.invalidate(weeklyEventsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposta approvata')),
      );
    }
  }

  void _skipProposal(int index) {
    setState(() => _skippedProposals.add(index));
  }

  void _modifyProposal(BuildContext context, WeeklyEventData proposal) {
    // Naviga alla selezione punto con data preselezionata
    context.push(
      AppRoutes.bodyMap,
      extra: {
        'scheduledDate': proposal.date,
        if (proposal.suggestion != null) 'zoneId': proposal.suggestion!.zoneId,
      },
    );
  }

  Future<void> _approveAll(
    List<WeeklyEventData> proposals,
    List<BodyZone> zones,
  ) async {
    setState(() => _isLoading = true);

    try {
      for (var i = 0; i < proposals.length; i++) {
        if (_approvedProposals.contains(i) || _skippedProposals.contains(i)) {
          continue;
        }
        final proposal = proposals[i];
        final zone = proposal.suggestion != null
            ? zones.where((z) => z.id == proposal.suggestion!.zoneId).firstOrNull
            : null;
        if (zone != null) {
          await _approveProposal(i, proposal, zone);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutte le proposte sono state approvate')),
        );
      }
    }
  }
}
