import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/services/import_service.dart';
import '../../core/services/notification_settings_provider.dart';
import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
import '../../core/ml/rotation_pattern_engine.dart';
import '../../app/router.dart';
import '../../models/rotation_pattern.dart';
import '../../models/therapy_plan.dart';
import '../auth/auth_provider.dart';
import '../injection/injection_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final therapyPlanAsync = ref.watch(therapyPlanProvider);
    final blacklistAsync = ref.watch(blacklistedPointsProvider);
    final injectionsAsync = ref.watch(injectionsProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          // Header
          _AppInfoHeader(isDark: isDark, onReset: () => _signOut(context)),

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

          const _SectionHeader(title: 'PATTERN DI ROTAZIONE'),
          _RotationPatternSection(),

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
                          final notifier = ref.read(
                            notificationSettingsProvider.notifier,
                          );
                          final granted = await notifier.requestPermissions();
                          if (mounted && !granted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Permessi non concessi. Abilitali dalle impostazioni del dispositivo.',
                                ),
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
                ? (value) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setEnabled(value)
                : null,
          ),
          _SettingsTile(
            title: 'Anticipo',
            trailing: Text('${notificationSettings.minutesBefore} min'),
            onTap: () => _editNotificationMinutes(
              context,
              notificationSettings.minutesBefore,
            ),
          ),
          SwitchListTile(
            title: const Text('Reminder dose saltata'),
            value: notificationSettings.missedDoseReminder,
            onChanged: notificationSettings.permissionsGranted
                ? (value) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setMissedDoseReminder(value)
                : null,
          ),

          const _SectionHeader(title: 'ASPETTO'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_themeModeLabel),
            onTap: () => _showThemeSelector(context),
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
            icon: Icons.upload_file,
            title: 'Importa da CSV',
            onTap: () => _importFromCsv(context),
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
  List<dynamic> _convertInjections(List<db.Injection> injections) {
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
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.resetOnboarding();
    if (mounted) {
      router.go(AppRoutes.login);
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
                    .map((n) => RadioListTile<int>(title: Text('$n'), value: n))
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
                        title: Text(
                          n < 60
                              ? '$n minuti'
                              : '${n ~/ 60} ${n == 60 ? 'ora' : 'ore'}',
                        ),
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
                ref
                    .read(notificationSettingsProvider.notifier)
                    .setMinutesBefore(value);
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

  Future<void> _importFromCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);

    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);

      // Show loading dialog
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text('Importazione in corso...'),
              ],
            ),
          ),
        );
      }

      // Import
      final importResult = await ImportService.instance.importFromFile(db, file);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Refresh providers
      ref.invalidate(injectionsProvider);
      ref.invalidate(adherenceStatsProvider);

      // Show result
      if (mounted) {
        if (importResult.hasErrors) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Importazione completata con errori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importate: ${importResult.successCount}'),
                  Text('Errori: ${importResult.errorCount}'),
                  const SizedBox(height: 16),
                  const Text('Dettagli errori:'),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        importResult.errors.take(10).join('\n'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Importate ${importResult.successCount} iniezioni'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: errorColor),
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

/// Header con info app
class _AppInfoHeader extends StatelessWidget {
  const _AppInfoHeader({required this.isDark, required this.onReset});

  final bool isDark;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isDark
                ? AppColors.darkOverlay
                : AppColors.dawnOverlay,
            child: Icon(
              Icons.favorite,
              size: 30,
              color: isDark ? AppColors.darkPine : AppColors.dawnPine,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InjeCare Plan', style: theme.textTheme.titleMedium),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 14,
                      color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dati salvati localmente',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset app',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

/// Sezione Pattern di Rotazione
class _RotationPatternSection extends ConsumerWidget {
  const _RotationPatternSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlansAsync = ref.watch(allTherapyPlansProvider);
    final patternAsync = ref.watch(currentRotationPatternProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return allPlansAsync.when(
      loading: () => const ListTile(
        leading: CircularProgressIndicator(strokeWidth: 2),
        title: Text('Caricamento...'),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Errore: $e'),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return const ListTile(
            leading: Icon(Icons.warning),
            title: Text('Nessun piano disponibile'),
          );
        }

        final activePlan = plans.firstWhere(
          (p) => p.isActive,
          orElse: () => plans.first,
        );
        final patternType = RotationPatternTypeExtension.fromDatabaseValue(
          activePlan.rotationPatternType,
        );

        return Column(
          children: [
            // Current plan display
            ListTile(
              leading: Text(
                patternType.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(activePlan.name),
              subtitle: Text(
                patternType.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPlanSelector(context, ref, plans, activePlan),
            ),

            // Info card for current pattern
            patternAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (pattern) {
                if (pattern.type == RotationPatternType.smart) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getPatternStatus(pattern),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Custom sequence button
            if (patternType == RotationPatternType.custom)
              patternAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (pattern) => _SettingsTile(
                  icon: Icons.reorder,
                  title: 'Modifica sequenza',
                  trailing: Text(
                    pattern.customSequence != null
                        ? '${pattern.customSequence!.length} zone'
                        : 'Non configurata',
                  ),
                  onTap: () => context.push(AppRoutes.customPattern),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getPatternStatus(RotationPattern pattern) {
    return switch (pattern.type) {
      RotationPatternType.smart => '',
      RotationPatternType.sequential =>
        'Posizione nella sequenza: ${pattern.currentIndex + 1}/8',
      RotationPatternType.alternateSides =>
        pattern.lastSide != null
            ? 'Ultimo lato: ${pattern.lastSide == 'left' ? 'sinistro' : 'destro'}'
            : 'Inizierà dal lato sinistro',
      RotationPatternType.weeklyRotation =>
        pattern.weekStartDate != null
            ? 'Settimana iniziata il ${_formatDate(pattern.weekStartDate!)}'
            : 'Inizierà dalla prossima iniezione',
      RotationPatternType.custom =>
        pattern.customSequence != null
            ? 'Posizione: ${pattern.currentIndex + 1}/${pattern.customSequence!.length}'
            : 'Sequenza non configurata',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPlanSelector(
    BuildContext context,
    WidgetRef ref,
    List<db.TherapyPlan> plans,
    db.TherapyPlan activePlan,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Seleziona Piano di Rotazione',
                style: theme.textTheme.titleLarge,
              ),
            ),

            const Divider(),

            // Plan options
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final patternType = RotationPatternTypeExtension.fromDatabaseValue(
                    plan.rotationPatternType,
                  );
                  final isSelected = plan.id == activePlan.id;

                  return RadioListTile<int>(
                    value: plan.id,
                    groupValue: activePlan.id,
                    onChanged: (planId) async {
                      if (planId == null) return;

                      final service = ref.read(rotationPatternServiceProvider);
                      
                      // Se è la rotazione settimanale, inizializza la data
                      if (patternType == RotationPatternType.weeklyRotation) {
                        await service.initWeeklyRotation();
                      } else {
                        await service.activatePlan(planId);
                      }

                      ref.invalidate(currentRotationPatternProvider);
                      ref.invalidate(allTherapyPlansProvider);
                      ref.invalidate(patternBasedZoneSuggestionProvider);

                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    title: Row(
                      children: [
                        Text(patternType.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plan.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ATTIVO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        patternType.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    selected: isSelected,
                    activeColor: isDark ? AppColors.darkIris : AppColors.dawnIris,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini zone label for the blacklist dialog body map
