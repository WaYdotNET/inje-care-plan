import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/database/app_database.dart' as db;
import '../injection/injection_provider.dart';

/// Injection history screen
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final injectionsAsync = ref.watch(injectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico'),
        actions: [
          injectionsAsync.maybeWhen(
            data: (injections) => IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: injections.isNotEmpty
                  ? () => _showExportOptions(context, injections)
                  : null,
              tooltip: 'Esporta',
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: injectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (injections) {
          if (injections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna iniezione registrata',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le tue iniezioni appariranno qui',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group injections by month
          final grouped = _groupByMonth(injections);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return _MonthSection(
                month: entry.key,
                injections: entry.value,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<db.Injection>> _groupByMonth(List<db.Injection> injections) {
    final grouped = <String, List<db.Injection>>{};
    final monthFormat = DateFormat('MMMM yyyy', 'it_IT');

    for (final inj in injections) {
      final key = monthFormat.format(inj.scheduledAt);
      grouped.putIfAbsent(key, () => []).add(inj);
    }

    return grouped;
  }

  void _showExportOptions(BuildContext context, List<db.Injection> injections) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Esporta PDF'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ExportService.instance.exportToPdf(injections);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Esporta CSV'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ExportService.instance.exportToCsv(injections);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.injections,
    required this.isDark,
  });

  final String month;
  final List<db.Injection> injections;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            month.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
            ),
          ),
        ),
        ...injections.map((inj) => _HistoryCard(
          injection: inj,
          isDark: isDark,
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.injection,
    required this.isDark,
  });

  final db.Injection injection;
  final bool isDark;

  Color get _statusColor => switch (injection.status) {
    'completed' => isDark ? AppColors.darkPine : AppColors.dawnPine,
    'skipped' => isDark ? AppColors.darkLove : AppColors.dawnLove,
    'delayed' => isDark ? AppColors.darkGold : AppColors.dawnGold,
    'scheduled' => isDark ? AppColors.darkFoam : AppColors.dawnFoam,
    _ => isDark ? AppColors.darkMuted : AppColors.dawnMuted,
  };

  String get _statusLabel => switch (injection.status) {
    'completed' => 'Completata',
    'skipped' => 'Saltata',
    'delayed' => 'In ritardo',
    'scheduled' => 'Programmata',
    _ => 'Sconosciuto',
  };
  
  String get _emoji => switch (injection.zoneId) {
    1 => '🦵', 2 => '🦵',
    3 => '💪', 4 => '💪',
    5 => '🎯', 6 => '🎯',
    7 => '🍑', 8 => '🍑',
    _ => '💉',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = injection.completedAt ?? injection.scheduledAt;
    final dayFormat = DateFormat('d', 'it_IT');
    final monthFormat = DateFormat('MMM', 'it_IT');
    final timeFormat = DateFormat('HH:mm', 'it_IT');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkHighlightLow
                      : AppColors.dawnHighlightLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      dayFormat.format(date),
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      monthFormat.format(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_emoji),
                        const SizedBox(width: 8),
                        Text(
                          injection.pointLabel,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _statusColor,
                          ),
                        ),
                        if (injection.sideEffects?.isNotEmpty == true) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${injection.sideEffects!.split(',').length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Time
              Text(
                timeFormat.format(date),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final date = injection.completedAt ?? injection.scheduledAt;
    final dateFormat = DateFormat('EEEE d MMMM yyyy, HH:mm', 'it_IT');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        injection.pointLabel,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        injection.pointCode,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Data',
              value: dateFormat.format(date),
            ),
            _DetailRow(
              icon: Icons.check_circle_outline,
              label: 'Stato',
              value: _statusLabel,
              valueColor: _statusColor,
            ),
            if (injection.notes?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.notes,
                label: 'Note',
                value: injection.notes!,
              ),
            if (injection.sideEffects?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.warning_amber_rounded,
                label: 'Effetti collaterali',
                value: injection.sideEffects!,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
