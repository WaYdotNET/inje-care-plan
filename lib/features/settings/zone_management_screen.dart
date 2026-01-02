import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/body_zone.dart';
import '../injection/zone_provider.dart';

/// Screen for managing body zones
class ZoneManagementScreen extends ConsumerStatefulWidget {
  const ZoneManagementScreen({super.key});

  @override
  ConsumerState<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends ConsumerState<ZoneManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Zone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddZoneDialog(context, isDark),
            tooltip: 'Aggiungi zona',
          ),
        ],
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (zones) => ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: zones.length,
          onReorder: (oldIndex, newIndex) => _onReorder(zones, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final zone = zones[index];
            return _ZoneTile(
              key: ValueKey(zone.id),
              zone: zone,
              isDark: isDark,
              onEdit: () => _showEditZoneDialog(context, zone, isDark),
              onDelete: () => _showDeleteConfirmation(context, zone, isDark),
              onToggle: (enabled) => _toggleZone(zone.id, enabled),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onReorder(List<BodyZone> zones, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reorderedZones = List<BodyZone>.from(zones);
    final item = reorderedZones.removeAt(oldIndex);
    reorderedZones.insert(newIndex, item);

    final actions = ref.read(zoneActionsProvider);
    await actions.reorderZones(reorderedZones.map((z) => z.id).toList());
  }

  Future<void> _toggleZone(int zoneId, bool enabled) async {
    final actions = ref.read(zoneActionsProvider);
    await actions.toggleEnabled(zoneId, enabled);
  }

  void _showAddZoneDialog(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ZoneEditDialog(
        isDark: isDark,
        onSave: (name, code, icon, type, side, pointCount) async {
          final actions = ref.read(zoneActionsProvider);
          await actions.addZone(
            code: code,
            name: name,
            icon: icon,
            type: type,
            side: side,
            numberOfPoints: pointCount,
          );
        },
      ),
    );
  }

  void _showEditZoneDialog(BuildContext context, BodyZone zone, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ZoneEditDialog(
        zone: zone,
        isDark: isDark,
        onSave: (name, code, icon, type, side, pointCount) async {
          final actions = ref.read(zoneActionsProvider);
          await actions.updateZone(
            id: zone.id,
            code: code,
            name: name,
            icon: icon.isNotEmpty ? icon : null,
            numberOfPoints: pointCount,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BodyZone zone, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina zona'),
        content: Text(
          'Sei sicuro di voler eliminare la zona "${zone.displayName}"?\n\n'
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actions = ref.read(zoneActionsProvider);
              await actions.deleteZone(zone.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkLove : AppColors.dawnLove,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

/// Individual zone tile
class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    super.key,
    required this.zone,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final BodyZone zone;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: zone.isEnabled
          ? (isDark ? AppColors.darkSurface : AppColors.dawnSurface)
          : (isDark ? AppColors.darkMuted : AppColors.dawnMuted).withValues(alpha: 0.2),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(zone.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          zone.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: zone.isEnabled
                ? null
                : (isDark ? AppColors.darkMuted : AppColors.dawnMuted),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              zone.code,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
              ),
            ),
            const SizedBox(width: 8),
            Text('•', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            Text(
              '${zone.numberOfPoints} punti',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Text('•', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            Text(
              _sideLabel(zone.side),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: zone.isEnabled,
              onChanged: onToggle,
              activeColor: isDark ? AppColors.darkPine : AppColors.dawnPine,
            ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifica'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Elimina', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  String _sideLabel(String side) {
    return switch (side) {
      'left' => 'Sinistra',
      'right' => 'Destra',
      _ => 'Centrale',
    };
  }
}

/// Dialog for adding/editing zones
class _ZoneEditDialog extends StatefulWidget {
  const _ZoneEditDialog({
    this.zone,
    required this.isDark,
    required this.onSave,
  });

  final BodyZone? zone;
  final bool isDark;
  final Future<void> Function(
    String name,
    String code,
    String icon,
    String type,
    String side,
    int pointCount,
  ) onSave;

  @override
  State<_ZoneEditDialog> createState() => _ZoneEditDialogState();
}

class _ZoneEditDialogState extends State<_ZoneEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _iconController;
  late String _type;
  late String _side;
  late int _pointCount;
  bool _saving = false;

  static const _emojis = ['🦵', '💪', '💧', '🍑', '📍', '💉', '🩺', '🔵', '🟢', '🟡'];
  static const _types = ['thigh', 'arm', 'abdomen', 'buttock', 'custom'];
  static const _sides = ['left', 'right', 'none'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone?.name ?? '');
    _codeController = TextEditingController(text: widget.zone?.code ?? '');
    _iconController = TextEditingController(text: widget.zone?.icon ?? '');
    _type = widget.zone?.type ?? 'custom';
    _side = widget.zone?.side ?? 'none';
    _pointCount = widget.zone?.numberOfPoints ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.zone == null ? 'Nuova Zona' : 'Modifica Zona'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome zona *',
                hintText: 'Es: Coscia Dx',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Code field
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Codice (2-4 caratteri) *',
                hintText: 'Es: CD',
                border: OutlineInputBorder(),
              ),
              maxLength: 4,
            ),
            const SizedBox(height: 8),

            // Icon selection
            Text('Icona', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) => GestureDetector(
                onTap: () => setState(() => _iconController.text = emoji),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _iconController.text == emoji
                        ? (widget.isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                        : (widget.isDark ? AppColors.darkSurface : AppColors.dawnSurface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _iconController.text == emoji
                          ? (widget.isDark ? AppColors.darkPine : AppColors.dawnPine)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo zona',
                border: OutlineInputBorder(),
              ),
              items: _types.map((t) => DropdownMenuItem(
                value: t,
                child: Text(_typeLabel(t)),
              )).toList(),
              onChanged: (v) => setState(() => _type = v ?? 'custom'),
            ),
            const SizedBox(height: 16),

            // Side dropdown
            DropdownButtonFormField<String>(
              value: _side,
              decoration: const InputDecoration(
                labelText: 'Lato',
                border: OutlineInputBorder(),
              ),
              items: _sides.map((s) => DropdownMenuItem(
                value: s,
                child: Text(_sideLabel(s)),
              )).toList(),
              onChanged: (v) => setState(() => _side = v ?? 'none'),
            ),
            const SizedBox(height: 16),

            // Point count slider
            Text('Numero di punti: $_pointCount', style: theme.textTheme.titleSmall),
            Slider(
              value: _pointCount.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_pointCount',
              onChanged: (v) => setState(() => _pointCount = v.round()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'thigh' => 'Coscia',
      'arm' => 'Braccio',
      'abdomen' => 'Addome',
      'buttock' => 'Gluteo',
      _ => 'Personalizzato',
    };
  }

  String _sideLabel(String side) {
    return switch (side) {
      'left' => 'Sinistra',
      'right' => 'Destra',
      _ => 'Nessuno (centrale)',
    };
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e codice sono obbligatori')),
      );
      return;
    }

    if (code.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il codice deve essere di almeno 2 caratteri')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.onSave(
        name,
        code,
        _iconController.text,
        _type,
        _side,
        _pointCount,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
