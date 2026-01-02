import 'package:drift/drift.dart';

/// Tabella zone del corpo per iniezioni
/// Zone predefinite + zone custom create dall'utente
class BodyZones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 10)();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get customName => text().nullable()(); // Nome personalizzato dall'utente
  TextColumn get icon => text().nullable()(); // Emoji/icona personalizzata
  TextColumn get type => text().withDefault(const Constant('custom'))(); // thigh, arm, abdomen, buttock, custom
  TextColumn get side => text().withDefault(const Constant('none'))(); // left, right, none
  IntColumn get numberOfPoints => integer().withDefault(const Constant(4))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Piano terapeutico dell'utente
class TherapyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get injectionsPerWeek =>
      integer().withDefault(const Constant(3))();
  TextColumn get weekDays =>
      text().withDefault(const Constant('1,3,5'))(); // CSV: Lun,Mer,Ven
  TextColumn get preferredTime =>
      text().withDefault(const Constant('20:00'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Registro iniezioni effettuate
class Injections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get zoneId => integer().references(BodyZones, #id)();
  IntColumn get pointNumber => integer()();
  TextColumn get pointCode => text().withLength(max: 10)(); // es. CD-3
  TextColumn get pointLabel => text().withLength(max: 50)(); // es. Coscia Dx · 3
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get sideEffects =>
      text().withDefault(const Constant(''))(); // CSV: effetto1,effetto2
  TextColumn get calendarEventId => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Punti esclusi dalla rotazione automatica
class BlacklistedPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pointCode =>
      text().withLength(max: 10).unique()(); // es. CD-2
  TextColumn get pointLabel => text().withLength(max: 50)(); // es. Coscia Dx · 2
  IntColumn get zoneId => integer().references(BodyZones, #id)();
  IntColumn get pointNumber => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get blacklistedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Impostazioni app
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Profilo utente (locale)
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get photoUrl => text().withDefault(const Constant(''))();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get calendarSyncEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get themeMode =>
      text().withDefault(const Constant('system'))(); // light, dark, system
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
