import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../app/router.dart';
import '../../models/body_zone.dart';
import '../../models/injection_record.dart';
import '../../models/therapy_plan.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_settings_provider.dart';
import 'injection_provider.dart';
import 'zone_provider.dart';

/// Returns Material Icon for zone type
IconData _getZoneIcon(String type) => switch (type) {
      'thigh' => Icons.accessibility_new_rounded,
      'arm' => Icons.fitness_center_rounded,
      'abdomen' => Icons.circle_outlined,
      'buttock' => Icons.airline_seat_legroom_reduced_rounded,
      _ => Icons.location_on_rounded,
    };

/// Record injection screen
class RecordInjectionScreen extends ConsumerStatefulWidget {
  const RecordInjectionScreen({
    super.key,
    required this.zoneId,
    required this.pointNumber,
    this.scheduledDate,
    this.existingInjectionId,
  });

  final int zoneId;
  final int pointNumber;
  final DateTime? scheduledDate;
  final int? existingInjectionId;

  @override
  ConsumerState<RecordInjectionScreen> createState() => _RecordInjectionScreenState();
}

class _RecordInjectionScreenState extends ConsumerState<RecordInjectionScreen> {
  final _notesController = TextEditingController();
  final Set<String> _selectedSideEffects = {};
  bool _isLoading = false;

  BodyZone? _getZone(List<BodyZone> zones) {
    final zone = zones.where((z) => z.id == widget.zoneId).firstOrNull;
    return zone ?? zones.firstOrNull;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'it_IT');
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registra iniezione'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (zones) {
          final zone = _getZone(zones);
          if (zone == null) {
            return const Center(child: Text('Zona non trovata'));
          }
          return _buildContent(context, theme, isDark, now, dateFormat, zone, zones);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    DateTime now,
    DateFormat dateFormat,
    BodyZone zone,
    List<BodyZone> zones,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date/time
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(now),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Selected point
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_getZoneIcon(zone.type), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.pointLabel(widget.pointNumber),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          zone.pointCode(widget.pointNumber),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cambia'),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // Notes
            Text(
              'Note (opzionale)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Aggiungi note...',
              ),
            ),

            const SizedBox(height: 24),

            // Side effects
            Text(
              'Effetti collaterali',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            ...[
              'Rossore nel punto',
              'Dolore locale',
              'Stanchezza',
              'Sintomi influenzali',
              'Altro',
            ].map((effect) => CheckboxListTile(
              title: Text(effect),
              value: _selectedSideEffects.contains(effect),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedSideEffects.add(effect);
                  } else {
                    _selectedSideEffects.remove(effect);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),

            const SizedBox(height: 32),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _confirmInjection(zone, zones),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Salvataggio...' : 'Conferma iniezione'),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _confirmInjection(BodyZone zone, List<BodyZone> zones) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(injectionRepositoryProvider);
      final now = DateTime.now();
      final scheduledAt = widget.scheduledDate ?? now;

      // Workflow: SEMPRE salvata prima come "scheduled", poi può essere completata
      // Questo permette all'utente di programmare e poi confermare
      const status = InjectionStatus.scheduled;

      // Create injection record - sempre come "scheduled" inizialmente
      final record = InjectionRecord(
        zoneId: widget.zoneId,
        pointNumber: widget.pointNumber,
        scheduledAt: scheduledAt,
        completedAt: null, // Non completata ancora
        status: status,
        notes: _notesController.text.isNotEmpty ? _notesController.text : '',
        sideEffects: _selectedSideEffects.toList(),
        createdAt: now,
        updatedAt: now,
      );

      // Se stiamo modificando un'iniezione esistente, aggiorna invece di creare
      int injectionId;
      if (widget.existingInjectionId != null) {
        await repository.updateInjection(widget.existingInjectionId!, record);
        injectionId = widget.existingInjectionId!;
      } else {
        injectionId = await repository.createInjection(record);
      }

      // Schedule next injection notification if enabled
      final notificationSettings = ref.read(notificationSettingsProvider);

      if (notificationSettings.enabled && notificationSettings.permissionsGranted) {
        // Schedule next injection notification using default plan
        final therapyPlan = TherapyPlan.defaults;
        final nextDate = therapyPlan.getNextInjectionDate(now.add(const Duration(hours: 1)));
        final suggestedPoint = await repository.getSuggestedNextPoint();

        if (suggestedPoint != null) {
          final nextZone = zones.firstWhere(
            (z) => z.id == suggestedPoint.zoneId,
            orElse: () => zones.first,
          );

          // Schedule notification for next injection
          await NotificationService.instance.scheduleInjectionReminder(
            id: nextDate.millisecondsSinceEpoch ~/ 1000,
            scheduledTime: nextDate,
            pointLabel: nextZone.pointLabel(suggestedPoint.pointNumber),
            minutesBefore: notificationSettings.minutesBefore,
          );
        }
      }

      if (mounted) {
        final isUpdate = widget.existingInjectionId != null;
        
        if (isUpdate) {
          // Per le modifiche, vai direttamente alla home
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text('Iniezione modificata: ${zone.pointLabel(widget.pointNumber)}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          context.go(AppRoutes.home);
        } else {
          // Per nuove iniezioni, chiedi se confermare subito
          final shouldComplete = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Iniezione programmata'),
              content: Text(
                '${zone.pointLabel(widget.pointNumber)} è stata programmata.\n\n'
                'Vuoi segnarla come completata adesso?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('No, dopo'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sì, completata'),
                ),
              ],
            ),
          );
          
          if (shouldComplete == true && mounted) {
            // Segna come completata
            final completedRecord = record.copyWith(
              status: InjectionStatus.completed,
              completedAt: DateTime.now(),
            );
            await repository.updateInjection(injectionId, completedRecord);
            
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text('✓ ${zone.pointLabel(widget.pointNumber)} completata!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          }
          
          if (mounted) {
            context.go(AppRoutes.home);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
