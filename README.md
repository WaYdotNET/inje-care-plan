# InjeCare Plan

> La tua terapia, sotto controllo.

Applicazione Flutter per la gestione delle iniezioni di Interferone beta-1a per pazienti con terapie iniettive.

## Caratteristiche

- **📅 Calendario intelligente**: Pianificazione automatica delle iniezioni con supporto a più schemi terapeutici
- **🧍 Mappa corpo interattiva**: 8 zone di iniezione con rotazione automatica dei punti
- **🔔 Promemoria avanzati**: Notifiche push configurabili pre e post-iniezione
- **📊 Diario terapia**: Storico completo con note ed effetti collaterali
- **☁️ Sync Cloud**: Firebase Firestore con persistenza offline nativa
- **📤 Export**: Generazione PDF/CSV dello storico
- **🔐 Privacy-first**: Nessun riferimento esplicito alla patologia, accesso biometrico

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| Framework | Flutter 3.38+ / Dart 3.10+ |
| Database | Firebase Firestore (offline-first) |
| Auth | Firebase Auth + Google Sign-in |
| Calendario | table_calendar |
| State | Riverpod 2.x |
| Routing | go_router |
| Notifiche | flutter_local_notifications |

## Requisiti

- Flutter SDK 3.38+
- Dart SDK 3.10+
- Firebase project configurato

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

### 3. Configura Firebase

```bash
# Installa FlutterFire CLI
dart pub global activate flutterfire_cli

# Configura Firebase (richiede un progetto Firebase esistente)
flutterfire configure
```

Questo genera `lib/firebase_options.dart` con le configurazioni per la tua app.

### 4. Configura Google Sign-In

#### Android
Aggiungi il tuo SHA-1 fingerprint alla console Firebase:
```bash
cd android && ./gradlew signingReport
```

#### iOS
Aggiungi il `GoogleService-Info.plist` a `ios/Runner/`.

### 5. Esegui l'app

```bash
flutter run
```

## Struttura Progetto

```
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Palette Rosé Pine
│   │   └── app_theme.dart       # Light/Dark theme
│   ├── services/
│   │   ├── firebase_service.dart
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

**Formato identificativi:**
- Database/Export: `CD-3`
- UI: `Coscia Dx · 3`

## Design System

L'app utilizza la palette [Rosé Pine](https://rosepinetheme.com/palette/):
- **Light Mode**: Rosé Pine Dawn
- **Dark Mode**: Rosé Pine

## Privacy e Sicurezza

- Nessun riferimento esplicito alla patologia nella UI
- Dati sincronizzati in modo sicuro con Firebase
- Autenticazione biometrica opzionale
- Persistenza offline per uso senza connessione
- GDPR-first by design

## Roadmap Future

- [ ] IA locale per suggerimenti intelligenti basati sullo storico
- [ ] Condivisione report con neurologo
- [ ] Accesso caregiver (read-only)

## Licenza

Proprietario - Tutti i diritti riservati.
