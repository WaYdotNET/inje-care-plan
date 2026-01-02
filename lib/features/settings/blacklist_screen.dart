import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/database_provider.dart';
import '../../models/blacklisted_point.dart' as models;
import '../injection/injection_provider.dart';
import '../injection/injection_repository.dart';

/// Screen to select and blacklist injection points
class BlacklistScreen extends ConsumerStatefulWidget {
  const BlacklistScreen({super.key});

  @override
  ConsumerState<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends ConsumerState<BlacklistScreen> {
  int? _selectedZoneId;
  int? _selectedPoint;
  final _reasonController = TextEditingController();

  // Zone data: (id, code, name, numPoints)
  static const _zones = [
    (1, 'CD', 'Coscia Destra', 6),
    (2, 'CS', 'Coscia Sinistra', 6),
    (3, 'BD', 'Braccio Destro', 4),
    (4, 'BS', 'Braccio Sinistro', 4),
    (5, 'AD', 'Addome Destro', 4),
    (6, 'AS', 'Addome Sinistro', 4),
    (7, 'GD', 'Gluteo Destro', 4),
    (8, 'GS', 'Gluteo Sinistro', 4),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blacklistedAsync = ref.watch(blacklistedPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escludi un punto'),
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
            // Instructions
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
                        'Seleziona una zona e poi il punto che vuoi escludere dalla rotazione.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Body map with zones
            Text(
              'Seleziona la zona',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Body silhouette with clickable zones
            _buildBodyMap(isDark),
            const SizedBox(height: 24),

            // Selected zone info and point selection
            if (_selectedZoneId != null) ...[
              _buildPointSelection(isDark),
              const SizedBox(height: 24),
            ],

            // Reason field
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

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedZoneId != null && _selectedPoint != null
                    ? () => _blacklistPoint(isDark)
                    : null,
                icon: const Icon(Icons.block),
                label: const Text('Escludi questo punto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Already blacklisted points
            Text(
              'Punti già esclusi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            blacklistedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Errore: $e'),
              data: (points) => points.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Nessun punto escluso',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.dawnMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: points.map((point) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark
                                  ? AppColors.darkLove.withValues(alpha: 0.2)
                                  : AppColors.dawnLove.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.block,
                                color: isDark
                                    ? AppColors.darkLove
                                    : AppColors.dawnLove,
                              ),
                            ),
                            title: Text(point.pointLabel),
                            subtitle: Text(point.reason),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeBlacklist(point.pointCode),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMap(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Row 1: Arms (BD - BS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildZoneButton(3, 'BD', 'Braccio Dx', isDark),
                const SizedBox(width: 80), // Space for body
                _buildZoneButton(4, 'BS', 'Braccio Sx', isDark),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Abdomen (AD - AS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildZoneButton(5, 'AD', 'Addome Dx', isDark),
                // Body silhouette
                Icon(
                  Icons.accessibility_new,
                  size: 100,
                  color: isDark
                      ? AppColors.darkMuted.withValues(alpha: 0.3)
                      : AppColors.dawnMuted.withValues(alpha: 0.3),
                ),
                _buildZoneButton(6, 'AS', 'Addome Sx', isDark),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Glutes (GD - GS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildZoneButton(7, 'GD', 'Gluteo Dx', isDark),
                const SizedBox(width: 80),
                _buildZoneButton(8, 'GS', 'Gluteo Sx', isDark),
              ],
            ),
            const SizedBox(height: 8),

            // Row 4: Thighs (CD - CS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildZoneButton(1, 'CD', 'Coscia Dx', isDark),
                const SizedBox(width: 40),
                _buildZoneButton(2, 'CS', 'Coscia Sx', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneButton(int id, String code, String name, bool isDark) {
    final isSelected = _selectedZoneId == id;
    final bgColor = isSelected
        ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
        : (isDark ? AppColors.darkSurface : AppColors.dawnSurface);
    final textColor = isSelected
        ? (isDark ? AppColors.darkBase : AppColors.dawnBase)
        : (isDark ? AppColors.darkText : AppColors.dawnText);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedZoneId = id;
          _selectedPoint = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointSelection(bool isDark) {
    final zone = _zones.firstWhere((z) => z.$1 == _selectedZoneId);
    final numPoints = zone.$4;

    return Card(
      color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                ),
                const SizedBox(width: 8),
                Text(
                  'Zona: ${zone.$3}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Seleziona il punto:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(numPoints, (i) {
                final pointNum = i + 1;
                final isSelected = _selectedPoint == pointNum;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPoint = pointNum),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                          : (isDark
                              ? AppColors.darkSurface
                              : AppColors.dawnSurface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkFoam
                                : AppColors.dawnFoam)
                            : (isDark
                                ? AppColors.darkMuted
                                : AppColors.dawnMuted),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$pointNum',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkBase
                                  : AppColors.dawnBase)
                              : (isDark
                                  ? AppColors.darkText
                                  : AppColors.dawnText),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_selectedPoint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPine.withValues(alpha: 0.2)
                      : AppColors.dawnPine.withValues(alpha: 0.2),
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
                      'Punto selezionato: ${zone.$3} · $_selectedPoint',
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

  Future<void> _blacklistPoint(bool isDark) async {
    if (_selectedZoneId == null || _selectedPoint == null) return;

    final zone = _zones.firstWhere((z) => z.$1 == _selectedZoneId);
    final reason = _reasonController.text.isNotEmpty
        ? _reasonController.text
        : 'Non specificato';

    final db = ref.read(databaseProvider);
    final repository = InjectionRepository(database: db);

    await repository.blacklistPoint(
      models.BlacklistedPoint(
        zoneId: zone.$1,
        pointNumber: _selectedPoint!,
        reason: reason,
        blacklistedAt: DateTime.now(),
      ),
    );

    ref.invalidate(blacklistedPointsProvider);

    if (mounted) {
      final label = '${zone.$3} · $_selectedPoint';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Punto $label escluso'),
          backgroundColor: isDark ? AppColors.darkPine : AppColors.dawnPine,
        ),
      );

      // Reset selection
      setState(() {
        _selectedZoneId = null;
        _selectedPoint = null;
        _reasonController.clear();
      });
    }
  }

  Future<void> _removeBlacklist(String pointCode) async {
    final db = ref.read(databaseProvider);
    final repository = InjectionRepository(database: db);
    await repository.unblacklistPoint(pointCode);
    ref.invalidate(blacklistedPointsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto rimosso dalla lista esclusi')),
      );
    }
  }
}

