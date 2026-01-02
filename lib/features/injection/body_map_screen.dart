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
    final suggestedAsync = ref.watch(suggestedNextPointProvider);
    
    // Use predefined zones (they are static)
    final displayZones = BodyZone.defaults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona zona'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
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
      color: isDark ? AppColors.darkHighlightLow : AppColors.dawnHighlightLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    zone.pointLabel(pointNumber).split(' · ')[1],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? AppColors.darkBase : AppColors.dawnBase,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prossima iniezione suggerita',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                      ),
                    ),
                    Text(
                      zone.pointLabel(pointNumber),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      zone.pointCode(pointNumber),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
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
  final void Function(int) onZoneTap;

  @override
  Widget build(BuildContext context) {
    // Simplified body map with tappable zones
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.dawnSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkHighlightMed : AppColors.dawnHighlightMed,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body outline placeholder
          Icon(
            Icons.accessibility_new,
            size: 200,
            color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted).withValues(alpha: 0.3),
          ),

          // Zone labels
          // Thighs
          Positioned(
            bottom: 50,
            left: 60,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 1),
              isDark: isDark,
              onTap: () => onZoneTap(1),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 60,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 2),
              isDark: isDark,
              onTap: () => onZoneTap(2),
            ),
          ),

          // Arms
          Positioned(
            top: 100,
            left: 20,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 3),
              isDark: isDark,
              onTap: () => onZoneTap(3),
            ),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 4),
              isDark: isDark,
              onTap: () => onZoneTap(4),
            ),
          ),

          // Abdomen
          Positioned(
            top: 120,
            left: 100,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 5),
              isDark: isDark,
              onTap: () => onZoneTap(5),
            ),
          ),
          Positioned(
            top: 120,
            right: 100,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 6),
              isDark: isDark,
              onTap: () => onZoneTap(6),
            ),
          ),

          // Glutes
          Positioned(
            bottom: 120,
            left: 80,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 7),
              isDark: isDark,
              onTap: () => onZoneTap(7),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 80,
            child: _ZoneLabel(
              zone: zones.firstWhere((z) => z.id == 8),
              isDark: isDark,
              onTap: () => onZoneTap(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({
    required this.zone,
    required this.isDark,
    required this.onTap,
  });

  final BodyZone zone;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkFoam.withValues(alpha: 0.9)
                : AppColors.dawnFoam.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            zone.code,
            style: TextStyle(
              color: isDark ? AppColors.darkBase : AppColors.dawnBase,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone.code,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                zone.name,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              Text(
                '${zone.pointCount} punti',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
