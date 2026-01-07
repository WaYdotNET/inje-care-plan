import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

/// Risultato dell'import
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    this.errors = const [],
  });

  bool get hasErrors => errorCount > 0;
  int get totalProcessed => successCount + errorCount;
}

/// Service per importare dati da CSV
///
/// Formato CSV supportato:
/// ```
/// data,zona,punto,stato
/// 2024-07-15 20:00,CD,3,completed
/// 2024-07-17 20:00,CS,1,completed
/// ```
///
/// Zone code: CD, CS, BD, BS, AD, AS, GD, GS
/// Status: completed, scheduled, skipped, delayed
class ImportService {
  ImportService._();

  static final instance = ImportService._();

  /// Mappa zone code a zoneId e displayName
  static const _zoneMap = <String, ({int id, String name})>{
    'CD': (id: 1, name: 'Coscia Dx'),
    'CS': (id: 2, name: 'Coscia Sx'),
    'BD': (id: 3, name: 'Braccio Dx'),
    'BS': (id: 4, name: 'Braccio Sx'),
    'AD': (id: 5, name: 'Addome Dx'),
    'AS': (id: 6, name: 'Addome Sx'),
    'GD': (id: 7, name: 'Gluteo Dx'),
    'GS': (id: 8, name: 'Gluteo Sx'),
  };

  static const _validStatuses = ['completed', 'scheduled', 'skipped', 'delayed', 'missed'];

  /// Importa iniezioni da stringa CSV
  Future<ImportResult> importFromCsv(AppDatabase db, String csvContent) async {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return ImportResult(successCount: 0, errorCount: 0);
    }

    // Skip header if present
    int startIndex = 0;
    if (lines.first.toLowerCase().contains('data') ||
        lines.first.toLowerCase().contains('date')) {
      startIndex = 1;
    }

    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineNumber = i + 1;
      final result = await _parseLine(db, line, lineNumber);

      if (result.isSuccess) {
        successCount++;
      } else {
        errorCount++;
        errors.add('Riga $lineNumber: ${result.error}');
      }
    }

    return ImportResult(
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  Future<_ParseResult> _parseLine(AppDatabase db, String line, int lineNumber) async {
    try {
      final parts = line.split(',').map((p) => p.trim()).toList();

      if (parts.length < 4) {
        return _ParseResult.failure('Formato non valido (richiesti: data,zona,punto,stato)');
      }

      // Parse date (supporta più formati)
      final dateStr = parts[0];
      DateTime? date;

      // Try multiple date formats
      for (final format in [
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd',
        'dd/MM/yyyy HH:mm',
        'dd/MM/yyyy',
      ]) {
        try {
          date = DateFormat(format).parse(dateStr);
          break;
        } catch (_) {
          // Try next format
        }
      }

      if (date == null) {
        return _ParseResult.failure('Data non valida: $dateStr');
      }

      // Parse zone
      final zoneCode = parts[1].toUpperCase();
      final zoneInfo = _zoneMap[zoneCode];
      if (zoneInfo == null) {
        return _ParseResult.failure('Zona non valida: $zoneCode (usa: CD, CS, BD, BS, AD, AS, GD, GS)');
      }

      // Parse point number
      final pointNumber = int.tryParse(parts[2]);
      if (pointNumber == null || pointNumber < 1) {
        return _ParseResult.failure('Numero punto non valido: ${parts[2]}');
      }

      // Parse status
      final status = parts[3].toLowerCase();
      if (!_validStatuses.contains(status)) {
        return _ParseResult.failure(
          'Stato non valido: $status (usa: completed, scheduled, skipped, delayed, missed)',
        );
      }

      // Determine completedAt
      DateTime? completedAt;
      if (status == 'completed') {
        completedAt = date;
      }

      // Insert injection
      await db.insertInjection(InjectionsCompanion.insert(
        zoneId: zoneInfo.id,
        pointNumber: pointNumber,
        pointCode: '$zoneCode-$pointNumber',
        pointLabel: '${zoneInfo.name} · $pointNumber',
        scheduledAt: date,
        completedAt: Value(completedAt),
        status: Value(status),
        notes: const Value(''),
        sideEffects: const Value(''),
        calendarEventId: const Value(''),
      ));

      return _ParseResult.success();
    } catch (e) {
      return _ParseResult.failure('Errore: $e');
    }
  }
}

class _ParseResult {
  final bool isSuccess;
  final String? error;

  _ParseResult._(this.isSuccess, this.error);

  factory _ParseResult.success() => _ParseResult._(true, null);
  factory _ParseResult.failure(String error) => _ParseResult._(false, error);
}
