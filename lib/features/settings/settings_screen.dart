import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/services/backup_provider.dart';
import '../../core/services/startup_service.dart';
import '../../core/services/notification_settings_provider.dart';
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
  bool _googleCalendarSync = false;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final blacklistAsync = ref.watch(blacklistedPointsProvider);
    final injectionsAsync = ref.watch(injectionsProvider);
    final backupState = ref.watch(backupNotifierProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

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

          const _SectionHeader(title: 'PIANO TERAPEUTICO'),
          therapyPlanAsync.when(
            loading: () => const ListTile(title: Text('Caricamento...')),
            error: (e, st) =>
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

          const _SectionHeader(title: 'ZONE E PUNTI'),
          _SettingsTile(
            icon: Icons.edit_location_alt,
            title: 'Gestisci zone',
            onTap: () => context.push(AppRoutes.zoneManagement),
          ),
          blacklistAsync.when(
            loading: () => const SizedBox(),
            error: (e, st) => const SizedBox(),
            data: (blacklist) => _SettingsTile(
              icon: Icons.block,
              iconColor: isDark ? AppColors.darkLove : AppColors.dawnLove,
              title: 'Punti esclusi',
              trailing: Text('${blacklist.length}'),
              onTap: () => context.push(AppRoutes.blacklist),
            ),
          ),

          const _SectionHeader(title: 'NOTIFICHE'),
          if (!notificationSettings.permissionsGranted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_off,
                        color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notifiche non abilitate'),
                            Text(
                              'Abilita per ricevere promemoria',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final notifier = ref.read(notificationSettingsProvider.notifier);
                          final granted = await notifier.requestPermissions();
                          if (mounted && !granted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Permessi non concessi. Abilitali dalle impostazioni del dispositivo.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Abilita'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Promemoria iniezione'),
            value: notificationSettings.enabled,
            onChanged: notificationSettings.permissionsGranted
                ? (value) => ref.read(notificationSettingsProvider.notifier).setEnabled(value)
                : null,
          ),
          _SettingsTile(
            title: 'Anticipo',
            trailing: Text('${notificationSettings.minutesBefore} min'),
            onTap: () => _editNotificationMinutes(context, notificationSettings.minutesBefore),
          ),
          SwitchListTile(
            title: const Text('Reminder dose saltata'),
            value: notificationSettings.missedDoseReminder,
            onChanged: notificationSettings.permissionsGranted
                ? (value) => ref.read(notificationSettingsProvider.notifier).setMissedDoseReminder(value)
                : null,
          ),

          const _SectionHeader(title: 'SINCRONIZZAZIONE'),
          SwitchListTile(
            title: const Text('Google Calendar'),
            value: _googleCalendarSync,
            onChanged: (value) => setState(() => _googleCalendarSync = value),
          ),

          // BACKUP SECTION
          const _SectionHeader(title: 'BACKUP E RIPRISTINO'),
          _BackupSection(
            backupState: backupState,
            isDark: isDark,
            onBackup: () async {
              final messenger = ScaffoldMessenger.of(context);
              // Mostra dialog per inserire password
              final password = await showDialog<String>(
                context: context,
                builder: (ctx) => const BackupPasswordDialog(
                  title: 'Password backup',
                  confirmButtonText: 'Crea backup',
                  isRestore: false,
                ),
              );

              if (password == null || !mounted) return;

              final notifier = ref.read(backupNotifierProvider.notifier);
              final result = await notifier.backup(password);
              if (mounted) {
                messenger.showSnackBar(
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
              final messenger = ScaffoldMessenger.of(context);
              // Mostra dialog per inserire password
              final password = await showDialog<String>(
                context: context,
                builder: (ctx) => const BackupPasswordDialog(
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
                  messenger.showSnackBar(
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
                  messenger.showSnackBar(
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

          const _SectionHeader(title: 'ASPETTO'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_themeModeLabel),
            onTap: () => _showThemeSelector(context),
          ),

          const _SectionHeader(title: 'SICUREZZA'),
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

          const _SectionHeader(title: 'DATI'),
          injectionsAsync.when(
            loading: () => const SizedBox(),
            error: (e, st) => const SizedBox(),
            data: (injections) => Column(
              children: [
                _SettingsTile(
                  title: 'Esporta storico (PDF)',
                  onTap: injections.isNotEmpty
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ExportService.instance.exportToPdf(
                              _convertInjections(injections),
                            );
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
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
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ExportService.instance.exportToCsv(
                              _convertInjections(injections),
                            );
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
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

          const _SectionHeader(title: 'AIUTO'),
          _SettingsTile(
            title: 'Guida all\'uso',
            icon: Icons.help_outline,
            onTap: () => context.push(AppRoutes.help),
          ),
          _SettingsTile(
            title: 'Informazioni sull\'app',
            icon: Icons.info_outline,
            onTap: () => context.push(AppRoutes.info),
          ),
          _SettingsTile(
            title: 'Rivedi introduzione',
            icon: Icons.replay,
            onTap: () => _showOnboardingConfirmation(context),
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

  String get _themeModeLabel {
    final mode = ref.watch(themeModeProvider);
    return switch (mode) {
      ThemeMode.light => 'Chiaro (Dawn)',
      ThemeMode.dark => 'Scuro (Rosé Pine)',
      ThemeMode.system => 'Automatico (sistema)',
    };
  }

  Future<void> _signOut(BuildContext context) async {
    final router = GoRouter.of(context);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.signOut();
    if (mounted) {
      router.go(AppRoutes.login);
    }
  }

  Future<void> _linkGoogleAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.linkGoogleAccount();
    if (mounted) {
      messenger.showSnackBar(
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
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scollega account Google'),
        content: const Text(
          'Scollegando l\'account non potrai più eseguire backup su Google Drive. '
          'I tuoi dati locali non verranno eliminati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Scollega'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.unlinkGoogleAccount();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Account Google scollegato')),
        );
      }
    }
  }

  Future<void> _showOnboardingConfirmation(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rivedi introduzione'),
        content: const Text(
          'Vuoi rivedere la schermata di introduzione? '
          'Verrai riportato alla schermata iniziale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rivedi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.resetOnboarding();
      if (mounted) {
        // Forza la navigazione con sostituzione completa dello stack
        while (router.canPop()) {
          router.pop();
        }
        router.go(AppRoutes.login);
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
            builder: (context, setState) => RadioGroup<int>(
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [1, 2, 3, 4, 5]
                    .map(
                      (n) => RadioListTile<int>(
                        title: Text('$n'),
                        value: n,
                      ),
                    )
                    .toList(),
              ),
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

  void _editNotificationMinutes(BuildContext context, int currentValue) {
    showDialog<void>(
      context: context,
      builder: (context) {
        int value = currentValue;
        return AlertDialog(
          title: const Text('Anticipo promemoria'),
          content: StatefulBuilder(
            builder: (context, setState) => RadioGroup<int>(
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [15, 30, 45, 60, 120]
                    .map(
                      (n) => RadioListTile<int>(
                        title: Text(n < 60 ? '$n minuti' : '${n ~/ 60} ${n == 60 ? 'ora' : 'ore'}'),
                        value: n,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(notificationSettingsProvider.notifier).setMinutesBefore(value);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => RadioGroup<ThemeMode>(
        groupValue: currentMode,
        onChanged: (value) {
          ref.read(themeModeProvider.notifier).setThemeMode(value!);
          Navigator.pop(ctx);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Chiaro (Dawn)'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Scuro (Rosé Pine)'),
              value: ThemeMode.dark,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Automatico (sistema)'),
              value: ThemeMode.system,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina tutti i dati'),
        content: const Text(
          'Sei sicuro di voler eliminare tutti i dati? Questa azione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.deleteAllData();

              // Refresh all providers
              ref.invalidate(therapyPlanProvider);
              ref.invalidate(injectionsProvider);
              ref.invalidate(blacklistedPointsProvider);
              ref.invalidate(adherenceStatsProvider);
              ref.invalidate(suggestedNextPointProvider);

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Tutti i dati sono stati eliminati'),
                    backgroundColor: isDark
                        ? AppColors.darkPine
                        : AppColors.dawnPine,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
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

/// Mini zone label for the blacklist dialog body map
