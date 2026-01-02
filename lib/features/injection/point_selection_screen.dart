import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/app_database.dart' as db;
import '../../models/body_zone.dart';
import '../../models/blacklisted_point.dart' as models;
import 'injection_provider.dart';
import 'injection_repository.dart';

/// Unified screen for selecting injection points
/// Can be used for: recording injections, blacklisting points
enum PointSelectionMode {
  injection,
  blacklist,
}

class PointSelectionScreen extends ConsumerStatefulWidget {
  const PointSelectionScreen({
    super.key,
    required this.mode,
    this.initialZoneId,
  });

  final PointSelectionMode mode;
  final int? initialZoneId;

  @override
  ConsumerState<PointSelectionScreen> createState() => _PointSelectionScreenState();
}

class _PointSelectionScreenState extends ConsumerState<PointSelectionScreen> {
  int? _selectedZoneId;
  int? _selectedPoint;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedZoneId = widget.initialZoneId;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
    PointSelectionMode.injection => 'Seleziona punto iniezione',
    PointSelectionMode.blacklist => 'Escludi un punto',
  };

  String get _actionLabel => switch (widget.mode) {
    PointSelectionMode.injection => 'Registra iniezione',
    PointSelectionMode.blacklist => 'Escludi questo punto',
  };

  IconData get _actionIcon => switch (widget.mode) {
    PointSelectionMode.injection => Icons.add_circle_outline,
    PointSelectionMode.blacklist => Icons.block,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blacklistedAsync = ref.watch(blacklistedPointsProvider);
    final suggestedAsync = ref.watch(suggestedNextPointProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.mode == PointSelectionMode.injection
                            ? 'Seleziona una zona e poi il punto dove effettuare l\'iniezione.'
                            : 'Seleziona una zona e poi il punto che vuoi escludere dalla rotazione.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Suggested point (only for injection mode)
            if (widget.mode == PointSelectionMode.injection)
              suggestedAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (suggested) {
                  if (suggested == null) return const SizedBox();
                  final zone = BodyZone.defaults.firstWhere(
                    (z) => z.id == suggested.zoneId,
                    orElse: () => BodyZone.defaults.first,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _SuggestedPointCard(
                      zone: zone,
                      pointNumber: suggested.pointNumber,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _selectedZoneId = zone.id;
                          _selectedPoint = suggested.pointNumber;
                        });
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Body map illustration with injection areas
            Text(
              'Aree di iniezione raccomandate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Come indicato nelle linee guida Rebif®, le aree raccomandate sono: '
              'coscia, superficie esterna del braccio, addome e gluteo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
            ),
            const SizedBox(height: 16),

            _InjectionAreasIllustration(
              selectedZoneId: _selectedZoneId,
              isDark: isDark,
              onZoneTap: (zoneId) {
                setState(() {
                  _selectedZoneId = zoneId;
                  _selectedPoint = null;
                });
              },
            ),

            const SizedBox(height: 24),

            // Zone detail with point positions
            if (_selectedZoneId != null) ...[
              _ZoneDetailCard(
                zone: BodyZone.defaults.firstWhere((z) => z.id == _selectedZoneId),
                selectedPoint: _selectedPoint,
                isDark: isDark,
                onPointTap: (point) => setState(() => _selectedPoint = point),
                blacklistedAsync: blacklistedAsync,
              ),
              const SizedBox(height: 24),
            ],

            // Reason field (only for blacklist mode)
            if (widget.mode == PointSelectionMode.blacklist) ...[
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Motivo (opzionale)',
                  hintText: 'Es: cicatrice, reazione, difficile da raggiungere',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.dawnSurface,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedZoneId != null && _selectedPoint != null
                    ? _performAction
                    : null,
                icon: Icon(_actionIcon),
                label: Text(_actionLabel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.mode == PointSelectionMode.blacklist
                      ? (isDark ? AppColors.darkLove : AppColors.dawnLove)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction() async {
    if (_selectedZoneId == null || _selectedPoint == null) return;

    final zone = BodyZone.defaults.firstWhere((z) => z.id == _selectedZoneId);

    if (widget.mode == PointSelectionMode.injection) {
      // Navigate to record screen with selected point
      context.push(
        '/record',
        extra: {'zoneId': _selectedZoneId, 'pointNumber': _selectedPoint},
      );
    } else {
      // Blacklist the point
      final reason = _reasonController.text.isNotEmpty
          ? _reasonController.text
          : 'Non specificato';

      final db = ref.read(databaseProvider);
      final repository = InjectionRepository(database: db);

      await repository.blacklistPoint(
        models.BlacklistedPoint(
          zoneId: zone.id,
          pointNumber: _selectedPoint!,
          reason: reason,
          blacklistedAt: DateTime.now(),
        ),
      );

      ref.invalidate(blacklistedPointsProvider);

      if (mounted) {
        final label = zone.pointLabel(_selectedPoint!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Punto $label escluso'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkPine
                : AppColors.dawnPine,
          ),
        );
        context.pop();
      }
    }
  }
}

/// Suggested point card
class _SuggestedPointCard extends StatelessWidget {
  const _SuggestedPointCard({
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggerito: ${zone.pointLabel(pointNumber)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tocca per selezionare automaticamente',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.touch_app,
                color: isDark ? AppColors.darkPine : AppColors.dawnPine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body illustration with injection areas highlighted
class _InjectionAreasIllustration extends StatelessWidget {
  const _InjectionAreasIllustration({
    required this.selectedZoneId,
    required this.isDark,
    required this.onZoneTap,
  });

  final int? selectedZoneId;
  final bool isDark;
  final void Function(int) onZoneTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Front view
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side zones
                Expanded(
                  child: Column(
                    children: [
                      _ZoneButton(
                        zoneId: 3,
                        code: 'BD',
                        name: 'Braccio Dx',
                        description: 'Superficie esterna',
                        icon: '💪',
                        isSelected: selectedZoneId == 3,
                        isDark: isDark,
                        onTap: () => onZoneTap(3),
                      ),
                      const SizedBox(height: 12),
                      _ZoneButton(
                        zoneId: 5,
                        code: 'AD',
                        name: 'Addome Dx',
                        description: 'Lontano dall\'ombelico',
                        icon: '💧',
                        isSelected: selectedZoneId == 5,
                        isDark: isDark,
                        onTap: () => onZoneTap(5),
                      ),
                      const SizedBox(height: 12),
                      _ZoneButton(
                        zoneId: 1,
                        code: 'CD',
                        name: 'Coscia Dx',
                        description: 'Parte anteriore/esterna',
                        icon: '🦵',
                        isSelected: selectedZoneId == 1,
                        isDark: isDark,
                        onTap: () => onZoneTap(1),
                      ),
                    ],
                  ),
                ),

                // Body silhouette - compact design
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right side zones
                Expanded(
                  child: Column(
                    children: [
                      _ZoneButton(
                        zoneId: 4,
                        code: 'BS',
                        name: 'Braccio Sx',
                        description: 'Superficie esterna',
                        icon: '💪',
                        isSelected: selectedZoneId == 4,
                        isDark: isDark,
                        onTap: () => onZoneTap(4),
                      ),
                      const SizedBox(height: 12),
                      _ZoneButton(
                        zoneId: 6,
                        code: 'AS',
                        name: 'Addome Sx',
                        description: 'Lontano dall\'ombelico',
                        icon: '💧',
                        isSelected: selectedZoneId == 6,
                        isDark: isDark,
                        onTap: () => onZoneTap(6),
                      ),
                      const SizedBox(height: 12),
                      _ZoneButton(
                        zoneId: 2,
                        code: 'CS',
                        name: 'Coscia Sx',
                        description: 'Parte anteriore/esterna',
                        icon: '🦵',
                        isSelected: selectedZoneId == 2,
                        isDark: isDark,
                        onTap: () => onZoneTap(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Back view - Glutes
            Row(
              children: [
                Expanded(
                  child: _ZoneButton(
                    zoneId: 7,
                    code: 'GD',
                    name: 'Gluteo Dx',
                    description: 'Quadrante superiore esterno',
                    icon: '🍑',
                    isSelected: selectedZoneId == 7,
                    isDark: isDark,
                    onTap: () => onZoneTap(7),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'GLUTEI',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: _ZoneButton(
                    zoneId: 8,
                    code: 'GS',
                    name: 'Gluteo Sx',
                    description: 'Quadrante superiore esterno',
                    icon: '🍑',
                    isSelected: selectedZoneId == 8,
                    isDark: isDark,
                    onTap: () => onZoneTap(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone button with description
class _ZoneButton extends StatelessWidget {
  const _ZoneButton({
    required this.zoneId,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final int zoneId;
  final String code;
  final String name;
  final String description;
  final String icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
        : (isDark ? AppColors.darkSurface : AppColors.dawnSurface);
    final textColor = isSelected
        ? (isDark ? AppColors.darkBase : AppColors.dawnBase)
        : (isDark ? AppColors.darkText : AppColors.dawnText);
    final subtitleColor = isSelected
        ? textColor.withValues(alpha: 0.8)
        : (isDark ? AppColors.darkMuted : AppColors.dawnMuted);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 9,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone detail with point position illustration
class _ZoneDetailCard extends StatelessWidget {
  const _ZoneDetailCard({
    required this.zone,
    required this.selectedPoint,
    required this.isDark,
    required this.onPointTap,
    required this.blacklistedAsync,
  });

  final BodyZone zone;
  final int? selectedPoint;
  final bool isDark;
  final void Function(int) onPointTap;
  final AsyncValue<List<db.BlacklistedPoint>> blacklistedAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone header
            Row(
              children: [
                Text(zone.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${zone.numberOfPoints} punti disponibili',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Point position illustration
            _PointPositionIllustration(
              zone: zone,
              selectedPoint: selectedPoint,
              isDark: isDark,
              onPointTap: onPointTap,
              blacklistedAsync: blacklistedAsync,
            ),

            const SizedBox(height: 16),

            // Point selection
            Text(
              'Seleziona il punto:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            blacklistedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Errore: $e'),
              data: (blacklist) {
                final zoneBlacklist = blacklist
                    .where((bp) => bp.zoneId == zone.id)
                    .map((bp) => bp.pointNumber)
                    .toSet();

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(zone.numberOfPoints, (i) {
                    final pointNum = i + 1;
                    final isBlacklisted = zoneBlacklist.contains(pointNum);
                    final isSelected = selectedPoint == pointNum;

                    return _PointChip(
                      number: pointNum,
                      isSelected: isSelected,
                      isBlacklisted: isBlacklisted,
                      isDark: isDark,
                      onTap: isBlacklisted ? null : () => onPointTap(pointNum),
                    );
                  }),
                );
              },
            ),

            if (selectedPoint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPine.withValues(alpha: 0.2)
                      : AppColors.dawnPine.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selezionato: ${zone.pointLabel(selectedPoint!)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Illustration showing point positions on the zone
class _PointPositionIllustration extends StatelessWidget {
  const _PointPositionIllustration({
    required this.zone,
    required this.selectedPoint,
    required this.isDark,
    required this.onPointTap,
    required this.blacklistedAsync,
  });

  final BodyZone zone;
  final int? selectedPoint;
  final bool isDark;
  final void Function(int) onPointTap;
  final AsyncValue<List<db.BlacklistedPoint>> blacklistedAsync;

  @override
  Widget build(BuildContext context) {
    // Different layout based on zone type
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.dawnSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkHighlightMed : AppColors.dawnHighlightMed,
        ),
      ),
      child: blacklistedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (blacklist) {
          final zoneBlacklist = blacklist
              .where((bp) => bp.zoneId == zone.id)
              .map((bp) => bp.pointNumber)
              .toSet();

          return _buildZoneLayout(zoneBlacklist);
        },
      ),
    );
  }

  Widget _buildZoneLayout(Set<int> blacklisted) {
    // Layout depends on zone type
    if (zone.id == 1 || zone.id == 2) {
      // Thigh - 6 points in 2 rows of 3
      return _buildGridLayout(6, 3, blacklisted);
    } else if (zone.id == 3 || zone.id == 4) {
      // Arm - 4 points in 2 rows of 2
      return _buildGridLayout(4, 2, blacklisted);
    } else if (zone.id == 5 || zone.id == 6) {
      // Abdomen - 4 points in 2 rows of 2
      return _buildGridLayout(4, 2, blacklisted);
    } else {
      // Glutes - 4 points in 2 rows of 2
      return _buildGridLayout(4, 2, blacklisted);
    }
  }

  Widget _buildGridLayout(int totalPoints, int columns, Set<int> blacklisted) {
    final rows = (totalPoints / columns).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Zone icon
          Text(zone.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          // Point grid
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(rows, (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(columns, (col) {
                    final pointNum = row * columns + col + 1;
                    if (pointNum > totalPoints) return const SizedBox(width: 40);

                    final isBlacklisted = blacklisted.contains(pointNum);
                    final isSelected = selectedPoint == pointNum;

                    return GestureDetector(
                      onTap: isBlacklisted ? null : () => onPointTap(pointNum),
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBlacklisted
                              ? (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                                  .withValues(alpha: 0.3)
                              : isSelected
                                  ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                                  : (isDark ? AppColors.darkHighlightLow : AppColors.dawnHighlightLow),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isBlacklisted
                              ? Icon(
                                  Icons.block,
                                  size: 16,
                                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                                )
                              : Text(
                                  '$pointNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark ? AppColors.darkBase : AppColors.dawnBase)
                                        : (isDark ? AppColors.darkText : AppColors.dawnText),
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(width: 16),
          // Description
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getZoneInstructions(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getZoneInstructions() {
    return switch (zone.id) {
      1 || 2 => 'Parte anteriore e laterale della coscia, evitare l\'interno coscia',
      3 || 4 => 'Superficie esterna del braccio superiore',
      5 || 6 => 'Almeno 5cm dall\'ombelico, evitare la linea centrale',
      7 || 8 => 'Quadrante superiore esterno del gluteo',
      _ => 'Seguire le indicazioni del medico',
    };
  }
}

/// Point selection chip
class _PointChip extends StatelessWidget {
  const _PointChip({
    required this.number,
    required this.isSelected,
    required this.isBlacklisted,
    required this.isDark,
    required this.onTap,
  });

  final int number;
  final bool isSelected;
  final bool isBlacklisted;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isBlacklisted
              ? (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                  .withValues(alpha: 0.2)
              : isSelected
                  ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                  : (isDark ? AppColors.darkSurface : AppColors.dawnSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBlacklisted
                ? (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                : isSelected
                    ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
                    : (isDark ? AppColors.darkMuted : AppColors.dawnMuted),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: isBlacklisted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block,
                      size: 20,
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ],
                )
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDark ? AppColors.darkBase : AppColors.dawnBase)
                        : (isDark ? AppColors.darkText : AppColors.dawnText),
                  ),
                ),
        ),
      ),
    );
  }
}
