---
name: Fix Bug InjeCare
overview: "Correzione di 6 bug nell'app InjeCare Plan: unificazione schermate selezione punto, editor visuale zone con SVG, sistema eventi settimanali con suggerimenti AI, fix calendario data selezionata, gestione modifica eventi, e persistenza login Google."
todos:
  - id: unify-screens
    content: "Unificare schermate: usare PointSelectionScreen per entrambe le modalita'"
    status: completed
  - id: db-points
    content: Aggiungere tabella point_configs al database per configurazioni punti
    status: completed
  - id: svg-asset
    content: Creare/importare asset SVG silhouette corpo umano
    status: completed
  - id: silhouette-editor
    content: Creare widget BodySilhouetteEditor con drag-and-drop punti
    status: completed
  - id: zone-dialog
    content: Modificare ZoneEditDialog per gestire singoli punti
    status: completed
  - id: week-events-list
    content: "Homepage: lista verticale eventi settimanali con badge AI"
    status: completed
  - id: suggested-events
    content: Generare eventi suggeriti se non esistono nel calendario
    status: completed
  - id: auto-skip-missed
    content: Auto-mark come skipped eventi passati nella settimana
    status: completed
  - id: weekly-proposals
    content: Nuova schermata Proposte Settimanali per approvazione eventi
    status: completed
  - id: sunday-notification
    content: Notifica domenica per approvare proposte settimanali
    status: completed
  - id: calendar-date
    content: "Calendario: passare data selezionata al flusso di creazione"
    status: completed
  - id: event-edit
    content: Aggiungere modifica/elimina eventi nel calendario
    status: completed
  - id: google-signin
    content: Condividere istanza GoogleSignIn tra auth e backup
    status: completed
  - id: signin-persist
    content: Verificare persistenza signInSilently all'avvio
    status: completed
---

# Fix Bug InjeCare Plan

## Bug 1: Unificare schermate selezione punto

**Problema**: La schermata "Registra iniezione" usa `BodyMapScreen` -> `ZoneDetailScreen`, mentre "Escludi punto" usa `PointSelectionScreen`. Le UI sono diverse.**Soluzione**: Usare `PointSelectionScreen` anche per la registrazione iniezione. Modificare:

- [router.dart](lib/app/router.dart): Cambiare la rotta `/body-map` per usare `PointSelectionScreen` con `mode: injection`
- Rimuovere o deprecare `BodyMapScreen` e `ZoneDetailScreen` (o mantenerle per altri usi)
- Aggiornare i link in [home_screen.dart](lib/features/home/home_screen.dart) e [calendar_screen.dart](lib/features/calendar/calendar_screen.dart)

---

## Bug 2: Editor visuale zone con silhouette SVG

**Problema**: La schermata modifica zona non permette di inserire nomi e posizioni dei singoli punti.**Soluzione**: Creare un sistema completo di gestione punti con editor visuale:

1. **Nuovo modello dati**: Creare tabella `point_configs` nel database per salvare configurazioni punti (nome, posizione X/Y per zona)
2. **Asset SVG silhouette**: Creare/importare un SVG stilizzato del corpo umano (fronte e retro)
3. **Nuovo widget `BodySilhouetteEditor`**:

- Mostra la silhouette SVG come sfondo
- Permette di posizionare punti con drag-and-drop
- Gestisce punti per zona selezionata

4. **Modificare `_ZoneEditDialog`** in [zone_management_screen.dart](lib/features/settings/zone_management_screen.dart):

- Aggiungere tab/sezione per gestire i singoli punti
- Integrare `BodySilhouetteEditor`
- Salvare configurazioni punti nel database

---

## Bug 3: Sistema eventi settimanali con suggerimenti AI

**Problema**: `_NextInjectionCard` mostra sempre una data calcolata dal piano terapeutico, anche se l'iniezione e' nel passato o non esiste.**Soluzione**: Implementare un sistema completo di gestione eventi settimanali:

### 3.1 Lista eventi settimanali in Homepage

Modificare [home_screen.dart](lib/features/home/home_screen.dart):

- Sostituire `_NextInjectionCard` con `_WeeklyEventsCard`
- Mostrare lista verticale di tutti gli eventi della settimana corrente
- Per ogni giorno della settimana mostrare:
- Evento confermato (dal database) con stato (pending/completed/skipped)
- Oppure evento **suggerito** con badge "AI" se non esiste evento per quel giorno
```dart
class _WeeklyEventItem extends StatelessWidget {
  final DateTime date;
  final Injection? confirmedEvent;  // null se suggerito
  final SuggestedPoint? suggestion; // non null se suggerito
  final bool isSuggested;

  // Badge AI per eventi suggeriti
  Widget _buildAiBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 10)),
  );
}
```




### 3.2 Generazione eventi suggeriti

Creare nuovo provider in [injection_provider.dart](lib/features/injection/injection_provider.dart):

- `weeklyEventsProvider`: combina eventi reali + suggerimenti
- Per ogni giorno del piano terapeutico senza evento, genera suggerimento
- Usa algoritmo esistente `getSuggestedNextPoint()` per punto suggerito

### 3.3 Auto-skip eventi mancati

Creare servizio `MissedInjectionService`:

- All'avvio app, controlla eventi nella settimana corrente con data passata
- Se evento schedulato e' passato e status = 'pending' -> marca come 'skipped'
- Se giorno del piano e' passato senza evento -> crea evento 'skipped' con punto random
```dart
Future<void> checkAndMarkMissedInjections() async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  // 1. Marca eventi pending passati come skipped
  final pendingPast = await getInjections(weekStart, now, status: 'pending');
  for (final inj in pendingPast) {
    if (inj.scheduledAt.isBefore(now)) {
      await skipInjection(inj.id);
    }
  }

  // 2. Crea eventi skipped per giorni mancanti del piano
  final therapyDays = getTherapyDaysInRange(weekStart, now);
  for (final day in therapyDays) {
    if (!hasEventOnDay(day)) {
      await createSkippedInjection(day, randomPoint: true);
    }
  }
}
```




### 3.4 Schermata Proposte Settimanali

Creare nuova schermata [weekly_proposals_screen.dart](lib/features/home/weekly_proposals_screen.dart):

- Lista di tutti gli eventi suggeriti per la prossima settimana
- Per ogni proposta:
- Data e ora suggerita
- Zona e punto suggeriti con badge AI
- Pulsanti: **Approva** | **Modifica** | **Salta**
- "Approva" crea l'evento nel database
- "Modifica" apre PointSelectionScreen per cambiare punto
- "Salta" ignora la proposta (non crea evento)
- Pulsante "Approva tutti" in alto

### 3.5 Notifica domenicale

Modificare [notification_service.dart](lib/core/services/notification_service.dart):

- Schedulare notifica ricorrente ogni domenica (es. ore 10:00)
- Testo: "Hai X iniezioni proposte per questa settimana. Tocca per confermarle."
- Tap sulla notifica apre `WeeklyProposalsScreen`

### 3.6 Click su evento suggerito

In `_WeeklyEventItem`:

- Tap su evento suggerito -> apre `PointSelectionScreen` con data pre-impostata
- Dopo conferma, l'evento viene creato nel database
- La lista si aggiorna mostrando l'evento come confermato

---

## Bug 4: Calendario usa data corrente invece di quella selezionata

**Problema**: Il FAB nel calendario naviga a `/body-map` senza passare la data selezionata.**Soluzione**: Modificare [calendar_screen.dart](lib/features/calendar/calendar_screen.dart):

- Passare `selectedDay` come parametro extra nella navigazione
- Modificare `RecordInjectionScreen` o il flusso per accettare una data preselezionata
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => context.push(
    AppRoutes.bodyMap,
    extra: {'scheduledDate': selectedDay ?? DateTime.now()},
  ),
  child: const Icon(Icons.add),
),
```


---

## Bug 5: Modificare/eliminare eventi nel calendario

**Problema**: Gli eventi nel calendario non sono interattivi, non si possono modificare o eliminare.**Soluzione**: Modificare `_InjectionCard` in [calendar_screen.dart](lib/features/calendar/calendar_screen.dart):

1. **Aggiungere `onTap`** per aprire un dialog/bottom sheet con opzioni:

- Segna come completata
- Segna come saltata
- Modifica punto
- Elimina

2. **Creare `_InjectionEditDialog`** con:

- Dropdown per stato (pending/completed/skipped)
- Opzione per cambiare zona/punto
- Pulsante elimina con conferma

3. **Usare metodi esistenti** in `InjectionRepository`:

- `completeInjection()`
- `skipInjection()`
- `updateInjection()`
- `deleteInjection()`

---

## Bug 6: Login Google non persistente

**Problema**: Il login Google viene richiesto ogni volta, lo stato non viene salvato correttamente.**Soluzione**: Il problema e' che `BackupService` crea una propria istanza di `GoogleSignIn` separata da `AuthRepository`. Quando si usa il backup, il login non e' condiviso.Modifiche:

1. **Condividere `GoogleSignIn`**: Creare un provider singleton per `GoogleSignIn` in [auth_provider.dart](lib/features/auth/auth_provider.dart)
2. **Modificare `BackupService`**: Ricevere `GoogleSignIn` come dipendenza invece di crearne uno nuovo
3. **Verificare `signInSilently()`**: Assicurarsi che venga chiamato correttamente all'avvio in `AuthRepository.initialize()`
4. **Persistenza token**: Verificare che `GoogleSignIn` stia usando correttamente il keychain/secure storage del dispositivo
```dart
// Provider condiviso per GoogleSignIn
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
});
```


---