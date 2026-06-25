import 'dart:typed_data';

/// Metadati di un file di backup presente nella destinazione.
class BackupFileInfo {
  const BackupFileInfo({
    required this.id,
    required this.filename,
    this.createdAt,
  });

  /// Identificatore opaco (path, content-URI o nome handle) usato per
  /// cancellare il file dalla destinazione.
  final String id;

  /// Nome file, es. `injecare-backup-20260625-200000.json[.enc]`.
  final String filename;

  /// Data di creazione, se disponibile dai metadati; altrimenti null e si
  /// ricava dal nome file (che contiene il timestamp ordinabile).
  final DateTime? createdAt;
}

/// Risultato della scelta di una cartella di destinazione da parte dell'utente.
class BackupDirectoryChoice {
  const BackupDirectoryChoice({required this.token, required this.label});

  /// Token opaco da persistere (tree-URI SAF su Android).
  final String token;

  /// Nome leggibile della cartella.
  final String label;
}

/// Astrae il "dove salvare" un backup. Una implementazione per piattaforma
/// (SAF su Android, File System Access su Web) viene risolta via
/// conditional-import in `backup_destination_factory.dart`.
abstract class BackupDestination {
  /// True se la destinazione è scelta e il permesso di scrittura è valido.
  Future<bool> isAvailable();

  /// Scrive un file di backup nella destinazione.
  Future<void> writeBackup(String filename, Uint8List bytes);

  /// Elenca i backup presenti, per applicare la ritenzione.
  Future<List<BackupFileInfo>> listBackups();

  /// Cancella un backup dalla destinazione.
  Future<void> deleteBackup(BackupFileInfo info);

  /// Nome leggibile della cartella, mostrato in UI (può essere null).
  String? get label;
}
