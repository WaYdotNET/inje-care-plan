---
name: Bugfix e miglioramenti v3.2
overview: Correzione fixtures.dart, salvataggio iniezioni future come "scheduled", rimozione autenticazione biometrica, aggiunta dati demo in onboarding, implementazione import/export CSV con formato unificato e nuovi screenshot.
todos:
  - id: fix-fixtures
    content: Fix test/helpers/fixtures.dart parametri Drift
    status: pending
  - id: fix-scheduled
    content: Fix iniezioni future salvate come scheduled
    status: pending
  - id: remove-biometric
    content: Rimuovere autenticazione biometrica
    status: pending
  - id: demo-data
    content: Aggiungere opzione dati demo in onboarding
    status: pending
  - id: export-csv
    content: Semplificare formato export CSV
    status: pending
  - id: import-csv
    content: Implementare import da CSV
    status: pending
    dependencies:
      - export-csv
  - id: screenshots
    content: Nuovi screenshot per README
    status: pending
    dependencies:
      - demo-data
  - id: update-docs
    content: Aggiornare README, CHANGELOG, guida
    status: pending
    dependencies:
      - screenshots
---

# Bugfix e Miglioramenti v3.2.0

## Riepilogo modifiche

1. **Fix fixtures.dart** - Correzione parametri errati
2. Fix salvataggio iniezioni future come "scheduled"
3. Rimozione autenticazione biometrica
4. Storico vuoto all'avvio (nessun dato pre-popolato)
5. Dati demo opzionali durante onboarding (ultimi 30 giorni, ~12 iniezioni)
6. Import/Export CSV con formato unificato semplice
7. Nuovi screenshot per README

---

## 1. Fix fixtures.dart

**File:** [`test/helpers/fixtures.dart`](test/helpers/fixtures.dart)

Il file usa nomi di parametri errati rispetto alle classi Drift generate.

### Correzioni necessarie:

**Injection:**
```dart
static Injection createInjection({
  int id = 1,
  int zoneId = 1,  // era: zoneCode
  int pointNumber = 1,
  DateTime? date,
  String? notes,
  bool completed = true,
}) {
  final now = DateTime.now();
  final scheduledAt = date ?? now;
  return Injection(
    id: id,
    zoneId: zoneId,
    pointNumber: pointNumber,
    pointCode: 'CD-$pointNumber',
    pointLabel: 'Coscia Dx · $pointNumber',
    scheduledAt: scheduledAt,
    completedAt: completed ? scheduledAt : null,
    status: completed ? 'completed' : 'scheduled',
    notes: notes ?? '',
    sideEffects: '',
    calendarEventId: '',
    createdAt: now,
    updatedAt: now,
  );
}
```

**PointConfig:**
```dart
static PointConfig createPointConfig({
  int id = 1,
  int zoneId = 1,  // era: zoneCode
  int pointNumber = 1,
  double x = 0.5,
  double y = 0.5,
  String? customName,
}) {
  final now = DateTime.now();
  return PointConfig(
    id: id,
    zoneId: zoneId,
    pointNumber: pointNumber,
    customName: customName ?? '',
    positionX: x,  // era: xPosition
    positionY: y,  // era: yPosition
    bodyView: 'front',
    createdAt: now,
    updatedAt: now,
  );
}
```

**BlacklistedPoint:** (era BlacklistedPointEntry)
```dart
static BlacklistedPoint createBlacklistedPoint({
  int id = 1,
  int zoneId = 1,  // era: zoneCode
  int pointNumber = 1,
  String reason = 'Test reason',
}) {
  final now = DateTime.now();
  return BlacklistedPoint(
    id: id,
    pointCode: 'CD-$pointNumber',
    pointLabel: 'Coscia Dx · $pointNumber',
    zoneId: zoneId,
    pointNumber: pointNumber,
    reason: reason,
    notes: '',
    blacklistedAt: now,  // era: excludedAt
    createdAt: now,
  );
}
```

---

## 2. Fix iniezioni future salvate come "scheduled"

**File:** [`lib/features/injection/injection_repository.dart`](lib/features/injection/injection_repository.dart)

Verificare che quando `scheduledAt` e' nel futuro, lo status sia sempre `scheduled` invece di `completed`.

---

## 3. Rimozione autenticazione biometrica

**File da eliminare:**
- [`lib/features/auth/biometric_lock_screen.dart`](lib/features/auth/biometric_lock_screen.dart)

**File da modificare:**
- [`lib/features/auth/auth_provider.dart`](lib/features/auth/auth_provider.dart): Rimuovere campi/metodi biometrici
- [`lib/app/router.dart`](lib/app/router.dart): Rimuovere route `/biometric-lock`
- [`lib/features/settings/settings_screen.dart`](lib/features/settings/settings_screen.dart): Rimuovere `_BiometricTile`
- [`pubspec.yaml`](pubspec.yaml): Rimuovere dipendenza `local_auth`
- [`test/unit/providers/auth_provider_test.dart`](test/unit/providers/auth_provider_test.dart): Rimuovere test biometria

---

## 4. Storico vuoto all'avvio

Il database deve iniziare senza iniezioni. Verificare che `seedDefaultZones()` non inserisca iniezioni demo.

---

## 5. Dati demo in onboarding

**File:** [`lib/features/auth/login_screen.dart`](lib/features/auth/login_screen.dart)

Aggiungere pagina 4 all'onboarding: "Vuoi inserire dati demo?"

**Nuovo file:** `lib/core/services/demo_data_service.dart`
- Genera ~12 iniezioni negli ultimi 30 giorni (3/settimana x 4 settimane)

---

## 6. Import/Export CSV - Formato Unificato

**Formato:**
```csv
data,zona,punto,stato
2024-07-15 20:00,CD,3,completed
```

**File da modificare:**
- [`lib/core/services/export_service.dart`](lib/core/services/export_service.dart): Semplificare formato

**Nuovo file:** `lib/core/services/import_service.dart`

**File:** [`lib/features/settings/settings_screen.dart`](lib/features/settings/settings_screen.dart)
- Aggiungere tile "Importa da CSV"

---

## 7. Nuovi screenshot

Catturare su emulatore Android con dati demo:
- `home.png`, `calendar.png`, `statistics.png`, `settings.png`, `body_map.png`, `history.png`

---

## Riepilogo file

| File | Azione |
|------|--------|
| `test/helpers/fixtures.dart` | Fix parametri Drift |
| `lib/features/auth/biometric_lock_screen.dart` | DELETE |
| `lib/features/auth/auth_provider.dart` | Semplificare |
| `lib/app/router.dart` | Rimuovere biometric |
| `lib/features/settings/settings_screen.dart` | Rimuovere biometric, aggiungere import |
| `lib/features/auth/login_screen.dart` | Aggiungere demo data |
| `lib/core/services/export_service.dart` | Semplificare CSV |
| `lib/core/services/demo_data_service.dart` | NEW |
| `lib/core/services/import_service.dart` | NEW |
| `pubspec.yaml` | Rimuovere local_auth, aggiungere file_picker |
| `test/unit/providers/auth_provider_test.dart` | Rimuovere test biometria |
