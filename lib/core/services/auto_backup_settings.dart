import 'package:shared_preferences/shared_preferences.dart';

/// Frequenza del backup automatico.
enum BackupFrequency {
  daily,
  weekly;

  /// Intervallo minimo tra due backup automatici.
  Duration get interval => switch (this) {
        BackupFrequency.daily => const Duration(days: 1),
        BackupFrequency.weekly => const Duration(days: 7),
      };

  String get storageValue => name;

  static BackupFrequency fromStorage(String? value) =>
      BackupFrequency.values.firstWhere(
        (f) => f.name == value,
        orElse: () => BackupFrequency.daily,
      );
}

/// Impostazioni del backup automatico locale, persistite in SharedPreferences.
///
/// La password di cifratura NON è qui: vive nel secure storage del dispositivo
/// (vedi [AutoBackupService] / provider). Qui c'è solo il flag [encrypted].
class AutoBackupSettings {
  const AutoBackupSettings({
    this.enabled = false,
    this.frequency = BackupFrequency.daily,
    this.encrypted = true,
    this.retentionCount = 7,
    this.destinationToken,
    this.destinationLabel,
    this.lastAutoBackupAt,
  });

  final bool enabled;
  final BackupFrequency frequency;
  final bool encrypted;
  final int retentionCount;

  /// Token opaco che identifica la destinazione (tree-URI SAF su Android,
  /// chiave dell'handle su Web). Null se non ancora scelta.
  final String? destinationToken;

  /// Nome leggibile della cartella, mostrato in UI.
  final String? destinationLabel;

  final DateTime? lastAutoBackupAt;

  bool get hasDestination =>
      destinationToken != null && destinationToken!.isNotEmpty;

  AutoBackupSettings copyWith({
    bool? enabled,
    BackupFrequency? frequency,
    bool? encrypted,
    int? retentionCount,
    String? destinationToken,
    String? destinationLabel,
    DateTime? lastAutoBackupAt,
    bool clearDestination = false,
    bool clearLastBackup = false,
  }) =>
      AutoBackupSettings(
        enabled: enabled ?? this.enabled,
        frequency: frequency ?? this.frequency,
        encrypted: encrypted ?? this.encrypted,
        retentionCount: retentionCount ?? this.retentionCount,
        destinationToken:
            clearDestination ? null : (destinationToken ?? this.destinationToken),
        destinationLabel:
            clearDestination ? null : (destinationLabel ?? this.destinationLabel),
        lastAutoBackupAt:
            clearLastBackup ? null : (lastAutoBackupAt ?? this.lastAutoBackupAt),
      );

  // --- Persistenza (SharedPreferences) ---

  static const _kEnabled = 'auto_backup_enabled';
  static const _kFrequency = 'auto_backup_frequency';
  static const _kEncrypted = 'auto_backup_encrypted';
  static const _kRetention = 'auto_backup_retention';
  static const _kToken = 'auto_backup_destination_token';
  static const _kLabel = 'auto_backup_destination_label';
  static const _kLastAt = 'auto_backup_last_at';

  static AutoBackupSettings fromPrefs(SharedPreferences prefs) {
    final lastMillis = prefs.getInt(_kLastAt);
    return AutoBackupSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      frequency: BackupFrequency.fromStorage(prefs.getString(_kFrequency)),
      encrypted: prefs.getBool(_kEncrypted) ?? true,
      retentionCount: prefs.getInt(_kRetention) ?? 7,
      destinationToken: prefs.getString(_kToken),
      destinationLabel: prefs.getString(_kLabel),
      lastAutoBackupAt: lastMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMillis)
          : null,
    );
  }

  Future<void> saveTo(SharedPreferences prefs) async {
    await prefs.setBool(_kEnabled, enabled);
    await prefs.setString(_kFrequency, frequency.storageValue);
    await prefs.setBool(_kEncrypted, encrypted);
    await prefs.setInt(_kRetention, retentionCount);
    if (destinationToken != null) {
      await prefs.setString(_kToken, destinationToken!);
    } else {
      await prefs.remove(_kToken);
    }
    if (destinationLabel != null) {
      await prefs.setString(_kLabel, destinationLabel!);
    } else {
      await prefs.remove(_kLabel);
    }
    if (lastAutoBackupAt != null) {
      await prefs.setInt(_kLastAt, lastAutoBackupAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kLastAt);
    }
  }
}
