import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A wrapper that centers and limits the width of its child on large screens.
/// This prevents the UI from stretching too much on ultrawide monitors.
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTokens.darkBg : AppTokens.lightBgTop;
    return ColoredBox(
      color: backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
