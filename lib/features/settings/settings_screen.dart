import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../info/info_screen.dart' show packageInfoProvider;
import '../../core/services/auto_backup_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/crypto_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/import_service.dart';
import '../../core/services/notification_settings_provider.dart';
import 'diagnostic_screen.dart';
import 'reminder_calendar_screen.dart';
import '../../core/utils/picked_file_to_bytes.dart';
import '../../core/utils/picked_file_to_string.dart';
import '../../core/database/app_database.dart' as db;
import '../../core/database/database_provider.dart';
import '../../core/ml/rotation_pattern_engine.dart' hide bodyZonesProvider;
import '../../app/router.dart';
import '../../models/rotation_pattern.dart';
import '../../models/therapy_plan.dart';
import '../auth/auth_provider.dart';
import '../home/home_layout_provider.dart';
import '../injection/injection_provider.dart';
import '../injection/point_selection_style_provider.dart';
import 'widgets/auto_backup_section.dart';

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

          const _SectionHeader(title: 'TERAPIA'),
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

          _RotationPatternSection(),

          const _SectionHeader(title: 'ZONE E PUNTI'),
          _SettingsTile(
            icon: PhosphorIconsDuotone.mapPinLine,
            title: 'Gestisci zone',
            onTap: () => context.push(AppRoutes.zoneManagement),
          ),
          blacklistAsync.when(
            loading: () => const SizedBox(),
            error: (e, st) => const SizedBox(),
            data: (blacklist) => _SettingsTile(
              icon: PhosphorIconsDuotone.prohibit,
              iconColor: isDark ? AppTokens.dangerDark : AppTokens.dangerLight,
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
                color: isDark ? AppTokens.darkOverlay : AppTokens.lightOverlay,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsDuotone.bellSlash,
                        color: isDark ? AppTokens.warnDark : AppTokens.warnLight,
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
          _SettingsTile(
            title: 'Tolleranza mancata',
            trailing: Text('${notificationSettings.overdueGraceMinutes} min'),
            onTap: () => _editOverdueGraceMinutes(
              context,
              notificationSettings.overdueGraceMinutes,
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
          _SettingsTile(
            title: 'Promemoria effetti collaterali',
            trailing: Text('${notificationSettings.sideEffectsReminderHours} ore'),
            onTap: () => _editSideEffectsReminderHours(
              context,
              notificationSettings.sideEffectsReminderHours,
            ),
          ),
          _SettingsTile(
            icon: PhosphorIconsDuotone.calendarCheck,
            title: 'Promemoria e Calendario',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReminderCalendarScreen(),
              ),
            ),
          ),

          const _SectionHeader(title: 'ASPETTO'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_themeModeLabel),
            onTap: () => _showThemeSelector(context),
          ),
          Consumer(
            builder: (context, ref, _) {
              final layout = ref.watch(homeLayoutProvider);
              final label =
                  layout == HomeLayout.silhouette ? 'Silhouette' : 'Settimana';
              return ListTile(
                title: const Text('Layout Home'),
                subtitle: Text(label),
                onTap: () => _showHomeLayoutSelector(context),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final style = ref.watch(pointSelectionStyleProvider);
              final label = style == PointSelectionStyle.classic
                  ? 'Classico (a step)'
                  : 'Mappa del corpo';
              return ListTile(
                title: const Text('Stile selezione punto'),
                subtitle: Text(label),
                onTap: () => _showPointSelectionStyleSelector(context),
              );
            },
          ),

          const _SectionHeader(title: 'DATI'),
          injectionsAsync.when(
            loading: () => const SizedBox(),
            error: (e, st) => const SizedBox(),
            data: (injections) => _SettingsTile(
              icon: PhosphorIconsDuotone.export,
              title: 'Esporta storico',
              onTap: injections.isNotEmpty
                  ? () => _showExportSelector(context, injections)
                  : () {},
            ),
          ),
          _SettingsTile(
            icon: PhosphorIconsDuotone.uploadSimple,
            title: 'Importa da CSV',
            onTap: () => _importFromCsv(context),
          ),
          _SettingsTile(
            icon: PhosphorIconsDuotone.cloudArrowUp,
            title: 'Backup completo (JSON)',
            onTap: () => _exportJsonBackup(context),
          ),
          _SettingsTile(
            icon: PhosphorIconsDuotone.arrowCounterClockwise,
            title: 'Ripristina da backup',
            onTap: () => _importJsonBackup(context),
          ),
          _SettingsTile(
            title: 'Elimina tutti i dati',
            titleColor: isDark ? AppTokens.dangerDark : AppTokens.dangerLight,
            onTap: () => _showDeleteConfirmation(context),
          ),

          const AutoBackupSection(),

          const _SectionHeader(title: 'AIUTO'),
          _SettingsTile(
            title: 'Guida all\'uso',
            icon: PhosphorIconsDuotone.question,
            onTap: () => context.push(AppRoutes.help),
          ),
          _SettingsTile(
            title: 'Informazioni sull\'app',
            icon: PhosphorIconsDuotone.info,
            onTap: () => context.push(AppRoutes.info),
          ),
          _SettingsTile(
            title: 'Rivedi introduzione',
            icon: PhosphorIconsDuotone.arrowCounterClockwise,
            onTap: () => _showOnboardingConfirmation(context),
          ),
          _SettingsTile(
            icon: PhosphorIconsDuotone.bug,
            title: 'Diagnostica',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DiagnosticScreen(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // App version (letta dinamicamente)
          Consumer(
            builder: (context, ref, _) {
              final packageInfoAsync = ref.watch(packageInfoProvider);
              return Center(
                child: packageInfoAsync.when(
                  data: (info) => Text(
                    'InjeCare Plan v${info.version}',
                    style: theme.textTheme.bodySmall,
                  ),
                  loading: () => Text(
                    'InjeCare Plan',
                    style: theme.textTheme.bodySmall,
                  ),
                  error: (_, __) => Text(
                    'InjeCare Plan',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
          Center(
            child: Text(
              'Privacy-first · Offline-first',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
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
      ThemeMode.light => 'Chiaro',
      ThemeMode.dark => 'Scuro',
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

  void _editOverdueGraceMinutes(BuildContext context, int currentValue) {
    _showStepperDialog(
      context: context,
      title: 'Tolleranza mancata',
      subtitle: 'Dopo questo tempo una programmata diventa mancata',
      current: currentValue,
      min: 0,
      max: 360,
      step: 5,
      format: _formatMinutes,
      onSave: (v) => ref
          .read(notificationSettingsProvider.notifier)
          .setOverdueGraceMinutes(v),
    );
  }

  /// Formatta una quantità di minuti in modo leggibile.
  static String _formatMinutes(int n) {
    if (n == 0) return 'Subito';
    if (n < 60) return '$n min';
    final h = n ~/ 60;
    final m = n % 60;
    final hLabel = '$h ${h == 1 ? 'ora' : 'ore'}';
    return m == 0 ? hLabel : '$hLabel $m min';
  }

  /// Dialog con selettore libero (− valore +) entro [min]..[max] a passo [step].
  void _showStepperDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    required int current,
    required int min,
    required int max,
    required int step,
    required String Function(int) format,
    required void Function(int) onSave,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        int value = current.clamp(min, max);
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTokens.accent.withValues(alpha: 0.14),
                        foregroundColor: AppTokens.accent,
                      ),
                      icon: const Icon(PhosphorIconsDuotone.minus),
                      onPressed: value > min
                          ? () => setState(
                                () => value = (value - step).clamp(min, max),
                              )
                          : null,
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        format(value),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton.filledTonal(
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTokens.accent.withValues(alpha: 0.14),
                        foregroundColor: AppTokens.accent,
                      ),
                      icon: const Icon(PhosphorIconsDuotone.plus),
                      onPressed: value < max
                          ? () => setState(
                                () => value = (value + step).clamp(min, max),
                              )
                          : null,
                    ),
                  ],
                ),
              ],
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
                onSave(value);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editNotificationMinutes(BuildContext context, int currentValue) {
    _showStepperDialog(
      context: context,
      title: 'Anticipo promemoria',
      subtitle: 'Quanto prima dell\'orario ricevere il promemoria',
      current: currentValue,
      min: 0,
      max: 240,
      step: 5,
      format: _formatMinutes,
      onSave: (v) =>
          ref.read(notificationSettingsProvider.notifier).setMinutesBefore(v),
    );
  }

  void _editSideEffectsReminderHours(BuildContext context, int currentValue) {
    _showStepperDialog(
      context: context,
      title: 'Promemoria effetti collaterali',
      subtitle: 'Quanto dopo l\'iniezione ricordare di annotare gli effetti',
      current: currentValue,
      min: 1,
      max: 48,
      step: 1,
      format: (n) => '$n ${n == 1 ? 'ora' : 'ore'} dopo',
      onSave: (v) => ref
          .read(notificationSettingsProvider.notifier)
          .setSideEffectsReminderHours(v),
    );
  }

  void _showExportSelector(BuildContext context, List<db.Injection> injections) {
    Future<void> run(Future<void> Function(List<dynamic>) export) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await export(_convertInjections(injections));
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsDuotone.filePdf),
              title: const Text('PDF'),
              subtitle: const Text('Report stampabile'),
              onTap: () {
                Navigator.pop(ctx);
                run(ExportService.instance.exportToPdf);
              },
            ),
            ListTile(
              leading: const Icon(PhosphorIconsDuotone.fileCsv),
              title: const Text('CSV'),
              subtitle: const Text('Foglio di calcolo'),
              onTap: () {
                Navigator.pop(ctx);
                run(ExportService.instance.exportToCsv);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
              title: Text('Chiaro'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Scuro'),
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

  void _showHomeLayoutSelector(BuildContext context) {
    final currentLayout = ref.read(homeLayoutProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => RadioGroup<HomeLayout>(
        groupValue: currentLayout,
        onChanged: (value) {
          ref.read(homeLayoutProvider.notifier).setLayout(value!);
          Navigator.pop(ctx);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<HomeLayout>(
              title: Text('Settimana'),
              subtitle: Text('Prossima iniezione + pallini della settimana'),
              value: HomeLayout.week,
            ),
            RadioListTile<HomeLayout>(
              title: Text('Silhouette'),
              subtitle: Text('Mappa del corpo con il punto'),
              value: HomeLayout.silhouette,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPointSelectionStyleSelector(BuildContext context) {
    final current = ref.read(pointSelectionStyleProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => RadioGroup<PointSelectionStyle>(
        groupValue: current,
        onChanged: (value) {
          ref.read(pointSelectionStyleProvider.notifier).setStyle(value!);
          Navigator.pop(ctx);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<PointSelectionStyle>(
              title: Text('Mappa del corpo'),
              subtitle: Text('Tutti i punti sulla silhouette, un tap per sceglierli'),
              value: PointSelectionStyle.map,
            ),
            RadioListTile<PointSelectionStyle>(
              title: Text('Classico (a step)'),
              subtitle: Text('Scegli prima la zona, poi il punto'),
              value: PointSelectionStyle.classic,
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
      final content = await readPickedFileAsString(result.files.first);
      final importResult = await ImportService.instance.importFromCsv(db, content);

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

  Future<void> _exportJsonBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);

    try {
      await BackupService.instance.exportBackup(db);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Backup esportato'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _importJsonBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'enc'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      // Risolve il contenuto: i backup cifrati (.enc) vanno decifrati con la
      // password (quella salvata o chiesta all'utente) prima dell'import.
      final pickedFile = result.files.first;
      final String content;
      if (AutoBackupService.isEncryptedBackup(pickedFile.name)) {
        final decrypted = await _decryptPickedBackup(pickedFile);
        if (decrypted == null) return; // annullato o errore già notificato
        content = decrypted;
      } else {
        content = await readPickedFileAsString(pickedFile);
      }

      // Scegli strategia
      final strategy = await showDialog<ImportStrategy>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Strategia di ripristino'),
          content: const Text(
            'Scegli come ripristinare i dati:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, ImportStrategy.mergeKeepExisting),
              child: const Text('Unisci (mantieni esistenti)'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, ImportStrategy.replaceAll),
              child: const Text('Sostituisci tutto'),
            ),
          ],
        ),
      );

      if (strategy == null) return;

      // Loading dialog
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text('Ripristino in corso...'),
              ],
            ),
          ),
        );
      }

      final importResult = await BackupService.instance.importBackup(
        db,
        content,
        strategy: strategy,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Invalidate all providers
      ref.invalidate(injectionsProvider);
      ref.invalidate(adherenceStatsProvider);
      ref.invalidate(bodyZonesProvider);
      ref.invalidate(therapyPlanProvider);
      ref.invalidate(blacklistedPointsProvider);

      if (mounted) {
        if (importResult.hasErrors) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Ripristino con errori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tabelle: ${importResult.tablesProcessed}'),
                  Text('Record: ${importResult.recordsImported}'),
                  const SizedBox(height: 16),
                  const Text('Errori:'),
                  const SizedBox(height: 8),
                  Text(
                    importResult.errors.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall,
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
              content: Text(
                'Ripristinati ${importResult.recordsImported} record da ${importResult.tablesProcessed} tabelle',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
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

  /// Decifra un backup `.enc` scelto. Prova la password salvata; se assente o
  /// errata la chiede all'utente (con possibilità di riprovare). Ritorna il
  /// JSON in chiaro, oppure null se l'utente annulla.
  Future<String?> _decryptPickedBackup(PlatformFile file) async {
    final bytes = await readPickedFileAsBytes(file);
    final crypto = CryptoService();

    final stored =
        await ref.read(autoBackupSettingsProvider.notifier).readPassword();
    if (stored != null &&
        stored.isNotEmpty &&
        crypto.verifyPassword(bytes, stored)) {
      return utf8.decode(crypto.decryptBytesWithPassword(bytes, stored));
    }

    while (mounted) {
      final pwd = await _askDecryptPassword();
      if (pwd == null) return null; // annullato
      if (crypto.verifyPassword(bytes, pwd)) {
        return utf8.decode(crypto.decryptBytesWithPassword(bytes, pwd));
      }
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Password errata')));
    }
    return null;
  }

  Future<String?> _askDecryptPassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup cifrato'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password del backup',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Decifra'),
          ),
        ],
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
                        ? AppTokens.accent
                        : AppTokens.accent,
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
                const Icon(PhosphorIconsDuotone.caretRight),
              ],
            )
          : const Icon(PhosphorIconsDuotone.caretRight),
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
                ? AppTokens.darkOverlay
                : AppTokens.lightOverlay,
            child: Icon(
              PhosphorIconsDuotone.heart,
              size: 30,
              color: isDark ? AppTokens.accent : AppTokens.accent,
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
                      PhosphorIconsDuotone.deviceMobile,
                      size: 14,
                      color: isDark ? AppTokens.accent : AppTokens.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dati salvati localmente',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppTokens.accent : AppTokens.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsDuotone.arrowClockwise),
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
        leading: const Icon(PhosphorIconsDuotone.warningCircle),
        title: Text('Errore: $e'),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return const ListTile(
            leading: Icon(PhosphorIconsDuotone.warning),
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
              trailing: const Icon(PhosphorIconsDuotone.caretRight),
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
                    color: isDark ? AppTokens.darkOverlay : AppTokens.lightOverlay,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsDuotone.info,
                            size: 20,
                            color: isDark ? AppTokens.accentEnd : AppTokens.accentEnd,
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
                  icon: PhosphorIconsDuotone.rows,
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
      RotationPatternType.clockwise =>
        'Posizione nella sequenza: ${pattern.currentIndex + 1}/8',
      RotationPatternType.counterClockwise =>
        'Posizione nella sequenza: ${pattern.currentIndex + 1}/8',
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
                color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
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
                              color: isDark ? AppTokens.accent : AppTokens.accent,
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
                    activeColor: isDark ? AppTokens.darkIris : AppTokens.accent,
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

