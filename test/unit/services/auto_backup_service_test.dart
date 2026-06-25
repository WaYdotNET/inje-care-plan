import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/auto_backup_service.dart';
import 'package:injecare_plan/core/services/auto_backup_settings.dart';
import 'package:injecare_plan/core/services/backup_destination.dart';
import 'package:injecare_plan/core/services/crypto_service.dart';

/// Destinazione fake in memoria per testare l'orchestratore senza I/O.
class FakeBackupDestination implements BackupDestination {
  FakeBackupDestination({this.available = true});

  bool available;
  final Map<String, Uint8List> files = {};
  final List<BackupFileInfo> deleted = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> writeBackup(String filename, Uint8List bytes) async {
    files[filename] = bytes;
  }

  @override
  Future<List<BackupFileInfo>> listBackups() async => files.keys
      .map((name) => BackupFileInfo(id: name, filename: name))
      .toList();

  @override
  Future<void> deleteBackup(BackupFileInfo info) async {
    deleted.add(info);
    files.remove(info.filename);
  }

  @override
  String? get label => 'Fake';
}

void main() {
  final fixedNow = DateTime(2026, 6, 25, 20, 0, 0);
  Future<Uint8List> jsonBytes() async =>
      Uint8List.fromList(utf8.encode('{"version":2}'));
  Future<String?> noPassword() async => null;
  Future<String?> withPassword() async => 'password123';

  group('isDue', () {
    test('true quando non c\'è mai stato un backup', () {
      expect(
        AutoBackupService.isDue(null, BackupFrequency.daily, fixedNow),
        isTrue,
      );
    });

    test('false se l\'ultimo backup è troppo recente (daily)', () {
      final last = fixedNow.subtract(const Duration(hours: 12));
      expect(
        AutoBackupService.isDue(last, BackupFrequency.daily, fixedNow),
        isFalse,
      );
    });

    test('true se è passato più dell\'intervallo (daily)', () {
      final last = fixedNow.subtract(const Duration(days: 1, minutes: 1));
      expect(
        AutoBackupService.isDue(last, BackupFrequency.daily, fixedNow),
        isTrue,
      );
    });

    test('rispetta l\'intervallo settimanale', () {
      final last = fixedNow.subtract(const Duration(days: 3));
      expect(
        AutoBackupService.isDue(last, BackupFrequency.weekly, fixedNow),
        isFalse,
      );
      final older = fixedNow.subtract(const Duration(days: 8));
      expect(
        AutoBackupService.isDue(older, BackupFrequency.weekly, fixedNow),
        isTrue,
      );
    });
  });

  group('selectBackupsToDelete', () {
    List<BackupFileInfo> infos(List<String> names) =>
        names.map((n) => BackupFileInfo(id: n, filename: n)).toList();

    test('non cancella nulla se entro la ritenzione', () {
      final all = infos([
        'injecare-backup-20260601-200000.json',
        'injecare-backup-20260602-200000.json',
      ]);
      expect(AutoBackupService.selectBackupsToDelete(all, 7), isEmpty);
    });

    test('mantiene i N più recenti e cancella i più vecchi', () {
      final all = infos([
        'injecare-backup-20260601-200000.json',
        'injecare-backup-20260603-200000.json',
        'injecare-backup-20260602-200000.json',
        'injecare-backup-20260604-200000.json',
      ]);
      final toDelete = AutoBackupService.selectBackupsToDelete(all, 2);
      final names = toDelete.map((e) => e.filename).toSet();
      // I due più vecchi (01 e 02) vengono cancellati.
      expect(names, {
        'injecare-backup-20260601-200000.json',
        'injecare-backup-20260602-200000.json',
      });
    });
  });

  group('buildFilename', () {
    test('chiaro vs cifrato', () {
      expect(
        AutoBackupService.buildFilename(fixedNow, encrypted: false),
        'injecare-backup-20260625-200000.json',
      );
      expect(
        AutoBackupService.buildFilename(fixedNow, encrypted: true),
        'injecare-backup-20260625-200000.json.enc',
      );
    });
  });

  group('maybeRunBackup', () {
    late AutoBackupService service;
    late FakeBackupDestination dest;

    setUp(() {
      service = AutoBackupService();
      dest = FakeBackupDestination();
    });

    test('salta se disabilitato', () async {
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: false),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.skippedDisabled);
      expect(dest.files, isEmpty);
    });

    test('salta se non è ancora scaduto', () async {
      final outcome = await service.maybeRunBackup(
        settings: AutoBackupSettings(
          enabled: true,
          encrypted: false,
          lastAutoBackupAt: fixedNow.subtract(const Duration(hours: 1)),
        ),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.skippedNotDue);
    });

    test('salta se la destinazione non è disponibile', () async {
      dest.available = false;
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: true, encrypted: false),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.skippedNoDestination);
    });

    test('cifratura attiva ma password assente → failedNoPassword', () async {
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: true, encrypted: true),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.failedNoPassword);
      expect(dest.files, isEmpty);
    });

    test('scrive un backup in chiaro e aggiorna lastAutoBackupAt', () async {
      DateTime? ranAt;
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: true, encrypted: false),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (t) async => ranAt = t,
      );
      expect(outcome.status, AutoBackupStatus.success);
      expect(dest.files.keys.single,
          'injecare-backup-20260625-200000.json');
      expect(ranAt, fixedNow);
      // In chiaro: i byte sono il JSON leggibile.
      expect(utf8.decode(dest.files.values.single), '{"version":2}');
    });

    test('scrive un backup cifrato ripristinabile con la password', () async {
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: true, encrypted: true),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: withPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.success);
      final name = dest.files.keys.single;
      expect(name.endsWith('.json.enc'), isTrue);
      // Round-trip: decifrando con la stessa password torna il JSON originale.
      final decrypted = CryptoService()
          .decryptBytesWithPassword(dest.files.values.single, 'password123');
      expect(utf8.decode(decrypted), '{"version":2}');
    });

    test('applica la ritenzione cancellando i backup eccedenti', () async {
      // Pre-popola 3 backup vecchi; ritenzione = 2 → ne resta 2 dopo la scrittura.
      dest.files['injecare-backup-20260601-200000.json'] =
          Uint8List.fromList([1]);
      dest.files['injecare-backup-20260602-200000.json'] =
          Uint8List.fromList([2]);
      dest.files['injecare-backup-20260603-200000.json'] =
          Uint8List.fromList([3]);

      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(
          enabled: true,
          encrypted: false,
          retentionCount: 2,
        ),
        destination: dest,
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.success);
      // Dopo scrittura del nuovo (20260625) + ritenzione=2 restano i 2 più recenti.
      expect(dest.files.length, 2);
      expect(dest.files.containsKey('injecare-backup-20260625-200000.json'),
          isTrue);
      expect(dest.files.containsKey('injecare-backup-20260603-200000.json'),
          isTrue);
    });

    test('non lancia: un errore di scrittura diventa failed', () async {
      final outcome = await service.maybeRunBackup(
        settings: const AutoBackupSettings(enabled: true, encrypted: false),
        destination: _ThrowingDestination(),
        now: fixedNow,
        buildJsonBytes: jsonBytes,
        readPassword: noPassword,
        onSuccess: (_) async {},
      );
      expect(outcome.status, AutoBackupStatus.failed);
    });
  });
}

class _ThrowingDestination implements BackupDestination {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> writeBackup(String filename, Uint8List bytes) async =>
      throw StateError('disco pieno');
  @override
  Future<List<BackupFileInfo>> listBackups() async => [];
  @override
  Future<void> deleteBackup(BackupFileInfo info) async {}
  @override
  String? get label => null;
}
