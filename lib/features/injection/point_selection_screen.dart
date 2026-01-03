import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart';
import 'zone_provider.dart';
import 'injection_provider.dart' hide blacklistedPointsProvider;
import 'widgets/body_silhouette_editor.dart';

/// Unified screen for selecting injection points
/// Can be used for: recording injections, blacklisting points
enum PointSelectionMode { injection, blacklist }

class PointSelectionScreen extends ConsumerStatefulWidget {
  const PointSelectionScreen({
    super.key,
    required this.mode,
    this.initialZoneId,
    this.scheduledDate,
  });

  final PointSelectionMode mode;
  final int? initialZoneId;
  final DateTime? scheduledDate;

  @override
  ConsumerState<PointSelectionScreen> createState() =>
      _PointSelectionScreenState();
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
    final zonesAsync = ref.watch(enabledZonesProvider);
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
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (zones) => SingleChildScrollView(
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
                  error: (e, st) => const SizedBox(),
                  data: (suggested) {
                    if (suggested == null) return const SizedBox();
                    final zone = zones.firstWhere(
                      (z) => z.id == suggested.zoneId,
                      orElse: () => zones.first,
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

              // Zone selection header
              Text(
                'Seleziona la zona',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le zone sono organizzate per lato anatomico (vista frontale: la tua sinistra è a sinistra).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Zone grid - organized by left/right sides
              _ZoneGrid(
                zones: zones,
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
                blacklistedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object e, _) => Text('Errore: $e'),
                  data: (List<db.BlacklistedPoint> blacklist) {
                    final zone = zones.firstWhere(
                      (z) => z.id == _selectedZoneId,
                    );
                    return _ZoneDetailCard(
                      zone: zone,
                      selectedPoint: _selectedPoint,
                      isDark: isDark,
                      onPointTap: (point) =>
                          setState(() => _selectedPoint = point),
                      blacklistedPoints: blacklist,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Reason field (only for blacklist mode)
              if (widget.mode == PointSelectionMode.blacklist) ...[
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Motivo (opzionale)',
                    hintText:
                        'Es: cicatrice, reazione, difficile da raggiungere',
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
                      ? () => _performAction(zones)
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
      ),
    );
  }

  Future<void> _performAction(List<BodyZone> zones) async {
    if (_selectedZoneId == null || _selectedPoint == null) return;

    final zone = zones.firstWhere((z) => z.id == _selectedZoneId);

    if (widget.mode == PointSelectionMode.injection) {
      // Navigate to record screen with selected point
      context.push(
        '/record',
        extra: {
          'zoneId': _selectedZoneId,
          'pointNumber': _selectedPoint,
          if (widget.scheduledDate != null) 'scheduledDate': widget.scheduledDate,
        },
      );
    } else {
      // Blacklist the point
      final reason = _reasonController.text.isNotEmpty
          ? _reasonController.text
          : 'Non specificato';

      final actions = ref.read(zoneActionsProvider);
      await actions.blacklistPoint(
        pointCode: zone.pointCode(_selectedPoint!),
        pointLabel: zone.pointLabel(_selectedPoint!),
        zoneId: zone.id,
        pointNumber: _selectedPoint!,
        reason: reason,
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
                        color: isDark
                            ? AppColors.darkSubtle
                            : AppColors.dawnSubtle,
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

/// Zone grid - organized by anatomical sides
class _ZoneGrid extends StatelessWidget {
  const _ZoneGrid({
    required this.zones,
    required this.selectedZoneId,
    required this.isDark,
    required this.onZoneTap,
  });

  final List<BodyZone> zones;
  final int? selectedZoneId;
  final bool isDark;
  final void Function(int) onZoneTap;

  @override
  Widget build(BuildContext context) {
    // Separate zones by side (anatomical view: left zones on left column)
    final leftZones = zones.where((z) => z.side == 'left').toList();
    final rightZones = zones.where((z) => z.side == 'right').toList();
    final centerZones = zones.where((z) => z.side == 'none').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with sides
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SINISTRA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'DESTRA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Paired zones (left/right)
            _buildPairedZones(leftZones, rightZones),

            // Center zones (if any)
            if (centerZones.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'ALTRE ZONE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: centerZones
                    .map(
                      (zone) => _ZoneButton(
                        zone: zone,
                        isSelected: selectedZoneId == zone.id,
                        isDark: isDark,
                        onTap: () => onZoneTap(zone.id),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPairedZones(
    List<BodyZone> leftZones,
    List<BodyZone> rightZones,
  ) {
    // Group zones by type for better pairing
    final types = <String>{
      ...leftZones.map((z) => z.type),
      ...rightZones.map((z) => z.type),
    };

    final rows = <Widget>[];
    for (final type in types) {
      final left = leftZones.where((z) => z.type == type).toList();
      final right = rightZones.where((z) => z.type == type).toList();

      final maxLen = left.length > right.length ? left.length : right.length;
      for (var i = 0; i < maxLen; i++) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: i < left.length
                      ? _ZoneButton(
                          zone: left[i],
                          isSelected: selectedZoneId == left[i].id,
                          isDark: isDark,
                          onTap: () => onZoneTap(left[i].id),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: i < right.length
                      ? _ZoneButton(
                          zone: right[i],
                          isSelected: selectedZoneId == right[i].id,
                          isDark: isDark,
                          onTap: () => onZoneTap(right[i].id),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(children: rows);
  }
}

/// Zone button
class _ZoneButton extends StatelessWidget {
  const _ZoneButton({
    required this.zone,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final BodyZone zone;
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
            Text(zone.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              zone.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${zone.numberOfPoints} punti',
              style: TextStyle(fontSize: 11, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone detail with point selection using body silhouette
class _ZoneDetailCard extends ConsumerStatefulWidget {
  const _ZoneDetailCard({
    required this.zone,
    required this.selectedPoint,
    required this.isDark,
    required this.onPointTap,
    required this.blacklistedPoints,
  });

  final BodyZone zone;
  final int? selectedPoint;
  final bool isDark;
  final void Function(int) onPointTap;
  final List<db.BlacklistedPoint> blacklistedPoints;

  @override
  ConsumerState<_ZoneDetailCard> createState() => _ZoneDetailCardState();
}

class _ZoneDetailCardState extends ConsumerState<_ZoneDetailCard> {
  List<PositionedPoint> _points = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void didUpdateWidget(_ZoneDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone.id != widget.zone.id) {
      _loadPoints();
    }
  }

  Future<void> _loadPoints() async {
    final database = ref.read(databaseProvider);
    final configs = await database.getPointConfigsForZone(widget.zone.id);

    if (configs.isEmpty) {
      // Genera posizioni predefinite
      _points = generateDefaultPointPositions(
        widget.zone.numberOfPoints,
        widget.zone.type,
        widget.zone.side,
      );
    } else {
      _points = configs.map((c) => c.toPositionedPoint()).toList();
      // Aggiungi punti mancanti
      for (var i = configs.length + 1; i <= widget.zone.numberOfPoints; i++) {
        final defaults = generateDefaultPointPositions(
          widget.zone.numberOfPoints,
          widget.zone.type,
          widget.zone.side,
        );
        final defaultPoint = defaults.firstWhere(
          (p) => p.pointNumber == i,
          orElse: () => PositionedPoint(pointNumber: i, x: 0.5, y: 0.5),
        );
        _points.add(defaultPoint);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Set<int> get _blacklistedNumbers {
    return widget.blacklistedPoints
        .where((bp) => bp.zoneId == widget.zone.id)
        .map((bp) => bp.pointNumber)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final selectedPoint = widget.selectedPoint;
    final isDark = widget.isDark;
    final onPointTap = widget.onPointTap;
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
                        zone.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${zone.numberOfPoints} punti disponibili',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkSubtle
                              : AppColors.dawnSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            Text(
              _getZoneInstructions(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            // Point selection with silhouette
            Text('Seleziona il punto:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 420,
                child: _PointSelectionSilhouette(
                  points: _points,
                  selectedPoint: selectedPoint,
                  blacklistedNumbers: _blacklistedNumbers,
                  isDark: isDark,
                  zoneType: zone.type,
                  onPointTap: onPointTap,
                ),
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
                      'Selezionato: ${zone.pointLabel(selectedPoint)}',
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

  String _getZoneInstructions() {
    return switch (widget.zone.type) {
      'thigh' =>
        'Parte anteriore e laterale della coscia, evitare l\'interno coscia',
      'arm' => 'Superficie esterna del braccio superiore',
      'abdomen' => 'Almeno 5cm dall\'ombelico, evitare la linea centrale',
      'buttock' => 'Quadrante superiore esterno del gluteo',
      _ => 'Seguire le indicazioni del medico',
    };
  }
}

/// Silhouette-based point selection widget
class _PointSelectionSilhouette extends StatelessWidget {
  const _PointSelectionSilhouette({
    required this.points,
    required this.selectedPoint,
    required this.blacklistedNumbers,
    required this.isDark,
    required this.zoneType,
    required this.onPointTap,
  });

  final List<PositionedPoint> points;
  final int? selectedPoint;
  final Set<int> blacklistedNumbers;
  final bool isDark;
  final String zoneType;
  final void Function(int) onPointTap;

  @override
  Widget build(BuildContext context) {
    // Filtra i punti blacklisted per mostrarli in modo diverso
    final visiblePoints = points.map((p) {
      if (blacklistedNumbers.contains(p.pointNumber)) {
        // Marca i punti blacklisted con un nome speciale per riconoscerli
        return p.copyWith(customName: '✗');
      }
      return p;
    }).toList();

    return BodySilhouetteEditor(
      points: visiblePoints,
      selectedPointNumber: selectedPoint,
      zoneType: zoneType,
      editable: false, // Non trascinabili, solo cliccabili
      onPointMoved: (p1, p2, p3, p4) {}, // Non usato
      onPointTapped: (pointNumber) {
        // Non permettere tap su punti blacklisted
        if (!blacklistedNumbers.contains(pointNumber)) {
          onPointTap(pointNumber);
        }
      },
    );
  }
}
