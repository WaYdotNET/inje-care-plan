import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';

/// Lightweight view-model for a single injection, usable without a DB import.
class AgendaInjection {
  const AgendaInjection({
    required this.id,
    required this.scheduledAt,
    required this.pointLabel,
    required this.status,
  });

  final int id;
  final DateTime scheduledAt;
  final String pointLabel;

  /// One of: 'scheduled' | 'completed' | 'skipped' | 'missed'
  final String status;
}

/// Scrollable weekly agenda: Mon→Sun of the given week.
/// Each day renders a tappable [AppCard] row when an injection exists,
/// or a muted "Nessuna iniezione" row otherwise.
class WeekAgendaView extends StatelessWidget {
  const WeekAgendaView({
    super.key,
    required this.startOfWeek,
    required this.injections,
    required this.onTapInjection,
  });

  /// Monday of the week to display.
  final DateTime startOfWeek;

  /// All injections scheduled within this week (pre-filtered by the caller).
  final List<AgendaInjection> injections;

  /// Called when the user taps an injection row.
  final void Function(AgendaInjection) onTapInjection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, i) {
        final day = startOfWeek.add(Duration(days: i));
        final dayDate = DateTime(day.year, day.month, day.day);
        final isToday = dayDate == todayDate;

        // Find injection for this day (if any).
        AgendaInjection? injection;
        for (final inj in injections) {
          final injDate = DateTime(
            inj.scheduledAt.year,
            inj.scheduledAt.month,
            inj.scheduledAt.day,
          );
          if (injDate == dayDate) {
            injection = inj;
            break;
          }
        }

        return KeyedSubtree(
          key: Key('day_row_$i'),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            accentBorder: isToday,
            onTap: injection != null ? () => onTapInjection(injection!) : null,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    DateFormat('EEE d', 'it_IT').format(day),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isToday
                          ? AppTokens.accent
                          : (isDark ? AppTokens.darkMuted : AppTokens.lightMuted),
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: injection != null
                      ? _InjectionInfo(
                          injection: injection,
                          isToday: isToday,
                          isDark: isDark,
                          theme: theme,
                        )
                      : Text(
                          'Nessuna iniezione',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTokens.darkMuted
                                : AppTokens.lightMuted,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InjectionInfo extends StatelessWidget {
  const _InjectionInfo({
    required this.injection,
    required this.isToday,
    required this.isDark,
    required this.theme,
  });

  final AgendaInjection injection;
  final bool isToday;
  final bool isDark;
  final ThemeData theme;

  InjectionVisualStatus _toVisualStatus() {
    if (isToday && injection.status == 'scheduled') {
      return InjectionVisualStatus.today;
    }
    return switch (injection.status) {
      'completed' => InjectionVisualStatus.completed,
      'skipped' => InjectionVisualStatus.skipped,
      'missed' => InjectionVisualStatus.missed,
      _ => InjectionVisualStatus.scheduled,
    };
  }

  String _chipLabel() {
    if (isToday && injection.status == 'scheduled') return 'Oggi';
    return switch (injection.status) {
      'completed' => 'Fatta',
      'skipped' => 'Saltata',
      'missed' => 'Persa',
      _ => 'Programmata',
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(injection.scheduledAt);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                injection.pointLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTokens.darkInk : AppTokens.lightInk,
                ),
              ),
              Text(
                timeStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                ),
              ),
            ],
          ),
        ),
        StatusChip(
          label: _chipLabel(),
          status: _toVisualStatus(),
        ),
      ],
    );
  }
}
