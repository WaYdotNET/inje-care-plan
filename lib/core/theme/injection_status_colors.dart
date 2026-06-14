import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Colori semantici per lo stato dell'iniezione (schema "semaforo":
/// verde = completata, giallo = programmata/in ritardo, rosso = saltata/persa).
sealed class InjectionStatusColors {
  /// Colore per lo stato (light mode).
  static Color getStatusColorLight(String status) => switch (status) {
    'completed' => AppTokens.successLight,
    'scheduled' => AppTokens.warnLight,
    'delayed' => AppTokens.warnLight,
    'skipped' => AppTokens.dangerLight,
    'missed' => AppTokens.dangerLight,
    'blacklisted' => AppTokens.lightMuted,
    _ => AppTokens.lightSubtle,
  };

  /// Colore per lo stato (dark mode).
  static Color getStatusColorDark(String status) => switch (status) {
    'completed' => AppTokens.successDark,
    'scheduled' => AppTokens.warnDark,
    'delayed' => AppTokens.warnDark,
    'skipped' => AppTokens.dangerDark,
    'missed' => AppTokens.dangerDark,
    'blacklisted' => AppTokens.darkMuted,
    _ => AppTokens.darkSubtle,
  };

  /// Sceglie la variante in base alla luminosità.
  static Color getStatusColor(String status, {required bool isDark}) =>
      isDark ? getStatusColorDark(status) : getStatusColorLight(status);
}
