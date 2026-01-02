import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/body_zone.dart';
import 'injection_provider.dart';

/// Body map screen for zone selection
class BodyMapScreen extends ConsumerWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(bodyZonesProvider);
    final suggestedAsync = ref.watch(suggestedNextPointProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona zona'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (zones) {
          // Use default zones if empty
          final displayZones = zones.isEmpty ? BodyZone.defaults : zones;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Suggested point card
                suggestedAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (suggested) {
                    if (suggested == null) return const SizedBox();
                    final zone = displayZones.firstWhere(
                      (z) => z.id == suggested.zoneId,
                      orElse: () => displayZones.first,
                    );
                    return _SuggestedCard(
                      zone: zone,
                      pointNumber: suggested.pointNumber,
                      isDark: isDark,
                      onTap: () => context.push('/zone/${zone.id}'),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Body map illustration
                _BodyMapIllustration(
                  zones: displayZones,
                  isDark: isDark,
                  onZoneTap: (zoneId) => context.push('/zone/$zoneId'),
                ),

                const SizedBox(height: 24),

                Text(
                  'Zone disponibili:',
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 16),

                // Zone grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: displayZones.where((z) => z.isEnabled).map((zone) {
                    return _ZoneCard(
                      zone: zone,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({
    required this.zone,
    required this.pointNumber,
    required this.isDark,
    required this.onTap,
  });

  final BodyZone zone;
  final int pointNumber;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isDark
          ? AppColors.darkPine.withValues(alpha: 0.2)
          : AppColors.dawnPine.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isDark ? AppColors.darkPine : AppColors.dawnPine,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggerito',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone.pointLabel(pointNumber),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Text(zone.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyMapIllustration extends StatelessWidget {
  const _BodyMapIllustration({
    required this.zones,
    required this.isDark,
    required this.onZoneTap,
  });

  final List<BodyZone> zones;
  final bool isDark;
  final void Function(int zoneId) onZoneTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body silhouette
          Icon(
            Icons.accessibility_new,
            size: 200,
            color: isDark ? AppColors.darkSubtle.withValues(alpha: 0.3) : AppColors.dawnSubtle.withValues(alpha: 0.3),
          ),

          // Zone buttons
          // Arms
          Positioned(
            left: 30,
            top: 80,
            child: _ZoneButton(
              zoneId: 4,
              label: 'BS',
              isDark: isDark,
              onTap: () => onZoneTap(4),
            ),
          ),
          Positioned(
            right: 30,
            top: 80,
            child: _ZoneButton(
              zoneId: 3,
              label: 'BD',
              isDark: isDark,
              onTap: () => onZoneTap(3),
            ),
          ),

          // Abdomen
          Positioned(
            left: 100,
            top: 120,
            child: _ZoneButton(
              zoneId: 6,
              label: 'AS',
              isDark: isDark,
              onTap: () => onZoneTap(6),
            ),
          ),
          Positioned(
            right: 100,
            top: 120,
            child: _ZoneButton(
              zoneId: 5,
              label: 'AD',
              isDark: isDark,
              onTap: () => onZoneTap(5),
            ),
          ),

          // Thighs
          Positioned(
            left: 85,
            bottom: 60,
            child: _ZoneButton(
              zoneId: 2,
              label: 'CS',
              isDark: isDark,
              onTap: () => onZoneTap(2),
            ),
          ),
          Positioned(
            right: 85,
            bottom: 60,
            child: _ZoneButton(
              zoneId: 1,
              label: 'CD',
              isDark: isDark,
              onTap: () => onZoneTap(1),
            ),
          ),

          // Buttocks (shown smaller as they're behind)
          Positioned(
            left: 120,
            top: 160,
            child: _ZoneButton(
              zoneId: 8,
              label: 'GS',
              isDark: isDark,
              onTap: () => onZoneTap(8),
              size: 32,
            ),
          ),
          Positioned(
            right: 120,
            top: 160,
            child: _ZoneButton(
              zoneId: 7,
              label: 'GD',
              isDark: isDark,
              onTap: () => onZoneTap(7),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneButton extends StatelessWidget {
  const _ZoneButton({
    required this.zoneId,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.size = 40,
  });

  final int zoneId;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkPine : AppColors.dawnPine,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.isDark,
  });

  final BodyZone zone;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/zone/${zone.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(zone.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                zone.name,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                '${zone.numberOfPoints} punti',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
