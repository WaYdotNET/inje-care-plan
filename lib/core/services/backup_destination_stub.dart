import 'dart:typed_data';

import 'backup_destination.dart';

/// Piattaforme senza supporto al backup automatico verso cartella scelta
/// (es. Web: la File System Access API e la persistenza dell'handle non sono
/// ancora implementate qui — il backup manuale resta disponibile).
bool get autoBackupSupported => false;

Future<BackupDirectoryChoice?> pickBackupDestination() async => null;

BackupDestination resolveBackupDestination(String? token, String? label) =>
    _UnavailableDestination(label);

class _UnavailableDestination implements BackupDestination {
  _UnavailableDestination(this._label);

  final String? _label;

  @override
  String? get label => _label;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> writeBackup(String filename, Uint8List bytes) async {}

  @override
  Future<List<BackupFileInfo>> listBackups() async => const [];

  @override
  Future<void> deleteBackup(BackupFileInfo info) async {}
}
