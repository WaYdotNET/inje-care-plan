import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// LEGACY: i nomi Rosé Pine sono mantenuti come ALIAS di compatibilità,
/// rimappati ai token "Pop Gradient" (vedi [AppTokens]). Molte schermate li
/// referenziano ancora; il rename completo verso AppTokens è un follow-up.
/// NON aggiungere nuovi usi: preferire direttamente AppTokens.
sealed class AppColors {
  // ==========================================================================
  // LIGHT (alias → Pop Gradient light)
  // ==========================================================================
  static const dawnBase = AppTokens.lightBgTop;
  static const dawnSurface = AppTokens.lightSurface;
  static const dawnOverlay = AppTokens.lightBgBottom;
  static const dawnMuted = AppTokens.lightMuted;
  static const dawnSubtle = AppTokens.lightSubtle;
  static const dawnText = AppTokens.lightInk;
  static const dawnLove = AppTokens.dangerLight;
  static const dawnGold = AppTokens.warnLight;
  static const dawnRose = AppTokens.pink;
  static const dawnPine = AppTokens.accent;
  static const dawnFoam = AppTokens.accentEnd;
  static const dawnIris = AppTokens.accent;
  static const dawnHighlightLow = Color(0xFFF3EEFB);
  static const dawnHighlightMed = AppTokens.lightBorder;
  static const dawnHighlightHigh = Color(0xFFD9CFEC);
  static const dawnSuccess = AppTokens.successLight;

  // ==========================================================================
  // DARK (alias → Pop Gradient dark)
  // ==========================================================================
  static const darkBase = AppTokens.darkBg;
  static const darkSurface = AppTokens.darkSurface;
  static const darkOverlay = Color(0xFF241B3A);
  static const darkMuted = AppTokens.darkMuted;
  static const darkSubtle = Color(0xFFA79EC4);
  static const darkText = AppTokens.darkInk;
  static const darkLove = AppTokens.dangerDark;
  static const darkGold = AppTokens.warnDark;
  static const darkRose = Color(0xFFF0A7C9);
  static const darkPine = AppTokens.accent;
  static const darkFoam = AppTokens.accentEnd;
  static const darkIris = Color(0xFFC9B6FF);
  static const darkHighlightLow = Color(0xFF181226);
  static const darkHighlightMed = AppTokens.darkBorder;
  static const darkHighlightHigh = Color(0xFF3A2F58);
  static const darkSuccess = AppTokens.successDark;
}

/// Semantic colors for injection status (schema "semaforo": verde/giallo/rosso)
extension InjectionStatusColors on AppColors {
  /// Get color for injection status (light mode)
  static Color getStatusColorLight(String status) => switch (status) {
    'completed' => AppColors.dawnSuccess,
    'scheduled' => AppColors.dawnGold,
    'delayed' => AppColors.dawnGold,
    'skipped' => AppColors.dawnLove,
    'missed' => AppColors.dawnLove,
    'blacklisted' => AppColors.dawnMuted,
    _ => AppColors.dawnSubtle,
  };

  /// Get color for injection status (dark mode)
  static Color getStatusColorDark(String status) => switch (status) {
    'completed' => AppColors.darkSuccess,
    'scheduled' => AppColors.darkGold,
    'delayed' => AppColors.darkGold,
    'skipped' => AppColors.darkLove,
    'missed' => AppColors.darkLove,
    'blacklisted' => AppColors.darkMuted,
    _ => AppColors.darkSubtle,
  };

  /// Convenience: pick the right variant based on brightness.
  static Color getStatusColor(String status, {required bool isDark}) =>
      isDark ? getStatusColorDark(status) : getStatusColorLight(status);
}
