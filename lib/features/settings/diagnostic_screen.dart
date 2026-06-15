import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/database/app_database.dart';
import '../../core/services/diagnostic_log_service.dart';
import '../../core/theme/app_tokens.dart';

/// Schermata "Diagnostica" nelle Impostazioni.
///
/// Mostra gli ultimi eventi e gli errori loggati da [DiagnosticLogService],
/// con la possibilità di condividere il report testuale o svuotare il log.
class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  List<AppLog> _logs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final logs = await DiagnosticLogService.instance.recent();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _share() async {
    await DiagnosticLogService.instance.shareReport();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Svuota log diagnostico'),
        content: const Text(
          'Eliminare tutti gli eventi registrati? '
          'Questa azione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Svuota'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DiagnosticLogService.instance.clear();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostica'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsDuotone.shareNetwork),
            tooltip: 'Condividi',
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(PhosphorIconsDuotone.trash),
            tooltip: 'Svuota',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nota privacy
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Card(
              color: isDark ? AppTokens.darkOverlay : AppTokens.lightOverlay,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsDuotone.shieldWarning,
                      size: 20,
                      color: isDark ? AppTokens.warnDark : AppTokens.warnLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Il report può contenere dettagli della terapia: '
                        'condividilo solo con chi ti assiste.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista o stato vuoto
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('Nessun evento registrato'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _LogEntryTile(log: log, isDark: isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.log, required this.isDark});

  final AppLog log;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = log.level == 'error';
    final leadingIcon = isError
        ? PhosphorIconsDuotone.warningCircle
        : PhosphorIconsDuotone.info;
    final iconColor = isError
        ? (isDark ? AppTokens.dangerDark : AppTokens.dangerLight)
        : (isDark ? AppTokens.darkMuted : AppTokens.lightMuted);
    final timestamp = DateFormat('dd/MM HH:mm:ss', 'it').format(log.createdAt);
    final hasDetails = log.details.isNotEmpty;

    if (!hasDetails) {
      return ListTile(
        leading: Icon(leadingIcon, color: iconColor),
        title: Text(
          '${log.tag} · $timestamp',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(log.message),
      );
    }

    return ExpansionTile(
      leading: Icon(leadingIcon, color: iconColor),
      title: Text(
        '${log.tag} · $timestamp',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(log.message),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              log.details,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
