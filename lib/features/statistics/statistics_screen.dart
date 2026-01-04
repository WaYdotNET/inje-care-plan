import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'statistics_provider.dart';
import 'widgets/adherence_chart.dart';
import 'widgets/zone_heatmap.dart';

/// Schermata delle statistiche avanzate
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(injectionStatsProvider);
    final selectedPeriod = ref.watch(statsPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
        actions: [
          // Filtro periodo
          PopupMenuButton<StatsPeriod>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Periodo',
            onSelected: (period) {
              ref.read(statsPeriodProvider.notifier).setPeriod(period);
            },
            itemBuilder: (context) => [
              _buildPeriodItem(StatsPeriod.week, 'Ultima settimana', selectedPeriod),
              _buildPeriodItem(StatsPeriod.month, 'Ultimo mese', selectedPeriod),
              _buildPeriodItem(StatsPeriod.quarter, 'Ultimi 3 mesi', selectedPeriod),
              _buildPeriodItem(StatsPeriod.year, 'Ultimo anno', selectedPeriod),
              _buildPeriodItem(StatsPeriod.all, 'Tutto', selectedPeriod),
            ],
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (stats) => _buildContent(context, theme, isDark, stats, selectedPeriod),
      ),
    );
  }

  PopupMenuItem<StatsPeriod> _buildPeriodItem(
    StatsPeriod period,
    String label,
    StatsPeriod selected,
  ) {
    return PopupMenuItem(
      value: period,
      child: Row(
        children: [
          if (period == selected)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    InjectionStats stats,
    StatsPeriod period,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con statistiche principali
          _StatsOverview(stats: stats, isDark: isDark),

          const SizedBox(height: 24),

          // Streak
          _StreakCard(stats: stats, isDark: isDark),

          const SizedBox(height: 24),

          // Grafico aderenza mensile
          const _SectionTitle(title: 'Aderenza Mensile', icon: Icons.bar_chart),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: AdherenceChart(monthlyData: stats.monthlyTrend),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Trend settimanale
          const _SectionTitle(title: 'Trend Settimanale', icon: Icons.show_chart),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: AdherenceTrendChart(weeklyData: stats.weeklyTrend),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Heatmap zone
          const _SectionTitle(title: 'Utilizzo Zone', icon: Icons.pie_chart),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ZoneHeatmap(zoneUsage: stats.zoneUsage),
            ),
          ),

          const SizedBox(height: 24),

          // Dettaglio zone
          const _SectionTitle(title: 'Dettaglio Zone', icon: Icons.location_on),
          const SizedBox(height: 12),
          ...stats.zoneUsage.take(5).map((zone) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ZoneStatsCard(zone: zone),
          )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Overview delle statistiche principali
class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.stats,
    required this.isDark,
  });

  final InjectionStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Aderenza grande
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularProgress(stats.adherenceRate, isDark),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.adherenceRate.toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getAdherenceColor(stats.adherenceRate, isDark),
                      ),
                    ),
                    Text(
                      'Aderenza',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: '${stats.completedCount}',
                  label: 'Completate',
                  color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                  icon: Icons.check_circle,
                ),
                _StatItem(
                  value: '${stats.skippedCount}',
                  label: 'Saltate',
                  color: isDark ? AppColors.darkLove : AppColors.dawnLove,
                  icon: Icons.cancel,
                ),
                _StatItem(
                  value: '${stats.scheduledCount}',
                  label: 'Programmate',
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                  icon: Icons.schedule,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double percentage, bool isDark) {
    final color = _getAdherenceColor(percentage, isDark);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 8,
            color: color.withValues(alpha: 0.2),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 8,
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ],
      ),
    );
  }

  Color _getAdherenceColor(double percentage, bool isDark) {
    if (percentage >= 80) {
      return isDark ? AppColors.darkPine : AppColors.dawnPine;
    } else if (percentage >= 60) {
      return isDark ? AppColors.darkGold : AppColors.dawnGold;
    } else {
      return isDark ? AppColors.darkLove : AppColors.dawnLove;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Card per lo streak
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.stats,
    required this.isDark,
  });

  final InjectionStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isDark ? AppColors.darkGold.withValues(alpha: 0.2) : AppColors.dawnGold.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak attuale: ${stats.currentStreak}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Record: ${stats.longestStreak} iniezioni consecutive',
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
    );
  }
}

/// Titolo sezione
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
