# Manuale Utente - InjeCare Plan

> La tua terapia, sotto controllo.

---

## Indice

1. [Introduzione](#introduzione)
2. [Primo Avvio](#primo-avvio)
3. [Dashboard Home](#dashboard-home)
4. [Registrare un'Iniezione](#registrare-uniniezione)
5. [Calendario](#calendario)
6. [Statistiche](#statistiche)
7. [Storico](#storico)
8. [Impostazioni](#impostazioni)
9. [Privacy e Sicurezza](#privacy-e-sicurezza)
10. [Domande Frequenti (FAQ)](#domande-frequenti-faq)

---

## Introduzione

**InjeCare Plan** è un'applicazione progettata per aiutarti a gestire la tua terapia iniettiva in modo semplice, sicuro e completamente privato.

### Caratteristiche Principali

- **Calendario intelligente**: Pianifica automaticamente le tue iniezioni
- **Mappa del corpo interattiva**: Ruota i punti di iniezione per evitare sovrapposizioni
- **Pattern di rotazione configurabili**: Scegli come ruotare le zone (AI, sequenza, alternanza, settimanale, personalizzato)
- **Suggerimenti AI**: Raccomandazioni intelligenti per zone e orari ottimali
- **Statistiche avanzate**: Grafici aderenza, heatmap zone, trend settimanali
- **Promemoria configurabili**: Non dimenticare mai una dose
- **Storico completo**: Tieni traccia di tutte le iniezioni
- **100% Offline**: I tuoi dati restano esclusivamente sul tuo dispositivo
- **Import/Export CSV**: Backup e importazione dati in formato semplice
- **Dati demo**: Opzione per provare l'app con dati di esempio

---

## Primo Avvio

Al primo avvio dell'app, vedrai una breve introduzione alle funzionalità principali.

<p align="center">
  <img src="../assets/screenshots/onboarding.png" width="280" alt="Schermata di Onboarding">
</p>

### Avvio Rapido

1. Scorri le schermate introduttive per scoprire le funzionalità
2. Scegli se inserire **dati demo** (~12 iniezioni nell'ultimo mese) o iniziare da zero
3. Tocca **"Inizia"** per entrare nell'app
4. Completa la configurazione iniziale del piano terapeutico

> **Nota**: L'app funziona completamente offline. I tuoi dati non lasciano mai il dispositivo.

### Dati Demo

Durante l'onboarding puoi scegliere di inserire dati di prova per esplorare le funzionalità:
- **~12 iniezioni** distribuite nell'ultimo mese
- **3 iniezioni a settimana** (Lunedì, Mercoledì, Venerdì)
- Tutte le zone vengono utilizzate in rotazione

Questa opzione è utile per vedere come funzionano le statistiche e i suggerimenti AI.

---

## Dashboard Home

Dopo il primo avvio, verrai accolto dalla schermata principale.

<p align="center">
  <img src="../assets/screenshots/home.png" width="280" alt="Dashboard Home">
</p>

### Elementi della Dashboard

| Elemento | Descrizione |
|----------|-------------|
| **Suggerimento AI** | Raccomandazione intelligente basata sui tuoi pattern |
| **Appuntamenti Settimanali** | Le prossime iniezioni programmate nella settimana |
| **Aderenza** | Percentuale di aderenza negli ultimi 30 giorni |
| **Registra ora** | Pulsante rapido per registrare l'iniezione |

### Suggerimenti Intelligenti

L'app analizza i tuoi dati per fornirti raccomandazioni personalizzate:

- **Zona suggerita**: La zona meno utilizzata di recente
- **Orario ottimale**: Basato sui tuoi pattern di successo
- **Avvisi aderenza**: Se l'aderenza cala sotto l'80%

Tocca la card del suggerimento per seguire la raccomandazione.

### Barra di Navigazione

In basso trovi quattro schede:
- **Home** - Dashboard principale
- **Calendario** - Vista mensile delle iniezioni
- **Nuova** - Registra una nuova iniezione
- **Impostazioni** - Configura l'app

---

## Registrare un'Iniezione

### Passo 1: Seleziona la Zona

Tocca "Registra ora" o "Nuova" per aprire la selezione punti.

<p align="center">
  <img src="../assets/screenshots/body_map.png" width="280" alt="Selezione Punto">
</p>

Il corpo è diviso in **8 zone**:

| Codice | Nome | Punti |
|--------|------|-------|
| CD | Coscia Destra | 6 |
| CS | Coscia Sinistra | 6 |
| BD | Braccio Destro | 4 |
| BS | Braccio Sinistro | 4 |
| AD | Addome Destro | 4 |
| AS | Addome Sinistro | 4 |
| GD | Gluteo Destro | 4 |
| GS | Gluteo Sinistro | 4 |

La zona **suggerita** dall'AI è evidenziata in verde.

### Passo 2: Seleziona il Punto

Usa la silhouette interattiva per selezionare il punto esatto.

- **Punti verdi**: Disponibili e suggeriti
- **Punti arancioni**: Usati di recente
- **Punti grigi**: Esclusi (blacklist)

Tocca il punto desiderato sulla silhouette.

### Passo 3: Conferma l'Iniezione

<p align="center">
  <img src="../assets/screenshots/record_injection.png" width="280" alt="Registra Iniezione">
</p>

In questa schermata puoi:

1. **Confermare** il punto selezionato
2. **Aggiungere note** (opzionale)
3. **Segnalare effetti collaterali** (opzionale)
4. **Salvare** l'iniezione

Dopo il salvataggio, l'app:
- Aggiorna lo storico
- Ricalcola la prossima iniezione suggerita
- Programma il prossimo promemoria

---

## Calendario

La vista calendario mostra tutte le iniezioni programmate e completate.

<p align="center">
  <img src="../assets/screenshots/calendar.png" width="280" alt="Calendario">
</p>

### Legenda Colori

- **Blu**: Iniezione programmata (futura)
- **Verde**: Iniezione completata
- **Rosso**: Iniezione saltata
- **Grigio**: Giorno senza iniezioni

### Interazioni

- **Tocca un giorno**: Vedi i dettagli delle iniezioni
- **Scorri sinistra/destra**: Cambia mese
- **Tocca un evento**: Modifica o elimina l'iniezione
- **Pulsante +**: Aggiungi iniezione nel giorno selezionato

### Modifica Eventi

Toccando un evento puoi:
- Cambiare il punto di iniezione
- Segnare come "Saltata" con motivo
- Eliminare l'evento

---

## Statistiche

Accedi alle statistiche avanzate dal menu laterale o dalle impostazioni.

<p align="center">
  <img src="../assets/screenshots/statistics.png" width="280" alt="Statistiche">
</p>

### Grafici Disponibili

| Grafico | Descrizione |
|---------|-------------|
| **Trend Aderenza** | Andamento mensile dell'aderenza in percentuale |
| **Heatmap Zone** | Mappa visiva dell'utilizzo di ogni zona |
| **Distribuzione Settimanale** | Iniezioni per giorno della settimana |
| **Storico Mensile** | Confronto tra mesi |

### Filtri Periodo

Puoi filtrare le statistiche per:
- Ultima settimana
- Ultimo mese
- Ultimi 3 mesi
- Ultimo anno
- Tutto

---

## Storico

Lo storico mostra tutte le iniezioni passate in ordine cronologico.

<p align="center">
  <img src="../assets/screenshots/history.png" width="280" alt="Storico">
</p>

### Funzionalità

- **Filtri**: Filtra per periodo, stato o zona
- **Dettagli**: Tocca un'iniezione per vedere i dettagli
- **Export**: Esporta in PDF o CSV (icona in alto a destra)

### Formato Export

Il report esportato include:
- Data e ora di ogni iniezione
- Punto utilizzato
- Note ed effetti collaterali
- Statistiche di aderenza
- Grafici riassuntivi (solo PDF)

Ideale per condividere con il tuo neurologo.

---

## Impostazioni

<p align="center">
  <img src="../assets/screenshots/settings.png" width="280" alt="Impostazioni">
</p>

### Sezioni Impostazioni

#### Piano Terapeutico

| Opzione | Descrizione |
|---------|-------------|
| **Iniezioni settimanali** | Numero di iniezioni a settimana (default: 3) |
| **Giorni** | Giorni della settimana (es. Lun, Mer, Ven) |
| **Orario preferito** | Ora promemoria (es. 20:00) |

#### Pattern di Rotazione

L'app include **5 piani di rotazione predefiniti** per le tue iniezioni. Puoi selezionare quello più adatto alle tue esigenze:

| Pattern | Descrizione |
|---------|-------------|
| **Suggerimento AI** | L'AI suggerisce la zona migliore basandosi sullo storico e sul tempo trascorso (default) |
| **Sequenza zone** | Segue un ordine fisso: Coscia Sx → Coscia Dx → Braccio Sx → Braccio Dx → ... |
| **Alternanza Sx/Dx** | Alterna sempre tra lato sinistro e destro del corpo |
| **Rotazione settimanale** | Cambia tipo di zona ogni settimana (es. cosce questa settimana, braccia la prossima) |
| **Personalizzato** | Definisci tu l'ordine delle zone da seguire con drag-and-drop |

**Come selezionare un pattern:**
1. Vai in **Impostazioni** > **Pattern di Rotazione**
2. Tocca il pattern attivo per aprire la lista
3. Seleziona il nuovo pattern desiderato
4. Il pattern selezionato sarà contrassegnato come **ATTIVO**

> **Consiglio**: Se hai bisogno di seguire uno schema specifico prescritto dal medico, usa il pattern "Personalizzato" per definire esattamente l'ordine delle zone.

#### Zone e Punti

- **Gestione zone**: Visualizza e configura le zone del corpo
- **Editor punti**: Personalizza posizione e nome dei punti con la silhouette interattiva
- **Punti esclusi**: Gestisci i punti in blacklist

<p align="center">
  <img src="../assets/screenshots/blacklist.png" width="280" alt="Punti Esclusi">
</p>

> **Punti Esclusi**: Puoi escludere punti che causano reazioni, hanno cicatrici o sono difficili da raggiungere. I punti esclusi non vengono suggeriti automaticamente ma restano selezionabili manualmente.

#### Notifiche

| Opzione | Descrizione |
|---------|-------------|
| **Promemoria iniezione** | Attiva/disattiva promemoria |
| **Anticipo** | Minuti prima dell'orario (es. 30 min) |

#### Aspetto

| Opzione | Descrizione |
|---------|-------------|
| **Tema** | Chiaro, Scuro o Automatico (segue il sistema) |
| **Lingua** | Italiano, English, Deutsch, Français, Español |

#### Dati

| Opzione | Descrizione |
|---------|-------------|
| **Esporta storico (PDF)** | Export completo con grafici per il medico |
| **Esporta storico (CSV)** | Export in formato semplice per backup |
| **Importa da CSV** | Importa iniezioni da un file CSV |
| **Elimina tutti i dati** | Rimuove tutti i dati (irreversibile) |

### Import CSV

Puoi importare iniezioni da un file CSV con questo formato:

```
data,zona,punto,stato
2024-07-15 20:00,CD,3,completed
2024-07-17 20:00,CS,1,completed
```

**Zone disponibili:** CD, CS, BD, BS, AD, AS, GD, GS

**Stati:** completed, scheduled, skipped, delayed

---

## Privacy e Sicurezza

### Dati 100% Locali

- Tutti i dati sono salvati **esclusivamente** sul dispositivo
- Utilizziamo **SQLite** (Drift) per massima affidabilità
- **Nessun dato viene mai inviato** a server esterni
- **Nessuna connessione internet richiesta**

### Privacy nell'Interfaccia

- L'app **non mostra riferimenti espliciti** alla patologia
- Ideale per utilizzo in pubblico

### Export Sicuro

- I file PDF/CSV esportati restano sul tuo dispositivo
- Condividili solo con chi desideri tu

---

## Domande Frequenti (FAQ)

### L'app richiede connessione internet?

**No!** L'app funziona completamente offline. Non richiede mai connessione internet.

### Come faccio il backup dei dati?

Puoi esportare tutti i dati in formato CSV dalla sezione Storico. Il file può essere salvato dove preferisci (cloud personale, email, etc.).

### Posso esportare i dati per il mio medico?

**Sì!** Vai in Storico e tocca l'icona di export in alto a destra. Puoi generare un PDF con grafici o un CSV con i dati grezzi.

### L'app funziona su tablet?

**Sì!** L'interfaccia si adatta automaticamente a schermi più grandi.

### Posso modificare le zone di iniezione?

**Sì!** Vai in Impostazioni → Gestione Zone per personalizzare le zone e i punti. Puoi anche spostare i punti sulla silhouette.

### L'app invia notifiche?

**Sì!** Puoi configurare promemoria per ogni iniezione. Le notifiche sono locali e non richiedono connessione internet.

### Come funzionano i suggerimenti AI?

L'app analizza localmente i tuoi dati di utilizzo per suggerire:
- La zona meno utilizzata di recente
- L'orario in cui hai maggior successo
- Avvisi se l'aderenza sta calando

Tutto avviene sul dispositivo, nessun dato viene inviato a server esterni.

### Posso escludere dei punti di iniezione?

**Sì!** Vai in Impostazioni → Gestione Zone → seleziona una zona → Punti esclusi. Puoi specificare il motivo dell'esclusione (reazione, cicatrice, difficile accesso).

### Cosa succede se aggiorno l'app?

**I tuoi dati vengono preservati!** Puoi aggiornare l'app tranquillamente senza doverla disinstallare:
- Tutte le iniezioni registrate rimangono
- Le tue impostazioni sono mantenute
- Le nuove funzionalità vengono aggiunte automaticamente
- I pattern di rotazione mancanti vengono creati durante l'aggiornamento

L'app gestisce automaticamente la migrazione dei dati tra una versione e l'altra.

---

## Supporto

Per segnalare bug o richiedere funzionalità:

- **GitHub Issues**: [github.com/WaYdotNET/inje-care-plan/issues](https://github.com/WaYdotNET/inje-care-plan/issues)
- **Website**: [waydotnet.com](https://waydotnet.com)

---

**InjeCare Plan** - Sviluppato con ❤️ da Carlo Bertini (WaYdotNET)

Licenza: GPL-3.0
