# InjeCare Plan

> La tua terapia, sotto controllo.

Applicazione Flutter per la gestione delle iniezioni di Interferone beta-1a per pazienti con terapie iniettive.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue)](LICENSE)
[![GitHub](https://img.shields.io/github/stars/WaYdotNET/inje-care-plan?style=social)](https://github.com/WaYdotNET/inje-care-plan)

**Developed by [Carlo Bertini](https://waydotnet.com) (WaYdotNET)**

- 📖 **[Manuale Utente](docs/MANUALE_UTENTE.md)** - Guida dettagliata con screenshot
- 🏗️ **[Architettura](docs/ARCHITECTURE.md)** - Documentazione tecnica

## Screenshots

<p align="center">
  <img src="assets/screenshots/home.png" width="180" alt="Home">
  <img src="assets/screenshots/calendar.png" width="180" alt="Calendario">
  <img src="assets/screenshots/statistics.png" width="180" alt="Statistiche">
  <img src="assets/screenshots/settings.png" width="180" alt="Impostazioni">
</p>

## Caratteristiche

### Core
- 📅 **Calendario intelligente**: Pianificazione automatica delle iniezioni
- 🧍 **Mappa corpo interattiva**: 8 zone con rotazione automatica dei punti
- 🔔 **Promemoria avanzati**: Notifiche configurabili
- 📊 **Statistiche avanzate**: Grafici aderenza, heatmap zone, trend settimanali
- 🤖 **Suggerimenti AI**: Raccomandazioni intelligenti per zone e orari
- 📤 **Export PDF/CSV**: Condivisione report con il medico

### Privacy-First (Offline-Only)
- 🔒 **100% Offline**: Tutti i dati restano sul tuo dispositivo
- 🛡️ **Nessun cloud**: Nessuna dipendenza da servizi esterni
- 👁️ **Privacy UI**: Nessun riferimento esplicito alla patologia
- 🔐 **Sblocco biometrico**: Supporto Face ID / Touch ID

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| Framework | Flutter 3.38+ / Dart 3.10+ |
| Database | Drift (SQLite) - offline-first |
| State | Riverpod 3.x |
| Routing | go_router |
| Notifiche | flutter_local_notifications |
| Grafici | fl_chart |
| Calendario | table_calendar |

## Requisiti

- Flutter SDK 3.38+
- Dart SDK 3.10+
- Android 5.0+ o iOS 12.0+

## Test

Il progetto include una suite completa di test:

```bash
# Esegui tutti i test
flutter test

# Test con copertura
flutter test --coverage
```

**Copertura dei test:**
- Unit test per modelli (`BodyZone`, `TherapyPlan`)
- Unit test per provider (`AuthProvider`, `InjectionProvider`)
- Unit test per algoritmi ML (`ZonePredictionModel`, `TimeOptimizer`, `AdherenceScorer`)
- Widget test per componenti UI (`ShimmerLoading`, `AnimatedCounter`, `CommonWidgets`)
- Integration test per flussi principali

## Setup

### 1. Clona il repository

```bash
git clone https://github.com/WaYdotNET/inje-care-plan.git
cd inje-care-plan
```

### 2. Installa le dipendenze

```bash
flutter pub get
```

### 3. Genera il codice Drift

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Esegui l'app

```bash
flutter run
```

## Struttura Progetto

```
lib/
├── app/                    # Router e configurazione
├── core/
│   ├── database/           # Drift database
│   ├── ml/                 # Algoritmi ML/suggerimenti
│   ├── services/           # Notifiche, export, etc.
│   ├── theme/              # Tema Rosé Pine
│   └── widgets/            # Widget riutilizzabili
├── features/
│   ├── auth/               # Onboarding
│   ├── calendar/           # Vista calendario
│   ├── history/            # Storico iniezioni
│   ├── home/               # Dashboard
│   ├── injection/          # Registrazione iniezioni
│   ├── settings/           # Impostazioni
│   └── statistics/         # Statistiche avanzate
└── models/                 # Modelli dati
```

## Zone di Iniezione

| Codice | Nome | Punti |
|--------|------|-------|
| CD | Coscia Dx | 6 |
| CS | Coscia Sx | 6 |
| BD | Braccio Dx | 4 |
| BS | Braccio Sx | 4 |
| AD | Addome Dx | 4 |
| AS | Addome Sx | 4 |
| GD | Gluteo Dx | 4 |
| GS | Gluteo Sx | 4 |

**Totale: 36 punti** con rotazione automatica.

## Design System

L'app utilizza la palette [Rosé Pine](https://rosepinetheme.com/palette/):
- **Light Mode**: Rosé Pine Dawn
- **Dark Mode**: Rosé Pine

## Localizzazione

Lingue supportate:
- 🇮🇹 Italiano (default)
- 🇬🇧 English
- 🇩🇪 Deutsch
- 🇫🇷 Français
- 🇪🇸 Español

## Autore

**Carlo Bertini** (WaYdotNET)
- 🌐 Website: [waydotnet.com](https://waydotnet.com)
- 📦 Repository: [github.com/WaYdotNET/inje-care-plan](https://github.com/WaYdotNET/inje-care-plan)

## Licenza

Questo progetto è rilasciato sotto licenza **GNU General Public License v3.0**.

Vedi il file [LICENSE](LICENSE) per i dettagli completi.

```
InjeCare Plan - App per gestione terapie iniettive
Copyright (C) 2024-2026 Carlo Bertini (WaYdotNET)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```
