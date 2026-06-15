import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_tokens.dart';

/// Stato di un giorno nella striscia settimanale.
enum DayStatus { done, scheduled, skipped, missed, none }

/// Mappa lo `status` di un'iniezione (stringa DB) nel relativo [DayStatus].
DayStatus dayStatusFromString(String status) => switch (status) {
      'completed' => DayStatus.done,
      'skipped' => DayStatus.skipped,
      'missed' => DayStatus.missed,
      _ => DayStatus.scheduled,
    };

/// Striscia compatta dei 7 giorni (Lun→Dom) con pallino di stato "Accent-led".
/// Oggi è evidenziato dall'iniziale del giorno in grassetto viola.
/// Quando [counts] è fornito e `counts[i] > 1`, mostra un badge con il
/// conteggio nell'angolo in alto a destra del pallino.
class WeekDots extends StatelessWidget {
  const WeekDots({
    super.key,
    required this.weekStart,
    required this.statuses,
    this.counts,
    this.onTapDay,
  })  : assert(statuses.length == 7, 'statuses deve avere 7 elementi (Lun→Dom)'),
        assert(
          counts == null || counts.length == 7,
          'counts deve avere 7 elementi (Lun→Dom)',
        );

  final DateTime weekStart;
  final List<DayStatus> statuses;

  /// Conteggio iniezioni per giorno (lunedì = indice 0). Opzionale.
  /// Un badge appare solo quando il valore è > 1.
  final List<int>? counts;
  final void Function(int index)? onTapDay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return Row(
      children: List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        final isToday = day == todayKey;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapDay == null ? null : () => onTapDay!(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEEE', 'it').format(day).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                    color: isToday ? AppTokens.accent : mutedColor,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusDot(
                  status: statuses[i],
                  count: counts?[i],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.status,
    this.count,
  });

  final DayStatus status;

  /// Se > 1, mostra un piccolo badge con il numero nell'angolo in alto a destra.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final dot = switch (status) {
      DayStatus.none => Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTokens.dotEmpty,
            shape: BoxShape.circle,
          ),
        ),
      DayStatus.done => _circle(
          AppTokens.accent,
          const Icon(PhosphorIconsDuotone.check, size: 13, color: Colors.white),
        ),
      DayStatus.scheduled => _circle(AppTokens.accentSoft, null),
      DayStatus.skipped || DayStatus.missed => _circle(
          AppTokens.skipBg,
          const Icon(
            PhosphorIconsDuotone.x,
            size: 12,
            color: AppTokens.skipFg,
          ),
        ),
    };

    final showBadge = count != null && count! > 1;
    if (!showBadge) return dot;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dot,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(Color bg, Widget? child) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: child,
      );
}
