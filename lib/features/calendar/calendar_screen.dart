import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/app_database.dart' as db;
import '../../app/router.dart';
import '../injection/injection_provider.dart';

/// Calendar screen with injection schedule
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final focusedDay = ref.watch(focusedDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final injectionsAsync = ref.watch(injectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: injectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (injections) => Column(
          children: [
            TableCalendar<db.Injection>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'it_IT',

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),

              eventLoader: (day) => _getInjections(injections, day),

              onDaySelected: (selected, focused) {
                ref.read(selectedDayProvider.notifier).select(selected);
                ref.read(focusedDayProvider.notifier).focus(focused);
              },

              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },

              onPageChanged: (focused) {
                ref.read(focusedDayProvider.notifier).focus(focused);
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
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.dawnText,
                ),
                selectedDecoration: BoxDecoration(
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: isDark ? AppColors.darkBase : AppColors.dawnBase,
                  fontWeight: FontWeight.bold,
                ),
                weekendTextStyle: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
                outsideTextStyle: TextStyle(
                  color: (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: selectedDay != null
                  ? _DayInjectionsList(
                      selectedDay: selectedDay,
                      injections: _getInjections(injections, selectedDay),
                    )
                  : _EmptyState(isDark: isDark),
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
        child: const Icon(Icons.add),
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
          Color color;
          switch (inj.status) {
            case 'completed':
              color = isDark ? AppColors.darkPine : AppColors.dawnPine;
              break;
            case 'skipped':
              color = isDark ? AppColors.darkLove : AppColors.dawnLove;
              break;
            default:
              color = isDark ? AppColors.darkFoam : AppColors.dawnFoam;
          }

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
            ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
            : isToday
                ? (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                    .withValues(alpha: 0.3)
                : null,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppColors.darkBase : AppColors.dawnBase)
                : isDark
                    ? AppColors.darkText
                    : AppColors.dawnText,
            fontWeight: isSelected ? FontWeight.bold : null,
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
            Icons.calendar_today_outlined,
            size: 48,
            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un giorno',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
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
              Icons.check_circle_outline,
              size: 48,
              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna iniezione programmata',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
            ),
            Text(
              DateFormat('d MMMM yyyy', 'it_IT').format(selectedDay),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
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
        statusColor = isDark ? AppColors.darkPine : AppColors.dawnPine;
        statusIcon = Icons.check_circle;
        statusLabel = 'Completata';
        break;
      case 'skipped':
        statusColor = isDark ? AppColors.darkLove : AppColors.dawnLove;
        statusIcon = Icons.cancel;
        statusLabel = 'Saltata';
        break;
      case 'delayed':
        statusColor = isDark ? AppColors.darkGold : AppColors.dawnGold;
        statusIcon = Icons.schedule;
        statusLabel = 'In ritardo';
        break;
      default:
        statusColor = isDark ? AppColors.darkFoam : AppColors.dawnFoam;
        statusIcon = Icons.pending;
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
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
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
                Icons.chevron_right,
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
            ],
          ),
        ),
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
          final repository = ref.read(injectionRepositoryProvider);
          await repository.completeInjection(injection.id);
          ref.invalidate(injectionsProvider);
        },
        onSkip: () async {
          Navigator.pop(ctx);
          final repository = ref.read(injectionRepositoryProvider);
          await repository.skipInjection(injection.id);
          ref.invalidate(injectionsProvider);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Elimina iniezione'),
              content: const Text('Vuoi davvero eliminare questa iniezione?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Elimina'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final repository = ref.read(injectionRepositoryProvider);
            await repository.deleteInjection(injection.id);
            ref.invalidate(injectionsProvider);
          }
        },
        onChangePoint: () {
          Navigator.pop(ctx);
          context.push(
            AppRoutes.bodyMap,
            extra: {
              'scheduledDate': injection.scheduledAt,
              'existingInjectionId': injection.id,
            },
          );
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
    required this.onDelete,
    required this.onChangePoint,
  });

  final db.Injection injection;
  final bool isDark;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onDelete;
  final VoidCallback onChangePoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = injection.status == 'completed';
    final isSkipped = injection.status == 'skipped';

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
                            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
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
                leading: Icon(
                  Icons.check_circle,
                  color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                ),
                title: const Text('Segna come completata'),
                onTap: onComplete,
              ),
            if (!isSkipped)
              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                ),
                title: const Text('Segna come saltata'),
                onTap: onSkip,
              ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
              ),
              title: const Text('Cambia punto'),
              onTap: onChangePoint,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
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
