# Architettura InjeCare Plan

## Panoramica

InjeCare Plan è un'app Flutter per la gestione delle iniezioni sottocutanee, progettata con un'architettura **offline-first** e **feature-first**.

## Principi Architetturali

### 1. Offline-First
- **Database locale**: Drift (SQLite) per la persistenza dei dati
- **Nessuna dipendenza cloud**: L'app funziona completamente offline
- **Dati sul dispositivo**: Privacy e controllo totale per l'utente

### 2. Feature-First Organization
Ogni feature è autocontenuta con i propri screen, widget e provider:

```
lib/
├── app/                    # Configurazione app (router, tema)
├── core/                   # Codice condiviso
│   ├── database/           # Drift database e tabelle
│   ├── ml/                 # Algoritmi ML/suggerimenti
│   ├── services/           # Servizi (notifiche, export)
│   ├── theme/              # Tema e colori
│   ├── utils/              # Utility functions
│   └── widgets/            # Widget riutilizzabili
├── features/               # Feature modules
│   ├── auth/               # Autenticazione/onboarding
│   ├── calendar/           # Vista calendario
│   ├── help/               # Guida utente
│   ├── history/            # Storico iniezioni
│   ├── home/               # Dashboard principale
│   ├── info/               # Info app
│   ├── injection/          # Registrazione iniezioni
│   ├── onboarding/         # Tour guidato
│   ├── settings/           # Impostazioni
│   └── statistics/         # Statistiche avanzate
└── models/                 # Modelli dati condivisi
```

### 3. State Management: Riverpod

Utilizziamo **Riverpod 3.x** per la gestione dello stato:

- `Provider`: Per servizi singleton (database, repository)
- `StateNotifier`/`Notifier`: Per stato mutabile complesso
- `FutureProvider`: Per dati asincroni (statistiche, configurazioni)
- `StreamProvider`: Per dati reattivi (lista zone, iniezioni)

**Esempio pattern**:
```dart
// Provider per dati
final injectionsProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllInjections();
});

// Notifier per azioni
class AuthNotifier extends Notifier<AuthState> {
  Future<void> signOut() async { ... }
}
```

### 4. Database: Drift

**Tabelle principali**:
- `BodyZones`: Zone corporee per le iniezioni
- `Injections`: Registro delle iniezioni
- `TherapyPlans`: Piano terapeutico
- `BlacklistedPoints`: Punti esclusi
- `PointConfigs`: Configurazione personalizzata punti
- `UserProfiles`: Profilo utente
- `AppSettings`: Impostazioni chiave-valore

**Caratteristiche**:
- Type-safe queries con codice generato
- Migrazioni automatiche
- Supporto Web (IndexedDB via WASM)

### 5. Navigation: GoRouter

Routing dichiarativo con:
- Deep linking support
- Shell routes per navigazione principale
- Redirect per autenticazione

## Pattern Utilizzati

### Repository Pattern
Separazione tra logica di business e accesso ai dati:
```
Feature -> Provider -> Repository -> Database
```

### Widget Composition
Widget piccoli e riutilizzabili in `core/widgets/`:
- `LoadingCard`, `ErrorCard`
- `StatCard`, `SectionHeader`
- `ConfirmDialog`, `EmptyStateCard`
- `ShimmerLoading`, `AnimatedCounter`

### ML/Suggerimenti Intelligenti
Sistema di raccomandazioni basato su regole in `core/ml/`:
- `ZonePredictionModel`: Suggerisce la zona ottimale
- `TimeOptimizer`: Suggerisce l'orario migliore
- `AdherenceScorer`: Analizza l'aderenza alla terapia
- `RotationPatternEngine`: Gestisce 7 pattern di rotazione

### Pattern di Rotazione
Sistema configurabile per la rotazione delle zone (`models/rotation_pattern.dart`):
- **Smart (AI)**: Analisi storico per suggerimento ottimale
- **Sequential**: Rotazione fissa tra le 8 zone
- **AlternateSides**: Alternanza lato sinistro/destro
- **WeeklyRotation**: Una zona per settimana
- **Clockwise/CounterClockwise**: Percorso orario/antiorario
- **Custom**: Sequenza definita dall'utente

### Stili Home
Due layout selezionabili dall'utente (`auth_provider.dart`):
- **Classic**: Vista completa con statistiche e panoramica settimanale
- **Minimalist**: Solo prossima iniezione con silhouette interattiva

## Decisioni Architetturali

### ADR-001: Offline-Only (v3.0)
**Contesto**: Google Sign-In e backup su Drive causavano problemi di configurazione e manutenzione.

**Decisione**: Rimuovere tutte le dipendenze Google (Sign-In, Drive, Calendar).

**Conseguenze**:
- ✅ App più semplice e affidabile
- ✅ Nessuna configurazione OAuth necessaria
- ✅ Privacy migliorata (dati solo locali)
- ⚠️ Nessun backup automatico cloud

### ADR-002: Drift invece di SQLite diretto
**Contesto**: Necessità di un database type-safe con supporto multi-piattaforma.

**Decisione**: Utilizzare Drift con supporto nativo + WASM per web.

**Conseguenze**:
- ✅ Queries type-safe
- ✅ Supporto Web senza modifiche
- ✅ Migrazioni gestite automaticamente

### ADR-003: Rule-Based ML invece di TensorFlow
**Contesto**: Suggerimenti intelligenti per zone e orari.

**Decisione**: Utilizzare algoritmi statistici/rule-based invece di veri modelli ML.

**Conseguenze**:
- ✅ Nessuna dipendenza pesante (TensorFlow ~50MB)
- ✅ Funziona offline senza download modelli
- ✅ Trasparente e debuggabile
- ⚠️ Meno sofisticato di veri modelli ML

### ADR-004: Feature-First invece di Layer-First
**Contesto**: Organizzazione del codice per scalabilità.

**Decisione**: Struttura feature-first con codice condiviso in `core/`.

**Conseguenze**:
- ✅ Feature isolate e testabili
- ✅ Facile aggiungere nuove feature
- ✅ Codice correlato raggruppato insieme

### ADR-005: Versione Dinamica (v4.2)
**Contesto**: La versione era hardcoded in più punti del codice.

**Decisione**: Usare `package_info_plus` per leggere la versione da `pubspec.yaml`.

**Conseguenze**:
- ✅ Versione aggiornata automaticamente ovunque
- ✅ Mostra anche il numero di build
- ✅ Un solo punto di aggiornamento (pubspec.yaml)

### ADR-006: Home Styles (v4.0)
**Contesto**: Utenti diversi preferiscono livelli di dettaglio diversi.

**Decisione**: Due stili di home selezionabili (Classic/Minimalist).

**Conseguenze**:
- ✅ UX personalizzabile
- ✅ Minimalist come default per semplicità
- ✅ Classic per utenti che vogliono più informazioni

## Performance

### Ottimizzazioni Applicate
- `const` constructors dove possibile
- `AutoDispose` su provider non globali
- Lazy loading degli screen
- Caching in memoria per calcoli ripetuti
- Widget riutilizzabili per evitare rebuild

### Metriche Target
- Cold start: < 2s
- Navigation: < 100ms
- Database query: < 50ms

## Testing

### Struttura Test
```
test/
├── unit/           # Test unitari (provider, servizi)
├── widget/         # Test widget (UI)
└── integration/    # Test end-to-end
```

### Mock Strategy
- `mocktail` per mock type-safe
- Database in-memory per test
- Provider overrides per isolamento

## Sicurezza

- **Dati locali**: Tutti i dati sensibili sono salvati solo sul dispositivo
- **No analytics**: Nessun tracciamento o telemetria
- **Export sicuro**: PDF/CSV restano sul dispositivo

## Localizzazione

Supporto multilingua tramite ARB files:
- Italiano (predefinito)
- English
- Deutsch
- Français
- Español

## Dipendenze Principali

| Dipendenza | Uso |
|------------|-----|
| `flutter_riverpod` | State management |
| `drift` | Database SQLite |
| `go_router` | Navigation |
| `flutter_local_notifications` | Notifiche |
| `table_calendar` | Widget calendario |
| `fl_chart` | Grafici statistiche |
| `pdf` | Export PDF |
| `csv` | Import/Export CSV |
| `file_picker` | Selezione file per import |
| `package_info_plus` | Versione app dinamica |

## Contribuire

1. Leggi questo documento
2. Segui la struttura feature-first
3. Aggiungi test per nuove funzionalità
4. Usa i widget comuni da `core/widgets/`
5. Mantieni le feature isolate
