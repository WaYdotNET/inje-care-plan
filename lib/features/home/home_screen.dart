import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../app/router.dart';
import '../../models/body_zone.dart';
import '../auth/auth_provider.dart';
import '../injection/injection_provider.dart';
import '../injection/zone_provider.dart';
import '../../core/services/missed_injection_service.dart';
import 'widgets/weekly_event_item.dart';

/// Home dashboard screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final adherenceAsync = ref.watch(adherenceStatsProvider);
    final weeklyEventsAsync = ref.watch(weeklyEventsProvider);
    final zonesAsync = ref.watch(zonesProvider);

    // Controlla iniezioni mancate all'avvio (eseguito una volta)
    ref.watch(checkMissedInjectionsProvider);

    final displayName = user?.displayName?.split(' ').first ?? 'Utente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('InjeCare Plan'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.dawnSurface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ciao, $displayName',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendario'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.calendar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nuova iniezione'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.bodyMap);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Storico'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.history);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Impostazioni'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Guida'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.help);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Informazioni'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.info);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adherenceStatsProvider);
          ref.invalidate(weeklyEventsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Ciao, $displayName',
                style: theme.textTheme.headlineMedium,
              ),

              const SizedBox(height: 24),

              // Weekly events card
              _buildWeeklyEventsCard(
                context,
                weeklyEventsAsync,
                zonesAsync,
                isDark,
              ),

              const SizedBox(height: 16),

              // Adherence stats
              adherenceAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const _ErrorCard(),
                data: (stats) => _AdherenceCard(
                  completed: stats.completed,
                  total: stats.total,
                  percentage: stats.percentage,
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.calendar_month,
                      label: 'Calendario',
                      onTap: () => context.go(AppRoutes.calendar),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history,
                      label: 'Storico',
                      onTap: () => context.go(AppRoutes.history),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyEventsCard(
    BuildContext context,
    AsyncValue<List<WeeklyEventData>> weeklyEventsAsync,
    AsyncValue<List<BodyZone>> zonesAsync,
    bool isDark,
  ) {
    return weeklyEventsAsync.when(
      loading: () => const _LoadingCard(),
      error: (_, __) => const _ErrorCard(),
      data: (weeklyEventData) {
        return zonesAsync.when(
          loading: () => const _LoadingCard(),
          error: (_, __) => const _ErrorCard(),
          data: (zones) {
            // Converti WeeklyEventData in WeeklyEvent con zone
            final events = weeklyEventData.map((data) {
              final zone = data.suggestion != null
                  ? zones.where((z) => z.id == data.suggestion!.zoneId).firstOrNull
                  : (data.confirmedEvent != null
                      ? zones.where((z) => z.id == data.confirmedEvent!.zoneId).firstOrNull
                      : null);
              return WeeklyEvent(
                date: data.date,
                confirmedEvent: data.confirmedEvent,
                suggestion: data.suggestion,
                zone: zone,
              );
            }).toList();

            return WeeklyEventsCard(
              events: events,
              onEventTap: (event) => _handleEventTap(context, event),
              onViewProposals: () => context.push('/weekly-proposals'),
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  void _handleEventTap(BuildContext context, WeeklyEvent event) {
    if (event.isConfirmed) {
      // Apri modifica evento
      context.push(AppRoutes.calendar);
    } else if (event.isSuggested) {
      // Naviga alla selezione punto con data preselezionata
      context.push(
        AppRoutes.bodyMap,
        extra: {
          'scheduledDate': event.date,
          if (event.suggestion != null) 'zoneId': event.suggestion!.zoneId,
        },
      );
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Impossibile caricare i dati',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({
    required this.completed,
    required this.total,
    required this.percentage,
    required this.isDark,
  });

  final int completed;
  final int total;
  final double percentage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aderenza ultimi 30 giorni',
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.darkHighlightMed
                    : AppColors.dawnHighlightMed,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? AppColors.darkPine : AppColors.dawnPine,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  total > 0 ? '$completed/$total iniezioni' : 'Nessuna iniezione',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isDark ? AppColors.darkPine : AppColors.dawnPine,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
