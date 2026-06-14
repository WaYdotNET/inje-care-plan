import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../utils/save_helper.dart'
    if (dart.library.io) '../utils/save_helper_mobile.dart'
    if (dart.library.html) '../utils/save_helper_web.dart';

/// Strategia di import per il backup JSON
enum ImportStrategy {
  /// Cancella tutto e reinserisce
  replaceAll,

  /// Aggiunge senza duplicare, salta record esistenti
  mergeKeepExisting,
}

/// Risultato dell'import da backup
class BackupImportResult {
  final int tablesProcessed;
  final int recordsImported;
  final List<String> errors;

  BackupImportResult({
    required this.tablesProcessed,
    required this.recordsImported,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// Service per backup e ripristino completo dei dati
class BackupService {
  BackupService._();

  static final instance = BackupService._();

  static const _backupVersion = 2;

  static const _prefKeys = [
    'home_layout',
    'theme_mode',
    'app_theme_mode',
    'scheduled_dark_mode_config',
  ];

  /// Esporta un backup completo di tutte le tabelle in formato JSON
  Future<void> exportBackup(AppDatabase db) async {
    final data = await generateBackupJson(db);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final fileName =
        'injecare_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    await saveAndShareFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/json',
      shareSubject: 'InjeCare Plan - Backup completo',
    );

    await db.updateLastBackupTime(DateTime.now());
  }

  /// Genera il JSON di backup (utile per i test)
  Future<Map<String, dynamic>> generateBackupJson(AppDatabase db) async {
    final zones = await db.getAllZones();
    final plans = await db.getAllTherapyPlans();
    final allInjections = await db.getAllInjections();
    final blacklisted = await db.getAllBlacklistedPoints();
    final configs = await db.getAllPointConfigs();
    final settings = await db.getAllSettings();
    final profile = await db.getUserProfile();

    final sharedPrefs = await SharedPreferences.getInstance();
    final preferences = <String, dynamic>{};
    for (final key in _prefKeys) {
      final value = sharedPrefs.getString(key);
      if (value != null) preferences[key] = value;
    }

    return {
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'bodyZones': zones.map(_zoneToJson).toList(),
      'therapyPlans': plans.map(_planToJson).toList(),
      'injections': allInjections.map(_injectionToJson).toList(),
      'blacklistedPoints': blacklisted.map(_blacklistedToJson).toList(),
      'pointConfigs': configs.map(_pointConfigToJson).toList(),
      'appSettings': settings.map(_settingToJson).toList(),
      'userProfile': profile != null ? _profileToJson(profile) : null,
      'preferences': preferences,
    };
  }

  /// Valida il contenuto JSON del backup
  String? validateBackup(Map<String, dynamic> data) {
    if (data['version'] == null) {
      return 'Campo "version" mancante';
    }
    if (data['version'] is! int || (data['version'] as int) > _backupVersion) {
      return 'Versione backup non supportata: ${data['version']}';
    }
    final requiredKeys = [
      'bodyZones',
      'therapyPlans',
      'injections',
    ];
    for (final key in requiredKeys) {
      if (data[key] == null) {
        return 'Sezione "$key" mancante';
      }
      if (data[key] is! List) {
        return 'Sezione "$key" non è una lista';
      }
    }
    return null;
  }

  /// Importa un backup JSON
  Future<BackupImportResult> importBackup(
    AppDatabase db,
    String jsonContent, {
    ImportStrategy strategy = ImportStrategy.replaceAll,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = json.decode(jsonContent) as Map<String, dynamic>;
    } catch (e) {
      return BackupImportResult(
        tablesProcessed: 0,
        recordsImported: 0,
        errors: ['JSON non valido: $e'],
      );
    }

    final validationError = validateBackup(data);
    if (validationError != null) {
      return BackupImportResult(
        tablesProcessed: 0,
        recordsImported: 0,
        errors: [validationError],
      );
    }

    return strategy == ImportStrategy.replaceAll
        ? _importReplaceAll(db, data)
        : _importMerge(db, data);
  }

  Future<BackupImportResult> _importReplaceAll(
    AppDatabase db,
    Map<String, dynamic> data,
  ) async {
    var tablesProcessed = 0;
    var recordsImported = 0;
    final errors = <String>[];

    try {
      await db.transaction(() async {
        // Cancella tutto nell'ordine corretto (FK)
        await db.delete(db.injections).go();
        await db.delete(db.blacklistedPoints).go();
        await db.delete(db.pointConfigs).go();
        await db.delete(db.therapyPlans).go();
        await db.delete(db.appSettings).go();
        await db.delete(db.userProfiles).go();
        await db.delete(db.bodyZones).go();

        // Ripristina bodyZones
        final zones = data['bodyZones'] as List;
        for (final z in zones) {
          final map = z as Map<String, dynamic>;
          await db.into(db.bodyZones).insert(
                BodyZonesCompanion.insert(
                  code: map['code'] as String,
                  name: map['name'] as String,
                  customName: Value(map['customName'] as String?),
                  icon: Value(map['icon'] as String?),
                  type: Value(map['type'] as String? ?? 'custom'),
                  side: Value(map['side'] as String? ?? 'none'),
                  numberOfPoints:
                      Value(map['numberOfPoints'] as int? ?? 4),
                  isEnabled: Value(map['isEnabled'] as bool? ?? true),
                  sortOrder: Value(map['sortOrder'] as int? ?? 0),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina therapyPlans
        final plans = data['therapyPlans'] as List;
        for (final p in plans) {
          final map = p as Map<String, dynamic>;
          await db.into(db.therapyPlans).insert(
                TherapyPlansCompanion.insert(
                  name: Value(map['name'] as String? ?? 'Piano Smart'),
                  isActive: Value(map['isActive'] as bool? ?? false),
                  injectionsPerWeek:
                      Value(map['injectionsPerWeek'] as int? ?? 3),
                  weekDays:
                      Value(map['weekDays'] as String? ?? '1,3,5'),
                  preferredTime:
                      Value(map['preferredTime'] as String? ?? '20:00'),
                  startDate: DateTime.parse(map['startDate'] as String),
                  rotationPatternType: Value(
                      map['rotationPatternType'] as String? ?? 'smart'),
                  customPatternSequence: Value(
                      map['customPatternSequence'] as String? ?? ''),
                  patternCurrentIndex:
                      Value(map['patternCurrentIndex'] as int? ?? 0),
                  patternLastZoneId:
                      Value(map['patternLastZoneId'] as int?),
                  patternLastSide:
                      Value(map['patternLastSide'] as String? ?? ''),
                  patternWeekStartDate: Value(
                    map['patternWeekStartDate'] != null
                        ? DateTime.parse(
                            map['patternWeekStartDate'] as String)
                        : null,
                  ),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina injections
        final injs = data['injections'] as List;
        for (final i in injs) {
          final map = i as Map<String, dynamic>;
          await db.into(db.injections).insert(
                InjectionsCompanion.insert(
                  zoneId: map['zoneId'] as int,
                  pointNumber: map['pointNumber'] as int,
                  pointCode: map['pointCode'] as String,
                  pointLabel: map['pointLabel'] as String,
                  scheduledAt:
                      DateTime.parse(map['scheduledAt'] as String),
                  completedAt: Value(
                    map['completedAt'] != null
                        ? DateTime.parse(map['completedAt'] as String)
                        : null,
                  ),
                  status:
                      Value(map['status'] as String? ?? 'scheduled'),
                  notes: Value(map['notes'] as String? ?? ''),
                  sideEffects:
                      Value(map['sideEffects'] as String? ?? ''),
                  calendarEventId:
                      Value(map['calendarEventId'] as String? ?? ''),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina blacklistedPoints
        final bl = data['blacklistedPoints'] as List? ?? [];
        for (final b in bl) {
          final map = b as Map<String, dynamic>;
          await db.into(db.blacklistedPoints).insert(
                BlacklistedPointsCompanion.insert(
                  pointCode: map['pointCode'] as String,
                  pointLabel: map['pointLabel'] as String,
                  zoneId: map['zoneId'] as int,
                  pointNumber: map['pointNumber'] as int,
                  reason: Value(map['reason'] as String? ?? ''),
                  notes: Value(map['notes'] as String? ?? ''),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina pointConfigs
        final pcs = data['pointConfigs'] as List? ?? [];
        for (final pc in pcs) {
          final map = pc as Map<String, dynamic>;
          await db.into(db.pointConfigs).insert(
                PointConfigsCompanion.insert(
                  zoneId: map['zoneId'] as int,
                  pointNumber: map['pointNumber'] as int,
                  customName:
                      Value(map['customName'] as String? ?? ''),
                  positionX:
                      Value((map['positionX'] as num?)?.toDouble() ?? 0.5),
                  positionY:
                      Value((map['positionY'] as num?)?.toDouble() ?? 0.5),
                  bodyView:
                      Value(map['bodyView'] as String? ?? 'front'),
                  isCustomPosition:
                      Value(map['isCustomPosition'] as bool? ?? false),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina appSettings
        final settings = data['appSettings'] as List? ?? [];
        for (final s in settings) {
          final map = s as Map<String, dynamic>;
          await db.into(db.appSettings).insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                  key: map['key'] as String,
                  value: map['value'] as String,
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Ripristina userProfile
        final profileData = data['userProfile'];
        if (profileData != null && profileData is Map<String, dynamic>) {
          await db.into(db.userProfiles).insert(
                UserProfilesCompanion.insert(
                  displayName: Value(
                      profileData['displayName'] as String? ?? ''),
                  email:
                      Value(profileData['email'] as String? ?? ''),
                  photoUrl:
                      Value(profileData['photoUrl'] as String? ?? ''),
                  biometricEnabled: Value(
                      profileData['biometricEnabled'] as bool? ?? false),
                  notificationsEnabled: Value(
                      profileData['notificationsEnabled'] as bool? ??
                          true),
                  calendarSyncEnabled: Value(
                      profileData['calendarSyncEnabled'] as bool? ??
                          false),
                  themeMode: Value(
                      profileData['themeMode'] as String? ?? 'system'),
                  lastBackupAt: Value(
                    profileData['lastBackupAt'] != null
                        ? DateTime.parse(
                            profileData['lastBackupAt'] as String)
                        : null,
                  ),
                ),
              );
          recordsImported++;
          tablesProcessed++;
        }
      });
    } catch (e) {
      errors.add('Errore durante il ripristino: $e');
    }

    await _restorePreferences(data);

    return BackupImportResult(
      tablesProcessed: tablesProcessed,
      recordsImported: recordsImported,
      errors: errors,
    );
  }

  Future<BackupImportResult> _importMerge(
    AppDatabase db,
    Map<String, dynamic> data,
  ) async {
    var tablesProcessed = 0;
    var recordsImported = 0;
    final errors = <String>[];

    try {
      await db.transaction(() async {
        // Merge bodyZones (upsert by code)
        final zones = data['bodyZones'] as List;
        for (final z in zones) {
          final map = z as Map<String, dynamic>;
          final code = map['code'] as String;
          final existing = await db.getZoneByCode(code);
          if (existing == null) {
            await db.into(db.bodyZones).insert(
                  BodyZonesCompanion.insert(
                    code: code,
                    name: map['name'] as String,
                    customName: Value(map['customName'] as String?),
                    icon: Value(map['icon'] as String?),
                    type: Value(map['type'] as String? ?? 'custom'),
                    side: Value(map['side'] as String? ?? 'none'),
                    numberOfPoints:
                        Value(map['numberOfPoints'] as int? ?? 4),
                    isEnabled:
                        Value(map['isEnabled'] as bool? ?? true),
                    sortOrder: Value(map['sortOrder'] as int? ?? 0),
                  ),
                );
            recordsImported++;
          }
        }
        tablesProcessed++;

        // Merge therapyPlans (skip by rotationPatternType)
        final plans = data['therapyPlans'] as List;
        final existingPlans = await db.getAllTherapyPlans();
        final existingTypes =
            existingPlans.map((p) => p.rotationPatternType).toSet();
        for (final p in plans) {
          final map = p as Map<String, dynamic>;
          final patternType =
              map['rotationPatternType'] as String? ?? 'smart';
          if (!existingTypes.contains(patternType)) {
            await db.into(db.therapyPlans).insert(
                  TherapyPlansCompanion.insert(
                    name:
                        Value(map['name'] as String? ?? 'Piano Smart'),
                    isActive: const Value(false),
                    startDate:
                        DateTime.parse(map['startDate'] as String),
                    rotationPatternType: Value(patternType),
                  ),
                );
            recordsImported++;
          }
        }
        tablesProcessed++;

        // Merge injections (insert all — no unique key to detect duplicates easily)
        final injs = data['injections'] as List;
        for (final i in injs) {
          final map = i as Map<String, dynamic>;
          await db.into(db.injections).insert(
                InjectionsCompanion.insert(
                  zoneId: map['zoneId'] as int,
                  pointNumber: map['pointNumber'] as int,
                  pointCode: map['pointCode'] as String,
                  pointLabel: map['pointLabel'] as String,
                  scheduledAt:
                      DateTime.parse(map['scheduledAt'] as String),
                  completedAt: Value(
                    map['completedAt'] != null
                        ? DateTime.parse(map['completedAt'] as String)
                        : null,
                  ),
                  status:
                      Value(map['status'] as String? ?? 'scheduled'),
                  notes: Value(map['notes'] as String? ?? ''),
                  sideEffects:
                      Value(map['sideEffects'] as String? ?? ''),
                  calendarEventId:
                      Value(map['calendarEventId'] as String? ?? ''),
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Merge blacklistedPoints (skip by pointCode)
        final bl = data['blacklistedPoints'] as List? ?? [];
        for (final b in bl) {
          final map = b as Map<String, dynamic>;
          final pointCode = map['pointCode'] as String;
          final isBlacklisted = await db.isPointBlacklisted(pointCode);
          if (!isBlacklisted) {
            await db.into(db.blacklistedPoints).insert(
                  BlacklistedPointsCompanion.insert(
                    pointCode: pointCode,
                    pointLabel: map['pointLabel'] as String,
                    zoneId: map['zoneId'] as int,
                    pointNumber: map['pointNumber'] as int,
                    reason: Value(map['reason'] as String? ?? ''),
                    notes: Value(map['notes'] as String? ?? ''),
                  ),
                );
            recordsImported++;
          }
        }
        tablesProcessed++;

        // Merge pointConfigs (upsert by zoneId+pointNumber)
        final pcs = data['pointConfigs'] as List? ?? [];
        for (final pc in pcs) {
          final map = pc as Map<String, dynamic>;
          final zoneId = map['zoneId'] as int;
          final pointNumber = map['pointNumber'] as int;
          final existing = await db.getPointConfig(zoneId, pointNumber);
          if (existing == null) {
            await db.into(db.pointConfigs).insert(
                  PointConfigsCompanion.insert(
                    zoneId: zoneId,
                    pointNumber: pointNumber,
                    customName:
                        Value(map['customName'] as String? ?? ''),
                    positionX: Value(
                        (map['positionX'] as num?)?.toDouble() ?? 0.5),
                    positionY: Value(
                        (map['positionY'] as num?)?.toDouble() ?? 0.5),
                    bodyView:
                        Value(map['bodyView'] as String? ?? 'front'),
                    isCustomPosition: Value(
                        map['isCustomPosition'] as bool? ?? false),
                  ),
                );
            recordsImported++;
          }
        }
        tablesProcessed++;

        // Merge appSettings (upsert by key)
        final settings = data['appSettings'] as List? ?? [];
        for (final s in settings) {
          final map = s as Map<String, dynamic>;
          await db.into(db.appSettings).insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                  key: map['key'] as String,
                  value: map['value'] as String,
                ),
              );
          recordsImported++;
        }
        tablesProcessed++;

        // Merge userProfile (skip if exists)
        final profileData = data['userProfile'];
        if (profileData != null && profileData is Map<String, dynamic>) {
          final existingProfile = await db.getUserProfile();
          if (existingProfile == null) {
            await db.into(db.userProfiles).insert(
                  UserProfilesCompanion.insert(
                    displayName: Value(
                        profileData['displayName'] as String? ?? ''),
                    email: Value(
                        profileData['email'] as String? ?? ''),
                    photoUrl: Value(
                        profileData['photoUrl'] as String? ?? ''),
                    biometricEnabled: Value(
                        profileData['biometricEnabled'] as bool? ??
                            false),
                    notificationsEnabled: Value(
                        profileData['notificationsEnabled'] as bool? ??
                            true),
                    calendarSyncEnabled: Value(
                        profileData['calendarSyncEnabled'] as bool? ??
                            false),
                    themeMode: Value(
                        profileData['themeMode'] as String? ??
                            'system'),
                  ),
                );
            recordsImported++;
            tablesProcessed++;
          }
        }
      });
    } catch (e) {
      errors.add('Errore durante il merge: $e');
    }

    await _restorePreferences(data);

    return BackupImportResult(
      tablesProcessed: tablesProcessed,
      recordsImported: recordsImported,
      errors: errors,
    );
  }

  Future<void> _restorePreferences(Map<String, dynamic> data) async {
    final raw = data['preferences'];
    if (raw is! Map) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (_prefKeys.contains(key) && value is String) {
        await prefs.setString(key, value);
      }
    }
  }

  // --- Serializzazione ---

  Map<String, dynamic> _zoneToJson(BodyZone z) => {
        'id': z.id,
        'code': z.code,
        'name': z.name,
        'customName': z.customName,
        'icon': z.icon,
        'type': z.type,
        'side': z.side,
        'numberOfPoints': z.numberOfPoints,
        'isEnabled': z.isEnabled,
        'sortOrder': z.sortOrder,
      };

  Map<String, dynamic> _planToJson(TherapyPlan p) => {
        'id': p.id,
        'name': p.name,
        'isActive': p.isActive,
        'injectionsPerWeek': p.injectionsPerWeek,
        'weekDays': p.weekDays,
        'preferredTime': p.preferredTime,
        'startDate': p.startDate.toIso8601String(),
        'rotationPatternType': p.rotationPatternType,
        'customPatternSequence': p.customPatternSequence,
        'patternCurrentIndex': p.patternCurrentIndex,
        'patternLastZoneId': p.patternLastZoneId,
        'patternLastSide': p.patternLastSide,
        'patternWeekStartDate':
            p.patternWeekStartDate?.toIso8601String(),
      };

  Map<String, dynamic> _injectionToJson(Injection i) => {
        'zoneId': i.zoneId,
        'pointNumber': i.pointNumber,
        'pointCode': i.pointCode,
        'pointLabel': i.pointLabel,
        'scheduledAt': i.scheduledAt.toIso8601String(),
        'completedAt': i.completedAt?.toIso8601String(),
        'status': i.status,
        'notes': i.notes,
        'sideEffects': i.sideEffects,
        'calendarEventId': i.calendarEventId,
      };

  Map<String, dynamic> _blacklistedToJson(BlacklistedPoint b) => {
        'pointCode': b.pointCode,
        'pointLabel': b.pointLabel,
        'zoneId': b.zoneId,
        'pointNumber': b.pointNumber,
        'reason': b.reason,
        'notes': b.notes,
      };

  Map<String, dynamic> _pointConfigToJson(PointConfig pc) => {
        'zoneId': pc.zoneId,
        'pointNumber': pc.pointNumber,
        'customName': pc.customName,
        'positionX': pc.positionX,
        'positionY': pc.positionY,
        'bodyView': pc.bodyView,
        'isCustomPosition': pc.isCustomPosition,
      };

  Map<String, dynamic> _settingToJson(AppSetting s) => {
        'key': s.key,
        'value': s.value,
      };

  Map<String, dynamic> _profileToJson(UserProfile p) => {
        'displayName': p.displayName,
        'email': p.email,
        'photoUrl': p.photoUrl,
        'biometricEnabled': p.biometricEnabled,
        'notificationsEnabled': p.notificationsEnabled,
        'calendarSyncEnabled': p.calendarSyncEnabled,
        'themeMode': p.themeMode,
        'lastBackupAt': p.lastBackupAt?.toIso8601String(),
      };
}
