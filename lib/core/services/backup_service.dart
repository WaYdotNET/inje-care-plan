import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import 'crypto_service.dart';

/// Risultato di un'operazione di backup
class BackupResult {
  final bool success;
  final String? message;
  final DateTime? backupDate;
  final String? error;

  BackupResult.success({this.message, this.backupDate})
      : success = true,
        error = null;

  BackupResult.failure(this.error)
      : success = false,
        message = null,
        backupDate = null;
}

/// Informazioni su un backup esistente
class BackupInfo {
  final String id;
  final String name;
  final DateTime modifiedTime;
  final int? size;

  BackupInfo({
    required this.id,
    required this.name,
    required this.modifiedTime,
    this.size,
  });
}

/// HTTP Client autenticato con Google
class _AuthenticatedClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _AuthenticatedClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Servizio per backup/restore su Google Drive
/// Richiede password per cifratura/decifratura
class BackupService {
  static const _backupFileName = 'injecare_backup.enc';
  static const _backupFolderName = 'InjeCare Backups';
  static const _driveScopes = [drive.DriveApi.driveFileScope];

  final CryptoService _cryptoService;
  GoogleSignInAccount? _currentUser;

  BackupService({
    required CryptoService cryptoService,
  }) : _cryptoService = cryptoService;

  /// Verifica se l'utente è autenticato con Google (con scope Drive)
  Future<bool> isAuthenticated() async {
    return _currentUser != null;
  }

  /// Richiede accesso a Google Drive
  Future<bool> signIn() async {
    try {
      final signIn = GoogleSignIn.instance;
      final account = await signIn.authenticate(scopeHint: _driveScopes);
      _currentUser = account;
      return account != null;
    } catch (e) {
      return false;
    }
  }

  /// Disconnette da Google Drive
  Future<void> signOut() async {
    final signIn = GoogleSignIn.instance;
    await signIn.signOut();
    _currentUser = null;
  }

  /// Ottiene l'API client per Google Drive
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) {
      // Prova a fare sign-in silenzioso
      final signIn = GoogleSignIn.instance;
      await signIn.attemptLightweightAuthentication();

      // Aspetta un po' per l'evento
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentUser == null) {
        return null;
      }
    }

    // Ottieni access token per gli scopes
    final headers = await _currentUser!.authorizationClient
        .authorizationHeaders(_driveScopes, promptIfNecessary: true);

    if (headers == null) return null;

    final authHeader = headers['Authorization'];
    if (authHeader == null) return null;

    final accessToken = authHeader.replaceFirst('Bearer ', '');
    final client = _AuthenticatedClient(accessToken);

    return drive.DriveApi(client);
  }

  /// Trova o crea la cartella di backup su Drive
  Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    // Cerca cartella esistente
    final folderList = await driveApi.files.list(
      q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
    );

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id;
    }

    // Crea nuova cartella
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id;
  }

  /// Esegue il backup del database su Google Drive
  /// Richiede password per cifrare i dati
  Future<BackupResult> backup(String password) async {
    // Valida password
    if (!CryptoService.isValidPassword(password)) {
      return BackupResult.failure('Password non valida (minimo 8 caratteri)');
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.failure('Non autenticato con Google Drive');
      }

      // Ottieni il file database
      final dbPath = await AppDatabase.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return BackupResult.failure('Database non trovato');
      }

      // Cifra il database con password
      final encryptedBytes =
          await _cryptoService.encryptFileWithPassword(dbFile, password);

      // Ottieni/crea cartella backup
      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        return BackupResult.failure('Impossibile creare cartella backup');
      }

      // Cerca file backup esistente per aggiornarlo
      final existingFiles = await driveApi.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      final metadata = drive.File()..name = _backupFileName;
      final media = drive.Media(
        Stream.value(encryptedBytes),
        encryptedBytes.length,
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Aggiorna file esistente
        await driveApi.files.update(
          metadata,
          existingFiles.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Crea nuovo file
        metadata.parents = [folderId];
        await driveApi.files.create(metadata, uploadMedia: media);
      }

      final now = DateTime.now();
      return BackupResult.success(
        message: 'Backup completato con successo',
        backupDate: now,
      );
    } catch (e) {
      return BackupResult.failure('Errore durante il backup: $e');
    }
  }

  /// Verifica se esiste un backup su Google Drive
  Future<BackupInfo?> checkForBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // Cerca cartella backup
      final folderList = await driveApi.files.list(
        q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );

      if (folderList.files == null || folderList.files!.isEmpty) {
        return null;
      }

      final folderId = folderList.files!.first.id!;

      // Cerca file backup
      final backupFiles = await driveApi.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        $fields: 'files(id, name, modifiedTime, size)',
        spaces: 'drive',
      );

      if (backupFiles.files == null || backupFiles.files!.isEmpty) {
        return null;
      }

      final file = backupFiles.files!.first;
      return BackupInfo(
        id: file.id!,
        name: file.name!,
        modifiedTime: file.modifiedTime ?? DateTime.now(),
        size: file.size != null ? int.tryParse(file.size!) : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Ripristina il database da un backup su Google Drive
  /// Richiede password per decifrare i dati
  Future<BackupResult> restore(String password) async {
    if (!CryptoService.isValidPassword(password)) {
      return BackupResult.failure('Password non valida');
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.failure('Non autenticato con Google Drive');
      }

      // Trova il backup
      final backupInfo = await checkForBackup();
      if (backupInfo == null) {
        return BackupResult.failure('Nessun backup trovato');
      }

      // Scarica il file cifrato
      final response = await driveApi.files.get(
        backupInfo.id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = [];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      // Decifra con password
      final Uint8List decryptedBytes;
      try {
        decryptedBytes = _cryptoService.decryptBytesWithPassword(
          Uint8List.fromList(bytes),
          password,
        );
      } catch (e) {
        return BackupResult.failure('Password errata o backup corrotto');
      }

      // Salva come nuovo database
      final dbPath = await AppDatabase.getDatabasePath();
      final tempPath = '$dbPath.restore';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);

      // Rinomina: backup dell'attuale e sostituzione
      final currentDb = File(dbPath);
      if (await currentDb.exists()) {
        final backupPath = '$dbPath.old';
        await currentDb.rename(backupPath);
        // Cancella dopo il restore riuscito
        await File(backupPath).delete();
      }

      await tempFile.rename(dbPath);

      return BackupResult.success(
        message: 'Ripristino completato con successo',
        backupDate: backupInfo.modifiedTime,
      );
    } catch (e) {
      return BackupResult.failure('Errore durante il ripristino: $e');
    }
  }

  /// Esporta il database localmente (per backup manuale)
  Future<String?> exportLocally(String password) async {
    if (!CryptoService.isValidPassword(password)) {
      return null;
    }

    try {
      final dbPath = await AppDatabase.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return null;
      }

      // Cifra il database con password
      final encryptedBytes =
          await _cryptoService.encryptFileWithPassword(dbFile, password);

      // Salva nella directory documenti
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportPath = '${docsDir.path}/injecare_backup_$timestamp.enc';
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(encryptedBytes);

      return exportPath;
    } catch (e) {
      return null;
    }
  }

  /// Importa un backup da file locale
  Future<BackupResult> importFromFile(String filePath, String password) async {
    if (!CryptoService.isValidPassword(password)) {
      return BackupResult.failure('Password non valida');
    }

    try {
      final importFile = File(filePath);
      if (!await importFile.exists()) {
        return BackupResult.failure('File non trovato');
      }

      final encryptedBytes = await importFile.readAsBytes();

      final Uint8List decryptedBytes;
      try {
        decryptedBytes = _cryptoService.decryptBytesWithPassword(
          encryptedBytes,
          password,
        );
      } catch (e) {
        return BackupResult.failure('Password errata o file corrotto');
      }

      // Salva come nuovo database
      final dbPath = await AppDatabase.getDatabasePath();
      final currentDb = File(dbPath);

      if (await currentDb.exists()) {
        await currentDb.delete();
      }

      await currentDb.writeAsBytes(decryptedBytes);

      return BackupResult.success(
        message: 'Import completato con successo',
        backupDate: DateTime.now(),
      );
    } catch (e) {
      return BackupResult.failure('Errore durante l\'import: $e');
    }
  }

  /// Cancella il backup da Google Drive
  Future<BackupResult> deleteBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.failure('Non autenticato con Google Drive');
      }

      final backupInfo = await checkForBackup();
      if (backupInfo == null) {
        return BackupResult.success(message: 'Nessun backup da cancellare');
      }

      await driveApi.files.delete(backupInfo.id);

      return BackupResult.success(message: 'Backup cancellato');
    } catch (e) {
      return BackupResult.failure('Errore durante la cancellazione: $e');
    }
  }
}
