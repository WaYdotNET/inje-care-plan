import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart';
import '../injection/widgets/body_silhouette_editor.dart';
import '../injection/zone_provider.dart';

/// Schermata per modificare i punti di una zona con editor visuale
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

    if (configs.isEmpty) {
      // Genera posizioni predefinite
      _points = generateDefaultPointPositions(
        zone.numberOfPoints,
        zone.type,
        zone.side,
      );
    } else {
      // Carica posizioni salvate
      _points = configs.map((c) => c.toPositionedPoint()).toList();

      // Aggiungi punti mancanti se il numero è aumentato
      for (var i = configs.length + 1; i <= zone.numberOfPoints; i++) {
        final defaults = generateDefaultPointPositions(
          zone.numberOfPoints,
          zone.type,
          zone.side,
        );
        final defaultPoint = defaults.firstWhere(
          (p) => p.pointNumber == i,
          orElse: () => PositionedPoint(
            pointNumber: i,
            x: 0.5,
            y: 0.5,
          ),
        );
        _points.add(defaultPoint);
      }
    }

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
        'front', // TODO: supportare vista back
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
        const SnackBar(content: Text('Posizioni punti salvate')),
      );
      setState(() => _hasChanges = false);
    }
  }

  void _onPointMoved(int pointNumber, double x, double y, BodyView view) {
    setState(() {
      final index = _points.indexWhere((p) => p.pointNumber == pointNumber);
      if (index != -1) {
        _points[index] = _points[index].copyWith(x: x, y: y);
        _hasChanges = true;
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(zonesProvider);

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
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
          return shouldSave ?? true;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Posiziona Punti'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _savePoints,
                icon: const Icon(Icons.save),
                label: const Text('Salva'),
              ),
          ],
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
                  return _buildContent(context, theme, isDark, zone);
                },
              ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BodyZone zone,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(zone.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${zone.numberOfPoints} punti',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Card(
            color: isDark
                ? AppColors.darkHighlightLow
                : AppColors.dawnHighlightLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Trascina i punti per posizionarli sulla silhouette. '
                      'Tocca un punto per modificarne il nome.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Body silhouette editor
          SizedBox(
            height: 320,
            child: BodySilhouetteEditor(
              points: _points,
              onPointMoved: _onPointMoved,
              onPointTapped: (pointNumber) {
                setState(() => _selectedPointNumber = pointNumber);
              },
              selectedPointNumber: _selectedPointNumber,
              zoneType: zone.type,
              editable: true,
            ),
          ),

          const SizedBox(height: 24),

          // Selected point editor
          if (_selectedPointNumber != null) ...[
            Text(
              'Modifica punto $_selectedPointNumber',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildPointEditor(_selectedPointNumber!),
          ],

          const SizedBox(height: 24),

          // Reset button
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
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
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Ripristina posizioni predefinite'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPointEditor(int pointNumber) {
    final point = _points.firstWhere(
      (p) => p.pointNumber == pointNumber,
      orElse: () => PositionedPoint(pointNumber: pointNumber, x: 0.5, y: 0.5),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PointNameEditor(
              pointNumber: pointNumber,
              currentName: point.customName ?? '',
              onNameChanged: (name) => _onPointNameChanged(pointNumber, name),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Posizione: X=${(point.x * 100).toStringAsFixed(0)}%, '
                    'Y=${(point.y * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedPointNumber = null),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
