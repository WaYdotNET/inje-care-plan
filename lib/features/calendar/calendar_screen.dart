import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../app/router.dart';
import '../../models/injection_record.dart';
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
            TableCalendar<InjectionRecord>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'it_IT',

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),

              eventLoader: (day) => _getInjections(injections, day),

              onDaySelected: (selected, focused) {
                ref.read(selectedDayProvider.notifier).state = selected;
                ref.read(focusedDayProvider.notifier).state = focused;
              },

              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },

              onPageChanged: (focused) {
                ref.read(focusedDayProvider.notifier).state = focused;
              },

              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return _buildMarkers(events, isDark);
                },
              ),

              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.dawnText,
                  fontWeight: FontWeight.w600,
                ),
                selectedDecoration: BoxDecoration(
                  color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                weekendTextStyle: TextStyle(
                  color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                ),
                defaultTextStyle: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.dawnText,
                ),
              ),

              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleLarge!,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: isDark ? AppColors.darkText : AppColors.dawnText,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.darkText : AppColors.dawnText,
                ),
              ),

              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Divider(),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendItem(
                    color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                    label: 'Completata',
                  ),
                  _LegendItem(
                    color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                    label: 'Programmata',
                  ),
                  _LegendItem(
                    color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                    label: 'In ritardo',
                  ),
                  _LegendItem(
                    color: isDark ? AppColors.darkLove : AppColors.dawnLove,
                    label: 'Saltata',
                  ),
                ],
              ),
            ),

            const Divider(),

            // Selected day details
            Expanded(
              child: selectedDay != null
                  ? _DayDetails(
                      selectedDay: selectedDay,
                      injections: _getInjections(injections, selectedDay),
                      isDark: isDark,
                    )
                  : Center(
                      child: Text(
                        'Seleziona un giorno',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<InjectionRecord> _getInjections(List<InjectionRecord> all, DateTime day) {
    return all.where((inj) => isSameDay(inj.scheduledAt, day)).toList();
  }

  Widget _buildMarkers(List<InjectionRecord> events, bool isDark) {
    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: events.take(3).map((event) {
          final color = switch (event.status) {
            InjectionStatus.completed => isDark ? AppColors.darkPine : AppColors.dawnPine,
            InjectionStatus.scheduled => isDark ? AppColors.darkFoam : AppColors.dawnFoam,
            InjectionStatus.delayed => isDark ? AppColors.darkGold : AppColors.dawnGold,
            InjectionStatus.skipped => isDark ? AppColors.darkLove : AppColors.dawnLove,
          };
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _DayDetails extends StatelessWidget {
  const _DayDetails({
    required this.selectedDay,
    required this.injections,
    required this.isDark,
  });

  final DateTime selectedDay;
  final List<InjectionRecord> injections;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMMM', 'it_IT');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(selectedDay),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (injections.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nessuna iniezione programmata',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: injections.length,
                itemBuilder: (context, index) {
                  final injection = injections[index];
                  return _InjectionCard(
                    injection: injection,
                    isDark: isDark,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InjectionCard extends StatelessWidget {
  const _InjectionCard({
    required this.injection,
    required this.isDark,
  });

  final InjectionRecord injection;
  final bool isDark;

  Color get _statusColor => switch (injection.status) {
    InjectionStatus.completed => isDark ? AppColors.darkPine : AppColors.dawnPine,
    InjectionStatus.scheduled => isDark ? AppColors.darkFoam : AppColors.dawnFoam,
    InjectionStatus.delayed => isDark ? AppColors.darkGold : AppColors.dawnGold,
    InjectionStatus.skipped => isDark ? AppColors.darkLove : AppColors.dawnLove,
  };

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'it_IT');

    return Card(
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
        ),
        title: Text(timeFormat.format(injection.scheduledAt)),
        subtitle: Text(injection.pointLabel),
        trailing: injection.status == InjectionStatus.scheduled
            ? TextButton(
                onPressed: () => context.push(
                  AppRoutes.recordInjection,
                  extra: {
                    'zoneId': injection.zoneId,
                    'pointNumber': injection.pointNumber,
                  },
                ),
                child: const Text('Vai'),
              )
            : null,
      ),
    );
  }
}
