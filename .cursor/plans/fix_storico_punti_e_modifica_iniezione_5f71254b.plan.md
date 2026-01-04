---
name: Fix Storico Punti e Modifica Iniezione
overview: "Ripristino di due funzionalita' core perse durante i refactoring: visualizzazione storico punti per evitare riutilizzo ravvicinato, e fix della modifica iniezione che creava duplicati invece di aggiornare."
todos:
  - id: point-usage-query
    content: Aggiungere getPointUsageHistory() in app_database.dart
    status: completed
  - id: repo-history
    content: Aggiungere getLastUsageForZone() in injection_repository.dart
    status: completed
    dependencies:
      - point-usage-query
  - id: point-history-widget
    content: Creare widget _PointHistoryCard con indicatore giorni/colore
    status: completed
    dependencies:
      - repo-history
  - id: integrate-history
    content: Integrare storico punti in _ZoneDetailCard
    status: completed
    dependencies:
      - point-history-widget
  - id: pass-injection-id
    content: Passare existingInjectionId da calendar_screen a bodyMap
    status: completed
  - id: propagate-id
    content: Propagare existingInjectionId in point_selection_screen e router
    status: completed
    dependencies:
      - pass-injection-id
  - id: update-record-screen
    content: Modificare record_screen per usare updateInjection se ID esiste
    status: completed
    dependencies:
      - propagate-id
---

# Fix Storico Punti e Modifica Iniezione

## Problema 1: Manca lo storico punti per zona

La schermata di selezione punto non mostra piu' lo storico d'uso di ogni punto. Questo impedisce all'utente di sapere quali punti sono stati usati di recente e quali evitare.

### Soluzione

Modificare `_ZoneDetailCard` in [`point_selection_screen.dart`](lib/features/injection/point_selection_screen.dart) per aggiungere:

1. **Per ogni punto mostrare:**

- Data ultimo utilizzo ("Ultima: 15 dic 2025")
- Giorni trascorsi ("18 giorni fa" o "Mai usato")
- Indicatore colore:
    - Verde: mai usato o >14 giorni
    - Giallo: 7-14 giorni
    - Arancione: 3-7 giorni
    - Rosso: <3 giorni (sconsigliato)

2. **Ordinare i punti dal meno usato al piu' usato**
3. **Aggiungere metodo nel repository:**
```dart
// In injection_repository.dart
Future<Map<int, DateTime?>> getLastUsageForZone(int zoneId) async {
  // Ritorna mappa: pointNumber -> ultima data uso
}
```




### File da modificare

- [`lib/features/injection/point_selection_screen.dart`](lib/features/injection/point_selection_screen.dart): Aggiungere widget `_PointHistoryList` che mostra storico punti
- [`lib/features/injection/injection_repository.dart`](lib/features/injection/injection_repository.dart): Aggiungere `getLastUsageForZone()`
- [`lib/core/database/app_database.dart`](lib/core/database/app_database.dart): Aggiungere query `getPointUsageHistory()`

---

## Problema 2: Modifica iniezione crea duplicato

Quando si clicca "Cambia punto" nel calendario, viene creata una NUOVA iniezione invece di aggiornare quella esistente.

### Causa

In `calendar_screen.dart` linea 463:

```dart
onChangePoint: () {
  context.push(AppRoutes.bodyMap, extra: {'scheduledDate': injection.scheduledAt});
  // ↑ Manca injectionId!
}
```



### Soluzione

1. **Passare l'ID dell'iniezione esistente** nel flusso di modifica:
```dart
onChangePoint: () {
  context.push(AppRoutes.bodyMap, extra: {
    'scheduledDate': injection.scheduledAt,
    'existingInjectionId': injection.id,  // NUOVO
  });
}
```




2. **Modificare `RecordInjectionScreen`** per:

- Accettare parametro `existingInjectionId`
- Se presente, chiamare `updateInjection()` invece di `createInjection()`
- Eliminare la vecchia iniezione e crearne una nuova con il nuovo punto

### File da modificare

- [`lib/features/calendar/calendar_screen.dart`](lib/features/calendar/calendar_screen.dart): Passare `existingInjectionId` in `onChangePoint`
- [`lib/features/injection/point_selection_screen.dart`](lib/features/injection/point_selection_screen.dart): Propagare `existingInjectionId`
- [`lib/features/injection/record_screen.dart`](lib/features/injection/record_screen.dart): Gestire update vs create
- [`lib/app/router.dart`](lib/app/router.dart): Aggiungere parametro `existingInjectionId` alle rotte

---

## Riepilogo modifiche

| File | Modifica |

|------|----------|

| `injection_repository.dart` | Aggiungere `getLastUsageForZone()` |

| `app_database.dart` | Aggiungere query storico punti |

| `point_selection_screen.dart` | Aggiungere widget storico punti + propagare `existingInjectionId` |

| `calendar_screen.dart` | Passare `existingInjectionId` in modifica |

| `record_screen.dart` | Gestire update vs create |