---
name: InjeCare Roadmap v2.0
overview: Piano completo multi-fase per l'evoluzione di InjeCare Plan con statistiche avanzate, promemoria intelligenti, widget, animazioni, localizzazione e test automatizzati.
todos:
  - id: stats-provider
    content: Creare statistics_provider.dart con calcolo metriche
    status: completed
  - id: stats-screen
    content: Creare statistics_screen.dart con UI grafici
    status: completed
  - id: stats-charts
    content: Implementare widget grafici (adherence, heatmap, trend)
    status: completed
  - id: stats-route
    content: Aggiungere route e navigazione a statistiche
    status: completed
  - id: smart-reminders
    content: Implementare smart_reminder_service per notifiche mancate
    status: completed
  - id: zone-suggestion
    content: Migliorare suggerimenti zona basati su tempo
    status: completed
  - id: pdf-enhanced
    content: PDF report con grafici e formattazione medico
    status: completed
  - id: widget-android
    content: Widget Android con prossima iniezione
    status: completed
  - id: widget-ios
    content: Widget iOS con WidgetKit
    status: completed
  - id: animations
    content: Hero animation e shimmer loading
    status: completed
  - id: onboarding-tour
    content: Tutorial guidato con overlay spotlight
    status: completed
  - id: darkmode-auto
    content: Dark mode automatica con orario
    status: completed
  - id: i18n-setup
    content: Setup localizzazione con ARB files
    status: completed
  - id: tests-unit
    content: Unit test per provider principali
    status: completed
  - id: tests-widget
    content: Widget test per schermate
    status: completed
  - id: performance
    content: Cache immagini e lazy loading
    status: completed
---

# InjeCare Plan - Roadmap v2.0

## Panoramica Fasi

```mermaid
gantt
    title Roadmap Implementazione
    dateFormat  YYYY-MM-DD
    section Fase 1
    Statistiche Avanzate       :a1, 2026-01-04, 3d
    section Fase 2
    Promemoria Intelligenti    :a2, after a1, 2d
    PDF Migliorato             :a3, after a2, 2d
    section Fase 3
    Widget Home Screen         :a4, after a3, 3d
    section Fase 4
    Animazioni UI              :a5, after a4, 2d
    Onboarding Guidato         :a6, after a5, 2d
    Dark Mode Auto             :a7, after a6, 1d
    section Fase 5
    Localizzazione             :a8, after a7, 2d
    Test Automatizzati         :a9, after a8, 3d
    Performance                :a10, after a9, 1d
```

---

## FASE 1: Statistiche Avanzate (Priorita Alta)

### 1.1 Nuova schermata Statistiche

**File:** `lib/features/statistics/statistics_screen.dart`

- Grafici mensili/annuali con `fl_chart`
- Heatmap zone del corpo (quale zona usata di piu)
- Trend aderenza con linea temporale
- Filtri per periodo (settimana/mese/anno/custom)

### 1.2 Provider Statistiche

**File:** `lib/features/statistics/statistics_provider.dart`

```dart
// Dati calcolati
class InjectionStats {
  final int totalInjections;
  final double adherenceRate;
  final Map<String, int> zoneUsage; // heatmap
  final List<MonthlyData> monthlyTrend;
  final int currentStreak;
  final int longestStreak;
}
```



### 1.3 Widget riutilizzabili

**Files:**

- `lib/features/statistics/widgets/adherence_chart.dart`
- `lib/features/statistics/widgets/zone_heatmap.dart`
- `lib/features/statistics/widgets/trend_line_chart.dart`

### Dipendenze da aggiungere

```yaml
dependencies:
  fl_chart: ^0.69.0
```

---

## FASE 2: Promemoria Intelligenti + PDF

### 2.1 Notifiche Mancate

**File:** `lib/core/services/smart_reminder_service.dart`

- Controlla a fine giornata se iniezione prevista non fatta
- Invia notifica "Hai dimenticato l'iniezione di oggi?"
- Opzione "Salta" o "Registra ora"

### 2.2 Suggerimenti Zona

**File:** `lib/core/services/zone_suggestion_service.dart`

- Calcola tempo dall'ultima iniezione per ogni zona
- Suggerisce la zona meno usata di recente
- Evita zone in blacklist

### 2.3 PDF Report Migliorato

**File:** `lib/core/services/pdf_report_service.dart`

- Intestazione con logo e dati paziente
- Grafici embedded (aderenza, zone)
- Tabella storico formattata
- Footer con data generazione

---

## FASE 3: Widget Home Screen

### 3.1 Android Widget

**Files:**

- `android/app/src/main/kotlin/.../InjeCareWidget.kt`
- `android/app/src/main/res/layout/widget_layout.xml`

### 3.2 iOS Widget (WidgetKit)

**Files:**

- `ios/InjeCareWidget/InjeCareWidget.swift`
- `ios/InjeCareWidget/InjeCareWidgetBundle.swift`

### 3.3 Shared Data

**File:** `lib/core/services/widget_data_service.dart`

- Prossima iniezione programmata
- Aderenza settimana corrente
- Quick action per registrare

---

## FASE 4: UI/UX Polish

### 4.1 Animazioni

- Hero animation su card iniezioni
- Shimmer loading (`shimmer: ^3.0.0`)
- Animated counters per statistiche
- Page transitions con `animations` package

### 4.2 Onboarding Guidato

**File:** `lib/features/onboarding/guided_tour.dart`

- Overlay tutorial con spotlight
- Tooltip contestuali su prima apertura
- Skip/Next navigation
- Salva stato completamento

### 4.3 Dark Mode Automatica

- Opzione "Sistema" in theme selector
- Orario personalizzabile (20:00-07:00)
- Transizione smooth

---

## FASE 5: Tecnico

### 5.1 Localizzazione (i18n)

**Files:**

- `lib/l10n/app_it.arb` (italiano - default)
- `lib/l10n/app_en.arb` (inglese)
- `lib/l10n/app_de.arb` (tedesco)
- `lib/l10n/app_fr.arb` (francese)
- `lib/l10n/app_es.arb` (spagnolo)

### 5.2 Test Automatizzati

**Files:**

- `test/unit/providers/*_test.dart`
- `test/widget/*_screen_test.dart`
- `integration_test/app_test.dart`

### 5.3 Performance

- `cached_network_image` per avatar
- Lazy loading zone con `Riverpod`
- Query ottimizzate con indici DB

---

## File Principali da Creare

| Fase | File | Descrizione ||------|------|-------------|| 1 | `statistics_screen.dart` | Schermata principale stats || 1 | `statistics_provider.dart` | Calcolo metriche || 1 | `adherence_chart.dart` | Grafico aderenza || 1 | `zone_heatmap.dart` | Heatmap zone || 2 | `smart_reminder_service.dart` | Notifiche intelligenti || 2 | `pdf_report_service.dart` | Report PDF avanzato || 3 | `widget_data_service.dart` | Dati per widget || 4 | `guided_tour.dart` | Tutorial onboarding || 5 | `app_*.arb` | File traduzioni |---

## Dipendenze Totali

```yaml
dependencies:
  fl_chart: ^0.69.0           # Grafici
  shimmer: ^3.0.0             # Loading shimmer
  cached_network_image: ^3.4.1 # Cache immagini
  flutter_localizations:
    sdk: flutter
  intl: any

dev_dependencies:
  mocktail: ^1.0.4            # Mocking per test
  integration_test:
    sdk: flutter


```