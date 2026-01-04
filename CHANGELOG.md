# Changelog

Tutte le modifiche rilevanti a InjeCare Plan sono documentate in questo file.

Il formato segue [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e il progetto aderisce a [Semantic Versioning](https://semver.org/lang/it/).

## [3.0.0] - 2026-01-04

### Cambiato
- **BREAKING**: Rimosso Google Sign-In, Drive backup e Calendar sync
- App completamente offline-first senza dipendenze cloud
- Semplificato onboarding (nessun login richiesto)
- Riorganizzato codice seguendo best practices

### Aggiunto
- Documentazione architetturale (`docs/ARCHITECTURE.md`)
- Widget riutilizzabili in `core/widgets/`
- Questo CHANGELOG

### Rimosso
- Dipendenze: `google_sign_in`, `googleapis`, `googleapis_auth`
- File: `backup_service.dart`, `backup_provider.dart`, `calendar_sync_service.dart`
- File: `body_map_screen.dart` (deprecato)

### Migliorato
- Performance: aggiunto `const` ovunque possibile
- Risolti tutti i warning linter
- Sostituito `withOpacity` deprecato con `withValues`

## [2.0.1] - 2026-01-03

### Corretto
- Navigazione SmartSuggestionCard
- Gestione errori Google Sign-In migliorata

## [2.0.0] - 2026-01-03

### Aggiunto
- **Suggerimenti AI**: Sistema di raccomandazioni intelligenti
  - `ZonePredictionModel`: Suggerisce la zona ottimale
  - `TimeOptimizer`: Suggerisce l'orario migliore
  - `AdherenceScorer`: Analizza l'aderenza alla terapia
- `SmartSuggestionCard` nella home
- Nuovo modulo `core/ml/` per algoritmi ML

## [1.3.0] - 2026-01-02

### Aggiunto
- **Statistiche avanzate**: Nuova schermata con grafici
  - Grafico aderenza mensile
  - Heatmap utilizzo zone
  - Trend settimanale
- **Localizzazione**: Supporto IT, EN, DE, FR, ES
- **UI Polish**: Shimmer loading, animated counters
- Onboarding tour guidato
- Widget per home screen Android/iOS

### Migliorato
- Export PDF con grafici incorporati
- Dark mode automatico con orario personalizzabile

## [1.2.2] - 2026-01-01

### Migliorato
- Editor punti fullscreen con zoom/pan
- Toolbar floating per editing
- Griglia toggleabile

## [1.2.1] - 2025-12-31

### Aggiunto
- Silhouette corpo a tutto schermo
- Nomi punti personalizzabili (max 3 caratteri)

### Corretto
- RadioGroup migration per deprecation warnings

## [1.2.0] - 2025-12-30

### Aggiunto
- Editor visuale posizione punti
- Silhouette corpo come sfondo
- Configurazione punti per zona

### Migliorato
- Icona app aggiornata
- UI generale migliorata

## [1.1.0] - 2025-12-29

### Aggiunto
- Supporto Web con IndexedDB (Drift WASM)
- Gestione eventi skipped automatica

### Corretto
- Calendario: data corretta per nuovi eventi
- Homepage: eventi mostrati correttamente

## [1.0.0] - 2025-12-28

### Prima Release
- Calendario iniezioni con pianificazione automatica
- 8 zone corporee con 36 punti totali
- Rotazione automatica punti
- Notifiche promemoria
- Export PDF/CSV
- Backup cifrato su Google Drive
- Tema Rosé Pine (light/dark)
