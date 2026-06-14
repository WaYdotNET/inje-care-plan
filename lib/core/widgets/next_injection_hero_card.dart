import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_tokens.dart';

/// Stato dell'hero "Prossima iniezione".
enum HeroState { upcoming, overdue, future, allDone, none }

/// Determina lo stato dell'hero dalla prossima schedulata, dall'ora e dal fatto
/// che oggi ci sia già un'iniezione completata.
HeroState heroStateFor({
  required DateTime? nextScheduledAt,
  required DateTime now,
  required bool hasCompletedToday,
}) {
  if (nextScheduledAt == null) {
    return hasCompletedToday ? HeroState.allDone : HeroState.none;
  }
  final today = DateTime(now.year, now.month, now.day);
  final nextDay = DateTime(
    nextScheduledAt.year,
    nextScheduledAt.month,
    nextScheduledAt.day,
  );
  if (nextDay.isAfter(today)) return HeroState.future;
  return nextScheduledAt.isAfter(now) ? HeroState.upcoming : HeroState.overdue;
}

/// Card hero a gradiente "Prossima iniezione" per la Home.
class NextInjectionHeroCard extends StatelessWidget {
  const NextInjectionHeroCard({
    super.key,
    required this.state,
    required this.pointLabel,
    required this.scheduledAt,
    required this.ctaLabel,
    required this.onCta,
  }) : assert(
          state != HeroState.allDone && state != HeroState.none,
          'NextInjectionHeroCard is only for upcoming/overdue/future states',
        );

  final HeroState state;
  final String pointLabel;
  final DateTime scheduledAt;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = state == HeroState.overdue
        ? AppTokens.warnGradient
        : AppTokens.accentGradient;

    final IconData icon;
    switch (state) {
      case HeroState.upcoming:
        icon = PhosphorIconsDuotone.clock;
      case HeroState.overdue:
        icon = PhosphorIconsDuotone.warning;
      case HeroState.future:
        icon = PhosphorIconsDuotone.calendarBlank;
      case HeroState.allDone:
      case HeroState.none:
        icon = PhosphorIconsDuotone.calendarBlank;
    }

    final String chipText;
    switch (state) {
      case HeroState.upcoming:
        chipText = 'PROSSIMA · ${DateFormat('HH:mm').format(scheduledAt)}';
      case HeroState.overdue:
        chipText = 'IN RITARDO · ${DateFormat('HH:mm').format(scheduledAt)}';
      case HeroState.future:
        chipText =
            'PROSSIMA · ${DateFormat('EEE d', 'it').format(scheduledAt)} · ${DateFormat('HH:mm').format(scheduledAt)}';
      case HeroState.allDone:
      case HeroState.none:
        chipText = '';
    }

    final sub = DateFormat('EEEE d MMM', 'it').format(scheduledAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppTokens.softShadow(dark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  chipText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pointLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: ctaLabel,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: onCta,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(
                      color: AppTokens.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
