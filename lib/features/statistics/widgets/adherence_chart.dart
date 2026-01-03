import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../statistics_provider.dart';

/// Grafico a barre per l'aderenza mensile/settimanale
class AdherenceChart extends StatelessWidget {
  const AdherenceChart({
    super.key,
    required this.monthlyData,
    this.showMonthly = true,
  });

  final List<MonthlyData> monthlyData;
  final bool showMonthly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPine : AppColors.dawnPine;
    final secondaryColor = isDark ? AppColors.darkFoam : AppColors.dawnFoam;

    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato disponibile',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => isDark
                ? AppColors.darkSurface
                : AppColors.dawnSurface,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = monthlyData[group.x.toInt()];
              return BarTooltipItem(
                '${DateFormat('MMM yyyy', 'it').format(data.month)}\n',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${data.adherenceRate.toStringAsFixed(0)}% aderenza\n',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: '${data.injections}/${data.expected} iniezioni',
                    style: TextStyle(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyData.length) {
                  return const SizedBox();
                }
                final data = monthlyData[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM', 'it').format(data.month),
                    style: TextStyle(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 35,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: monthlyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.adherenceRate,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    secondaryColor.withValues(alpha: 0.7),
                    primaryColor,
                  ],
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Grafico a linea per il trend di aderenza
class AdherenceTrendChart extends StatelessWidget {
  const AdherenceTrendChart({
    super.key,
    required this.weeklyData,
  });

  final List<WeeklyData> weeklyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPine : AppColors.dawnPine;

    if (weeklyData.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato disponibile',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark
                ? AppColors.darkSurface
                : AppColors.dawnSurface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final data = weeklyData[spot.x.toInt()];
                return LineTooltipItem(
                  'Sett. ${DateFormat('d/M', 'it').format(data.weekStart)}\n',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${data.adherenceRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (weeklyData.length / 4).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= weeklyData.length) {
                  return const SizedBox();
                }
                final data = weeklyData[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d/M', 'it').format(data.weekStart),
                    style: TextStyle(
                      color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 35,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: weeklyData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.adherenceRate);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.5),
                primaryColor,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
