import 'package:flutter/material.dart';

/// Design tokens del tema "Pop Gradient".
/// Nuovo sistema che sostituisce Rosé Pine (rimozione finale in una fase successiva).
sealed class AppTokens {
  // Accento
  static const accent = Color(0xFF7C5CFF);
  static const accentEnd = Color(0xFFC86BFF);
  static const pink = Color(0xFFE8569B);

  // Light
  static const lightBgTop = Color(0xFFFBF2FF);
  static const lightBgBottom = Color(0xFFEEF1FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF231A36);
  static const lightMuted = Color(0xFF9A8FC0);
  static const lightSubtle = Color(0xFF7A7393);
  static const lightBorder = Color(0xFFE5DEEF);

  // Dark
  static const darkBg = Color(0xFF0E0B16);
  static const darkSurface = Color(0xFF1C1530);
  static const darkInk = Color(0xFFECE7FB);
  static const darkMuted = Color(0xFF8A82A6);
  static const darkBorder = Color(0xFF2A2140);

  // Stati (semaforo)
  static const successLight = Color(0xFF2F8F6B);
  static const successDark = Color(0xFF8BC474);
  static const warnLight = Color(0xFFEA9D34);
  static const warnDark = Color(0xFFF6C177);
  static const dangerLight = Color(0xFFB4637A);
  static const dangerDark = Color(0xFFEB6F92);

  /// Gradiente accento (azioni primarie, "oggi", punto selezionato).
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentEnd],
  );

  /// Gradiente sfondo app (light).
  static const lightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBgTop, lightBgBottom],
  );

  /// Ombra morbida colorata; più intensa in dark (glow).
  static List<BoxShadow> softShadow({bool dark = false}) => [
    BoxShadow(
      color: accent.withValues(alpha: dark ? 0.30 : 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Raggi standard.
sealed class AppRadius {
  static const card = 20.0;
  static const button = 14.0;
  static const input = 14.0;
  static const pill = 999.0;
}

/// Scala di spaziatura.
sealed class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}
