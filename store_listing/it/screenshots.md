# Google Play Store — Screenshot e Asset Grafici

> Guida per la selezione e l'upload degli screenshot nella Google Play Console.

---

## App icon (512x512 PNG)

| Asset | Percorso | Dimensione |
|-------|----------|------------|
| Play Store icon | `AppIcons/playstore.png` | 512x512 px |

Pronto per l'upload. Google applica automaticamente il corner radius (30%).

---

## Feature graphic (1024x500 PNG) — DA GENERARE

| Asset | Percorso | Dimensione |
|-------|----------|------------|
| Feature graphic template | `store_listing/feature_graphic.html` | 1024x500 px |

Aprire il template HTML nel browser e fare screenshot a 1024x500px (vedi istruzioni nel file HTML).

---

## Phone screenshots (min 2, max 8)

Risoluzione esistente: **1080x2400** (aspect ratio 9:20, accettato da Google Play).

### Screenshot consigliati per il listing (in ordine di priorita)

| # | Descrizione | Percorso | Note |
|---|-------------|----------|------|
| 1 | Home | `screenshots/02_home.png` | Prima schermata: mostra la dashboard principale |
| 2 | Calendario | `screenshots/03_calendar.png` | Visualizzazione calendario con iniezioni |
| 3 | Selezione punto | `screenshots/05_point_selection.png` | Mappa corpo con selezione zona/punto |
| 4 | Impostazioni | `screenshots/04_settings.png` | Configurazione app e piano terapeutico |
| 5 | Statistiche | `assets/screenshots/statistics.png` | Grafici aderenza e distribuzione |
| 6 | Storico | `assets/screenshots/history.png` | Lista iniezioni con filtri |

### Ordine suggerito per Google Play

Caricare nell'ordine 1-6. I primi 3 screenshot sono i più importanti perché appaiono
nell'anteprima della scheda dello store.

---

## Tablet screenshots (opzionale)

Non disponibili al momento. Google Play accetta screenshot da telefono anche per tablet
se non vengono forniti screenshot specifici.

---

## Checklist pre-upload

- [ ] App icon (512x512) — `AppIcons/playstore.png`
- [ ] Feature graphic (1024x500) — generata da `store_listing/feature_graphic.html`
- [ ] Almeno 2 phone screenshots (consigliati 4-6)
- [ ] Short description (max 80 char) — vedi `store_listing/it/listing.md`
- [ ] Full description (max 4000 char) — vedi `store_listing/it/listing.md`
- [ ] Privacy policy URL — `https://waydotnet.github.io/inje-care-plan/privacy/`
- [ ] Content rating completato
- [ ] Categoria: Medicina (Medical)
