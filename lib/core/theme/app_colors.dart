import 'package:flutter/material.dart';

/// Rosé Pine color palette
/// Design system: https://rosepinetheme.com/palette/
sealed class AppColors {
  // ==========================================================================
  // ROSÉ PINE DAWN (Light Mode - Default)
  // ==========================================================================

  static const dawnBase = Color(0xFFfaf4ed);
  static const dawnSurface = Color(0xFFfffaf3);
  static const dawnOverlay = Color(0xFFf2e9e1);
  static const dawnMuted = Color(0xFF9893a5);
  static const dawnSubtle = Color(0xFF797593);
  static const dawnText = Color(0xFF575279);
  static const dawnLove = Color(0xFFb4637a);
  static const dawnGold = Color(0xFFea9d34);
  static const dawnRose = Color(0xFFd7827e);
  static const dawnPine = Color(0xFF286983);
  static const dawnFoam = Color(0xFF56949f);
  static const dawnIris = Color(0xFF907aa9);
  static const dawnHighlightLow = Color(0xFFf4ede8);
  static const dawnHighlightMed = Color(0xFFdfdad9);
  static const dawnHighlightHigh = Color(0xFFcecacd);

  // ==========================================================================
  // ROSÉ PINE (Dark Mode)
  // ==========================================================================

  static const darkBase = Color(0xFF191724);
  static const darkSurface = Color(0xFF1f1d2e);
  static const darkOverlay = Color(0xFF26233a);
  static const darkMuted = Color(0xFF6e6a86);
  static const darkSubtle = Color(0xFF908caa);
  static const darkText = Color(0xFFe0def4);
  static const darkLove = Color(0xFFeb6f92);
  static const darkGold = Color(0xFFf6c177);
  static const darkRose = Color(0xFFebbcba);
  static const darkPine = Color(0xFF31748f);
  static const darkFoam = Color(0xFF9ccfd8);
  static const darkIris = Color(0xFFc4a7e7);
  static const darkHighlightLow = Color(0xFF21202e);
  static const darkHighlightMed = Color(0xFF403d52);
  static const darkHighlightHigh = Color(0xFF524f67);
}

/// Semantic colors for injection status
extension InjectionStatusColors on AppColors {
  /// Get color for injection status (light mode)
  static Color getStatusColorLight(String status) => switch (status) {
    'completed' => AppColors.dawnPine,
    'scheduled' => AppColors.dawnFoam,
    'delayed' => AppColors.dawnGold,
    'skipped' => AppColors.dawnLove,
    'blacklisted' => AppColors.dawnMuted,
    _ => AppColors.dawnSubtle,
  };

  /// Get color for injection status (dark mode)
  static Color getStatusColorDark(String status) => switch (status) {
    'completed' => AppColors.darkPine,
    'scheduled' => AppColors.darkFoam,
    'delayed' => AppColors.darkGold,
    'skipped' => AppColors.darkLove,
    'blacklisted' => AppColors.darkMuted,
    _ => AppColors.darkSubtle,
  };
}
