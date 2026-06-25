import 'package:flutter/services.dart';

import 'backup_destination.dart';

const MethodChannel _channel = MethodChannel('injecare/saf');

/// Su Android il backup automatico locale è supportato via SAF.
bool get autoBackupSupported => true;

/// Apre il selettore di cartella di sistema (SAF) e prende un permesso
/// persistente. Ritorna null se l'utente annulla.
Future<BackupDirectoryChoice?> pickBackupDestination() async {
  try {
    final res = await _channel.invokeMapMethod<String, dynamic>('openTree');
    final token = res?['treeUri'] as String?;
    if (token == null) return null;
    final label = (res?['label'] as String?) ?? token;
    return BackupDirectoryChoice(token: token, label: label);
  } catch (_) {
    return null;
  }
}

BackupDestination resolveBackupDestination(String? token, String? label) =>
    _SafDestination(token, label);

class _SafDestination implements BackupDestination {
  _SafDestination(this._token, this._label);

  final String? _token;
  final String? _label;

  @override
  String? get label => _label;

  @override
  Future<bool> isAvailable() async {
    if (_token == null) return false;
    try {
      return await _channel
              .invokeMethod<bool>('isWritable', {'treeUri': _token}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> writeBackup(String filename, Uint8List bytes) async {
    await _channel.invokeMethod<String>('writeFile', {
      'treeUri': _token,
      'name': filename,
      'bytes': bytes,
    });
  }

  @override
  Future<List<BackupFileInfo>> listBackups() async {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'listFiles',
      {'treeUri': _token},
    );
    if (raw == null) return const [];
    return raw.whereType<Map<Object?, Object?>>().map((m) {
      final lm = m['lastModified'] as int?;
      return BackupFileInfo(
        id: m['docUri'] as String? ?? '',
        filename: m['name'] as String? ?? '',
        createdAt: (lm != null && lm > 0)
            ? DateTime.fromMillisecondsSinceEpoch(lm)
            : null,
      );
    }).toList();
  }

  @override
  Future<void> deleteBackup(BackupFileInfo info) async {
    await _channel.invokeMethod<bool>('deleteFile', {'docUri': info.id});
  }
}
