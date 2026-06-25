import 'dart:convert';
import 'dart:typed_data';

import 'auto_backup_settings.dart';
import 'backup_destination.dart';
import 'crypto_service.dart';

/// Esito di un tentativo di backup automatico.
enum AutoBackupStatus {
  success,
  skippedDisabled,
  skippedNoDestination,
  skippedNotDue,
  failedNoPassword,
  failed,
}

class AutoBackupOutcome {
  const AutoBackupOutcome(this.status, [this.message]);

  final AutoBackupStatus status;
  final String? message;

  bool get didRun => status == AutoBackupStatus.success;
}

/// Estensione file per i backup cifrati.
const String kEncryptedBackupSuffix = '.json.enc';
const String kPlainBackupSuffix = '.json';

/// Orchestratore platform-agnostic del backup automatico locale.
///
/// Tutte le dipendenze I/O sono iniettate, così la logica è testabile con dei
/// fake. Le decisioni temporali e di ritenzione sono funzioni pure statiche.
class AutoBackupService {
  AutoBackupService({CryptoService? crypto})
      : _crypto = crypto ?? CryptoService();

  final CryptoService _crypto;

  /// True se è il momento di eseguire un nuovo backup.
  static bool isDue(
    DateTime? last,
    BackupFrequency frequency,
    DateTime now,
  ) {
    if (last == null) return true;
    return now.difference(last) >= frequency.interval;
  }

  /// Dato l'elenco dei backup presenti, restituisce quelli da cancellare per
  /// rispettare la ritenzione (mantiene i [keep] più recenti). L'ordinamento
  /// usa il nome file, che contiene il timestamp `YYYYMMDD-HHmmss` ordinabile.
  static List<BackupFileInfo> selectBackupsToDelete(
    List<BackupFileInfo> all,
    int keep,
  ) {
    if (keep <= 0) return List.of(all);
    if (all.length <= keep) return const [];
    final sorted = List.of(all)
      ..sort((a, b) {
        final byDate = (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0));
        if (byDate != 0) return byDate;
        return b.filename.compareTo(a.filename);
      });
    return sorted.sublist(keep);
  }

  /// Nome file di backup deterministico a partire dall'istante.
  static String buildFilename(DateTime now, {required bool encrypted}) {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final suffix = encrypted ? kEncryptedBackupSuffix : kPlainBackupSuffix;
    return 'injecare-backup-$stamp$suffix';
  }

  /// Esegue un backup automatico se le condizioni sono soddisfatte.
  ///
  /// - [buildJsonBytes]: produce i byte del JSON di backup in chiaro.
  /// - [readPassword]: legge la password dal secure storage (null se assente).
  /// - [onSuccess]: callback per persistere `lastAutoBackupAt` dopo il successo.
  ///
  /// Non lancia mai: gli errori sono catturati e tradotti in
  /// [AutoBackupStatus.failed].
  Future<AutoBackupOutcome> maybeRunBackup({
    required AutoBackupSettings settings,
    required BackupDestination destination,
    required DateTime now,
    required Future<Uint8List> Function() buildJsonBytes,
    required Future<String?> Function() readPassword,
    required Future<void> Function(DateTime ranAt) onSuccess,
  }) async {
    if (!settings.enabled) {
      return const AutoBackupOutcome(AutoBackupStatus.skippedDisabled);
    }
    if (!isDue(settings.lastAutoBackupAt, settings.frequency, now)) {
      return const AutoBackupOutcome(AutoBackupStatus.skippedNotDue);
    }

    try {
      if (!await destination.isAvailable()) {
        return const AutoBackupOutcome(AutoBackupStatus.skippedNoDestination);
      }

      Uint8List bytes = await buildJsonBytes();

      if (settings.encrypted) {
        final password = await readPassword();
        if (password == null || password.isEmpty) {
          return const AutoBackupOutcome(AutoBackupStatus.failedNoPassword);
        }
        bytes = _crypto.encryptBytesWithPassword(bytes, password);
      }

      final filename = buildFilename(now, encrypted: settings.encrypted);
      await destination.writeBackup(filename, bytes);

      // Ritenzione (best-effort: un errore qui non invalida il backup).
      try {
        final existing = await destination.listBackups();
        for (final stale
            in selectBackupsToDelete(existing, settings.retentionCount)) {
          await destination.deleteBackup(stale);
        }
      } catch (_) {/* best-effort */}

      await onSuccess(now);
      return const AutoBackupOutcome(AutoBackupStatus.success);
    } catch (e) {
      return AutoBackupOutcome(AutoBackupStatus.failed, e.toString());
    }
  }

  /// Helper: byte JSON in chiaro da una mappa di backup.
  static Uint8List jsonBytesFromMap(Map<String, dynamic> data) =>
      Uint8List.fromList(utf8.encode(jsonEncode(data)));

  /// Rileva se dei byte/un nome file rappresentano un backup cifrato.
  static bool isEncryptedBackup(String filename) =>
      filename.toLowerCase().endsWith('.enc');
}
