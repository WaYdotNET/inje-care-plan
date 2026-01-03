import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../models/body_zone.dart';

/// Rappresenta un evento settimanale (confermato o suggerito)
class WeeklyEvent {
  final DateTime date;
  final db.Injection? confirmedEvent;
  final ({int zoneId, int pointNumber})? suggestion;
  final BodyZone? zone;

  const WeeklyEvent({
    required this.date,
    this.confirmedEvent,
    this.suggestion,
    this.zone,
  });

  bool get isSuggested => confirmedEvent == null && suggestion != null;
  bool get isConfirmed => confirmedEvent != null;
  bool get isPast => date.isBefore(DateTime.now().subtract(const Duration(hours: 1)));

  String get status {
    if (confirmedEvent != null) return confirmedEvent!.status;
    if (isPast) return 'missed';
    return 'suggested';
  }
}

/// Widget per un singolo evento settimanale
class WeeklyEventItem extends StatelessWidget {
  const WeeklyEventItem({
    super.key,
    required this.event,
    required this.onTap,
    required this.isDark,
  });

  final WeeklyEvent event;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE d', 'it_IT');
    final timeFormat = DateFormat('HH:mm', 'it_IT');

    // Colori e icone basati sullo stato
    final (Color statusColor, IconData statusIcon, String statusLabel) = switch (event.status) {
      'completed' => (
        isDark ? AppColors.darkPine : AppColors.dawnPine,
        Icons.check_circle,
        'Completata'
      ),
      'skipped' => (
        isDark ? AppColors.darkLove : AppColors.dawnLove,
        Icons.cancel,
        'Saltata'
      ),
      'missed' => (
        isDark ? AppColors.darkLove : AppColors.dawnLove,
        Icons.warning_amber,
        'Mancata'
      ),
      'pending' => (
        isDark ? AppColors.darkGold : AppColors.dawnGold,
        Icons.schedule,
        'Programmata'
      ),
      'suggested' => (
        isDark ? AppColors.darkFoam : AppColors.dawnFoam,
        Icons.lightbulb_outline,
        'Suggerita'
      ),
      _ => (
        isDark ? AppColors.darkMuted : AppColors.dawnMuted,
        Icons.help_outline,
        'Sconosciuto'
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: event.isPast && event.isSuggested
          ? (isDark ? AppColors.darkMuted : AppColors.dawnMuted).withValues(alpha: 0.2)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Data
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _getDateBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateFormat.format(event.date).split(' ')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getDateTextColor(),
                      ),
                    ),
                    Text(
                      '${event.date.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getDateTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Dettagli evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (event.zone != null)
                          Text(event.zone!.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getEventTitle(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              decoration: event.status == 'skipped'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        // Badge AI per suggerimenti
                        if (event.isSuggested) _buildAiBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                        if (event.confirmedEvent != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${timeFormat.format(event.confirmedEvent!.scheduledAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Freccia
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

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 10,
            color: Colors.white,
          ),
          SizedBox(width: 2),
          Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDateBackgroundColor() {
    if (_isToday()) {
      return isDark ? AppColors.darkPine : AppColors.dawnPine;
    }
    if (event.isPast) {
      return (isDark ? AppColors.darkMuted : AppColors.dawnMuted).withValues(alpha: 0.3);
    }
    return isDark ? AppColors.darkSurface : AppColors.dawnSurface;
  }

  Color _getDateTextColor() {
    if (_isToday()) {
      return isDark ? AppColors.darkBase : AppColors.dawnBase;
    }
    if (event.isPast) {
      return isDark ? AppColors.darkMuted : AppColors.dawnMuted;
    }
    return isDark ? AppColors.darkText : AppColors.dawnText;
  }

  bool _isToday() {
    final now = DateTime.now();
    return event.date.year == now.year &&
        event.date.month == now.month &&
        event.date.day == now.day;
  }

  String _getEventTitle() {
    if (event.confirmedEvent != null) {
      return event.confirmedEvent!.pointLabel;
    }
    if (event.zone != null && event.suggestion != null) {
      return event.zone!.pointLabel(event.suggestion!.pointNumber);
    }
    return 'Iniezione suggerita';
  }
}

/// Card per la lista eventi settimanali
class WeeklyEventsCard extends StatelessWidget {
  const WeeklyEventsCard({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onViewProposals,
    required this.isDark,
  });

  final List<WeeklyEvent> events;
  final void Function(WeeklyEvent event) onEventTap;
  final VoidCallback onViewProposals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestedCount = events.where((e) => e.isSuggested && !e.isPast).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'QUESTA SETTIMANA',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (suggestedCount > 0)
                  TextButton.icon(
                    onPressed: onViewProposals,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text('$suggestedCount proposte'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nessun evento questa settimana',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...events.map((event) => WeeklyEventItem(
                event: event,
                onTap: () => onEventTap(event),
                isDark: isDark,
              )),
          ],
        ),
      ),
    );
  }
}
