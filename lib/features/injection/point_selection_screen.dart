import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

// Emoji used from zone.emoji property

class PointSelectionScreen extends ConsumerStatefulWidget {
  const PointSelectionScreen({
    super.key,
    required this.mode,
    this.initialZoneId,
    this.scheduledDate,
    this.existingInjectionId,
  });

  final PointSelectionMode mode;
  final int? initialZoneId;
  final DateTime? scheduledDate;
  final int? existingInjectionId;

  @override
  ConsumerState<PointSelectionScreen> createState() =>
      _PointSelectionScreenState();
}

class _PointSelectionScreenState extends ConsumerState<PointSelectionScreen> {
  int? _selectedZoneId;
  int? _selectedPoint;
  final _reasonController = TextEditingController();
  late DateTime _scheduledDateTime;
  late TimeOfDay _scheduledTime;

  @override
  void initState() {
    super.initState();
    _selectedZoneId = widget.initialZoneId;
    // Inizializza data/ora dalla prop o usa ora corrente
    _scheduledDateTime = widget.scheduledDate ?? DateTime.now();
    _scheduledTime = TimeOfDay.fromDateTime(_scheduledDateTime);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Aggiorna l'orario schedulato
  void _updateScheduledTime(TimeOfDay newTime) {
    setState(() {
      _scheduledTime = newTime;
      _scheduledDateTime = DateTime(
        _scheduledDateTime.year,
        _scheduledDateTime.month,
        _scheduledDateTime.day,
        newTime.hour,
        newTime.minute,
      );
    });
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
              // Date/time header per iniezioni
              if (widget.mode == PointSelectionMode.injection)
                _ScheduleDateTimeCard(
                  scheduledDateTime: _scheduledDateTime,
                  scheduledTime: _scheduledTime,
                  isDark: isDark,
                  onTimeChanged: _updateScheduledTime,
                ),

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
      // Navigate to record screen with selected point and updated datetime
      context.push(
        '/record',
        extra: {
          'zoneId': _selectedZoneId,
          'pointNumber': _selectedPoint,
          'scheduledDate': _scheduledDateTime, // Usa la data/ora aggiornata
          if (widget.existingInjectionId != null) 'existingInjectionId': widget.existingInjectionId,
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

/// Card per mostrare e modificare data/ora dell'iniezione
class _ScheduleDateTimeCard extends StatelessWidget {
  const _ScheduleDateTimeCard({
    required this.scheduledDateTime,
    required this.scheduledTime,
    required this.isDark,
    required this.onTimeChanged,
  });

  final DateTime scheduledDateTime;
  final TimeOfDay scheduledTime;
  final bool isDark;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'it_IT');
    final timeFormat = DateFormat('HH:mm', 'it_IT');

    return Card(
      color: isDark
          ? AppColors.darkFoam.withValues(alpha: 0.15)
          : AppColors.dawnFoam.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                ),
                const SizedBox(width: 12),
                Text(
                  'Iniezione per:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Data
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capitalizeFirst(dateFormat.format(scheduledDateTime)),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Orario modificabile
                InkWell(
                  onTap: () => _showTimePicker(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOverlay
                          : AppColors.dawnOverlay,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkFoam.withValues(alpha: 0.5)
                            : AppColors.dawnFoam.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(scheduledDateTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'L\'orario verrà usato per il promemoria',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: scheduledTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeChanged(picked);
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
  Map<int, DateTime?> _usageHistory = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_ZoneDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone.id != widget.zone.id) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final database = ref.read(databaseProvider);

    // Carica posizioni punti
    final configs = await database.getPointConfigsForZone(widget.zone.id);
    if (configs.isEmpty) {
      _points = generateDefaultPointPositions(
        widget.zone.numberOfPoints,
        widget.zone.type,
        widget.zone.side,
      );
    } else {
      _points = configs.map((c) => c.toPositionedPoint()).toList();
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

    // Carica storico utilizzo
    _usageHistory = await database.getPointUsageHistory(widget.zone.id);

    if (mounted) setState(() => _isLoading = false);
  }

  /// Ottiene l'etichetta del punto, preferendo il nome personalizzato se presente
  String _getPointLabel(int pointNumber) {
    final point = _points.firstWhere(
      (p) => p.pointNumber == pointNumber,
      orElse: () => PositionedPoint(pointNumber: pointNumber, x: 0.5, y: 0.5),
    );
    if (point.customName != null && point.customName!.isNotEmpty) {
      return '${widget.zone.name} · ${point.customName}';
    }
    return widget.zone.pointLabel(pointNumber);
  }

  List<_PointHistoryItem> _buildHistoryItems() {
    final items = <_PointHistoryItem>[];
    for (var i = 1; i <= widget.zone.numberOfPoints; i++) {
      items.add(_PointHistoryItem(
        pointNumber: i,
        pointLabel: _getPointLabel(i),
        lastUsed: _usageHistory[i],
        isBlacklisted: _blacklistedNumbers.contains(i),
      ));
    }
    return items;
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
                      'Selezionato: ${_getPointLabel(selectedPoint)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Point usage history section
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Storico d\'uso',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'I punti sono ordinati dal meno usato (consigliato) al più recente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            _PointHistoryList(
              items: _buildHistoryItems(),
              selectedPoint: selectedPoint,
              isDark: isDark,
              onPointTap: onPointTap,
            ),
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

/// Enum per indicare il livello di utilizzo del punto
enum PointUsageLevel {
  neverUsed, // Mai usato - verde
  safe, // >14 giorni - verde
  caution, // 7-14 giorni - giallo
  warning, // 3-7 giorni - arancione
  avoid, // <3 giorni - rosso
}

extension PointUsageLevelExtension on PointUsageLevel {
  Color getColor(bool isDark) {
    return switch (this) {
      PointUsageLevel.neverUsed => isDark ? AppColors.darkPine : AppColors.dawnPine,
      PointUsageLevel.safe => isDark ? AppColors.darkPine : AppColors.dawnPine,
      PointUsageLevel.caution => isDark ? AppColors.darkGold : AppColors.dawnGold,
      PointUsageLevel.warning => Colors.orange,
      PointUsageLevel.avoid => isDark ? AppColors.darkLove : AppColors.dawnLove,
    };
  }

  String get label => switch (this) {
    PointUsageLevel.neverUsed => 'Mai usato',
    PointUsageLevel.safe => 'Consigliato',
    PointUsageLevel.caution => 'Attenzione',
    PointUsageLevel.warning => 'Recente',
    PointUsageLevel.avoid => 'Evitare',
  };

  IconData get icon => switch (this) {
    PointUsageLevel.neverUsed => Icons.star,
    PointUsageLevel.safe => Icons.check_circle,
    PointUsageLevel.caution => Icons.info,
    PointUsageLevel.warning => Icons.warning,
    PointUsageLevel.avoid => Icons.block,
  };

  static PointUsageLevel fromDaysSinceLastUse(int? days) {
    if (days == null) return PointUsageLevel.neverUsed;
    if (days > 14) return PointUsageLevel.safe;
    if (days >= 7) return PointUsageLevel.caution;
    if (days >= 3) return PointUsageLevel.warning;
    return PointUsageLevel.avoid;
  }
}

/// Point history item with usage indicator
class _PointHistoryItem {
  final int pointNumber;
  final String pointLabel;
  final DateTime? lastUsed;
  final int? daysSinceLastUse;
  final PointUsageLevel usageLevel;
  final bool isBlacklisted;

  _PointHistoryItem({
    required this.pointNumber,
    required this.pointLabel,
    required this.lastUsed,
    required this.isBlacklisted,
  })  : daysSinceLastUse = lastUsed != null
            ? DateTime.now().difference(lastUsed).inDays
            : null,
        usageLevel = PointUsageLevelExtension.fromDaysSinceLastUse(
          lastUsed != null ? DateTime.now().difference(lastUsed).inDays : null,
        );
}

/// Widget for displaying point usage history
class _PointHistoryList extends StatelessWidget {
  const _PointHistoryList({
    required this.items,
    required this.selectedPoint,
    required this.isDark,
    required this.onPointTap,
  });

  final List<_PointHistoryItem> items;
  final int? selectedPoint;
  final bool isDark;
  final void Function(int) onPointTap;

  @override
  Widget build(BuildContext context) {
    // Ordina per data di utilizzo: mai usati prima, poi dal meno recente
    final sortedItems = List<_PointHistoryItem>.from(items)
      ..sort((a, b) {
        // Blacklisted punti sempre alla fine
        if (a.isBlacklisted && !b.isBlacklisted) return 1;
        if (!a.isBlacklisted && b.isBlacklisted) return -1;

        // Mai usati prima
        if (a.lastUsed == null && b.lastUsed == null) {
          return a.pointNumber.compareTo(b.pointNumber);
        }
        if (a.lastUsed == null) return -1;
        if (b.lastUsed == null) return 1;

        // Ordina per data (meno recente prima)
        return a.lastUsed!.compareTo(b.lastUsed!);
      });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return _PointHistoryCard(
          item: item,
          isSelected: item.pointNumber == selectedPoint,
          isDark: isDark,
          onTap: item.isBlacklisted ? null : () => onPointTap(item.pointNumber),
        );
      },
    );
  }
}

/// Card for a single point in the history list
class _PointHistoryCard extends StatelessWidget {
  const _PointHistoryCard({
    required this.item,
    required this.isSelected,
    required this.isDark,
    this.onTap,
  });

  final _PointHistoryItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageColor = item.usageLevel.getColor(isDark);

    return Material(
      color: isSelected
          ? usageColor.withValues(alpha: 0.2)
          : (isDark ? AppColors.darkOverlay : AppColors.dawnOverlay),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: usageColor, width: 2)
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
          ),
          child: Row(
            children: [
              // Usage indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isBlacklisted
                      ? Colors.grey.withValues(alpha: 0.3)
                      : usageColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isBlacklisted ? Icons.block : item.usageLevel.icon,
                  color: item.isBlacklisted ? Colors.grey : usageColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Point info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pointLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration:
                            item.isBlacklisted ? TextDecoration.lineThrough : null,
                        color: item.isBlacklisted
                            ? (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isBlacklisted
                          ? 'Punto escluso'
                          : (item.lastUsed != null
                              ? 'Ultima: ${DateFormat('d MMM yyyy', 'it').format(item.lastUsed!)}'
                              : 'Mai usato'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Days indicator
              if (!item.isBlacklisted) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: usageColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.daysSinceLastUse != null
                            ? '${item.daysSinceLastUse} gg fa'
                            : '★ Nuovo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: usageColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.usageLevel.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: usageColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
