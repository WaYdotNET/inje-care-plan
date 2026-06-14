import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Legenda dei colori di stato (schema "Accent-led"), riusabile in Home e
/// Calendario. "Oggi" non è una voce: è l'iniziale del giorno in grassetto viola.
class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.darkMuted : AppTokens.lightSubtle;
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: AppTokens.accent, label: 'Fatta', icon: Icons.check, textColor: textColor),
        _LegendItem(color: AppTokens.accentSoft, label: 'Da fare', textColor: textColor),
        _LegendItem(color: AppTokens.skipBg, label: 'Saltata/Persa', icon: Icons.close, iconColor: AppTokens.skipFg, textColor: textColor),
        _LegendItem(color: AppTokens.dotEmpty, label: 'Nessuna', small: true, textColor: textColor),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textColor,
    this.icon,
    this.iconColor,
    this.small = false,
  });

  final Color color;
  final String label;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 8.0 : 13.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: icon == null ? null : Icon(icon, size: 8, color: iconColor ?? Colors.white),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }
}
