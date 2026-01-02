import 'dart:io';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import 'backup_service.dart';
import 'crypto_service.dart';

/// Risultato del check all'avvio
enum StartupCheckResult {
  /// Database locale esiste, avvio normale
  normalStart,

  /// Nessun database locale, nessun backup remoto - prima esecuzione
  firstRun,

  /// Nessun database locale, backup remoto trovato - chiedi import
  backupAvailable,

  /// Errore durante il check
  error,
}

/// Info dettagliate sul risultato dello startup check
class StartupInfo {
  final StartupCheckResult result;
  final BackupInfo? backupInfo;
  final String? errorMessage;

  StartupInfo({
    required this.result,
    this.backupInfo,
    this.errorMessage,
  });
}

/// Servizio per gestire la logica di avvio dell'app
class StartupService {
  final BackupService _backupService;

  StartupService({
    required BackupService backupService,
    CryptoService? cryptoService, // Non più necessario, mantenuto per compatibilità
  }) : _backupService = backupService;

  /// Controlla lo stato all'avvio
  /// - Se esiste DB locale -> avvio normale
  /// - Se non esiste DB locale -> controlla backup su Drive
  Future<StartupInfo> checkStartupState() async {
    try {
      // Verifica se esiste il database locale
      final dbPath = await AppDatabase.getDatabasePath();
      final dbFile = File(dbPath);
      final dbExists = await dbFile.exists();

      if (dbExists) {
        // Database esiste, avvio normale
        return StartupInfo(result: StartupCheckResult.normalStart);
      }

      // Database non esiste, verifica se c'è un backup
      final isAuthenticated = await _backupService.isAuthenticated();
      if (!isAuthenticated) {
        // Non autenticato, prima esecuzione
        return StartupInfo(result: StartupCheckResult.firstRun);
      }

      // Controlla se esiste un backup su Drive
      final backupInfo = await _backupService.checkForBackup();
      if (backupInfo != null) {
        return StartupInfo(
          result: StartupCheckResult.backupAvailable,
          backupInfo: backupInfo,
        );
      }

      // Nessun backup trovato
      return StartupInfo(result: StartupCheckResult.firstRun);
    } catch (e) {
      return StartupInfo(
        result: StartupCheckResult.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Esegue il restore del backup con password
  Future<BackupResult> restoreBackup(String password) async {
    return _backupService.restore(password);
  }
}

/// Dialog per chiedere all'utente se importare il backup
class RestoreBackupDialog extends StatelessWidget {
  final BackupInfo backupInfo;
  final VoidCallback onRestore;
  final VoidCallback onSkip;

  const RestoreBackupDialog({
    super.key,
    required this.backupInfo,
    required this.onRestore,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Backup trovato'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'È stato trovato un backup dei tuoi dati.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ultimo backup',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        _formatDate(backupInfo.modifiedTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (backupInfo.size != null)
                        Text(
                          _formatSize(backupInfo.size!),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Per ripristinare dovrai inserire la password usata per il backup.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: const Text('Inizia da zero'),
        ),
        FilledButton.icon(
          onPressed: onRestore,
          icon: const Icon(Icons.restore),
          label: const Text('Ripristina'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Oggi alle ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ieri alle ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Widget per mostrare il progresso del restore
class RestoreProgressDialog extends StatelessWidget {
  const RestoreProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Ripristino in corso...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Non chiudere l\'app',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Dialog per inserire la password di backup
class BackupPasswordDialog extends StatefulWidget {
  final String title;
  final String confirmButtonText;
  final bool isRestore;

  const BackupPasswordDialog({
    super.key,
    required this.title,
    this.confirmButtonText = 'Conferma',
    this.isRestore = false,
  });

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimo 8 caratteri',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: CryptoService.validatePassword,
            ),
            if (!widget.isRestore) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Conferma password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Le password non coincidono';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            Text(
              widget.isRestore
                  ? 'Inserisci la password usata per creare il backup.'
                  : 'Questa password sarà necessaria per ripristinare il backup su un nuovo dispositivo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          child: Text(widget.confirmButtonText),
        ),
      ],
    );
  }
}
