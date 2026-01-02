import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/app_database.dart' as db;
import '../../app/router.dart';
import '../../models/body_zone.dart';
import '../../models/blacklisted_point.dart';
import 'injection_provider.dart';
import 'zone_provider.dart';

/// Zone detail screen with point history
class ZoneDetailScreen extends ConsumerWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});

  final int zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(zonesProvider);
    final injectionsAsync = ref.watch(injectionsByZoneProvider(zoneId));
    final blacklistAsync = ref.watch(blacklistedPointsByZoneProvider(zoneId));

    return zonesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Errore')),
        body: Center(child: Text('Errore: $e')),
      ),
      data: (zones) {
        final zone = zones.where((z) => z.id == zoneId).firstOrNull ?? zones.first;
        return Scaffold(
          appBar: AppBar(
            title: Text(zone.displayName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: injectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Errore: $error')),
            data: (injections) => blacklistAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Errore: $error')),
              data: (blacklist) => _buildContent(
                context,
                ref,
                theme,
                isDark,
                zone,
                injections,
                blacklist,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    BodyZone zone,
    List<db.Injection> injections,
    List<db.BlacklistedPoint> blacklist,
  ) {
    final availablePoints = zone.numberOfPoints - blacklist.length;

    // Group injections by point and get the most recent for each
    final pointHistory = <int, db.Injection>{};
    for (final inj in injections) {
      if (!pointHistory.containsKey(inj.pointNumber) ||
          (inj.completedAt ?? inj.scheduledAt)
              .isAfter(pointHistory[inj.pointNumber]!.completedAt ?? pointHistory[inj.pointNumber]!.scheduledAt)) {
        pointHistory[inj.pointNumber] = inj;
      }
    }

    // Sort points by last usage (oldest first)
    final sortedPoints = <int>[];
    for (var i = 1; i <= zone.numberOfPoints; i++) {
      if (!blacklist.any((bp) => bp.pointNumber == i)) {
        sortedPoints.add(i);
      }
    }
    sortedPoints.sort((a, b) {
      final aDate = pointHistory[a]?.completedAt ?? DateTime(1970);
      final bDate = pointHistory[b]?.completedAt ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header
          Row(
            children: [
              Text(zone.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.displayName,
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      '$availablePoints punti disponibili${blacklist.isNotEmpty ? ' (${blacklist.length} escluso/i)' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Suggested point
          if (sortedPoints.isNotEmpty)
            _SuggestedCard(
              zone: zone,
              pointNumber: sortedPoints.first,
              lastUsed: pointHistory[sortedPoints.first]?.completedAt,
              isDark: isDark,
              onTap: () => _goToRecord(context, sortedPoints.first),
            ),

          const SizedBox(height: 24),

          Text(
            'Storico punti (dal meno usato)',
            style: theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 12),

          // Point cards
          ...sortedPoints.map((pointNumber) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PointCard(
              zone: zone,
              pointNumber: pointNumber,
              lastInjection: pointHistory[pointNumber],
              isDark: isDark,
              onTap: () => _goToRecord(context, pointNumber),
              onMenu: () => _showMenu(context, ref, zone, pointNumber),
            ),
          )),

          if (blacklist.isNotEmpty) ...[
            const SizedBox(height: 24),

            Text(
              'PUNTI ESCLUSI (blacklist)',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            ...blacklist.map((bp) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BlacklistedPointCard(
                blacklistedPoint: bp,
                isDark: isDark,
                onRestore: () => _restorePoint(context, ref, bp),
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _goToRecord(BuildContext context, int pointNumber) {
    context.push(
      AppRoutes.recordInjection,
      extra: {'zoneId': zoneId, 'pointNumber': pointNumber},
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, BodyZone zone, int pointNumber) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Usa questo punto'),
            onTap: () {
              Navigator.pop(context);
              _goToRecord(context, pointNumber);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Vedi storico'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
            title: const Text('Escludi punto'),
            onTap: () {
              Navigator.pop(context);
              _showExcludeDialog(context, ref, zone, pointNumber);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showExcludeDialog(BuildContext context, WidgetRef ref, BodyZone zone, int pointNumber) {
    BlacklistReason? selectedReason;
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Escludi punto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stai per escludere: ${zone.displayName} · $pointNumber'),
              const SizedBox(height: 16),
              const Text('Motivo (opzionale):'),
              const SizedBox(height: 8),
              ...BlacklistReason.values.map((reason) {
                final label = switch (reason) {
                  BlacklistReason.skinReaction => 'Reazione cutanea',
                  BlacklistReason.scar => 'Cicatrice / lesione',
                  BlacklistReason.hardToReach => 'Difficile da raggiungere',
                  BlacklistReason.other => 'Altro',
                };
                return RadioListTile<BlacklistReason>(
                  title: Text(label),
                  value: reason,
                  groupValue: selectedReason,
                  dense: true,
                  onChanged: (value) => setState(() => selectedReason = value),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Aggiungi note...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _blacklistPoint(
                  context,
                  ref,
                  zone,
                  pointNumber,
                  selectedReason ?? BlacklistReason.other,
                  notesController.text,
                );
              },
              child: const Text('Escludi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _blacklistPoint(
    BuildContext context,
    WidgetRef ref,
    BodyZone zone,
    int pointNumber,
    BlacklistReason reason,
    String? notes,
  ) async {
    final repository = ref.read(injectionRepositoryProvider);
    await repository.blacklistPoint(
      BlacklistedPoint(
        zoneId: zoneId,
        pointNumber: pointNumber,
        reason: reason.name,
        notes: notes ?? '',
        blacklistedAt: DateTime.now(),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${zone.pointLabel(pointNumber)} escluso')),
      );
    }
  }

  Future<void> _restorePoint(
    BuildContext context,
    WidgetRef ref,
    db.BlacklistedPoint bp,
  ) async {
    final repository = ref.read(injectionRepositoryProvider);
    await repository.unblacklistPoint(bp.pointCode);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bp.pointLabel} riabilitato')),
      );
    }
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({
    required this.zone,
    required this.pointNumber,
    required this.lastUsed,
    required this.isDark,
    required this.onTap,
  });

  final BodyZone zone;
  final int pointNumber;
  final DateTime? lastUsed;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysAgo = lastUsed != null
        ? DateTime.now().difference(lastUsed!).inDays
        : null;

    return Card(
      color: isDark
          ? AppColors.darkPine.withValues(alpha: 0.2)
          : AppColors.dawnPine.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isDark ? AppColors.darkPine : AppColors.dawnPine,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggerito: Punto $pointNumber',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      daysAgo != null
                          ? '(non usato da $daysAgo giorni)'
                          : '(mai usato)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onTap,
                child: const Text('Usa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.zone,
    required this.pointNumber,
    required this.lastInjection,
    required this.isDark,
    required this.onTap,
    required this.onMenu,
  });

  final BodyZone zone;
  final int pointNumber;
  final db.Injection? lastInjection;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  Color get _color {
    if (lastInjection == null) {
      return isDark ? AppColors.darkPine : AppColors.dawnPine;
    }
    final daysAgo = DateTime.now()
        .difference(lastInjection!.completedAt ?? lastInjection!.scheduledAt)
        .inDays;
    if (daysAgo > 14) return isDark ? AppColors.darkPine : AppColors.dawnPine;
    if (daysAgo > 7) return isDark ? AppColors.darkGold : AppColors.dawnGold;
    if (daysAgo > 3) return isDark ? AppColors.darkRose : AppColors.dawnRose;
    return isDark ? AppColors.darkLove : AppColors.dawnLove;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy', 'it_IT');
    final lastDate = lastInjection?.completedAt ?? lastInjection?.scheduledAt;
    final daysAgo = lastDate != null
        ? DateTime.now().difference(lastDate).inDays
        : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          zone.pointCode(pointNumber),
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          zone.pointLabel(pointNumber),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    Text(
                      lastDate != null
                          ? 'Ultima: ${dateFormat.format(lastDate)}${daysAgo != null && daysAgo > 0 ? ' · $daysAgo giorni fa' : daysAgo == 0 ? ' · Oggi' : ''}'
                          : 'Mai usato',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMenu,
              ),
              TextButton(
                onPressed: onTap,
                child: const Text('Usa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlacklistedPointCard extends StatelessWidget {
  const _BlacklistedPointCard({
    required this.blacklistedPoint,
    required this.isDark,
    required this.onRestore,
  });

  final db.BlacklistedPoint blacklistedPoint;
  final bool isDark;
  final VoidCallback onRestore;

  String _reasonLabel(String reason) => switch (reason) {
    'skinReaction' => 'Reazione cutanea',
    'scar' => 'Cicatrice / lesione',
    'hardToReach' => 'Difficile da raggiungere',
    'other' => 'Altro',
    _ => reason,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isDark
          ? AppColors.darkMuted.withValues(alpha: 0.2)
          : AppColors.dawnMuted.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.block,
              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        blacklistedPoint.pointCode,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        blacklistedPoint.pointLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  Text(
                    'Motivo: ${_reasonLabel(blacklistedPoint.reason)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              child: const Text('Riabilita'),
            ),
          ],
        ),
      ),
    );
  }
}
