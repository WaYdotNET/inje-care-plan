import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/app_database.dart' show BodyZone;
import '../../core/ml/rotation_pattern_engine.dart';

/// Schermata per configurare una sequenza personalizzata di zone
class CustomPatternScreen extends ConsumerStatefulWidget {
  const CustomPatternScreen({super.key});

  @override
  ConsumerState<CustomPatternScreen> createState() => _CustomPatternScreenState();
}

class _CustomPatternScreenState extends ConsumerState<CustomPatternScreen> {
  List<int> _sequence = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSequence();
  }

  Future<void> _loadCurrentSequence() async {
    final pattern = await ref.read(currentRotationPatternProvider.future);
    final zones = await ref.read(bodyZonesProvider.future);

    setState(() {
      if (pattern.customSequence != null && pattern.customSequence!.isNotEmpty) {
        _sequence = List.from(pattern.customSequence!);
      } else {
        // Default: tutte le zone in ordine
        _sequence = zones.map((z) => z.id).toList();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(bodyZonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequenza Personalizzata'),
        actions: [
          TextButton(
            onPressed: _saveSequence,
            child: const Text('Salva'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (zones) {
                final zoneMap = {for (var z in zones) z.id: z};

                return Column(
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: isDark
                          ? AppColors.darkOverlay
                          : AppColors.dawnOverlay,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark
                                ? AppColors.darkFoam
                                : AppColors.dawnFoam,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Trascina le zone per definire l\'ordine di rotazione. '
                              'Le iniezioni seguiranno questa sequenza.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Current sequence preview
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Ordine attuale:',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _sequence.asMap().entries.map((e) {
                                  final zone = zoneMap[e.value];
                                  if (zone == null) return const SizedBox();
                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkHighlightMed
                                          : AppColors.dawnHighlightMed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${e.key + 1}. ${_getZoneEmoji(zone.type)}',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Reorderable list
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _sequence.length,
                        onReorder: _onReorder,
                        itemBuilder: (context, index) {
                          final zoneId = _sequence[index];
                          final zone = zoneMap[zoneId];
                          if (zone == null) {
                            return const SizedBox(key: ValueKey(-1));
                          }

                          return _ZoneReorderTile(
                            key: ValueKey(zoneId),
                            index: index,
                            zoneName: zone.name,
                            zoneEmoji: _getZoneEmoji(zone.type),
                            zoneSide: zone.side,
                            isDark: isDark,
                            onRemove: () => _removeZone(index),
                          );
                        },
                      ),
                    ),

                    // Add zone button
                    if (_getAvailableZones(zones).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddZoneDialog(context, zones),
                          icon: const Icon(Icons.add),
                          label: const Text('Aggiungi zona'),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  String _getZoneEmoji(String type) {
    return switch (type) {
      'thigh' => '🦵',
      'arm' => '💪',
      'abdomen' => '👤',
      'buttock' => '🍑',
      _ => '📍',
    };
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sequence.removeAt(oldIndex);
      _sequence.insert(newIndex, item);
    });
  }

  void _removeZone(int index) {
    if (_sequence.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devi avere almeno una zona nella sequenza'),
        ),
      );
      return;
    }

    setState(() {
      _sequence.removeAt(index);
    });
  }

  List<BodyZone> _getAvailableZones(List<BodyZone> zones) {
    return zones.where((z) => !_sequence.contains(z.id)).toList();
  }

  void _showAddZoneDialog(BuildContext context, List<BodyZone> zones) {
    final available = _getAvailableZones(zones);
    if (available.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Seleziona zona da aggiungere',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...available.map((zone) => ListTile(
                leading: Text(
                  _getZoneEmoji(zone.type),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(zone.name),
                subtitle: Text(_getSideLabel(zone.side)),
                onTap: () {
                  setState(() {
                    _sequence.add(zone.id);
                  });
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getSideLabel(String side) {
    return switch (side) {
      'left' => 'Sinistro',
      'right' => 'Destro',
      _ => '',
    };
  }

  Future<void> _saveSequence() async {
    if (_sequence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La sequenza non può essere vuota')),
      );
      return;
    }

    final service = ref.read(rotationPatternServiceProvider);
    await service.setCustomSequence(_sequence);

    ref.invalidate(currentRotationPatternProvider);
    ref.invalidate(patternBasedZoneSuggestionProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sequenza salvata: ${_sequence.length} zone'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      context.pop();
    }
  }
}

class _ZoneReorderTile extends StatelessWidget {
  const _ZoneReorderTile({
    super.key,
    required this.index,
    required this.zoneName,
    required this.zoneEmoji,
    required this.zoneSide,
    required this.isDark,
    required this.onRemove,
  });

  final int index;
  final String zoneName;
  final String zoneEmoji;
  final String zoneSide;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkHighlightMed : AppColors.dawnHighlightMed,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(zoneEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(zoneName)),
          ],
        ),
        subtitle: zoneSide.isNotEmpty
            ? Text(zoneSide == 'left' ? 'Sinistro' : 'Destro')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: isDark ? AppColors.darkLove : AppColors.dawnLove,
              ),
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
      ),
    );
  }
}
