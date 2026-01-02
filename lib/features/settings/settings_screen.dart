import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../app/router.dart';
import '../../models/therapy_plan.dart';
import '../../models/blacklisted_point.dart';
import '../auth/auth_provider.dart';
import '../injection/injection_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _missedDoseReminder = true;
  bool _googleCalendarSync = false;
  bool _biometricEnabled = false;
  String _themeMode = 'system';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final blacklistAsync = ref.watch(blacklistedPointsProvider);
    final injectionsAsync = ref.watch(injectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          // User info
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'Utente',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          user.email ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _signOut(context),
                    child: const Text('Esci'),
                  ),
                ],
              ),
            ),

          const Divider(),

          _SectionHeader(title: 'PIANO TERAPEUTICO'),
          therapyPlanAsync.when(
            loading: () => const ListTile(
              title: Text('Caricamento...'),
            ),
            error: (_, __) => const ListTile(
              title: Text('Errore nel caricamento'),
            ),
            data: (plan) => Column(
              children: [
                _SettingsTile(
                  title: 'Iniezioni settimanali',
                  trailing: Text('${plan.injectionsPerWeek}'),
                  onTap: () => _editInjectionsPerWeek(context, plan),
                ),
                _SettingsTile(
                  title: 'Giorni',
                  trailing: Text(plan.weekDaysString),
                  onTap: () => _editWeekDays(context, plan),
                ),
                _SettingsTile(
                  title: 'Orario preferito',
                  trailing: Text(plan.preferredTime),
                  onTap: () => _editPreferredTime(context, plan),
                ),
              ],
            ),
          ),

          _SectionHeader(title: 'ZONE E PUNTI'),
          _SettingsTile(
            title: 'Configura zone',
            onTap: () {},
          ),
          blacklistAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (blacklist) => _SettingsTile(
              icon: Icons.block,
              iconColor: isDark ? AppColors.darkLove : AppColors.dawnLove,
              title: 'Punti esclusi',
              trailing: Text('${blacklist.length}'),
              onTap: () => _showBlacklistedPoints(context, blacklist),
            ),
          ),

          _SectionHeader(title: 'NOTIFICHE'),
          SwitchListTile(
            title: const Text('Promemoria iniezione'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          _SettingsTile(
            title: 'Anticipo',
            trailing: const Text('30 min'),
            onTap: () {},
          ),
          SwitchListTile(
            title: const Text('Reminder dose saltata'),
            value: _missedDoseReminder,
            onChanged: (value) => setState(() => _missedDoseReminder = value),
          ),

          _SectionHeader(title: 'SINCRONIZZAZIONE'),
          SwitchListTile(
            title: const Text('Google Calendar'),
            value: _googleCalendarSync,
            onChanged: (value) => setState(() => _googleCalendarSync = value),
          ),

          _SectionHeader(title: 'ASPETTO'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_themeModeLabel),
            onTap: () => _showThemeSelector(context),
          ),

          _SectionHeader(title: 'SICUREZZA'),
          SwitchListTile(
            title: const Text('Sblocco biometrico'),
            value: _biometricEnabled,
            onChanged: (value) async {
              final repository = ref.read(authRepositoryProvider);
              await repository.setBiometricEnabled(value);
              setState(() => _biometricEnabled = value);
            },
          ),

          _SectionHeader(title: 'DATI'),
          injectionsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (injections) => Column(
              children: [
                _SettingsTile(
                  title: 'Esporta storico (PDF)',
                  onTap: injections.isNotEmpty
                      ? () async {
                          try {
                            await ExportService.instance.exportToPdf(injections);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Errore: $e')),
                              );
                            }
                          }
                        }
                      : () {},
                ),
                _SettingsTile(
                  title: 'Esporta storico (CSV)',
                  onTap: injections.isNotEmpty
                      ? () async {
                          try {
                            await ExportService.instance.exportToCsv(injections);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Errore: $e')),
                              );
                            }
                          }
                        }
                      : () {},
                ),
              ],
            ),
          ),
          _SettingsTile(
            title: 'Elimina tutti i dati',
            titleColor: isDark ? AppColors.darkLove : AppColors.dawnLove,
            onTap: () => _showDeleteConfirmation(context),
          ),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'InjeCare Plan v1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String get _themeModeLabel => switch (_themeMode) {
    'light' => 'Chiaro (Dawn)',
    'dark' => 'Scuro (Rosé Pine)',
    _ => 'Automatico (sistema)',
  };

  Future<void> _signOut(BuildContext context) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _editInjectionsPerWeek(BuildContext context, TherapyPlan plan) {
    showDialog(
      context: context,
      builder: (context) {
        int value = plan.injectionsPerWeek;
        return AlertDialog(
          title: const Text('Iniezioni settimanali'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3, 4, 5].map((n) => RadioListTile(
                title: Text('$n'),
                value: n,
                groupValue: value,
                onChanged: (v) => setState(() => value = v!),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateTherapyPlan(plan.copyWith(injectionsPerWeek: value));
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editWeekDays(BuildContext context, TherapyPlan plan) {
    showDialog(
      context: context,
      builder: (context) {
        final selected = Set<int>.from(plan.weekDays);
        final days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

        return AlertDialog(
          title: const Text('Giorni della settimana'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (i) {
                final dayNum = i + 1;
                return CheckboxListTile(
                  title: Text(days[i]),
                  value: selected.contains(dayNum),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selected.add(dayNum);
                      } else {
                        selected.remove(dayNum);
                      }
                    });
                  },
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final sortedDays = selected.toList()..sort();
                await _updateTherapyPlan(plan.copyWith(weekDays: sortedDays));
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editPreferredTime(BuildContext context, TherapyPlan plan) async {
    final parts = plan.preferredTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await _updateTherapyPlan(plan.copyWith(preferredTime: timeStr));
    }
  }

  Future<void> _updateTherapyPlan(TherapyPlan plan) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repository = ref.read(injectionRepositoryProvider);
    await repository.updateTherapyPlan(user.uid, plan);
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: const Text('Chiaro (Dawn)'),
            value: 'light',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile(
            title: const Text('Scuro (Rosé Pine)'),
            value: 'dark',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile(
            title: const Text('Automatico (sistema)'),
            value: 'system',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showBlacklistedPoints(BuildContext context, List<BlacklistedPoint> blacklist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Punti esclusi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (blacklist.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun punto escluso',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      '${blacklist.length} punti attualmente esclusi dalla rotazione automatica',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...blacklist.map((bp) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.block,
                              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bp.pointLabel),
                                  Text(
                                    'Motivo: ${bp.reasonLabel}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final user = ref.read(currentUserProvider);
                                if (user == null || bp.id == null) return;
                                final repository = ref.read(injectionRepositoryProvider);
                                await repository.unblacklistPoint(user.uid, bp.id!);
                              },
                              child: const Text('Riabilita'),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nota: i punti esclusi non vengono suggeriti nella rotazione automatica ma restano selezionabili manualmente.',
                      style: Theme.of(context).textTheme.bodySmall,
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina tutti i dati'),
        content: const Text(
          'Sei sicuro di voler eliminare tutti i dati? Questa azione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Elimina'),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: iconColor)
          : null,
      title: Text(
        title,
        style: titleColor != null
            ? TextStyle(color: titleColor)
            : null,
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                trailing!,
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
