# InjeCare Plan

> La tua terapia, sotto controllo.

Applicazione Flutter per la gestione delle iniezioni di Interferone beta-1a per pazienti con terapie iniettive.

![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)

## Screenshots

<p align="center">
  <img src="assets/screenshots/home.png" width="180" alt="Home">
  <img src="assets/screenshots/body_map.png" width="180" alt="Body Map">
  <img src="assets/screenshots/zone_detail.png" width="180" alt="Zona">
  <img src="assets/screenshots/record_injection.png" width="180" alt="Registra">
</p>

<p align="center">
  <img src="assets/screenshots/calendar.png" width="180" alt="Calendario">
  <img src="assets/screenshots/settings.png" width="180" alt="Impostazioni">
</p>

> L'app funziona completamente offline. Google è opzionale per il backup su Drive.

## Caratteristiche

### Core
- **📅 Calendario intelligente**: Pianificazione automatica delle iniezioni con supporto a più schemi terapeutici (3x/settimana default)
- **🧍 Mappa corpo interattiva**: 8 zone di iniezione con rotazione automatica dei punti
- **🔔 Promemoria avanzati**: Notifiche push configurabili pre e post-iniezione
- **📊 Diario terapia**: Storico completo con note ed effetti collaterali
- **📤 Export**: Generazione PDF/CSV dello storico per condivisione con medico

### Privacy-First Architecture
- **🔒 Offline-first**: Database SQLite locale con Drift
- **☁️ Backup cifrato**: Google Drive con cifratura AES-256 (password utente)
- **🔐 Cross-device**: Ripristino backup su qualsiasi dispositivo con la stessa password
- **🛡️ GDPR-compliant**: Nessun dato sensibile su server centrali
- **👁️ Privacy UI**: Nessun riferimento esplicito alla patologia nell'interfaccia

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| Framework | Flutter 3.38+ / Dart 3.10+ |
| Database | **Drift (SQLite)** - offline-first |
| Backup | **Google Drive** + AES-256 encryption |
| Auth | Google Sign-in (solo per Drive API) |
| Crypto | PBKDF2 (100k iterations) + AES-256-CBC |
| Calendario | table_calendar |
| State | Riverpod 3.x |
| Routing | go_router |
| Notifiche | flutter_local_notifications |

## Architettura Sicurezza

```
┌─────────────────────────────────────────────────────────────┐
│                      DISPOSITIVO                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   SQLite DB     │    │        CryptoService            │ │
│  │   (Drift)       │───▶│  PBKDF2(password, salt) → key   │ │
│  │   Plain data    │    │  AES-256-CBC(data, key) → enc   │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└────────────────────────────────┬────────────────────────────┘
                                 │ [salt][iv][encrypted_data]
                                 ▼
                    ┌────────────────────────┐
                    │     Google Drive       │
                    │  (encrypted backup)    │
                    │  injecare_backup.enc   │
                    └────────────────────────┘
```

## Requisiti

- Flutter SDK 3.38+
- Dart SDK 3.10+
- Account Google (per backup su Drive)

## Setup

### 1. Clona il repository

```bash
git clone <repository-url>
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

### 4. Configura Google Sign-In

#### Android
1. Crea un progetto nella [Google Cloud Console](https://console.cloud.google.com/)
2. Abilita Google Drive API
3. Crea credenziali OAuth 2.0 per Android
4. Aggiungi il tuo SHA-1 fingerprint:
```bash
cd android && ./gradlew signingReport
```

#### iOS
1. Crea credenziali OAuth 2.0 per iOS nella Google Cloud Console
2. Aggiungi `GoogleService-Info.plist` a `ios/Runner/`
3. Configura URL schemes in `Info.plist`

### 5. Esegui l'app

```bash
flutter run
```

## Struttura Progetto

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── database/
│   │   ├── app_database.dart      # Drift database
│   │   ├── tables.dart            # Schema tabelle
│   │   └── database_provider.dart
│   ├── theme/
│   │   ├── app_colors.dart        # Palette Rosé Pine
│   │   └── app_theme.dart         # Light/Dark theme
│   ├── services/
│   │   ├── crypto_service.dart    # AES-256 + PBKDF2
│   │   ├── backup_service.dart    # Google Drive sync
│   │   ├── startup_service.dart   # App initialization
│   │   ├── notification_service.dart
│   │   ├── calendar_sync_service.dart
│   │   └── export_service.dart
│   └── utils/
├── features/
│   ├── auth/
│   ├── home/
│   ├── calendar/
│   ├── injection/
│   ├── history/
│   └── settings/
├── models/
│   ├── injection_record.dart
│   ├── therapy_plan.dart
│   ├── body_zone.dart
│   └── blacklisted_point.dart
└── l10n/
```

## Zone di Iniezione

| ID | Codice | Nome | Punti |
|----|--------|------|-------|
| 1 | CD | Coscia Dx | 6 |
| 2 | CS | Coscia Sx | 6 |
| 3 | BD | Braccio Dx | 4 |
| 4 | BS | Braccio Sx | 4 |
| 5 | AD | Addome Dx | 4 |
| 6 | AS | Addome Sx | 4 |
| 7 | GD | Gluteo Dx | 4 |
| 8 | GS | Gluteo Sx | 4 |

**Totale: 36 punti** con rotazione automatica per evitare sovrapposizioni.

**Formato identificativi:**
- Database/Export: `CD-3`
- UI: `Coscia Dx · 3`

## Backup e Ripristino

### Creare un Backup
1. Vai in **Impostazioni** → **Backup e Ripristino**
2. Tocca **Backup su Google Drive**
3. Inserisci una **password sicura** (minimo 8 caratteri)
4. Il backup viene cifrato e caricato su Drive

### Ripristinare su Nuovo Dispositivo
1. Accedi con lo stesso account Google
2. L'app rileva automaticamente il backup esistente
3. Inserisci la **stessa password** usata per il backup
4. I dati vengono decifrati e ripristinati

> ⚠️ **Importante**: La password non viene salvata. Se la dimentichi, non potrai recuperare il backup.

## Design System

L'app utilizza la palette [Rosé Pine](https://rosepinetheme.com/palette/):
- **Light Mode**: Rosé Pine Dawn
- **Dark Mode**: Rosé Pine

## Roadmap Future

- [ ] IA locale per suggerimenti intelligenti basati sullo storico
- [ ] Recovery key per backup (alternativa alla password)
- [ ] Condivisione report con neurologo
- [ ] Accesso caregiver (read-only)
- [ ] Widget iOS/Android per quick-access

## Licenza

Questo progetto è rilasciato sotto licenza **GNU General Public License v3.0**.

Vedi il file [LICENSE](LICENSE) per i dettagli completi.

```
InjeCare Plan - App per gestione terapie iniettive
Copyright (C) 2024

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```
