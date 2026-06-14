import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/injection_status_colors.dart';
import '../../core/database/app_database.dart' as db;
import '../../app/router.dart';
import '../../core/services/missed_injection_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_settings_provider.dart';
import '../injection/injection_provider.dart';
import '../injection/injection_repository.dart';
import '../../core/widgets/completion_time_dialog.dart';
import '../history/widgets/injection_history_list.dart';

/// Calendar screen with injection schedule
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showList = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final focusedDay = ref.watch(focusedDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final injectionsAsync = ref.watch(injectionsProvider);

    // Controlla e marca le iniezioni mancate (una volta per sessione container)
    ref.watch(checkMissedInjectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: injectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (injections) => Column(
          children: [
            _CalendarViewToggle(
              showList: _showList,
              isDark: isDark,
              onChanged: (value) => setState(() => _showList = value),
            ),
            Expanded(
              child: _showList
                  ? InjectionHistoryList(injections: injections)
                  : Column(
                      children: [
                        TableCalendar<db.Injection>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: focusedDay,
                          calendarFormat: _calendarFormat,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          locale: 'it_IT',

                          selectedDayPredicate: (day) =>
                              isSameDay(selectedDay, day),

                          eventLoader: (day) =>
                              _getInjections(injections, day),

                          onDaySelected: (selected, focused) {
                            ref
                                .read(selectedDayProvider.notifier)
                                .select(selected);
                            ref
                                .read(focusedDayProvider.notifier)
                                .focus(focused);
                          },

                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },

                          onPageChanged: (focused) {
                            ref
                                .read(focusedDayProvider.notifier)
                                .focus(focused);
                          },

                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return null;
                              return _buildMarkers(events, isDark);
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return _buildDayCell(
                                day,
                                isToday: true,
                                isSelected: false,
                                isDark: isDark,
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _buildDayCell(
                                day,
                                isToday: isSameDay(day, DateTime.now()),
                                isSelected: true,
                                isDark: isDark,
                              );
                            },
                          ),

                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonShowsNext: false,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? AppTokens.darkMuted
                                    : AppTokens.lightMuted,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: (isDark
                                      ? AppTokens.accentEnd
                                      : AppTokens.accentEnd)
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(
                              color: isDark
                                  ? AppTokens.darkInk
                                  : AppTokens.lightInk,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: isDark
                                  ? AppTokens.accentEnd
                                  : AppTokens.accentEnd,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: TextStyle(
                              color: isDark
                                  ? AppTokens.darkBg
                                  : AppTokens.lightBgTop,
                              fontWeight: FontWeight.bold,
                            ),
                            weekendTextStyle: TextStyle(
                              color: isDark
                                  ? AppTokens.darkMuted
                                  : AppTokens.lightMuted,
                            ),
                            outsideTextStyle: TextStyle(
                              color: (isDark
                                      ? AppTokens.darkMuted
                                      : AppTokens.lightMuted)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: selectedDay != null
                              ? _DayInjectionsList(
                                  selectedDay: selectedDay,
                                  injections:
                                      _getInjections(injections, selectedDay),
                                )
                              : _EmptyState(isDark: isDark),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final dateToUse = selectedDay ?? focusedDay;
          context.push(
            AppRoutes.bodyMap,
            extra: {'scheduledDate': dateToUse},
          );
        },
        child: const Icon(PhosphorIconsDuotone.plus),
      ),
    );
  }

  List<db.Injection> _getInjections(List<db.Injection> injections, DateTime day) {
    return injections.where((inj) {
      return isSameDay(inj.scheduledAt, day);
    }).toList();
  }

  Widget _buildMarkers(List<db.Injection> events, bool isDark) {
    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: events.take(3).map((inj) {
          final color =
              InjectionStatusColors.getStatusColor(inj.status, isDark: isDark);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isToday,
    required bool isSelected,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppTokens.accentEnd : AppTokens.accentEnd)
            : isToday
                ? (isDark ? AppTokens.accentEnd : AppTokens.accentEnd)
                    .withValues(alpha: 0.3)
                : null,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppTokens.darkBg : AppTokens.lightBgTop)
                : isDark
                    ? AppTokens.darkInk
                    : AppTokens.lightInk,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _CalendarViewToggle extends StatelessWidget {
  const _CalendarViewToggle({
    required this.showList,
    required this.isDark,
    required this.onChanged,
  });

  final bool showList;
  final bool isDark;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkHighlightLow : AppTokens.lightHighlightLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TogglePill(
              label: 'Mese',
              selected: !showList,
              isDark: isDark,
              onTap: () => onChanged(false),
            ),
            _TogglePill(
              label: 'Lista',
              selected: showList,
              isDark: isDark,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppTokens.accent : AppTokens.accent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? Colors.white
                : (isDark ? AppTokens.darkSubtle : AppTokens.lightSubtle),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsDuotone.calendarDot,
            size: 48,
            color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un giorno',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _DayInjectionsList extends StatelessWidget {
  const _DayInjectionsList({
    required this.selectedDay,
    required this.injections,
  });

  final DateTime selectedDay;
  final List<db.Injection> injections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (injections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsDuotone.checkCircle,
              size: 48,
              color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna iniezione programmata',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
              ),
            ),
            Text(
              DateFormat('d MMMM yyyy', 'it_IT').format(selectedDay),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            DateFormat('EEEE d MMMM', 'it_IT').format(selectedDay),
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: injections.length,
            itemBuilder: (context, index) {
              final injection = injections[index];
              return _InjectionCard(injection: injection, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _InjectionCard extends ConsumerWidget {
  const _InjectionCard({
    required this.injection,
    required this.isDark,
  });

  final db.Injection injection;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (injection.status) {
      case 'completed':
        statusColor = isDark ? AppTokens.accent : AppTokens.accent;
        statusIcon = PhosphorIconsDuotone.checkCircle;
        statusLabel = 'Completata';
        break;
      case 'skipped':
        statusColor = isDark ? AppTokens.dangerDark : AppTokens.dangerLight;
        statusIcon = PhosphorIconsDuotone.prohibit;
        statusLabel = 'Saltata';
        break;
      case 'missed':
        statusColor = isDark ? AppTokens.dangerDark : AppTokens.dangerLight;
        statusIcon = PhosphorIconsDuotone.warning;
        statusLabel = 'Mancata';
        break;
      case 'delayed':
        statusColor = isDark ? AppTokens.warnDark : AppTokens.warnLight;
        statusIcon = PhosphorIconsDuotone.clock;
        statusLabel = 'In ritardo';
        break;
      default:
        statusColor = isDark ? AppTokens.accentEnd : AppTokens.accentEnd;
        statusIcon = PhosphorIconsDuotone.clock;
        statusLabel = 'Programmata';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEditOptions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      injection.pointLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      injection.pointCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(injection.scheduledAt),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsDuotone.caretRight,
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDestructive ? 'Elimina' : 'Conferma'),
          ),
        ],
      ),
    );
  }

  void _showEditOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _InjectionEditSheet(
        injection: injection,
        isDark: isDark,
        onComplete: () async {
          Navigator.pop(ctx);
          if (!context.mounted) return;

          final at = await showCompletionTimeDialog(
            context,
            pointLabel: injection.pointLabel,
          );
          if (at == null) return;

          final repository = ref.read(injectionRepositoryProvider);

          await NotificationService.instance.cancelNotification(injection.id);

          try {
            await repository.completeInjection(injection.id, at: at);
          } on StateError catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Disponibile dal ${DateFormat('d MMM yyyy', 'it_IT').format(injection.scheduledAt)}',
                  ),
                ),
              );
            }
            return;
          }

          final notifSettings = ref.read(notificationSettingsProvider);
          if (notifSettings.enabled && notifSettings.permissionsGranted) {
            await NotificationService.instance.scheduleSideEffectsReminder(
              id: injection.id,
              completedAt: at,
              pointLabel: injection.pointLabel,
              hoursAfter: notifSettings.sideEffectsReminderHours,
            );
          }

          ref.invalidate(injectionsProvider);
        },
        onSkip: () async {
          Navigator.pop(ctx);
          if (injection.status == 'completed') {
            final confirm = await _showConfirmDialog(
              context,
              title: 'Cambia stato',
              message: 'Questa iniezione è registrata come completata. '
                  'Vuoi davvero segnarla come saltata?',
            );
            if (confirm != true) return;
          }
          final repository = ref.read(injectionRepositoryProvider);

          await NotificationService.instance.cancelNotification(injection.id);

          await repository.skipInjection(injection.id);
          ref.invalidate(injectionsProvider);
        },
        onRestore: () async {
          Navigator.pop(ctx);
          final confirm = await _showConfirmDialog(
            context,
            title: 'Ripristina iniezione',
            message: 'Vuoi davvero ripristinare questa iniezione come pianificata?',
          );
          if (confirm != true) return;
          final repository = ref.read(injectionRepositoryProvider);
          await repository.restoreInjection(injection.id);
          ref.invalidate(injectionsProvider);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirm = await _showConfirmDialog(
            context,
            title: 'Elimina iniezione',
            message: 'Vuoi davvero eliminare questa iniezione?',
            isDestructive: true,
          );
          if (confirm != true) return;
          final repository = ref.read(injectionRepositoryProvider);
          await repository.deleteInjection(injection.id);
          ref.invalidate(injectionsProvider);
        },
        onChangePoint: () async {
          Navigator.pop(ctx);
          if (injection.status == 'completed' ||
              injection.status == 'skipped') {
            final confirm = await _showConfirmDialog(
              context,
              title: 'Cambia punto',
              message: 'Questa iniezione è già stata registrata. '
                  'Cambiare il punto modificherà i dati esistenti. Continuare?',
            );
            if (confirm != true) return;
          }
          if (!context.mounted) return;
          context.push(
            AppRoutes.bodyMap,
            extra: {
              'scheduledDate': injection.scheduledAt,
              'existingInjectionId': injection.id,
            },
          );
        },
        onOpenDetail: () {
          Navigator.pop(ctx);
          context.push(AppRoutes.injectionDetailPath(injection.id));
        },
      ),
    );
  }
}

class _InjectionEditSheet extends StatelessWidget {
  const _InjectionEditSheet({
    required this.injection,
    required this.isDark,
    required this.onComplete,
    required this.onSkip,
    required this.onRestore,
    required this.onDelete,
    required this.onChangePoint,
    required this.onOpenDetail,
  });

  final db.Injection injection;
  final bool isDark;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onChangePoint;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = injection.status == 'completed';
    final isSkipped = injection.status == 'skipped';
    final canComplete = canCompleteNow(injection.scheduledAt);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          injection.pointLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat('d MMMM yyyy, HH:mm', 'it_IT')
                              .format(injection.scheduledAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Actions
            if (!isCompleted)
              ListTile(
                enabled: canComplete,
                leading: Icon(
                  PhosphorIconsDuotone.checkCircle,
                  color: !canComplete
                      ? (isDark ? AppTokens.darkMuted : AppTokens.lightMuted)
                      : (isDark ? AppTokens.accent : AppTokens.accent),
                ),
                title: const Text('Segna come completata'),
                subtitle: !canComplete
                    ? Text(
                        'Disponibile dal ${DateFormat('d MMM yyyy', 'it_IT').format(injection.scheduledAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTokens.darkMuted
                              : AppTokens.lightMuted,
                        ),
                      )
                    : null,
                onTap: canComplete ? onComplete : null,
              ),
            if (!isSkipped)
              ListTile(
                leading: Icon(
                  PhosphorIconsDuotone.prohibit,
                  color: isDark ? AppTokens.warnDark : AppTokens.warnLight,
                ),
                title: const Text('Segna come saltata'),
                onTap: onSkip,
              ),
            if (isCompleted || isSkipped)
              ListTile(
                leading: Icon(
                  PhosphorIconsDuotone.arrowCounterClockwise,
                  color: isDark ? AppTokens.accentEnd : AppTokens.accentEnd,
                ),
                title: const Text('Ripristina come pianificata'),
                onTap: onRestore,
              ),
            ListTile(
              leading: Icon(
                PhosphorIconsDuotone.pencilSimple,
                color: isDark ? AppTokens.darkIris : AppTokens.accent,
              ),
              title: const Text('Apri dettaglio (note + effetti)'),
              onTap: onOpenDetail,
            ),
            ListTile(
              leading: Icon(
                PhosphorIconsDuotone.pencilSimple,
                color: isDark ? AppTokens.accentEnd : AppTokens.accentEnd,
              ),
              title: const Text('Cambia punto'),
              onTap: onChangePoint,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(PhosphorIconsDuotone.trash, color: Colors.red),
              title: const Text(
                'Elimina',
                style: TextStyle(color: Colors.red),
              ),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
