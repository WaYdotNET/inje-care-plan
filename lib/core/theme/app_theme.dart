import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Tema dell'app — design system "Pop Gradient".
sealed class AppTheme {
  static const _font = 'Plus Jakarta Sans';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    surface: AppTokens.lightSurface,
    ink: AppTokens.lightInk,
    muted: AppTokens.lightMuted,
    subtle: AppTokens.lightSubtle,
    border: AppTokens.lightBorder,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    surface: AppTokens.darkSurface,
    ink: AppTokens.darkInk,
    muted: AppTokens.darkMuted,
    subtle: AppTokens.darkMuted,
    border: AppTokens.darkBorder,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color subtle,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppTokens.accent,
      onPrimary: Colors.white,
      secondary: AppTokens.pink,
      onSecondary: Colors.white,
      error: isDark ? AppTokens.dangerDark : AppTokens.dangerLight,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: isDark ? AppTokens.darkBg : AppTokens.lightBgBottom,
      outline: muted,
      outlineVariant: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _font,
      colorScheme: scheme,
      // Sfondo solido (non trasparente) per evitare il flash bianco durante le
      // transizioni: lo Scaffold trasparente lasciava intravedere il bianco di
      // base prima che il gradiente venisse dipinto.
      scaffoldBackgroundColor: isDark ? AppTokens.darkBg : AppTokens.lightBgTop,
      cardColor: surface,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.accent,
          side: const BorderSide(color: AppTokens.accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppTokens.accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppTokens.darkBg : AppTokens.lightBgBottom,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppTokens.accent, width: 2),
        ),
        labelStyle: TextStyle(color: subtle),
        hintStyle: TextStyle(color: muted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightInk,
        contentTextStyle: TextStyle(
          fontFamily: _font,
          color: isDark ? AppTokens.darkInk : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppTokens.darkBg : AppTokens.lightBgBottom,
        selectedColor: AppTokens.accent,
        labelStyle: TextStyle(fontFamily: _font, color: ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      textTheme: _textTheme(ink, subtle),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: primary),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: primary),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: primary),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: primary),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primary),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secondary),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: secondary),
  );
}
