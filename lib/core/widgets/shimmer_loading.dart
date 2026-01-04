import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Widget per loading shimmer effect
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkOverlay : Colors.grey.shade300,
      highlightColor: isDark ? AppColors.darkHighlightMed : Colors.grey.shade100,
      child: child,
    );
  }
}

/// Placeholder card per shimmer
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerLoading(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Placeholder testo per shimmer
class ShimmerText extends StatelessWidget {
  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 16,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Placeholder lista per shimmer
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 70,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _ShimmerListItem(height: itemHeight),
        ),
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerLoading(
      child: Row(
        children: [
          // Avatar
          Container(
            width: height - 20,
            height: height - 20,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer per statistiche
class ShimmerStats extends StatelessWidget {
  const ShimmerStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: Column(
        children: [
          // Overview card
          ShimmerCard(height: 180),
          SizedBox(height: 16),

          // Chart
          ShimmerCard(height: 200),
          SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(child: ShimmerCard(height: 100)),
              SizedBox(width: 12),
              Expanded(child: ShimmerCard(height: 100)),
            ],
          ),
        ],
      ),
    );
  }
}
