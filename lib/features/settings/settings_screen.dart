import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/services/backup_provider.dart';
import '../../core/services/startup_service.dart';
import '../../core/database/app_database.dart' hide TherapyPlan;
import '../../core/database/database_provider.dart';
import '../../app/router.dart';
import '../../models/therapy_plan.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_repository.dart' show LocalUser;
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
    final backupState = ref.watch(backupNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          // User info
          _UserInfoSection(
            user: user,
            isDark: isDark,
            onLinkGoogle: () => _linkGoogleAccount(context),
            onUnlinkGoogle: () => _unlinkGoogleAccount(context),
            onSignOut: () => _signOut(context),
          ),

          const Divider(),

          _SectionHeader(title: 'PIANO TERAPEUTICO'),
          therapyPlanAsync.when(
            loading: () => const ListTile(title: Text('Caricamento...')),
            error: (_, __) =>
                const ListTile(title: Text('Errore nel caricamento')),
            data: (plan) {
              final therapyPlan = plan ?? TherapyPlan.defaults;
              return Column(
                children: [
                  _SettingsTile(
                    title: 'Iniezioni settimanali',
                    trailing: Text('${therapyPlan.injectionsPerWeek}'),
                    onTap: () => _editInjectionsPerWeek(context, therapyPlan),
                  ),
                  _SettingsTile(
                    title: 'Giorni',
                    trailing: Text(therapyPlan.weekDaysString),
                    onTap: () => _editWeekDays(context, therapyPlan),
                  ),
                  _SettingsTile(
                    title: 'Orario preferito',
                    trailing: Text(therapyPlan.preferredTime),
                    onTap: () => _editPreferredTime(context, therapyPlan),
                  ),
                ],
              );
            },
          ),

          _SectionHeader(title: 'ZONE E PUNTI'),
          _SettingsTile(title: 'Configura zone', onTap: () {}),
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

          // BACKUP SECTION
          _SectionHeader(title: 'BACKUP E RIPRISTINO'),
          _BackupSection(
            backupState: backupState,
            isDark: isDark,
            onBackup: () async {
              // Mostra dialog per inserire password
              final password = await showDialog<String>(
                context: context,
                builder: (context) => const BackupPasswordDialog(
                  title: 'Password backup',
                  confirmButtonText: 'Crea backup',
                  isRestore: false,
                ),
              );

              if (password == null || !mounted) return;

              final notifier = ref.read(backupNotifierProvider.notifier);
              final result = await notifier.backup(password);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Backup completato'
                          : result.error ?? 'Errore',
                    ),
                    backgroundColor: result.success
                        ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
                        : (isDark ? AppColors.darkLove : AppColors.dawnLove),
                  ),
                );
              }
            },
            onRestore: () async {
              // Mostra dialog per inserire password
              final password = await showDialog<String>(
                context: context,
                builder: (context) => const BackupPasswordDialog(
                  title: 'Password ripristino',
                  confirmButtonText: 'Ripristina',
                  isRestore: true,
                ),
              );

              if (password == null || !mounted) return;

              final notifier = ref.read(backupNotifierProvider.notifier);
              final result = await notifier.restore(password);
              if (mounted) {
                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Ripristino completato. Riavvia l\'app.',
                      ),
                      backgroundColor: isDark
                          ? AppColors.darkPine
                          : AppColors.dawnPine,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.error ?? 'Errore'),
                      backgroundColor: isDark
                          ? AppColors.darkLove
                          : AppColors.dawnLove,
                    ),
                  );
                }
              }
            },
            onSignIn: () async {
              final notifier = ref.read(backupNotifierProvider.notifier);
              final success = await notifier.signIn();
              if (success) {
                await notifier.checkBackup();
              }
            },
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
              final db = ref.read(databaseProvider);
              await repository.setBiometricEnabled(db, value);
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
                            await ExportService.instance.exportToPdf(
                              _convertInjections(injections),
                            );
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
                            await ExportService.instance.exportToCsv(
                              _convertInjections(injections),
                            );
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
          Center(
            child: Text(
              'Privacy-first · Offline-first',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Convert Drift Injection to model for export
  List<dynamic> _convertInjections(List<Injection> injections) {
    // ExportService needs to be updated to work with Drift types
    // For now, pass the raw list
    return injections;
  }

  String get _themeModeLabel => switch (_themeMode) {
    'light' => 'Chiaro (Dawn)',
    'dark' => 'Scuro (Rosé Pine)',
    _ => 'Automatico (sistema)',
  };

  Future<void> _signOut(BuildContext context) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _linkGoogleAccount(BuildContext context) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.linkGoogleAccount();
    if (mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Account Google collegato con successo'
                : 'Collegamento annullato',
          ),
          backgroundColor: success
              ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
              : (isDark ? AppColors.darkLove : AppColors.dawnLove),
        ),
      );
    }
  }

  Future<void> _unlinkGoogleAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scollega account Google'),
        content: const Text(
          'Scollegando l\'account non potrai più eseguire backup su Google Drive. '
          'I tuoi dati locali non verranno eliminati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Scollega'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.unlinkGoogleAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Google scollegato')),
        );
      }
    }
  }

  void _editInjectionsPerWeek(BuildContext context, TherapyPlan plan) {
    showDialog<void>(
      context: context,
      builder: (context) {
        int value = plan.injectionsPerWeek;
        return AlertDialog(
          title: const Text('Iniezioni settimanali'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3, 4, 5]
                  .map(
                    (n) => RadioListTile<int>(
                      title: Text('$n'),
                      value: n,
                      groupValue: value,
                      onChanged: (v) => setState(() => value = v!),
                    ),
                  )
                  .toList(),
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
                await _updateTherapyPlan(
                  plan.copyWith(injectionsPerWeek: value),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editWeekDays(BuildContext context, TherapyPlan plan) {
    showDialog<void>(
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

    final time = await showTimePicker(context: context, initialTime: initial);

    if (time != null) {
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await _updateTherapyPlan(plan.copyWith(preferredTime: timeStr));
    }
  }

  Future<void> _updateTherapyPlan(TherapyPlan plan) async {
    final repository = ref.read(injectionRepositoryProvider);
    await repository.saveTherapyPlan(plan);
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('Chiaro (Dawn)'),
            value: 'light',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('Scuro (Rosé Pine)'),
            value: 'dark',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
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

  void _showBlacklistedPoints(
    BuildContext context,
    List<BlacklistedPoint> blacklist,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
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
                            color: isDark
                                ? AppColors.darkPine
                                : AppColors.dawnPine,
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
                    ...blacklist.map(
                      (bp) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.dawnMuted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bp.pointLabel),
                                    Text(
                                      'Motivo: ${bp.reason}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final repository = ref.read(
                                    injectionRepositoryProvider,
                                  );
                                  await repository.unblacklistPoint(
                                    bp.pointCode,
                                  );
                                },
                                child: const Text('Riabilita'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
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
            onPressed: () async {
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              await db.deleteAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Dati eliminati'),
                    backgroundColor: isDark
                        ? AppColors.darkPine
                        : AppColors.dawnPine,
                  ),
                );
              }
            },
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

/// Backup section widget
class _BackupSection extends StatelessWidget {
  const _BackupSection({
    required this.backupState,
    required this.isDark,
    required this.onBackup,
    required this.onRestore,
    required this.onSignIn,
  });

  final BackupState backupState;
  final bool isDark;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (backupState.isLoading) {
      return const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Operazione in corso...'),
      );
    }

    return Column(
      children: [
        // Backup info card
        if (backupState.backupInfo != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ultimo backup'),
                          Text(
                            _formatDate(backupState.backupInfo!.modifiedTime),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        _SettingsTile(
          icon: Icons.cloud_upload_outlined,
          title: 'Backup su Google Drive',
          onTap: onBackup,
        ),
        _SettingsTile(
          icon: Icons.cloud_download_outlined,
          title: 'Ripristina da backup',
          onTap: backupState.backupInfo != null ? onRestore : () {},
        ),

        // Info text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'I tuoi dati sono cifrati prima del backup. Solo tu puoi decifrarli.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
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
      leading: icon != null ? Icon(icon, color: iconColor) : null,
      title: Text(
        title,
        style: titleColor != null ? TextStyle(color: titleColor) : null,
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

/// Widget per mostrare le informazioni utente
/// Gestisce sia la modalità offline che con account Google
class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection({
    required this.user,
    required this.isDark,
    required this.onLinkGoogle,
    required this.onUnlinkGoogle,
    required this.onSignOut,
  });

  final LocalUser? user;
  final bool isDark;
  final VoidCallback onLinkGoogle;
  final VoidCallback onUnlinkGoogle;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Utente con account Google collegato
    if (user != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user!.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user!.photoUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user!.displayName ?? 'Utente',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(user!.email ?? '', style: theme.textTheme.bodySmall),
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_done,
                        size: 14,
                        color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Backup abilitato',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkPine
                              : AppColors.dawnPine,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'unlink') {
                  onUnlinkGoogle();
                } else if (value == 'signout') {
                  onSignOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unlink',
                  child: Row(
                    children: [
                      Icon(Icons.link_off),
                      SizedBox(width: 8),
                      Text('Scollega Google'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Esci e cancella dati'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Utente in modalità offline (senza account Google)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? AppColors.darkOverlay
                    : AppColors.dawnOverlay,
                child: Icon(
                  Icons.person_outline,
                  size: 30,
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modalità offline',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'I tuoi dati sono salvati solo su questo dispositivo',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLinkGoogle,
              icon: const Icon(Icons.cloud_outlined),
              label: const Text('Collega account Google per backup'),
            ),
          ),
        ],
      ),
    );
  }
}
