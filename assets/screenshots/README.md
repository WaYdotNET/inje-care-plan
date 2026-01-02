# Screenshots

Questa cartella contiene gli screenshot dell'app per il README.

## Screenshot disponibili

| Nome file | Descrizione |
|-----------|-------------|
| `home.png` | Dashboard principale con prossima iniezione |
| `body_map.png` | Mappa interattiva del corpo con 8 zone |
| `zone_detail.png` | Dettaglio zona con 6 punti di iniezione |
| `record_injection.png` | Form per registrare un'iniezione |
| `calendar.png` | Calendario mensile delle iniezioni |
| `settings.png` | Impostazioni (modalità offline) |

## Come generare gli screenshot

1. Esegui l'app su un simulatore/emulatore
2. Cattura le schermate con:
   - **Android Emulator**: `adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png`
   - **iOS Simulator**: `Cmd + S` o File → Save Screen
   - **Flutter**: `flutter screenshot`

## Dimensioni

- **Emulator usato**: 1080 x 2400 px (Pixel 6a / API 34)

## Ottimizzazione

Per ridurre la dimensione dei file PNG:

```bash
# Installa pngquant
brew install pngquant

# Ottimizza tutti gli screenshot
pngquant --quality=65-80 --ext .png --force *.png
```
