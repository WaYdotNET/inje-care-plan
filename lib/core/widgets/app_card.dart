import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Card di superficie con ombra morbida; bordo accento opzionale.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.accentBorder = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool accentBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTokens.darkSurface : AppTokens.lightSurface;
    final border = accentBorder
        ? AppTokens.accent
        : (isDark ? AppTokens.darkBorder : AppTokens.lightBorder);

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: accentBorder ? 2 : 1),
        boxShadow: AppTokens.softShadow(dark: isDark),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
