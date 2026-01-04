import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../database/app_database.dart';

/// Risultato del check all'avvio
enum StartupCheckResult {
  /// Database locale esiste, avvio normale
  normalStart,

  /// Nessun database locale - prima esecuzione
  firstRun,

  /// Errore durante il check
  error,
}

/// Info dettagliate sul risultato dello startup check
class StartupInfo {
  final StartupCheckResult result;
  final String? errorMessage;

  StartupInfo({
    required this.result,
    this.errorMessage,
  });
}

/// Servizio per gestire la logica di avvio dell'app
class StartupService {
  StartupService();

  /// Controlla lo stato all'avvio
  /// - Se esiste DB locale -> avvio normale
  /// - Se non esiste DB locale -> prima esecuzione
  Future<StartupInfo> checkStartupState() async {
    try {
      // Su web, controlliamo in modo diverso
      if (kIsWeb) {
        // Per web, assumiamo sempre che il database esista (IndexedDB)
        return StartupInfo(result: StartupCheckResult.normalStart);
      }

      // Verifica se esiste il database locale
      final dbPath = await AppDatabase.getDatabasePath();
      final dbFile = File(dbPath);
      final dbExists = await dbFile.exists();

      if (dbExists) {
        return StartupInfo(result: StartupCheckResult.normalStart);
      }

      // Database non esiste, prima esecuzione
      return StartupInfo(result: StartupCheckResult.firstRun);
    } catch (e) {
      return StartupInfo(
        result: StartupCheckResult.error,
        errorMessage: e.toString(),
      );
    }
  }
}
