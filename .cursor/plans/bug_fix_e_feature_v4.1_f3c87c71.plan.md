---
name: Bug Fix e Feature v4.1
overview: Correzione di 6 bug critici (calcolo giorni, demo data, nomi custom, coordinate punti, drag lento, icone) e implementazione di 4 nuove feature (workflow schedulazione, pattern orario/antiorario, data/ora in selezione punto, set icone Rosepine).
todos:
  - id: bug-days-calc
    content: "Fix calcolo giorni: usare scheduledAt invece di completedAt"
    status: completed
  - id: bug-demo-data
    content: "Fix demo data: verificare logica e aggiungere feedback utente"
    status: completed
  - id: bug-custom-name
    content: "Fix nome custom punto: usare customName da PointConfig nello storico"
    status: completed
  - id: bug-coordinates
    content: Aggiornare coordinate punti secondo immagine posizione_punti.png
    status: completed
  - id: bug-drag-slow
    content: Ottimizzare drag and drop con throttling e Transform.translate
    status: completed
  - id: feat-schedule-flow
    content: "Implementare workflow: sempre schedulata prima, poi completabile"
    status: completed
  - id: feat-clockwise
    content: Aggiungere pattern Orario e Antiorario con sequenza specificata
    status: completed
  - id: feat-datetime-picker
    content: Mostrare data/ora in selezione punto con possibilità di modifica
    status: completed
  - id: icons-create
    content: Creare set completo icone SVG Rosepine in assets/icons/rosepine/
    status: completed
  - id: icons-structure
    content: Strutturare folder per futura pubblicazione come repo dedicato
    status: completed
  - id: update-docs
    content: Aggiornare README, CHANGELOG, manuale, screenshot e test
    status: completed
---

# Piano Bug Fix e Feature v4.1

## Bug Fix

### 1. Calcolo giorni errato per iniezioni passate

**Problema**: Quando si aggiunge un'iniezione nel passato, il numero di giorni mostra "0" invece del valore corretto.**Causa**: In [`app_database.dart`](lib/core/database/app_database.dart) linea 640, `getPointUsageHistory` usa `inj.completedAt ?? inj.scheduledAt`. Se l'iniezione viene registrata oggi per una data passata, `completedAt` è oggi.**Fix**: Usare sempre `scheduledAt` come data di riferimento per calcolare i giorni trascorsi, poiché rappresenta quando l'iniezione è stata effettivamente fatta.

### 2. Demo data creati anche senza selezione

**Problema**: L'utente vede dati anche selezionando "nessun dato" nell'onboarding.**Causa**: I suggerimenti AI appaiono sempre perché il piano terapeutico di default (Lun/Mer/Ven) viene creato. L'utente confonde i suggerimenti con i dati demo.**Fix**: Aggiungere un messaggio più chiaro nell'onboarding e verificare che `_insertDemoData` sia rispettato. Mostrare un toast/snackbar di conferma.

### 3. Nome custom punto non mostrato nello storico

**Problema**: Lo storico usa `zone.pointLabel(i)` invece del nome personalizzato.**Fix**: In [`point_selection_screen.dart`](lib/features/injection/point_selection_screen.dart) linea 654-655, recuperare il `customName` dalla lista `_points` invece di usare il metodo della zona.

```dart
// Prima (errato)
pointLabel: widget.zone.pointLabel(i),

// Dopo (corretto)
pointLabel: _getPointLabel(i),

String _getPointLabel(int pointNumber) {
  final point = _points.firstWhere(
    (p) => p.pointNumber == pointNumber,
    orElse: () => PositionedPoint(pointNumber: pointNumber, x: 0.5, y: 0.5),
  );
  if (point.customName != null && point.customName!.isNotEmpty) {
    return '${widget.zone.name} · ${point.customName}';
  }
  return widget.zone.pointLabel(pointNumber);
}
```



### 4. Coordinate punti da immagine

**Problema**: I punti non sono posizionati come nell'immagine `posizione_punti.png`.**Fix**: Aggiornare `generateDefaultPointPositions` in [`body_silhouette_editor.dart`](lib/features/injection/widgets/body_silhouette_editor.dart) con coordinate precise:| Zona | Vista | Layout | Coordinate (normalizzate 0-1) ||------|-------|--------|------------------------------|| Coscia Sx | Front | 2x3 | x: 0.25-0.40, y: 0.55-0.75 || Coscia Dx | Front | 2x3 | x: 0.60-0.75, y: 0.55-0.75 || Braccio Sx | Front | 2x2 | x: 0.10-0.22, y: 0.22-0.32 || Braccio Dx | Front | 2x2 | x: 0.78-0.90, y: 0.22-0.32 || Addome Sx | Front | 2x2 | x: 0.30-0.42, y: 0.32-0.42 || Addome Dx | Front | 2x2 | x: 0.58-0.70, y: 0.32-0.42 || Gluteo Sx | Back | 2x2 | x: 0.30-0.42, y: 0.48-0.58 || Gluteo Dx | Back | 2x2 | x: 0.58-0.70, y: 0.48-0.58 |

### 5. Drag and drop lento

**Problema**: Il movimento dei punti nella schermata modifica è lento.**Fix**: In [`body_silhouette_editor.dart`](lib/features/injection/widgets/body_silhouette_editor.dart):

- Ridurre la frequenza di `setState` durante il drag usando throttling
- Usare `Transform.translate` invece di ricostruire il widget
- Aumentare `hitSlop` per migliore responsività

### 6. Set Completo Icone Rosepine

**Obiettivo**: Creare un set completo di icone SVG in stile Rosepine, pronte per pubblicazione futura come repo dedicato.**Struttura folder** (in `assets/icons/rosepine/`):

```javascript
assets/icons/rosepine/
├── README.md                 # Documentazione per repo futuro
├── LICENSE                   # MIT License
├── body/                     # Icone zone del corpo (8 icone)
│   ├── thigh-left.svg
│   ├── thigh-right.svg
│   ├── arm-left.svg
│   ├── arm-right.svg
│   ├── abdomen-left.svg
│   ├── abdomen-right.svg
│   ├── buttock-left.svg
│   └── buttock-right.svg
├── actions/                  # Icone azioni (8 icone)
│   ├── add.svg
│   ├── edit.svg
│   ├── delete.svg
│   ├── save.svg
│   ├── cancel.svg
│   ├── schedule.svg
│   ├── complete.svg
│   └── skip.svg
├── status/                   # Icone stati (6 icone)
│   ├── completed.svg
│   ├── scheduled.svg
│   ├── pending.svg
│   ├── skipped.svg
│   ├── missed.svg
│   └── warning.svg
├── navigation/               # Icone navigazione (5 icone)
│   ├── home.svg
│   ├── calendar.svg
│   ├── stats.svg
│   ├── settings.svg
│   └── info.svg
├── patterns/                 # Icone pattern rotazione (7 icone)
│   ├── ai-smart.svg
│   ├── sequential.svg
│   ├── alternate.svg
│   ├── weekly.svg
│   ├── clockwise.svg
│   ├── counter-clockwise.svg
│   └── custom.svg
└── misc/                     # Icone varie (5 icone)
    ├── notification.svg
    ├── export.svg
    ├── import.svg
    ├── syringe.svg
    └── medical.svg
```

**Stile icone Rosepine**:

- Dimensione base: 24x24px (viewBox)
- Stroke width: 1.5-2px
- Colori: variabili CSS per tema (--icon-primary, --icon-secondary)
- Linee arrotondate (stroke-linecap: round, stroke-linejoin: round)
- Minimaliste, senza riempimento (solo stroke)

**Totale icone**: ~40 icone complete**Preparazione per repo dedicato**:

- README con preview di tutte le icone
- Istruzioni di utilizzo (Flutter, Web, React Native)
- Script per generazione sprite sheet
- package.json per pubblicazione npm (futuro)

---

## Feature

### 1. Workflow schedulazione dal calendario

**Comportamento**: Quando si seleziona un giorno dal calendario e si registra un'iniezione:

1. L'iniezione viene SEMPRE salvata prima come "scheduled" con orario preferito dai settings
2. Appare un pulsante "Segna come completata" per confermare
3. Solo dopo la conferma diventa "completed"

**File coinvolti**:

- [`calendar_screen.dart`](lib/features/calendar/calendar_screen.dart): Aggiungere azione "Programma"
- [`record_screen.dart`](lib/features/injection/record_screen.dart): Modificare logica salvataggio
- Nuovo widget `_ScheduledInjectionCard` con azione "Completa ora"

### 2. Pattern rotazione Orario/Antiorario

**Nuovi pattern** in [`rotation_pattern.dart`](lib/models/rotation_pattern.dart):

```dart
enum RotationPatternType {
  // ... esistenti ...
  clockwise,        // Orario
  counterClockwise, // Antiorario
}
```

**Sequenza ORARIO** (partendo da Braccio Sx):

1. Braccio Sx (ID 3)
2. Braccio Dx (ID 4)
3. Addome Dx (ID 6)
4. Gluteo Dx (ID 8)
5. Coscia Dx (ID 1)
6. Coscia Sx (ID 2)
7. Gluteo Sx (ID 7)
8. Addome Sx (ID 5)

**Sequenza ANTIORARIO**: inverso (8 -> 7 -> 6 -> ... -> 1)**File coinvolti**:

- [`rotation_pattern.dart`](lib/models/rotation_pattern.dart): Aggiungere enum values
- [`rotation_pattern_engine.dart`](lib/core/ml/rotation_pattern_engine.dart): Implementare logica
- [`app_database.dart`](lib/core/database/app_database.dart): Aggiungere piani di default (totale 7 piani)

### 3. Data/ora visibile in selezione punto

**Comportamento**: Nella schermata "Seleziona punto iniezione":

- Mostrare in alto: "Iniezione per: Lunedi 6 Gen 2026 ore 20:00"
- Pulsante per modificare l'orario (TimePicker)
- L'orario modificato viene usato per il promemoria

**File coinvolti**:

- [`point_selection_screen.dart`](lib/features/injection/point_selection_screen.dart): Aggiungere header con data/ora
- Passare `scheduledTime` modificabile al `record_screen`

### 4. Set Completo Icone Rosepine

**Implementazione**: Creazione di ~40 icone SVG in stile Rosepine organizzate per categoria (vedi sezione Bug Fix #6 per struttura folder completa).**Integrazione nell'app**:

- Creare `RosepineIcon` widget wrapper per caricare le icone SVG
- Sostituire gradualmente le Material Icons con le nuove icone
- Mantenere fallback su Material Icons per compatibilità

**Preparazione pubblicazione repo**:

- Struttura folder gia pronta per `git init` separato
- README.md con documentazione e preview
- LICENSE MIT
- Script di build per generare varianti (filled, outlined)

**Timeline futura**:

1. v4.1.0: Creazione icone e integrazione base
2. v4.2.0: Sostituzione completa icone principali
3. Post-v4.2.0: Pubblicazione repo `rosepine-icons` su GitHub

---

## Aggiornamenti documentazione

- README.md: Nuove feature e icone
- CHANGELOG.md: v4.1.0
- MANUALE_UTENTE.md: Nuove istruzioni
- Screenshot aggiornati