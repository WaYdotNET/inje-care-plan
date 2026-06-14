import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/injection_status_colors.dart';
import '../../../core/database/app_database.dart' as db;

/// Reusable widget that renders the full injection history grouped by month.
///
/// Usato dalla vista "Lista" del Calendario (assorbe lo storico iniezioni).
class InjectionHistoryList extends StatelessWidget {
  const InjectionHistoryList({
    super.key,
    required this.injections,
    this.onTapInjection,
  });

  final List<db.Injection> injections;

  /// Optional tap override. When null, cards navigate to the injection
  /// detail route directly (default behaviour matching the original screen).
  final void Function(db.Injection)? onTapInjection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (injections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsDuotone.clockCounterClockwise,
              size: 64,
              color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna iniezione registrata',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? AppTokens.darkSubtle : AppTokens.lightSubtle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le tue iniezioni appariranno qui',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
              ),
            ),
          ],
        ),
      );
    }

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
          onTapInjection: onTapInjection,
        );
      },
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
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.injections,
    required this.isDark,
    this.onTapInjection,
  });

  final String month;
  final List<db.Injection> injections;
  final bool isDark;
  final void Function(db.Injection)? onTapInjection;

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
              color: isDark ? AppTokens.darkSubtle : AppTokens.lightSubtle,
            ),
          ),
        ),
        ...injections.map(
          (inj) => _HistoryCard(
            injection: inj,
            isDark: isDark,
            onTap: onTapInjection,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.injection,
    required this.isDark,
    this.onTap,
  });

  final db.Injection injection;
  final bool isDark;
  final void Function(db.Injection)? onTap;

  Color get _statusColor =>
      InjectionStatusColors.getStatusColor(injection.status, isDark: isDark);

  String get _statusLabel => switch (injection.status) {
    'completed' => 'Completata',
    'skipped' => 'Saltata',
    'delayed' => 'In ritardo',
    'scheduled' => 'Programmata',
    'missed' => 'Mancata',
    _ => 'Sconosciuto',
  };

  String get _emoji => switch (injection.zoneId) {
    1 => '🍗', 2 => '🍗',
    3 => '💪', 4 => '💪',
    5 => '🐢', 6 => '🐢',
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
        onTap: () {
          if (onTap != null) {
            onTap!(injection);
          } else {
            context.push(AppRoutes.injectionDetailPath(injection.id));
          }
        },
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
                      ? AppTokens.darkHighlightLow
                      : AppTokens.lightHighlightLow,
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
                        if (injection.sideEffects.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            PhosphorIconsDuotone.warning,
                            size: 14,
                            color: isDark
                                ? AppTokens.warnDark
                                : AppTokens.warnLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${injection.sideEffects.split(',').length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTokens.warnDark
                                  : AppTokens.warnLight,
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
}
