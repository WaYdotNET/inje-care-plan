# Changelog

Tutte le modifiche rilevanti a InjeCare Plan sono documentate in questo file.

Il formato segue [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e il progetto aderisce a [Semantic Versioning](https://semver.org/lang/it/).

## [4.2.5] - 2026-01-05

### Aggiornato
- **Guida in-app completamente riscritta**: Rimossi riferimenti a Google Drive backup
- Nuove sezioni: Pattern di Rotazione, Stili Home, Import/Export CSV
- FAQ aggiornate con domande attuali

## [4.2.4] - 2026-01-05

### Corretto
- **Coordinate punti unificate**: La home minimal ora usa le stesse coordinate esatte di `generateDefaultPointPositions`
- I punti sono ora correttamente posizionati sulla silhouette, allineati con la schermata di selezione punto

## [4.2.3] - 2026-01-05

### Corretto
- **Punti proporzionali**: I punti sulla silhouette ora si ridimensionano proporzionalmente alla dimensione della silhouette
- **Versione dinamica ovunque**: La versione dell'app è ora dinamica anche nella schermata Impostazioni (era hardcoded a v4.1.0)

## [4.2.2] - 2026-01-05

### Corretto
- **Home Minimalista di default**: La home minimalista è ora il default per tutti gli utenti (nuovi e esistenti)

## [4.2.1] - 2026-01-05

### Migliorato
- **Versione dinamica**: La versione dell'app viene ora letta automaticamente dal `pubspec.yaml` tramite `package_info_plus`
- Non più necessario aggiornare manualmente la versione nella schermata Info
- Mostra anche il numero di build: "Versione X.Y.Z (build N)"

## [4.2.0] - 2026-01-05

### Aggiornato
- **Nuovo logo**: Aggiornate tutte le icone dell'app (Android, iOS, assets)
- **Cache pulita**: Ricompilazione completa con nuove risorse
- **Screenshot aggiornati**: Nuove immagini con il logo aggiornato
- **Documentazione**: README e manuale utente aggiornati

## [4.1.6] - 2026-01-05

### Aggiunto
- **Menu rapido in Home Minimal**: Aggiunto pulsante ⋮ nell'app bar con accesso rapido a:
  - 📜 Storico
  - 📊 Statistiche
  - ❓ Guida
  - ℹ️ Info

## [4.1.5] - 2026-01-05

### Aggiunto
- **Test notifiche**: Nuovo pulsante nelle impostazioni per testare le notifiche di promemoria
  - Mostra una notifica di esempio per verificare funzionamento e aspetto
  - Utile per confermare che le notifiche sono configurate correttamente

## [4.1.4] - 2026-01-05

### Modificato
- **Emoji per zone del corpo**: Ripristinati gli emoji originali (🦵💪💧🍑) al posto delle Material Icons per una migliore leggibilità

Le zone ora mostrano:
- Coscia: 🦵
- Braccio: 💪
- Addome: 💧
- Gluteo: 🍑

## [4.1.3] - 2026-01-05

### Modificato
- **Home Minimalista default**: Ora è la home di default per nuove installazioni
- **Iniezioni programmate in home**: La home minimal mostra le iniezioni già programmate con la possibilità di segnarle come completate
- **Posizione punti braccio**: Corrette le coordinate dei punti per braccia (sinistro e destro)
- **Conferma immediata**: Dalla home minimal si può confermare un'iniezione programmata con un tap

### Corretto
- Posizioni X/Y errate per le zone braccio nella silhouette
- La home minimalista ora mostra correttamente iniezioni programmate invece di solo suggerimenti AI

## [4.1.2] - 2026-01-05

### Migliorato
- **UX conferma iniezione**: Dopo aver inserito una nuova iniezione, viene mostrato un dialog che permette di segnarla subito come completata, senza dover andare al calendario
- **Risolto toast bloccato**: I toast ora scompaiono correttamente grazie a `clearSnackBars()` prima di mostrarne uno nuovo
- **Feedback più chiaro**: Toast più brevi (2 secondi) e messaggi più concisi

## [4.1.1] - 2026-01-05

### Cambiato
- **Passaggio a Material Icons**: Sostituito il set icone Rosepine SVG personalizzato con [Google Material Icons](https://fonts.google.com/icons)
  - Navigation bar: icone `home`, `calendar_month`, `add_circle`, `settings`
  - Zone del corpo: icone semantiche (`accessibility_new`, `fitness_center`, `circle_outlined`, `airline_seat_legroom_reduced`)
  - Vantaggio: icone già incluse in Flutter, nessun asset aggiuntivo, stile coerente con Material Design 3

### Rimosso
- Pacchetto icone Rosepine SVG (`assets/icons/rosepine/`)
- Helper `RosepineIcons` e widget correlati
- Dipendenza da flutter_svg per le icone (mantenuta solo per silhouette corpo)

## [4.1.0] - 2026-01-05

### Aggiunto
- **Pattern di rotazione oraria e antioraria**: Due nuovi pattern per la rotazione delle zone
  - Oraria: Braccio Sx → Braccio Dx → Addome Dx → Gluteo Dx → Coscia Dx → Coscia Sx → Gluteo Sx → Addome Sx
  - Antioraria: percorso inverso
- **Visualizzazione data/ora nella selezione punto**: L'utente può vedere e modificare l'orario dell'iniezione prima di confermare
- **Set completo icone Rosepine**: ~40 icone SVG minimaliste organizzate per categoria, pronte per futura pubblicazione come repo separato
  - Categorie: body, actions, status, navigation, patterns, misc
  - Stile coerente con tema Rosepine

### Migliorato
- **Workflow iniezioni**: Tutte le iniezioni vengono prima salvate come "scheduled", poi l'utente può confermarle dal calendario
- **Drag and drop punti più fluido**: Ottimizzato con throttling (~60fps) e hit area estesa per migliore UX
- **Coordinate punti precise**: Aggiornate secondo l'immagine di riferimento `posizione_punti.png`
- **Nomi personalizzati nello storico**: I punti con nome custom mostrano correttamente il nome personalizzato nella lista storico

### Corretto
- **Calcolo giorni iniezioni passate**: Ora usa `scheduledAt` invece di `completedAt` per calcolare i giorni trascorsi
- **Feedback onboarding migliorato**: Messaggio più chiaro che spiega la differenza tra dati demo e suggerimenti AI

---

## [4.0.0] - 2026-01-04

### Aggiunto
- **Due stili di Home**: L'utente può scegliere tra due visualizzazioni
  - **Classica**: Vista completa con tutte le informazioni, statistiche, azioni rapide
  - **Minimalista**: Focus solo sulla prossima iniezione con silhouette interattiva
- **Selettore stile home**: Nuova opzione in Impostazioni > Aspetto per cambiare stile
- Provider `homeStyleProvider` per gestione preferenza
- Persistenza della preferenza in SharedPreferences
- `HomeMinimalScreen` con:
  - Data corrente e prossima iniezione
  - Silhouette con punto suggerito evidenziato
  - Tap per registrare direttamente
  - Indicatore pattern e confidenza AI

### Migliorato
- Router condizionale che mostra la home corretta in base alla preferenza
- Info screen aggiornata con versione 4.0
- Settings screen riorganizzata con sezione Aspetto migliorata

---

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
