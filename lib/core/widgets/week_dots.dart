import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
class WeekDots extends StatelessWidget {
  const WeekDots({
    super.key,
    required this.weekStart,
    required this.statuses,
    this.onTapDay,
  }) : assert(statuses.length == 7, 'statuses deve avere 7 elementi (Lun→Dom)');

  final DateTime weekStart;
  final List<DayStatus> statuses;
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
                _StatusDot(status: statuses[i]),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DayStatus.none:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppTokens.dotEmpty, shape: BoxShape.circle),
        );
      case DayStatus.done:
        return _circle(AppTokens.accent, const Icon(Icons.check, size: 13, color: Colors.white));
      case DayStatus.scheduled:
        return _circle(AppTokens.accentSoft, null);
      case DayStatus.skipped:
      case DayStatus.missed:
        return _circle(AppTokens.skipBg, const Icon(Icons.close, size: 12, color: AppTokens.skipFg));
    }
  }

  Widget _circle(Color bg, Widget? child) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: child,
      );
}
