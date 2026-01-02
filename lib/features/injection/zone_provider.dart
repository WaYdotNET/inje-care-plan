import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../models/body_zone.dart' as model;

/// Provider per le zone dal database (stream reattivo)
final zonesProvider = StreamProvider<List<model.BodyZone>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllZones().map((zones) => zones.map(_toModelZone).toList());
});

/// Provider per le zone abilitate (stream reattivo)
final enabledZonesProvider = StreamProvider<List<model.BodyZone>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEnabledZones().map(
    (zones) => zones.map(_toModelZone).toList(),
  );
});

/// Provider per i punti blacklistati (stream reattivo)
final blacklistedPointsProvider = StreamProvider<List<BlacklistedPoint>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBlacklistedPoints();
});

/// Provider per le operazioni sulle zone
final zoneActionsProvider = Provider<ZoneActions>((ref) {
  return ZoneActions(ref.watch(databaseProvider));
});

/// Classe per le operazioni CRUD sulle zone
class ZoneActions {
  ZoneActions(this._db);

  final AppDatabase _db;

  /// Aggiunge una nuova zona custom
  Future<int> addZone({
    required String code,
    required String name,
    String? customName,
    String? icon,
    String type = 'custom',
    String side = 'none',
    int numberOfPoints = 4,
  }) async {
    final zones = await _db.getAllZones();
    final maxOrder = zones.fold<int>(
      0,
      (max, z) => z.sortOrder > max ? z.sortOrder : max,
    );

    return _db.insertZone(
      BodyZonesCompanion.insert(
        code: code,
        name: name,
        customName: Value(customName),
        icon: Value(icon),
        type: Value(type),
        side: Value(side),
        numberOfPoints: Value(numberOfPoints),
        sortOrder: Value(maxOrder + 1),
      ),
    );
  }

  /// Aggiorna una zona esistente
  Future<void> updateZone({
    required int id,
    String? code,
    String? name,
    String? customName,
    String? icon,
    String? type,
    String? side,
    int? numberOfPoints,
    bool? isEnabled,
    int? sortOrder,
  }) async {
    await _db.updateZone(
      BodyZonesCompanion(
        id: Value(id),
        code: code != null ? Value(code) : const Value.absent(),
        name: name != null ? Value(name) : const Value.absent(),
        customName: customName != null
            ? Value(customName)
            : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        side: side != null ? Value(side) : const Value.absent(),
        numberOfPoints: numberOfPoints != null
            ? Value(numberOfPoints)
            : const Value.absent(),
        isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina una zona
  Future<void> deleteZone(int id) async {
    await _db.deleteZone(id);
  }

  /// Aggiorna il numero di punti per una zona
  Future<void> updatePointCount(int zoneId, int count) async {
    await _db.updateZonePointCount(zoneId, count);
  }

  /// Aggiorna il nome personalizzato
  Future<void> updateCustomName(int zoneId, String? customName) async {
    await _db.updateZoneCustomName(zoneId, customName);
  }

  /// Aggiorna l'icona
  Future<void> updateIcon(int zoneId, String? icon) async {
    await _db.updateZoneIcon(zoneId, icon);
  }

  /// Abilita/disabilita una zona
  Future<void> toggleEnabled(int zoneId, bool enabled) async {
    await _db.toggleZoneEnabled(zoneId, enabled);
  }

  /// Riordina le zone
  Future<void> reorderZones(List<int> zoneIdsInOrder) async {
    await _db.reorderZones(zoneIdsInOrder);
  }

  /// Aggiunge un punto alla blacklist
  Future<void> blacklistPoint({
    required String pointCode,
    required String pointLabel,
    required int zoneId,
    required int pointNumber,
    String? reason,
    String? notes,
  }) async {
    await _db.insertBlacklistedPoint(
      BlacklistedPointsCompanion.insert(
        pointCode: pointCode,
        pointLabel: pointLabel,
        zoneId: zoneId,
        pointNumber: pointNumber,
        reason: Value(reason ?? ''),
        notes: Value(notes ?? ''),
      ),
    );
  }

  /// Rimuove un punto dalla blacklist
  Future<void> removeFromBlacklist(String pointCode) async {
    await _db.removeBlacklistedPoint(pointCode);
  }

  /// Verifica se un punto è in blacklist
  Future<bool> isPointBlacklisted(String pointCode) async {
    return _db.isPointBlacklisted(pointCode);
  }
}

/// Converte un BodyZone dal database al modello dell'app
model.BodyZone _toModelZone(BodyZone dbZone) {
  return model.BodyZone(
    id: dbZone.id,
    code: dbZone.code,
    name: dbZone.name,
    customName: dbZone.customName,
    icon: dbZone.icon,
    type: dbZone.type,
    side: dbZone.side,
    numberOfPoints: dbZone.numberOfPoints,
    isEnabled: dbZone.isEnabled,
    sortOrder: dbZone.sortOrder,
  );
}
