import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_tokens.dart';

/// Enum per indicare il livello di utilizzo del punto.
enum PointUsageLevel {
  neverUsed, // Mai usato - verde
  safe, // >14 giorni - verde
  caution, // 7-14 giorni - giallo
  warning, // 3-7 giorni - arancione
  avoid, // <3 giorni - rosso
}

extension PointUsageLevelExtension on PointUsageLevel {
  Color getColor(bool isDark) {
    return switch (this) {
      // Colori distinti per stato, così i punti spiccano sul corpo (mono viola):
      // verde = disponibile, ambra/arancio = recente, rosso = da evitare.
      PointUsageLevel.neverUsed =>
        isDark ? AppTokens.successDark : AppTokens.successLight,
      PointUsageLevel.safe =>
        isDark ? AppTokens.successDark : AppTokens.successLight,
      PointUsageLevel.caution =>
        isDark ? AppTokens.warnDark : AppTokens.warnLight,
      PointUsageLevel.warning =>
        isDark ? AppTokens.warnDark : AppTokens.warnLight,
      PointUsageLevel.avoid =>
        isDark ? AppTokens.dangerDark : AppTokens.dangerLight,
    };
  }

  String get label => switch (this) {
    PointUsageLevel.neverUsed => 'Mai usato',
    PointUsageLevel.safe => 'Consigliato',
    PointUsageLevel.caution => 'Attenzione',
    PointUsageLevel.warning => 'Recente',
    PointUsageLevel.avoid => 'Evitare',
  };

  IconData get icon => switch (this) {
    PointUsageLevel.neverUsed => PhosphorIconsDuotone.star,
    PointUsageLevel.safe => PhosphorIconsDuotone.checkCircle,
    PointUsageLevel.caution => PhosphorIconsDuotone.info,
    PointUsageLevel.warning => PhosphorIconsDuotone.warning,
    PointUsageLevel.avoid => PhosphorIconsDuotone.prohibit,
  };

  static PointUsageLevel fromDaysSinceLastUse(int? days) {
    if (days == null) return PointUsageLevel.neverUsed;
    if (days > 14) return PointUsageLevel.safe;
    if (days >= 7) return PointUsageLevel.caution;
    if (days >= 3) return PointUsageLevel.warning;
    return PointUsageLevel.avoid;
  }
}
