---
name: Update Docs & App Name
overview: Aggiornare documentazione (README, manuale utente, guida in-app) con funzionalità v3.0 e correggere il nome app da "injecare_plan" a "InjeCare Plan".
todos:
  - id: fix-app-name
    content: Correggere nome app in AndroidManifest e Info.plist
    status: completed
  - id: update-readme
    content: Aggiornare README con funzionalità v3.0
    status: completed
  - id: update-manual
    content: Aggiornare MANUALE_UTENTE.md con nuovi screenshot
    status: completed
  - id: update-tour
    content: Aggiornare guided_tour.dart
    status: completed
  - id: commit-push
    content: Commit e push modifiche
    status: pending
---

# Aggiornamento Documentazione e Nome App

## 1. Correggere Nome App

Il nome visualizzato deve essere "InjeCare Plan" (con spazio):| File | Campo ||------|-------|| `android/app/src/main/AndroidManifest.xml` | `android:label` || `ios/Runner/Info.plist` | `CFBundleDisplayName` |

## 2. Aggiornare README.md

- Rimuovere riferimenti a Google/backup
- Aggiungere sezione "Suggerimenti AI"
- Aggiornare stack tecnologico
- Aggiornare screenshot gallery

## 3. Aggiornare Manuale Utente

File: [`docs/MANUALE_UTENTE.md`](docs/MANUALE_UTENTE.md)

- Rimuovere sezioni Google/backup
- Aggiungere sezione "Suggerimenti Intelligenti"
- Aggiornare tutti gli screenshot con quelli nuovi
- Aggiornare descrizione schermata Home
- Aggiornare descrizione Impostazioni

## 4. Aggiornare Guida In-App

File: [`lib/features/onboarding/guided_tour.dart`](lib/features/onboarding/guided_tour.dart)

- Verificare e aggiornare i testi del tour