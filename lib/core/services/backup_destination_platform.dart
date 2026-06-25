// Punto unico di accesso alle funzioni di destinazione, risolte per
// piattaforma via conditional-import:
// - `dart.library.io` (Android) → SAF
// - default (Web e altri) → stub non-supportato
//
// Espone: `autoBackupSupported`, `pickBackupDestination()`,
// `resolveBackupDestination(token, label)`.
export 'backup_destination_stub.dart'
    if (dart.library.io) 'backup_destination_android.dart';
