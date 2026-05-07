import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import 'injection_provider.dart';
import 'injection_repository.dart';

/// Schermata di dettaglio di una singola iniezione.
///
/// Aperta sia tramite tap su elementi delle liste (storico, calendario)
/// sia come deep-link target dal tap su una notifica reminder.
/// Le note sono editabili in qualunque momento (anche dopo il completamento).
class InjectionDetailScreen extends ConsumerStatefulWidget {
  const InjectionDetailScreen({super.key, required this.injectionId});

  final int injectionId;

  @override
  ConsumerState<InjectionDetailScreen> createState() =>
      _InjectionDetailScreenState();
}

class _InjectionDetailScreenState extends ConsumerState<InjectionDetailScreen> {
  static const _commonEffects = [
    'Rossore nel punto',
    'Dolore locale',
    'Stanchezza',
    'Sintomi influenzali',
    'Altro',
  ];

  final _notesController = TextEditingController();
  Timer? _notesDebounce;
  bool _notesInitialized = false;
  Set<String> _selectedEffects = <String>{};
  bool _effectsInitialized = false;

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromInjection(db.Injection injection) {
    if (!_notesInitialized) {
      _notesController.text = injection.notes;
      _notesInitialized = true;
    }
    if (!_effectsInitialized) {
      _selectedEffects = injection.sideEffects
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();
      _effectsInitialized = true;
    }
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 600), () {
      ref
          .read(injectionRepositoryProvider)
          .updateNotes(widget.injectionId, value);
    });
  }

  Future<void> _toggleEffect(String effect, bool selected) async {
    setState(() {
      if (selected) {
        _selectedEffects.add(effect);
      } else {
        _selectedEffects.remove(effect);
      }
    });
    await ref
        .read(injectionRepositoryProvider)
        .updateSideEffects(widget.injectionId, _selectedEffects.toList());
  }

  Future<void> _complete(db.Injection injection) async {
    final repo = ref.read(injectionRepositoryProvider);
    try {
      await repo.completeInjection(
        injection.id,
        notes: _notesController.text,
        sideEffects: _selectedEffects.toList(),
      );
    } on StateError catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Disponibile dal ${DateFormat('d MMM yyyy', 'it_IT').format(injection.scheduledAt)}',
          ),
        ),
      );
      return;
    }
    await NotificationService.instance.cancelNotification(injection.id);
    ref.invalidate(injectionByIdProvider(widget.injectionId));
    ref.invalidate(injectionsProvider);
  }

  Future<void> _skip(db.Injection injection) async {
    await ref.read(injectionRepositoryProvider).skipInjection(injection.id);
    await NotificationService.instance.cancelNotification(injection.id);
    ref.invalidate(injectionByIdProvider(widget.injectionId));
    ref.invalidate(injectionsProvider);
  }

  Future<void> _restore(db.Injection injection) async {
    await ref.read(injectionRepositoryProvider).restoreInjection(injection.id);
    ref.invalidate(injectionByIdProvider(widget.injectionId));
    ref.invalidate(injectionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final injectionAsync =
        ref.watch(injectionByIdProvider(widget.injectionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio iniezione'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: injectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (injection) {
          if (injection == null) {
            return const Center(
              child: Text('Iniezione non trovata'),
            );
          }
          _initFromInjection(injection);
          return _buildContent(context, theme, isDark, injection);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    db.Injection injection,
  ) {
    final isCompleted = injection.status == 'completed';
    final isSkipped = injection.status == 'skipped';
    final canComplete = canCompleteNow(injection.scheduledAt);
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'it_IT');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(injection.pointLabel, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(injection.scheduledAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusChip(status: injection.status, isDark: isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Note', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Aggiungi note (auto-salvataggio)',
            border: OutlineInputBorder(),
          ),
          onChanged: _onNotesChanged,
        ),
        const SizedBox(height: 24),
        Text('Effetti collaterali', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._commonEffects.map(
          (effect) => CheckboxListTile(
            title: Text(effect),
            value: _selectedEffects.contains(effect),
            onChanged: (value) => _toggleEffect(effect, value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const SizedBox(height: 24),
        if (!isCompleted && !isSkipped) ...[
          FilledButton.icon(
            onPressed: canComplete ? () => _complete(injection) : null,
            icon: const Icon(Icons.check_circle),
            label: Text(
              canComplete
                  ? 'Segna come completata'
                  : 'Disponibile dal ${DateFormat('d MMM yyyy', 'it_IT').format(injection.scheduledAt)}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _skip(injection),
            icon: const Icon(Icons.cancel),
            label: const Text('Segna come saltata'),
          ),
        ],
        if (isCompleted || isSkipped)
          OutlinedButton.icon(
            onPressed: () => _restore(injection),
            icon: const Icon(Icons.restore),
            label: const Text('Ripristina come pianificata'),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isDark});

  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => (
        'Completata',
        isDark ? AppColors.darkPine : AppColors.dawnPine,
      ),
      'skipped' => (
        'Saltata',
        isDark ? AppColors.darkGold : AppColors.dawnGold,
      ),
      _ => (
        'Pianificata',
        isDark ? AppColors.darkFoam : AppColors.dawnFoam,
      ),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
