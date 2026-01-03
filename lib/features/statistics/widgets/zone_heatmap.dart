import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../statistics_provider.dart';

/// Heatmap delle zone più utilizzate
class ZoneHeatmap extends StatelessWidget {
  const ZoneHeatmap({
    super.key,
    required this.zoneUsage,
  });

  final List<ZoneUsage> zoneUsage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (zoneUsage.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato disponibile',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
          ),
        ),
      );
    }

    // Trova il massimo per normalizzare i colori
    final maxCount = zoneUsage.map((z) => z.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: zoneUsage.map((zone) {
        final intensity = maxCount > 0 ? zone.count / maxCount : 0.0;
        return _ZoneHeatmapItem(
          zone: zone,
          intensity: intensity,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _ZoneHeatmapItem extends StatelessWidget {
  const _ZoneHeatmapItem({
    required this.zone,
    required this.intensity,
    required this.isDark,
  });

  final ZoneUsage zone;
  final double intensity;
  final bool isDark;

  Color _getHeatColor(double intensity) {
    // Da verde chiaro (poco usata) a rosso (molto usata)
    if (intensity < 0.25) {
      return isDark ? AppColors.darkPine.withValues(alpha: 0.3) : AppColors.dawnPine.withValues(alpha: 0.3);
    } else if (intensity < 0.5) {
      return isDark ? AppColors.darkPine.withValues(alpha: 0.5) : AppColors.dawnPine.withValues(alpha: 0.5);
    } else if (intensity < 0.75) {
      return isDark ? AppColors.darkGold.withValues(alpha: 0.7) : AppColors.dawnGold.withValues(alpha: 0.7);
    } else {
      return isDark ? AppColors.darkLove.withValues(alpha: 0.8) : AppColors.dawnLove.withValues(alpha: 0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heatColor = _getHeatColor(intensity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Emoji e nome
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Text(zone.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.zoneName,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Barra con gradiente
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: intensity.clamp(0.05, 1.0),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          heatColor.withValues(alpha: 0.6),
                          heatColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Label
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${zone.count} (${zone.percentage.toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: intensity > 0.5 ? Colors.white : null,
                      ),
                    ),
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

/// Card con statistiche di una singola zona
class ZoneStatsCard extends StatelessWidget {
  const ZoneStatsCard({
    super.key,
    required this.zone,
  });

  final ZoneUsage zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji grande
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkOverlay
                    : AppColors.dawnOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(zone.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.zoneName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zone.count} iniezioni (${zone.percentage.toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                  if (zone.lastUsed != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ultima: ${_formatDate(zone.lastUsed!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Oggi';
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} settimane fa';
    } else {
      return '${(diff.inDays / 30).floor()} mesi fa';
    }
  }
}
