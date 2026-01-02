# Screenshots

Questa cartella contiene gli screenshot dell'app per il README.

## Screenshot disponibili

| Nome file | Descrizione |
|-----------|-------------|
| `onboarding_1.png` | Prima schermata onboarding - Pianifica con cura |
| `onboarding_2.png` | Seconda schermata onboarding - Alterna i siti |
| `onboarding_3.png` | Terza schermata onboarding - Login Google |

## Come generare gli screenshot

1. Esegui l'app su un simulatore/emulatore
2. Cattura le schermate con:
   - **iOS Simulator**: `Cmd + S` o File → Save Screen
   - **Android Emulator**: Icona camera nella toolbar
   - **Flutter**: `flutter screenshot`
   - **ADB**: `adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png`

## Screenshots richiesti per completare la documentazione

| Nome file | Descrizione | Stato |
|-----------|-------------|-------|
| `home.png` | Schermata Home con prossima iniezione | ❌ Richiede login |
| `calendar.png` | Vista calendario mensile | ❌ Richiede login |
| `body_map.png` | Mappa corpo interattiva | ❌ Richiede login |
| `settings.png` | Schermata impostazioni | ❌ Richiede login |

**Nota**: Per catturare le schermate principali è necessario configurare un account Google sull'emulatore.

## Dimensioni consigliate

- **iPhone**: 390 x 844 px (iPhone 14)
- **Android**: 412 x 892 px (Pixel 7)
- **Emulator usato**: 1080 x 2400 px (Pixel 6a)

## Ottimizzazione

Per ridurre la dimensione dei file PNG:

```bash
# Installa pngquant
brew install pngquant

# Ottimizza tutti gli screenshot
pngquant --quality=65-80 --ext .png --force *.png
```
