---
name: Dynamic Zones Refactor
overview: Refactor the point selection screen to use dynamic zones stored in the database, remove the human figure illustration, fix left/right positioning to anatomical view, and allow users to customize zone names, points count, and icons.
todos:
  - id: update-model
    content: Update BodyZone model with icon and customName fields
    status: completed
  - id: update-tables
    content: Add new columns to BodyZones table and regenerate database
    status: completed
  - id: zone-provider
    content: Create zone_provider.dart with CRUD operations
    status: completed
  - id: refactor-selection
    content: "Refactor PointSelectionScreen: remove omino, fix L/R, use dynamic zones"
    status: completed
  - id: zone-management
    content: Create ZoneManagementScreen for customizing zones
    status: completed
  - id: update-settings
    content: Add zone management link to settings screen
    status: completed
  - id: seed-database
    content: Add database seeding for default zones on first run
    status: completed
---

# Refactoring Zone e Punti Dinamici

## Obiettivo

Rendere le zone completamente dinamiche con possibilita' di:

- Configurare il numero di punti per zona
- Aggiungere/rimuovere zone custom
- Personalizzare nomi e icone
- Correggere l'inversione destra/sinistra

---

## 1. Aggiornare il modello BodyZone e database

### [lib/models/body_zone.dart](lib/models/body_zone.dart)

- Aggiungere campo `icon` (String) per emoji/icona personalizzabile
- Aggiungere campo `customName` opzionale per nome personalizzato dall'utente
- Rimuovere `defaults` statico - le zone verranno lette dal database

### [lib/core/database/tables.dart](lib/core/database/tables.dart)

Modificare tabella `BodyZones`:

```dart
class BodyZones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 4)();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get customName => text().nullable()(); // Nome personalizzato
  TextColumn get icon => text().withDefault(const Constant('📍'))(); // Emoji
  TextColumn get type => text().withDefault(const Constant('custom'))();
  TextColumn get side => text().withDefault(const Constant('none'))();
  IntColumn get numberOfPoints => integer().withDefault(const Constant(4))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // ... timestamps
}
```

---

## 2. Creare Provider per zone dinamiche

### Nuovo file: `lib/features/injection/zone_provider.dart`

```dart
// Provider per le zone dal database
final zonesProvider = StreamProvider<List<BodyZone>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllZones();
});

// Notifier per CRUD zone
class ZoneNotifier extends Notifier<AsyncValue<void>> {
  Future<void> addZone(BodyZone zone);
  Future<void> updateZone(BodyZone zone);
  Future<void> deleteZone(int id);
  Future<void> updatePointCount(int zoneId, int count);
  Future<void> updateZoneName(int zoneId, String name);
}
```

---

## 3. Refactoring PointSelectionScreen

### [lib/features/injection/point_selection_screen.dart](lib/features/injection/point_selection_screen.dart)

**Rimuovere:**

- Widget `_InjectionAreasIllustration` (contiene l'omino)
- Riferimenti a `BodyZone.defaults`

**Modificare:**

- Usare `ref.watch(zonesProvider)` per ottenere le zone
- Correggere posizione destra/sinistra (vista anatomica):
- Colonna SINISTRA schermo = zone con `side: 'left'`
- Colonna DESTRA schermo = zone con `side: 'right'`

**Nuovo layout semplificato:**

```dart
// Griglia zone senza omino
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // 2 colonne
  ),
  itemBuilder: (ctx, i) => _ZoneCard(zone: zones[i]),
)
```

---

## 4. Creare schermata gestione zone

### Nuovo file: `lib/features/settings/zone_management_screen.dart`

Permette all'utente di:

- Vedere lista zone esistenti
- Modificare numero punti per zona (slider 1-12)
- Modificare nome personalizzato
- Cambiare icona/emoji
- Abilitare/disabilitare zone
- Aggiungere nuove zone custom
- Riordinare zone (drag & drop)

---

## 5. Aggiornare settings screen

### [lib/features/settings/settings_screen.dart](lib/features/settings/settings_screen.dart)

Aggiungere tile nella sezione "ZONE E PUNTI":

```dart
_SettingsTile(
  title: 'Gestisci zone',
  icon: Icons.edit_location_alt,
  onTap: () => context.push(AppRoutes.zoneManagement),
),
```

---

## 6. Inizializzazione database

### [lib/core/database/app_database.dart](lib/core/database/app_database.dart)

Aggiungere metodo per inizializzare le zone di default se la tabella e' vuota:

```dart
Future<void> seedDefaultZones() async {
  final count = await (select(bodyZones)..limit(1)).get();
  if (count.isEmpty) {
    // Inserisci le 8 zone predefinite
  }
}
```

---

## 7. Riepilogo file da modificare

| File | Azione |

|------|--------|

| `lib/models/body_zone.dart` | Aggiungere campi icon, customName |

| `lib/core/database/tables.dart` | Aggiungere colonne icon, customName, type, side |

| `lib/core/database/app_database.dart` | Aggiungere metodi CRUD zone + seed |

| `lib/features/injection/point_selection_screen.dart` | Rimuovere omino, usare zone dinamiche, fix destra/sinistra |

| `lib/features/injection/zone_provider.dart` | Nuovo - provider zone |

| `lib/features/settings/zone_management_screen.dart` | Nuovo - gestione zone |

| `lib/features/settings/settings_screen.dart` | Aggiungere link a gestione zone |

| `lib/app/router.dart` | Aggiungere route zone management |---

## Note implementative

- Dopo modifica tabelle, rigenerare con: `dart run build_runner build`
- Le zone esistenti nel database verranno migrate con una migration Drift