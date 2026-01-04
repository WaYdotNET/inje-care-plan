import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/features/injection/zone_provider.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ZoneActions zoneActions;

  setUp(() async {
    db = createTestDatabase();
    zoneActions = ZoneActions(db);
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  group('ZoneActions - CRUD operations', () {
    test('addZone creates new zone with next sortOrder', () async {
      final initialZones = await db.getAllZones();
      final maxOrder = initialZones.map((z) => z.sortOrder).reduce((a, b) => a > b ? a : b);

      final id = await zoneActions.addZone(
        code: 'CZ',
        name: 'Custom Zone',
        customName: 'My Zone',
        icon: '⭐',
        numberOfPoints: 5,
      );

      expect(id, greaterThan(0));

      final newZone = await db.getZoneById(id);
      expect(newZone, isNotNull);
      expect(newZone!.code, 'CZ');
      expect(newZone.name, 'Custom Zone');
      expect(newZone.customName, 'My Zone');
      expect(newZone.icon, '⭐');
      expect(newZone.numberOfPoints, 5);
      expect(newZone.sortOrder, maxOrder + 1);
      expect(newZone.type, 'custom');
      expect(newZone.side, 'none');
    });

    test('addZone creates zone with custom type and side', () async {
      final id = await zoneActions.addZone(
        code: 'CU',
        name: 'Custom Upper',
        type: 'arm',
        side: 'left',
      );

      final newZone = await db.getZoneById(id);
      expect(newZone!.type, 'arm');
      expect(newZone.side, 'left');
    });

    test('updateZone modifies code', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        code: 'NEW',
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.code, 'NEW');
    });

    test('updateZone modifies name', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        name: 'New Zone Name',
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.name, 'New Zone Name');
    });

    test('updateZone modifies customName', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        customName: 'My Custom Name',
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.customName, 'My Custom Name');
    });

    test('updateZone modifies icon', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        icon: '💉',
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.icon, '💉');
    });

    test('updateZone modifies numberOfPoints', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        numberOfPoints: 12,
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.numberOfPoints, 12);
    });

    test('updateZone modifies isEnabled', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        isEnabled: false,
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.isEnabled, isFalse);
    });

    test('updateZone modifies sortOrder', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        sortOrder: 99,
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.sortOrder, 99);
    });

    test('updateZone modifies type and side', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        type: 'abdomen',
        side: 'center',
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.type, 'abdomen');
      expect(updated.side, 'center');
    });

    test('updateZone modifies multiple fields at once', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateZone(
        id: zone.id,
        name: 'Updated Name',
        customName: 'Custom Updated',
        numberOfPoints: 8,
        isEnabled: false,
      );

      final updated = await db.getZoneById(zone.id);
      expect(updated!.name, 'Updated Name');
      expect(updated.customName, 'Custom Updated');
      expect(updated.numberOfPoints, 8);
      expect(updated.isEnabled, isFalse);
    });

    test('deleteZone removes zone', () async {
      final zones = await db.getAllZones();
      final zoneToDelete = zones.last;

      await zoneActions.deleteZone(zoneToDelete.id);

      final deletedZone = await db.getZoneById(zoneToDelete.id);
      expect(deletedZone, isNull);
    });

    test('updatePointCount updates numberOfPoints', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updatePointCount(zone.id, 10);

      final updated = await db.getZoneById(zone.id);
      expect(updated!.numberOfPoints, 10);
    });

    test('updateCustomName updates customName', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateCustomName(zone.id, 'New Custom');

      final updated = await db.getZoneById(zone.id);
      expect(updated!.customName, 'New Custom');
    });

    test('updateCustomName sets null', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      // First set a custom name
      await zoneActions.updateCustomName(zone.id, 'Temp Name');
      
      // Then clear it
      await zoneActions.updateCustomName(zone.id, null);

      final updated = await db.getZoneById(zone.id);
      expect(updated!.customName, isNull);
    });

    test('updateIcon updates icon', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateIcon(zone.id, '🌟');

      final updated = await db.getZoneById(zone.id);
      expect(updated!.icon, '🌟');
    });

    test('updateIcon sets null', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.updateIcon(zone.id, '⭐');
      await zoneActions.updateIcon(zone.id, null);

      final updated = await db.getZoneById(zone.id);
      expect(updated!.icon, isNull);
    });

    test('toggleEnabled enables zone', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.toggleEnabled(zone.id, false);
      var updated = await db.getZoneById(zone.id);
      expect(updated!.isEnabled, isFalse);

      await zoneActions.toggleEnabled(zone.id, true);
      updated = await db.getZoneById(zone.id);
      expect(updated!.isEnabled, isTrue);
    });

    test('reorderZones updates sortOrder for all zones', () async {
      final zones = await db.getAllZones();
      final originalOrder = zones.map((z) => z.id).toList();
      
      // Reverse the order
      final newOrder = originalOrder.reversed.toList();

      await zoneActions.reorderZones(newOrder);

      final reorderedZones = await db.getAllZones();
      for (var i = 0; i < reorderedZones.length; i++) {
        expect(reorderedZones[i].id, newOrder[i]);
        expect(reorderedZones[i].sortOrder, i + 1);
      }
    });
  });

  group('ZoneActions - Blacklist operations', () {
    test('blacklistPoint adds point to blacklist', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.blacklistPoint(
        pointCode: 'CD-1',
        pointLabel: 'Coscia Dx - 1',
        zoneId: zone.id,
        pointNumber: 1,
        reason: 'scar',
        notes: 'Test note',
      );

      final isBlacklisted = await db.isPointBlacklisted('CD-1');
      expect(isBlacklisted, isTrue);

      final blacklistedPoints = await db.getAllBlacklistedPoints();
      expect(blacklistedPoints.length, 1);
      expect(blacklistedPoints.first.pointCode, 'CD-1');
      expect(blacklistedPoints.first.reason, 'scar');
      expect(blacklistedPoints.first.notes, 'Test note');
    });

    test('blacklistPoint works without reason and notes', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await zoneActions.blacklistPoint(
        pointCode: 'CD-2',
        pointLabel: 'Coscia Dx - 2',
        zoneId: zone.id,
        pointNumber: 2,
      );

      final blacklistedPoints = await db.getAllBlacklistedPoints();
      expect(blacklistedPoints.length, 1);
      expect(blacklistedPoints.first.reason, '');
      expect(blacklistedPoints.first.notes, '');
    });

    test('removeFromBlacklist removes point', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zone.id,
        pointNumber: 1,
      ));

      var isBlacklisted = await db.isPointBlacklisted('CD-1');
      expect(isBlacklisted, isTrue);

      await zoneActions.removeFromBlacklist('CD-1');

      isBlacklisted = await db.isPointBlacklisted('CD-1');
      expect(isBlacklisted, isFalse);
    });

    test('isPointBlacklisted returns correct value', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      expect(await zoneActions.isPointBlacklisted('CD-1'), isFalse);

      await db.insertBlacklistedPoint(BlacklistedPointsCompanion.insert(
        pointCode: 'CD-1',
        pointLabel: 'Test',
        zoneId: zone.id,
        pointNumber: 1,
      ));

      expect(await zoneActions.isPointBlacklisted('CD-1'), isTrue);
      expect(await zoneActions.isPointBlacklisted('CD-2'), isFalse);
    });
  });
}
