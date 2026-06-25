import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/services/auto_backup_provider.dart';
import '../../../core/services/auto_backup_service.dart';
import '../../../core/services/auto_backup_settings.dart';
import '../../../core/services/backup_destination_platform.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/theme/app_tokens.dart';

/// Sezione "Backup automatico" delle Impostazioni. Autonoma: legge/scrive lo
/// stato via [autoBackupSettingsProvider] e orchestra scelta cartella,
/// password, frequenza, ritenzione ed esecuzione manuale.
class AutoBackupSection extends ConsumerStatefulWidget {
  const AutoBackupSection({super.key});

  @override
  ConsumerState<AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends ConsumerState<AutoBackupSection> {
  bool _busy = false;

  AutoBackupController get _controller =>
      ref.read(autoBackupSettingsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final supported = ref.watch(autoBackupSupportedProvider);
    final settings = ref.watch(autoBackupSettingsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'BACKUP AUTOMATICO',
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
          ),
        ),
        if (!supported)
          const ListTile(
            leading: Icon(PhosphorIconsDuotone.info),
            title: Text('Non disponibile su questa piattaforma'),
            subtitle: Text(
              'Su web usa il backup manuale. Disponibile su Android.',
            ),
          )
        else ...[
          SwitchListTile(
            secondary: const Icon(PhosphorIconsDuotone.clockCounterClockwise),
            title: const Text('Backup automatico'),
            subtitle: const Text('Salva i dati nella cartella scelta'),
            value: settings.enabled,
            onChanged: _busy ? null : (v) => _toggleEnabled(v),
          ),
          if (settings.enabled) ..._enabledControls(settings, theme),
        ],
      ],
    );
  }

  List<Widget> _enabledControls(AutoBackupSettings s, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return [
      ListTile(
        leading: const Icon(PhosphorIconsDuotone.folder),
        title: const Text('Cartella di destinazione'),
        subtitle: Text(s.destinationLabel ?? 'Nessuna cartella scelta'),
        trailing: const Icon(PhosphorIconsDuotone.pencilSimple, size: 18),
        onTap: _busy ? null : _pickFolder,
      ),
      if (s.hasDestination)
        _AvailabilityBanner(
          token: s.destinationToken,
          label: s.destinationLabel,
          onReselect: _pickFolder,
        ),
      ListTile(
        leading: const Icon(PhosphorIconsDuotone.calendarDots),
        title: const Text('Frequenza'),
        trailing: Text(
          s.frequency == BackupFrequency.daily ? 'Giornaliero' : 'Settimanale',
          style: TextStyle(
            color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
          ),
        ),
        onTap: _busy ? null : () => _pickFrequency(s),
      ),
      SwitchListTile(
        secondary: const Icon(PhosphorIconsDuotone.lockKey),
        title: const Text('Cifra i backup'),
        subtitle: const Text('AES-256 con password'),
        value: s.encrypted,
        onChanged: _busy ? null : (v) => _toggleEncrypted(s, v),
      ),
      if (s.encrypted)
        ListTile(
          leading: const Icon(PhosphorIconsDuotone.password),
          title: const Text('Password di cifratura'),
          trailing: const Icon(PhosphorIconsDuotone.pencilSimple, size: 18),
          onTap: _busy ? null : _setPassword,
        ),
      ListTile(
        leading: const Icon(PhosphorIconsDuotone.stack),
        title: const Text('Mantieni gli ultimi'),
        trailing: Text(
          '${s.retentionCount} backup',
          style: TextStyle(
            color: isDark ? AppTokens.darkMuted : AppTokens.lightMuted,
          ),
        ),
        onTap: _busy ? null : () => _pickRetention(s),
      ),
      ListTile(
        leading: const Icon(PhosphorIconsDuotone.clock),
        title: const Text('Ultimo backup automatico'),
        subtitle: Text(
          s.lastAutoBackupAt != null
              ? DateFormat('d MMM yyyy, HH:mm', 'it_IT')
                  .format(s.lastAutoBackupAt!)
              : 'Mai',
        ),
        trailing: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _runNow,
                child: const Text('Esegui ora'),
              ),
      ),
    ];
  }

  Future<void> _toggleEnabled(bool value) async {
    final s = ref.read(autoBackupSettingsProvider);
    await _controller.update(s.copyWith(enabled: value));
    // All'abilitazione, se manca la cartella, invita subito a sceglierla.
    if (value && !s.hasDestination) {
      await _pickFolder();
    }
  }

  Future<void> _pickFolder() async {
    setState(() => _busy = true);
    try {
      final choice = await pickBackupDestination();
      if (choice != null) {
        final s = ref.read(autoBackupSettingsProvider);
        await _controller.update(
          s.copyWith(
            destinationToken: choice.token,
            destinationLabel: choice.label,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFrequency(AutoBackupSettings s) async {
    final choice = await showDialog<BackupFrequency>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Frequenza backup'),
        children: [
          for (final f in BackupFrequency.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, f),
              child: Text(
                f == BackupFrequency.daily ? 'Giornaliero' : 'Settimanale',
              ),
            ),
        ],
      ),
    );
    if (choice != null) {
      await _controller.update(s.copyWith(frequency: choice));
    }
  }

  Future<void> _pickRetention(AutoBackupSettings s) async {
    const options = [3, 7, 14, 30];
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Backup da mantenere'),
        children: [
          for (final n in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text('$n backup'),
            ),
        ],
      ),
    );
    if (choice != null) {
      await _controller.update(s.copyWith(retentionCount: choice));
    }
  }

  Future<void> _toggleEncrypted(AutoBackupSettings s, bool value) async {
    if (value) {
      // Per attivare la cifratura serve una password.
      final hasPwd = await _controller.hasPassword();
      if (!hasPwd) {
        final ok = await _promptPassword();
        if (!ok) return; // annullato: non attivare
      }
    }
    await _controller.update(s.copyWith(encrypted: value));
  }

  Future<void> _setPassword() async {
    // Pre-compila con la password salvata: così, se l'utente l'ha dimenticata,
    // può rivelarla (occhio) e recuperarla — è custodita nel secure storage del
    // dispositivo. Per i backup già cifrati la password non è altrimenti
    // recuperabile altrove (è la natura della cifratura).
    final current = await _controller.readPassword();
    if (!mounted) return;
    await _promptPassword(initial: current);
  }

  /// Mostra il dialog di impostazione password. Ritorna true se salvata.
  Future<bool> _promptPassword({String? initial}) async {
    final controllerText = TextEditingController(text: initial ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? error;
        var obscure = true;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Password di cifratura'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Se la perdi, i backup cifrati non saranno ripristinabili. '
                  'Tocca l’occhio per rivedere quella salvata.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controllerText,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Password (min 8 caratteri)',
                    errorText: error,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? PhosphorIconsDuotone.eye
                            : PhosphorIconsDuotone.eyeSlash,
                      ),
                      tooltip: obscure ? 'Mostra' : 'Nascondi',
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () {
                  final err =
                      CryptoService.validatePassword(controllerText.text);
                  if (err != null) {
                    setLocal(() => error = err);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
        );
      },
    );
    if (saved == true) {
      await _controller.setPassword(controllerText.text);
      return true;
    }
    return false;
  }

  Future<void> _runNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final outcome = await runAutoBackupNow(ref);
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_messageFor(outcome.status))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AutoBackupStatus status) => switch (status) {
        AutoBackupStatus.success => 'Backup eseguito',
        AutoBackupStatus.skippedNoDestination =>
          'Scegli prima una cartella di destinazione',
        AutoBackupStatus.failedNoPassword =>
          'Imposta una password per i backup cifrati',
        AutoBackupStatus.skippedDisabled => 'Backup automatico disabilitato',
        AutoBackupStatus.skippedNotDue => 'Backup non ancora necessario',
        AutoBackupStatus.failed => 'Backup non riuscito',
      };
}

/// Banner non bloccante mostrato se il permesso sulla cartella scelta è perso.
class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({
    required this.token,
    required this.label,
    required this.onReselect,
  });

  final String? token;
  final String? label;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final destination = resolveBackupDestination(token, label);
    return FutureBuilder<bool>(
      future: destination.isAvailable(),
      builder: (context, snap) {
        if (snap.data != false) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fg = isDark ? AppTokens.warnDark : AppTokens.warnLight;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: fg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onReselect,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(PhosphorIconsDuotone.warning, color: fg, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Permesso sulla cartella perso. Tocca per riselezionarla.',
                        style: TextStyle(color: fg, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
