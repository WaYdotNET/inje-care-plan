import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/services/calendar_sync_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_settings_provider.dart';
import '../../models/reminder_rule.dart';
import '../injection/injection_provider.dart';

/// Schermata "Promemoria e Calendario" nelle Impostazioni.
///
/// Consente all'utente di:
/// - abilitare/disabilitare la sincronizzazione con il calendario del telefono;
/// - scegliere il canale (solo calendario / solo notifiche / entrambi);
/// - configurare cosa succede al completamento dell'iniezione;
/// - includere il feedback nell'evento (con avviso privacy);
/// - gestire le regole di promemoria (offset, attiva/disattiva, aggiungi, elimina).
class ReminderCalendarScreen extends ConsumerStatefulWidget {
  const ReminderCalendarScreen({super.key});

  @override
  ConsumerState<ReminderCalendarScreen> createState() =>
      _ReminderCalendarScreenState();
}

class _ReminderCalendarScreenState
    extends ConsumerState<ReminderCalendarScreen> {
  bool _loading = false;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  ReminderSettingsView _viewFrom(ReminderSettings s) => ReminderSettingsView.from(s);

  String _offsetLabel(int m) {
    if (m == 0) return "All'orario";
    if (m < 60) return '$m min prima';
    if (m % 60 == 0 && m < 1440) return '${m ~/ 60} h prima';
    if (m == 1440) return '24h prima';
    if (m == 2880) return '48h prima';
    return '$m min prima';
  }

  // ── Cancella notifiche app pre-iniezione già schedulate ─────────────────────

  /// Cancella le notifiche app pre-iniezione (promemoria anticipato e 1 min
  /// prima) per tutte le iniezioni future. Chiamato best-effort quando
  /// l'utente passa al canale "Solo calendario" per evitare duplicati con
  /// l'allarme del calendario.
  Future<void> _cancelPreInjectionRemindersIfNeeded() async {
    try {
      final db = ref.read(databaseProvider);
      final injections = await db.getFutureScheduledInjections(DateTime.now());
      final ids = injections.map((i) => i.id).toList();
      if (ids.isNotEmpty) {
        await NotificationService.instance.cancelPreInjectionReminders(ids);
      }
    } catch (e) {
      debugPrint(
        '[ReminderCalendarScreen] cancelPreInjectionReminders error (best-effort): $e',
      );
    }
  }

  // ── Toggle calendario ON/OFF ─────────────────────────────────────────────────

  Future<void> _onCalendarToggle({required bool value}) async {
    if (_loading) return;
    final settings = ref.read(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);
    final sync = ref.read(calendarSyncServiceProvider);
    final db = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    try {
      if (value) {
        // Richiedi permessi
        final granted = await sync.ensureCalendarPermission();
        if (!granted) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Permesso calendario negato')),
            );
          }
          return;
        }

        await sync.ensureInjeCareCalendar();

        final updated = settings.copyWith(
          calendarEnabled: true,
          channel: ReminderChannel.calendar,
        );
        await notifier.update(updated);

        // Cancella le notifiche app pre-iniezione già schedulate: il calendario
        // le sostituirà, quindi non servono duplicati.
        await _cancelPreInjectionRemindersIfNeeded();

        // Backfill: sincronizza le prossime iniezioni programmate
        final injections = await db.getFutureScheduledInjections(DateTime.now());
        var synced = 0;
        final view = _viewFrom(updated);
        for (final inj in injections) {
          final prev = await db.getPreviousCompletedBefore(inj.scheduledAt);
          final eventId = await sync.upsertEvent(inj, prev, view);
          if (eventId != null) {
            await db.setCalendarEventId(inj.id, eventId);
            synced++;
          }
        }

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                synced > 0
                    ? '$synced iniezioni sincronizzate con il calendario'
                    : 'Calendario abilitato (nessuna iniezione futura da sincronizzare)',
              ),
            ),
          );
        }
      } else {
        // Disabilita: elimina il calendario dedicato
        await sync.teardown();
        await notifier.update(
          settings.copyWith(
            calendarEnabled: false,
            channel: ReminderChannel.appNotifications,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ── Dialogo aggiungi promemoria ──────────────────────────────────────────────

  Future<void> _showAddReminderDialog(ReminderSettings settings) async {
    final existing = settings.rules.map((r) => r.minutesBefore).toSet();
    final available = ReminderRule.presetMinutes
        .where((m) => !existing.contains(m))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutti i promemoria disponibili sono già stati aggiunti'),
        ),
      );
      return;
    }

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Aggiungi promemoria'),
        children: available
            .map(
              (m) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m),
                child: Text(_offsetLabel(m)),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || !mounted) return;

    final updatedRules = [
      ...settings.rules,
      ReminderRule(minutesBefore: selected, enabled: true),
    ]..sort((a, b) => a.minutesBefore.compareTo(b.minutesBefore));

    await ref
        .read(reminderSettingsProvider.notifier)
        .update(settings.copyWith(rules: updatedRules));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Promemoria e Calendario')),
      body: ListView(
        children: [
          // Master toggle
          SwitchListTile(
            title: const Text('Aggiungi al calendario del telefono'),
            subtitle: const Text(
              'Crea eventi nel calendario del dispositivo per ogni iniezione programmata.',
            ),
            value: settings.calendarEnabled,
            onChanged: _loading
                ? null
                : (v) => _onCalendarToggle(value: v),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: LinearProgressIndicator()),
            ),

          if (settings.calendarEnabled) ...[
            const Divider(),

            // Canale promemoria
            const _SectionHeader(title: 'CANALE PROMEMORIA'),
            RadioGroup<ReminderChannel>(
              groupValue: settings.channel,
              onChanged: (v) async {
                await notifier.update(settings.copyWith(channel: v));
                // Se si passa a "Solo calendario", cancella le notifiche app
                // pre-iniezione già schedulate per le iniezioni future.
                if (v == ReminderChannel.calendar) {
                  await _cancelPreInjectionRemindersIfNeeded();
                }
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ReminderChannel>(
                    title: Text('Solo calendario'),
                    value: ReminderChannel.calendar,
                  ),
                  RadioListTile<ReminderChannel>(
                    title: Text('Solo notifiche app'),
                    value: ReminderChannel.appNotifications,
                  ),
                  RadioListTile<ReminderChannel>(
                    title: Text('Entrambi'),
                    subtitle: Text('Possibili doppi avvisi'),
                    value: ReminderChannel.both,
                  ),
                ],
              ),
            ),

            const Divider(),

            // A completamento
            const _SectionHeader(title: 'A COMPLETAMENTO'),
            RadioGroup<CompletionBehavior>(
              groupValue: settings.completionBehavior,
              onChanged: (v) =>
                  notifier.update(settings.copyWith(completionBehavior: v)),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<CompletionBehavior>(
                    title: Text('Segna come fatta ✓'),
                    value: CompletionBehavior.markDone,
                  ),
                  RadioListTile<CompletionBehavior>(
                    title: Text('Rimuovi evento'),
                    value: CompletionBehavior.remove,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Feedback nell'evento
            SwitchListTile(
              title: const Text(
                "Includi il feedback dell'ultima iniezione nell'evento",
              ),
              subtitle: const Text(
                'Se sincronizzi il calendario con un servizio cloud, '
                'questi dati lasciano il dispositivo.',
              ),
              value: settings.includeFeedback,
              onChanged: (v) => notifier.update(
                settings.copyWith(includeFeedback: v),
              ),
            ),

            const Divider(),

            // Regole promemoria
            const _SectionHeader(title: 'PROMEMORIA'),
            ...List.generate(settings.rules.length, (i) {
              final rule = settings.rules[i];
              return ListTile(
                title: Text(_offsetLabel(rule.minutesBefore)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: rule.enabled,
                      onChanged: (v) {
                        final updated = List<ReminderRule>.from(settings.rules);
                        updated[i] = rule.copyWith(enabled: v);
                        notifier.update(settings.copyWith(rules: updated));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Rimuovi',
                      onPressed: () {
                        final updated = List<ReminderRule>.from(settings.rules)
                          ..removeAt(i);
                        notifier.update(settings.copyWith(rules: updated));
                      },
                    ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton.icon(
                onPressed: () => _showAddReminderDialog(settings),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi promemoria'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}
