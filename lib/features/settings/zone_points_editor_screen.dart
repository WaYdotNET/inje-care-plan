import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart';
import '../injection/widgets/body_silhouette_editor.dart';
import '../injection/zone_provider.dart';

/// Schermata per modificare i punti di una zona con editor visuale fullscreen
class ZonePointsEditorScreen extends ConsumerStatefulWidget {
  const ZonePointsEditorScreen({super.key, required this.zoneId});

  final int zoneId;

  @override
  ConsumerState<ZonePointsEditorScreen> createState() =>
      _ZonePointsEditorScreenState();
}

class _ZonePointsEditorScreenState
    extends ConsumerState<ZonePointsEditorScreen> {
  List<PositionedPoint> _points = [];
  int? _selectedPointNumber;
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _showGrid = false;
  BodyView _currentView = BodyView.front;

  // Per le coordinate in tempo reale durante il drag
  int? _draggingPointNumber;
  double? _dragX;
  double? _dragY;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final db = ref.read(databaseProvider);
    final zone = await db.getZoneById(widget.zoneId);
    if (zone == null) {
      if (mounted) context.pop();
      return;
    }

    final configs = await db.getPointConfigsForZone(widget.zoneId);
    // Vista preferenziale di seed per i punti mancanti: il default per tipo.
    final seedView = defaultBodyViewForZoneType(zone.type);

    if (configs.isEmpty) {
      _points = generateDefaultPointPositions(
        zone.numberOfPoints,
        zone.type,
        zone.side,
      ).map((p) => p.copyWith(bodyView: seedView)).toList();
    } else {
      _points = configs.map((c) => c.toPositionedPoint()).toList();

      // Riempi eventuali pointNumber mancanti con default sulla view di seed.
      final existingNumbers = _points.map((p) => p.pointNumber).toSet();
      for (var i = 1; i <= zone.numberOfPoints; i++) {
        if (existingNumbers.contains(i)) continue;
        final defaults = generateDefaultPointPositions(
          zone.numberOfPoints,
          zone.type,
          zone.side,
        );
        final defaultPoint = defaults.firstWhere(
          (p) => p.pointNumber == i,
          orElse: () => PositionedPoint(pointNumber: i, x: 0.5, y: 0.5),
        );
        _points.add(defaultPoint.copyWith(bodyView: seedView));
      }
    }

    // View iniziale dipende da dove sono effettivamente i punti: se tutti
    // sul retro (anche per zone non-buttock) parte dal retro, e viceversa.
    _currentView = pickInitialBodyView(_points, zone.type);

    setState(() => _isLoading = false);
  }

  Future<void> _savePoints() async {
    final database = ref.read(databaseProvider);

    for (final point in _points) {
      await database.updatePointPosition(
        widget.zoneId,
        point.pointNumber,
        point.x,
        point.y,
        point.bodyView == BodyView.front ? 'front' : 'back',
      );
      if (point.customName != null && point.customName!.isNotEmpty) {
        await database.updatePointName(
          widget.zoneId,
          point.pointNumber,
          point.customName!,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(PhosphorIconsDuotone.checkCircle, color: Colors.white),
              SizedBox(width: 8),
              Text('Posizioni salvate!'),
            ],
          ),
          backgroundColor: AppTokens.successLight,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
      setState(() => _hasChanges = false);
    }
  }

  void _onPointMoved(int pointNumber, double x, double y, BodyView view) {
    setState(() {
      final index = _points.indexWhere((p) => p.pointNumber == pointNumber);
      if (index != -1) {
        _points[index] =
            _points[index].copyWith(x: x, y: y, bodyView: view);
        _hasChanges = true;
      }
      _draggingPointNumber = pointNumber;
      _dragX = x;
      _dragY = y;
    });
  }

  void _onDragEnd() {
    setState(() {
      _draggingPointNumber = null;
      _dragX = null;
      _dragY = null;
    });
  }

  void _onPointNameChanged(int pointNumber, String name) {
    setState(() {
      final index = _points.indexWhere((p) => p.pointNumber == pointNumber);
      if (index != -1) {
        _points[index] = _points[index].copyWith(customName: name);
        _hasChanges = true;
      }
    });
  }

  void _onPointViewChanged(int pointNumber, BodyView view) {
    setState(() {
      final index = _points.indexWhere((p) => p.pointNumber == pointNumber);
      if (index != -1) {
        _points[index] = _points[index].copyWith(bodyView: view);
        _hasChanges = true;
      }
    });
  }

  void _resetPoints(BodyZone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripristina posizioni?'),
        content: const Text(
          'Questo ripristinerà tutte le posizioni dei punti ai valori predefiniti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _points = generateDefaultPointPositions(
          zone.numberOfPoints,
          zone.type,
          zone.side,
        );
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(zonesProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Salvare le modifiche?'),
            content: const Text(
              'Hai modifiche non salvate. Vuoi salvarle prima di uscire?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Scarta'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _savePoints();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
        );

        if (context.mounted && (shouldSave == true || shouldSave == false)) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppTokens.darkSurface : AppTokens.lightSurface)
                    .withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsDuotone.arrowLeft),
            ),
            onPressed: () => context.pop(),
          ),
          title: zonesAsync.when(
            loading: () => null,
            error: (e, _) => null,
            data: (zones) {
              final zone = zones.firstWhere(
                (z) => z.id == widget.zoneId,
                orElse: () => zones.first,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppTokens.darkSurface : AppTokens.lightSurface)
                          .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(zone.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(zone.displayName),
                  ],
                ),
              );
            },
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : zonesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Errore: $e')),
                data: (zones) {
                  final zone = zones.firstWhere(
                    (z) => z.id == widget.zoneId,
                    orElse: () => zones.first,
                  );
                  return _buildFullscreenEditor(context, theme, isDark, zone);
                },
              ),
      ),
    );
  }

  Widget _buildFullscreenEditor(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BodyZone zone,
  ) {
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppTokens.darkBg, AppTokens.darkSurface]
                    : [AppTokens.lightBgTop, AppTokens.lightSurface],
              ),
            ),
          ),
        ),

        // Editor fullscreen con InteractiveViewer
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 100),
              child: BodySilhouetteEditor(
                points: _points,
                onPointMoved: _onPointMoved,
                onPointTapped: (pointNumber) {
                  _showPointEditPopup(context, pointNumber, isDark, zone);
                },
                onDragEnd: _onDragEnd,
                selectedPointNumber: _selectedPointNumber,
                zoneType: zone.type,
                editable: true,
                showGrid: _showGrid,
                currentView: _currentView,
                onViewChanged: (view) => setState(() => _currentView = view),
                enableZoom: true,
              ),
            ),
          ),
        ),

        // Coordinate overlay durante il drag
        if (_draggingPointNumber != null && _dragX != null && _dragY != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppTokens.accent : AppTokens.accent)
                      .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Punto $_draggingPointNumber: X ${(_dragX! * 100).toStringAsFixed(0)}% · Y ${(_dragY! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

        // Floating toolbar
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: _FloatingToolbar(
            isDark: isDark,
            hasChanges: _hasChanges,
            showGrid: _showGrid,
            currentView: _currentView,
            onSave: _savePoints,
            onReset: () => _resetPoints(zone),
            onToggleGrid: () => setState(() => _showGrid = !_showGrid),
            onViewChanged: (view) => setState(() => _currentView = view),
          ),
        ),
      ],
    );
  }

  void _showPointEditPopup(
    BuildContext context,
    int pointNumber,
    bool isDark,
    BodyZone zone,
  ) {
    final point = _points.firstWhere(
      (p) => p.pointNumber == pointNumber,
      orElse: () => PositionedPoint(pointNumber: pointNumber, x: 0.5, y: 0.5),
    );

    final existingNames = _points
        .where((p) => p.pointNumber != pointNumber && p.customName != null)
        .map((p) => p.customName!)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          BodyView localView = _points
              .firstWhere(
                (p) => p.pointNumber == pointNumber,
                orElse: () => point,
              )
              .bodyView;
          return Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppTokens.accent : AppTokens.accent,
                        (isDark ? AppTokens.accent : AppTokens.accent)
                            .withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      point.customName?.isNotEmpty == true
                          ? point.customName!.substring(
                              0,
                              point.customName!.length > 3
                                  ? 3
                                  : point.customName!.length,
                            )
                          : '$pointNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                        'Modifica Punto $pointNumber',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'X: ${(point.x * 100).toStringAsFixed(0)}% · Y: ${(point.y * 100).toStringAsFixed(0)}%',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTokens.darkMuted
                              : AppTokens.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name editor
            PointNameEditor(
              pointNumber: pointNumber,
              currentName: point.customName ?? '',
              onNameChanged: (name) {
                _onPointNameChanged(pointNumber, name);
              },
              existingNames: existingNames,
            ),
            const SizedBox(height: 16),

            // View toggle (fronte/retro per singolo punto)
            Text(
              'Vista corpo',
              style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppTokens.darkMuted
                        : AppTokens.lightMuted,
                  ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<BodyView>(
              segments: const [
                ButtonSegment(
                  value: BodyView.front,
                  label: Text('Fronte'),
                  icon: Icon(PhosphorIconsDuotone.user),
                ),
                ButtonSegment(
                  value: BodyView.back,
                  label: Text('Retro'),
                  icon: Icon(PhosphorIconsDuotone.user),
                ),
              ],
              selected: {localView},
              onSelectionChanged: (selection) {
                final next = selection.first;
                setSheetState(() => localView = next);
                _onPointViewChanged(pointNumber, next);
              },
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Chiudi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedPointNumber = pointNumber);
                    },
                    icon: const Icon(PhosphorIconsDuotone.check),
                    label: const Text('Conferma'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}

/// Toolbar flottante con azioni rapide
class _FloatingToolbar extends StatelessWidget {
  const _FloatingToolbar({
    required this.isDark,
    required this.hasChanges,
    required this.showGrid,
    required this.currentView,
    required this.onSave,
    required this.onReset,
    required this.onToggleGrid,
    required this.onViewChanged,
  });

  final bool isDark;
  final bool hasChanges;
  final bool showGrid;
  final BodyView currentView;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onToggleGrid;
  final void Function(BodyView) onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.darkSurface.withValues(alpha: 0.95)
            : AppTokens.lightSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle griglia
          _ToolbarButton(
            icon: showGrid ? PhosphorIconsDuotone.gridFour : PhosphorIconsDuotone.gridFour,
            label: 'Griglia',
            isActive: showGrid,
            isDark: isDark,
            onTap: onToggleGrid,
          ),

          // Toggle fronte/retro
          _ToolbarButton(
            icon: currentView == BodyView.front
                ? PhosphorIconsDuotone.user
                : PhosphorIconsDuotone.user,
            label: currentView == BodyView.front ? 'Fronte' : 'Retro',
            isActive: false,
            isDark: isDark,
            onTap: () => onViewChanged(
              currentView == BodyView.front ? BodyView.back : BodyView.front,
            ),
          ),

          // Reset
          _ToolbarButton(
            icon: PhosphorIconsDuotone.arrowClockwise,
            label: 'Reset',
            isActive: false,
            isDark: isDark,
            onTap: onReset,
          ),

          // Salva (evidenziato se ci sono modifiche)
          _SaveButton(hasChanges: hasChanges, isDark: isDark, onTap: onSave),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppTokens.accentEnd : AppTokens.accentEnd;
    final inactiveColor = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.hasChanges,
    required this.isDark,
    required this.onTap,
  });

  final bool hasChanges;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: hasChanges
            ? LinearGradient(
                colors: [
                  isDark ? AppTokens.accent : AppTokens.accent,
                  (isDark ? AppTokens.accent : AppTokens.accent).withValues(
                    alpha: 0.8,
                  ),
                ],
              )
            : null,
        color: hasChanges ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: hasChanges ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsDuotone.floppyDisk,
                color: hasChanges
                    ? Colors.white
                    : (isDark ? AppTokens.darkMuted : AppTokens.lightMuted),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Salva',
                style: TextStyle(
                  fontSize: 11,
                  color: hasChanges
                      ? Colors.white
                      : (isDark ? AppTokens.darkMuted : AppTokens.lightMuted),
                  fontWeight: hasChanges ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
