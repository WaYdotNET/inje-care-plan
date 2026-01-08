import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background color for the areas outside the centered content
    final backgroundColor = isDark ? AppColors.darkBase : AppColors.dawnBase;

    return Container(
      color: backgroundColor,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If the screen is wider thanmaxWidth, we constrain it
            if (constraints.maxWidth > maxWidth) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(maxWidth, constraints.maxHeight),
                ),
                child: SizedBox(
                  width: maxWidth,
                  child: child,
                ),
              );
            }
            // Otherwise, let it be natural (mobile/tablet size)
            return child;
          },
        ),
      ),
    );
  }
}
