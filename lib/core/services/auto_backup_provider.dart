import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'auto_backup_service.dart';
import 'auto_backup_settings.dart';
import 'backup_destination_platform.dart';
import 'backup_service.dart';
import 'diagnostic_log_service.dart';

const _kPasswordKey = 'auto_backup_password';
const _secureStorage = FlutterSecureStorage();

/// Stato + persistenza delle impostazioni di backup automatico.
class AutoBackupController extends Notifier<AutoBackupSettings> {
  @override
  AutoBackupSettings build() {
    _load();
    return const AutoBackupSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AutoBackupSettings.fromPrefs(prefs);
  }

  Future<void> update(AutoBackupSettings next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await next.saveTo(prefs);
  }

  Future<void> setPassword(String password) =>
      _secureStorage.write(key: _kPasswordKey, value: password);

  Future<String?> readPassword() => _secureStorage.read(key: _kPasswordKey);

  Future<bool> hasPassword() async => (await readPassword())?.isNotEmpty == true;

  Future<void> clearPassword() => _secureStorage.delete(key: _kPasswordKey);
}

final autoBackupSettingsProvider =
    NotifierProvider<AutoBackupController, AutoBackupSettings>(
  AutoBackupController.new,
);

/// True se la piattaforma corrente supporta il backup automatico verso cartella.
final autoBackupSupportedProvider = Provider<bool>((_) => autoBackupSupported);

/// Esegue il backup automatico con dipendenze esplicite (così è invocabile sia
/// da un `Ref` di provider che da un `WidgetRef`). Con [force] ignora il
/// controllo "è scaduto?" (pulsante "Esegui backup ora").
Future<AutoBackupOutcome> _performBackup({
  required AutoBackupController controller,
  required AutoBackupSettings settings,
  required AppDatabase db,
  bool force = false,
}) async {
  if (!autoBackupSupported) {
    return const AutoBackupOutcome(AutoBackupStatus.skippedNoDestination);
  }
  final destination = resolveBackupDestination(
    settings.destinationToken,
    settings.destinationLabel,
  );
  final service = AutoBackupService();
  // Con force, azzera lastAutoBackupAt solo per il controllo di scadenza.
  final effective = force ? settings.copyWith(clearLastBackup: true) : settings;

  final outcome = await service.maybeRunBackup(
    settings: effective,
    destination: destination,
    now: DateTime.now(),
    buildJsonBytes: () async => AutoBackupService.jsonBytesFromMap(
      await BackupService.instance.generateBackupJson(db),
    ),
    readPassword: controller.readPassword,
    onSuccess: (ranAt) async {
      await controller.update(settings.copyWith(lastAutoBackupAt: ranAt));
      await db.updateLastBackupTime(ranAt);
    },
  );

  if (outcome.status == AutoBackupStatus.failed) {
    DiagnosticLogService.instance
        .logEvent('auto_backup', 'fallito: ${outcome.message}');
  }
  return outcome;
}

/// Esegue il backup dal contesto UI (pulsante "Esegui ora").
Future<AutoBackupOutcome> runAutoBackupNow(WidgetRef ref) => _performBackup(
      controller: ref.read(autoBackupSettingsProvider.notifier),
      settings: ref.read(autoBackupSettingsProvider),
      db: ref.read(databaseProvider),
      force: true,
    );

/// Trigger opportunistico: eseguito una volta per sessione (e ri-eseguito su
/// resume invalidandolo). Non blocca la UI e ignora gli esiti "saltato".
final autoBackupRunnerProvider = FutureProvider<AutoBackupOutcome>((ref) async {
  return _performBackup(
    controller: ref.read(autoBackupSettingsProvider.notifier),
    settings: ref.read(autoBackupSettingsProvider),
    db: ref.read(databaseProvider),
  );
});
