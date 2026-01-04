# Changelog

Tutte le modifiche rilevanti a InjeCare Plan sono documentate in questo file.

Il formato segue [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e il progetto aderisce a [Semantic Versioning](https://semver.org/lang/it/).

## [3.5.0] - 2026-01-04

### Nuovo
- **Panoramica settimanale migliorata**: La home mostra tutti i 7 giorni della settimana con:
  - Indicatori visivi per ogni giorno (completato ✓, suggerito ✨, mancato ✗, riposo)
  - Contatore progressi (es. 2/3 iniezioni completate)
  - Visualizzazione compatta che evidenzia oggi
- **Chiarezza onboarding**: Aggiunta nota informativa che spiega la differenza tra:
  - Dati demo (iniezioni passate per testare)
  - Suggerimenti AI (proposte future basate sul piano terapeutico)

### Migliorato
- **Silhouette aggiornate**: Pulita cache asset per garantire visualizzazione corretta fronte/retro
- **Eventi settimanali**: Ora tutti i 7 giorni vengono visualizzati, anche i giorni di riposo

---

## [3.4.3] - 2026-01-04

### Corretto
- **Migrazione database ottimizzata**: L'app può essere aggiornata senza perdere i dati esistenti
  - Gli utenti che aggiornano da versioni precedenti manterranno le loro iniezioni e impostazioni
  - I piani mancanti vengono creati automaticamente durante la migrazione
  - Il piano esistente viene mantenuto come attivo
- Nuova funzione `_migrateTherapyPlansToV4()` per gestire aggiornamenti da versioni precedenti

---

## [3.4.2] - 2026-01-04

### Migliorato
- **Screenshot aggiornati**: Tutti gli screenshot del README mostrano correttamente le nuove funzionalità
- Screenshot per: Home, Calendario, Selezione punti, Impostazioni, Demo data, Onboarding

---

## [3.4.1] - 2026-01-04

### Corretto
- **Selezione pattern di rotazione**: I pattern ora sono correttamente selezionabili
- **5 piani terapeutici predefiniti**: All'avvio vengono creati 5 piani (Smart, Sequenza, Alternanza, Settimanale, Personalizzato)
- **Attivazione piano**: Solo un piano può essere attivo alla volta
- Migrazione database per supportare il campo `isActive` e `name` sui piani
- Fix test per la nuova architettura dei piani multipli

### Aggiunto
- `getAllTherapyPlans()` per ottenere tutti i piani disponibili
- `activateTherapyPlan(id)` per cambiare il piano attivo
- `allTherapyPlansProvider` per l'UI di selezione
- Provider `activatePlan()` e `activatePlanByType()` nel servizio

---

## [3.4.0] - 2026-01-04

### Aggiunto
- **Pattern di Rotazione Configurabili**: Nuova sezione in Impostazioni per scegliere lo schema di rotazione
  - **Suggerimento AI**: L'AI suggerisce la zona migliore (comportamento precedente)
  - **Sequenza zone**: Segue un ordine fisso predefinito (Coscia Sx → Coscia Dx → ...)
  - **Alternanza Sx/Dx**: Alterna tra lato sinistro e destro del corpo
  - **Rotazione settimanale**: Cambia tipo di zona ogni settimana
  - **Personalizzato**: Definisci tu l'ordine delle zone con drag-and-drop
- **Schermata sequenza personalizzata**: Riordina le zone per creare la tua sequenza
- **Indicatori visivi silhouette**: Viso stilizzato sulla vista frontale, nuca/scapole sulla vista posteriore
- **Etichette FRONTE/RETRO**: Testo indicativo su ogni silhouette
- Modello `RotationPattern` con supporto JSON e database
- `RotationPatternEngine` per gestire tutti i tipi di pattern
- Test unitari per `RotationPattern` (13 test)

### Migliorato
- Silhouette corpo più riconoscibile (fronte vs retro)
- Smart suggestions ora rispettano il pattern configurato
- Sezione impostazioni riorganizzata

---

## [3.3.0] - 2026-01-04

### Aggiunto
- **Storico punti per zona**: Visualizza l'ultimo utilizzo di ogni punto con indicatori colorati
  - Verde (★ Nuovo): Mai usato o >14 giorni - consigliato
  - Giallo: 7-14 giorni - attenzione
  - Arancione: 3-7 giorni - recente
  - Rosso: <3 giorni - evitare
- Lista punti ordinata dal meno usato al più recente
- Metodo `getPointUsageHistory()` in database
- Provider `pointUsageHistoryProvider` per caricare lo storico

### Corretto
- **Modifica iniezioni**: Ora "Cambia punto" aggiorna l'iniezione esistente invece di creare un duplicato
- Propagazione `existingInjectionId` attraverso router e schermate
- `updateInjection()` chiamato correttamente invece di `createInjection()`

---

## [3.2.0] - 2026-01-04

### Aggiunto
- **Dati demo in onboarding**: Opzione per inserire ~12 iniezioni demo nell'ultimo mese
- **Import CSV**: Possibilità di importare iniezioni da file CSV
- **Formato CSV unificato**: Export e import usano lo stesso formato semplice

### Cambiato
- **Iniezioni future**: Se la data è nel futuro, lo stato è automaticamente "scheduled"
- **Formato export CSV semplificato**: `data,zona,punto,stato`
- **Onboarding**: Nuova pagina 4 per scegliere se inserire dati demo

### Rimosso
- **Sblocco biometrico**: Rimosso per problemi di compatibilità (local_auth)

### Corretto
- Fix parametri Drift in test fixtures
- Fix test helpers con Override type

---

## [3.1.0] - 2026-01-04

### Aggiunto
- **Sblocco biometrico**: Supporto Face ID / Touch ID all'avvio
  - Nuova schermata `BiometricLockScreen`
  - Provider `biometricEnabledProvider`, `requiresBiometricUnlockProvider`
  - Persistenza impostazione in SharedPreferences
- Redirect automatico via GoRouter per schermata di sblocco

### Migliorato
- **Test coverage 100%** su tutti i 57 file non generati
- Totale **642 test** passati
- 5 nuovi test per funzionalità biometrica

---

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
