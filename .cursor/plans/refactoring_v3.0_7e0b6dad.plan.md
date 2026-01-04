---
name: Refactoring v3.0
overview: Riorganizzare il codebase, rimuovere Google services, migliorare manutenibilita e creare documentazione completa.
todos:
  - id: remove-google
    content: Rimuovere Google Sign-In, Drive backup, Calendar sync
    status: completed
  - id: create-daos
    content: Estrarre DAOs dal database in file separati
    status: cancelled
  - id: common-widgets
    content: Creare widget riutilizzabili in core/widgets
    status: completed
  - id: remove-dead-code
    content: Rimuovere body_map_screen.dart e codice non usato
    status: completed
  - id: add-const
    content: Aggiungere const e ottimizzazioni performance
    status: completed
  - id: architecture-doc
    content: Creare docs/ARCHITECTURE.md
    status: completed
  - id: update-readme
    content: Aggiornare README.md con nuove info
    status: completed
  - id: create-changelog
    content: Creare CHANGELOG.md
    status: completed
  - id: update-screenshots
    content: Aggiornare screenshot app
    status: cancelled
  - id: version-bump
    content: Aggiornare versione a 3.0.0 e creare PR
    status: in_progress
---

# Refactoring InjeCare v3.0 - Best Practices

## Obiettivi

- Rimuovere dipendenze Google (semplificazione)
- Separazione responsabilita (Single Responsibility Principle)
- Performance ottimizzate
- Documentazione completa (ARCHITECTURE, README, CHANGELOG)
- Screenshot aggiornati

## Modifiche Pianificate

### 1. RIMUOVERE GOOGLE SERVICES

**File da eliminare:**

- `lib/core/services/backup_service.dart`
- `lib/core/services/backup_provider.dart`
- `lib/core/services/calendar_sync_service.dart`

**File da modificare:**

- `lib/features/auth/auth_provider.dart` - rimuovere Google Sign-In
- `lib/features/auth/auth_repository.dart` - rimuovere Google
- `lib/features/settings/settings_screen.dart` - rimuovere sezione backup/sync
- `pubspec.yaml` - rimuovere dipendenze Google

**Dipendenze da rimuovere:**

```yaml
google_sign_in: ^6.2.2
googleapis: ^15.0.0
googleapis_auth: ^2.0.0
```



### 2. Separare Database DAOs

Estrarre DAOs in file separati:

```javascript
lib/core/database/
    - app_database.dart      (solo configurazione ~100 righe)
    - tables.dart            (definizioni tabelle)
    - daos/
        - injection_dao.dart   (CRUD iniezioni)
        - zone_dao.dart        (CRUD zone)
        - therapy_dao.dart     (CRUD piano terapia)
        - settings_dao.dart    (CRUD impostazioni)
```



### 3. Widget Riutilizzabili

Estrarre in `lib/core/widgets/`:

- `LoadingCard` / `ErrorCard`
- `SectionHeader`
- `StatCard`
- `ConfirmDialog`

### 4. Rimuovere Codice Morto

- `lib/features/injection/body_map_screen.dart`
- Riferimenti a Google in tutto il codebase
- Import non utilizzati

### 5. Performance Optimizations

- Aggiungere `const` ovunque possibile
- Usare `AutoDispose` sui provider
- Fix deprecation warnings (`withOpacity` -> `withValues`)

### 6. Documentazione

**docs/ARCHITECTURE.md:**

- Struttura progetto
- Pattern utilizzati (Riverpod, Repository, Feature-first)
- Flusso dati
- Decisioni architetturali

**README.md:**

- Descrizione app
- Screenshot
- Requisiti
- Installazione
- Struttura progetto
- Contributing

**CHANGELOG.md:**

- v3.0.0 - Refactoring completo
- v2.0.x - ML Smart Suggestions
- v1.x.x - Versioni precedenti

### 7. Screenshot

Catturare nuovi screenshot da emulatore:

- Home screen
- Calendario
- Selezione zona
- Statistiche
- Impostazioni

## File da Eliminare

| File | Motivo ||------|--------|| `lib/core/services/backup_service.dart` | Google Drive rimosso || `lib/core/services/backup_provider.dart` | Google Drive rimosso || `lib/core/services/calendar_sync_service.dart` | Google Calendar rimosso || `lib/features/injection/body_map_screen.dart` | Sostituito |

## File da Creare

| File | Contenuto ||------|-----------|| `lib/core/database/daos/injection_dao.dart` | DAO iniezioni || `lib/core/database/daos/zone_dao.dart` | DAO zone || `lib/core/widgets/common_widgets.dart` | Widget condivisi || `docs/ARCHITECTURE.md` | Documentazione architettura || `CHANGELOG.md` | Storico versioni |

## Risultato Atteso

- App 100% offline (nessuna dipendenza Google)
- Codebase piu leggero (~3 dipendenze in meno)
- Documentazione completa per nuovi sviluppatori
- Screenshot aggiornati