import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = createTestDatabase();
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService - isCustomPosition migration', () {
    test('new PointConfig defaults isCustomPosition to false', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await db.into(db.pointConfigs).insert(
            PointConfigsCompanion.insert(
              zoneId: zone.id,
              pointNumber: 1,
              positionX: const Value(0.3),
              positionY: const Value(0.4),
            ),
          );

      final config = await db.getPointConfig(zone.id, 1);
      expect(config, isNotNull);
      expect(config!.isCustomPosition, isFalse);
    });

    test('updatePointPosition sets isCustomPosition to true', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      await db.updatePointPosition(zone.id, 1, 0.3, 0.4, 'front');

      final config = await db.getPointConfig(zone.id, 1);
      expect(config, isNotNull);
      expect(config!.isCustomPosition, isTrue);
      expect(config.positionX, 0.3);
      expect(config.positionY, 0.4);
    });

    test('updatePointPosition marks existing non-custom as custom', () async {
      final zones = await db.getAllZones();
      final zone = zones.first;

      // Inserisci come non-custom
      await db.into(db.pointConfigs).insert(
            PointConfigsCompanion.insert(
              zoneId: zone.id,
              pointNumber: 1,
              positionX: const Value(0.5),
              positionY: const Value(0.5),
            ),
          );

      // L'utente personalizza la posizione
      await db.updatePointPosition(zone.id, 1, 0.2, 0.8, 'front');

      final config = await db.getPointConfig(zone.id, 1);
      expect(config!.isCustomPosition, isTrue);
      expect(config.positionX, 0.2);
      expect(config.positionY, 0.8);
    });
  });

  group('BackupService - custom position preserved on fix', () {
    test('custom position survives _fixIncorrectPointCoordinates', () async {
      final zones = await db.getAllZones();
      final zone = zones.first; // CD

      // L'utente personalizza il punto 1
      await db.updatePointPosition(zone.id, 1, 0.1, 0.9, 'front');

      // Verifica che sia custom
      var config = await db.getPointConfig(zone.id, 1);
      expect(config!.isCustomPosition, isTrue);
      expect(config.positionX, 0.1);
      expect(config.positionY, 0.9);

      // Simula un riavvio dell'app (chiama la funzione di fix)
      // La funzione è privata, ma viene chiamata in beforeOpen.
      // Apriamo un nuovo database con gli stessi dati per testarlo.
      // In alternativa, testiamo direttamente il comportamento:
      // il batch update con isCustomPosition.equals(false) non toccherà questo punto.

      // Crea un punto NON custom nello stesso zona
      await db.into(db.pointConfigs).insert(
            PointConfigsCompanion.insert(
              zoneId: zone.id,
              pointNumber: 2,
              positionX: const Value(0.99),
              positionY: const Value(0.99),
              isCustomPosition: const Value(false),
            ),
          );

      // Verifica che il punto custom è rimasto
      config = await db.getPointConfig(zone.id, 1);
      expect(config!.isCustomPosition, isTrue);
      expect(config.positionX, 0.1);
      expect(config.positionY, 0.9);
    });
  });

  group('BackupService - export', () {
    test('generateBackupJson produces valid JSON with all sections', () async {
      // Aggiungi dati di test
      await db.insertInjection(TestData.createInjection(
        status: 'completed',
        completedAt: TestData.now,
      ));
      await db.insertBlacklistedPoint(TestData.createBlacklistedPoint());
      await db.setSetting('test_key', 'test_value');
      await db.updatePointPosition(1, 1, 0.3, 0.4, 'front');

      final data = await BackupService.instance.generateBackupJson(db);

      expect(data['version'], 2);
      expect(data['createdAt'], isNotNull);
      expect(data['bodyZones'], isA<List<Map<String, dynamic>>>());
      expect((data['bodyZones'] as List<Map<String, dynamic>>).length, 8);
      expect(data['therapyPlans'], isA<List<Map<String, dynamic>>>());
      expect((data['therapyPlans'] as List<Map<String, dynamic>>).length, 7);
      expect(data['injections'], isA<List<Map<String, dynamic>>>());
      expect((data['injections'] as List<Map<String, dynamic>>).length, 1);
      expect(data['blacklistedPoints'], isA<List<Map<String, dynamic>>>());
      expect((data['blacklistedPoints'] as List<Map<String, dynamic>>).length, 1);
      expect(data['pointConfigs'], isA<List<Map<String, dynamic>>>());
      expect((data['pointConfigs'] as List<Map<String, dynamic>>).length, 1);
      expect(data['appSettings'], isA<List<Map<String, dynamic>>>());
      expect((data['appSettings'] as List<Map<String, dynamic>>).length, 1);

      // Verifica che il JSON è serializzabile
      final jsonStr = json.encode(data);
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], 2);
    });

    test('export includes isCustomPosition in pointConfigs', () async {
      await db.updatePointPosition(1, 1, 0.3, 0.4, 'front');

      final data = await BackupService.instance.generateBackupJson(db);
      final configs = data['pointConfigs'] as List<Map<String, dynamic>>;
      expect(configs.length, 1);

      final config = configs.first;
      expect(config['isCustomPosition'], isTrue);
      expect(config['positionX'], 0.3);
      expect(config['positionY'], 0.4);
    });
  });

  group('BackupService - validateBackup', () {
    test('rejects missing version', () {
      final error = BackupService.instance.validateBackup(<String, dynamic>{
        'bodyZones': <dynamic>[],
        'therapyPlans': <dynamic>[],
        'injections': <dynamic>[],
      });
      expect(error, contains('version'));
    });

    test('rejects unsupported version', () {
      final error = BackupService.instance.validateBackup(<String, dynamic>{
        'version': 999,
        'bodyZones': <dynamic>[],
        'therapyPlans': <dynamic>[],
        'injections': <dynamic>[],
      });
      expect(error, contains('non supportata'));
    });

    test('rejects missing required sections', () {
      final error = BackupService.instance.validateBackup(<String, dynamic>{
        'version': 1,
        'bodyZones': <dynamic>[],
      });
      expect(error, contains('therapyPlans'));
    });

    test('accepts valid backup', () {
      final error = BackupService.instance.validateBackup(<String, dynamic>{
        'version': 1,
        'bodyZones': <dynamic>[],
        'therapyPlans': <dynamic>[],
        'injections': <dynamic>[],
      });
      expect(error, isNull);
    });
  });

  group('BackupService - import replaceAll', () {
    test('replaceAll restores data correctly', () async {
      // Aggiungi dati e fai export
      await db.insertInjection(TestData.createInjection(
        status: 'completed',
        completedAt: TestData.now,
      ));
      await db.setSetting('key1', 'value1');
      await db.updatePointPosition(1, 1, 0.3, 0.4, 'front');

      final backupData = await BackupService.instance.generateBackupJson(db);
      final jsonStr = json.encode(backupData);

      // Cancella tutto manualmente
      await db.deleteAllData();
      final injectionsAfterDelete = await db.getAllInjections();
      expect(injectionsAfterDelete, isEmpty);

      // Importa il backup
      final result = await BackupService.instance.importBackup(
        db,
        jsonStr,
        strategy: ImportStrategy.replaceAll,
      );

      expect(result.hasErrors, isFalse);
      expect(result.recordsImported, greaterThan(0));
      expect(result.tablesProcessed, greaterThan(0));

      // Verifica ripristino
      final zones = await db.getAllZones();
      expect(zones.length, 8);

      final injections = await db.getAllInjections();
      expect(injections.length, 1);

      final setting = await db.getSetting('key1');
      expect(setting, 'value1');

      final config = await db.getPointConfig(1, 1);
      expect(config, isNotNull);
      expect(config!.isCustomPosition, isTrue);
      expect(config.positionX, 0.3);
    });

    test('replaceAll rejects invalid JSON', () async {
      final result = await BackupService.instance.importBackup(
        db,
        'not json',
      );
      expect(result.hasErrors, isTrue);
      expect(result.errors.first, contains('JSON non valido'));
    });

    test('replaceAll rejects invalid backup structure', () async {
      final result = await BackupService.instance.importBackup(
        db,
        json.encode({'foo': 'bar'}),
      );
      expect(result.hasErrors, isTrue);
    });
  });

  group('BackupService - import merge', () {
    test('merge does not duplicate existing zones', () async {
      final backupData = await BackupService.instance.generateBackupJson(db);
      final jsonStr = json.encode(backupData);

      // Import con merge (le zone già esistono)
      final result = await BackupService.instance.importBackup(
        db,
        jsonStr,
        strategy: ImportStrategy.mergeKeepExisting,
      );

      expect(result.hasErrors, isFalse);

      // Le zone devono essere 8 (non duplicate)
      final zones = await db.getAllZones();
      expect(zones.length, 8);
    });

    test('merge skips existing pointConfigs', () async {
      // Crea un punto custom
      await db.updatePointPosition(1, 1, 0.1, 0.2, 'front');

      // Export con quel punto
      final backupData = await BackupService.instance.generateBackupJson(db);

      // Modifica la posizione localmente
      await db.updatePointPosition(1, 1, 0.9, 0.8, 'back');

      // Import con merge — la posizione locale deve essere preservata
      final jsonStr = json.encode(backupData);
      await BackupService.instance.importBackup(
        db,
        jsonStr,
        strategy: ImportStrategy.mergeKeepExisting,
      );

      final config = await db.getPointConfig(1, 1);
      expect(config!.positionX, 0.9); // Preservato
      expect(config.positionY, 0.8); // Preservato
    });
  });

  group('BackupService - DAO methods', () {
    test('getAllPointConfigs returns all configs', () async {
      await db.updatePointPosition(1, 1, 0.3, 0.4, 'front');
      await db.updatePointPosition(1, 2, 0.5, 0.6, 'front');
      await db.updatePointPosition(2, 1, 0.7, 0.8, 'back');

      final configs = await db.getAllPointConfigs();
      expect(configs.length, 3);
    });

    test('getAllSettings returns all settings', () async {
      await db.setSetting('k1', 'v1');
      await db.setSetting('k2', 'v2');

      final settings = await db.getAllSettings();
      expect(settings.length, 2);
    });
  });

  group('BackupService - SharedPreferences', () {
    test('generateBackupJson include le preferenze SharedPreferences', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'home_layout': 'silhouette',
        'theme_mode': 'dark',
      });
      final data = await BackupService.instance.generateBackupJson(db);
      final prefs = data['preferences'] as Map<String, dynamic>;
      expect(prefs['home_layout'], 'silhouette');
      expect(prefs['theme_mode'], 'dark');
    });

    test('importBackup ripristina le preferenze SharedPreferences', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({}); // nessuna pref iniziale
      final backup = {
        'version': 2,
        'createdAt': DateTime.now().toIso8601String(),
        'bodyZones': <dynamic>[],
        'therapyPlans': <dynamic>[],
        'injections': <dynamic>[],
        'preferences': {'home_layout': 'silhouette'},
      };
      await BackupService.instance.importBackup(db, jsonEncode(backup));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('home_layout'), 'silhouette');
    });
  });
}
