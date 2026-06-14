import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Stati visivi per il chip semaforo.
enum InjectionVisualStatus { completed, scheduled, skipped, missed, today, neutral }

/// Pill compatta per indicare lo stato di un'iniezione/punto.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.status = InjectionVisualStatus.neutral});

  final String label;
  final InjectionVisualStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    switch (status) {
      case InjectionVisualStatus.completed:
        fg = isDark ? AppTokens.successDark : AppTokens.successLight;
        bg = fg.withValues(alpha: 0.16);
      case InjectionVisualStatus.scheduled:
        fg = isDark ? AppTokens.warnDark : AppTokens.warnLight;
        bg = fg.withValues(alpha: 0.16);
      case InjectionVisualStatus.skipped:
      case InjectionVisualStatus.missed:
        fg = isDark ? AppTokens.dangerDark : AppTokens.dangerLight;
        bg = fg.withValues(alpha: 0.16);
      case InjectionVisualStatus.today:
        fg = Colors.white;
        bg = Colors.transparent;
      case InjectionVisualStatus.neutral:
        fg = isDark ? AppTokens.darkInk : AppTokens.accent;
        bg = AppTokens.accent.withValues(alpha: isDark ? 0.18 : 0.12);
    }

    final isToday = status == InjectionVisualStatus.today;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isToday ? null : bg,
        gradient: isToday ? AppTokens.accentGradient : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
