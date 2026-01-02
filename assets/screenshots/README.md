# Screenshots

Questa cartella contiene gli screenshot dell'app per il README.

## Come generare gli screenshot

1. Esegui l'app su un simulatore/emulatore
2. Cattura le schermate con:
   - **iOS Simulator**: `Cmd + S` o File → Save Screen
   - **Android Emulator**: Icona camera nella toolbar
   - **Flutter**: `flutter screenshot`

## Screenshots richiesti

| Nome file | Descrizione |
|-----------|-------------|
| `home.png` | Schermata Home con prossima iniezione |
| `calendar.png` | Vista calendario mensile |
| `body_map.png` | Mappa corpo interattiva |
| `settings.png` | Schermata impostazioni |

## Dimensioni consigliate

- **iPhone**: 390 x 844 px (iPhone 14)
- **Android**: 412 x 892 px (Pixel 7)

## Ottimizzazione

Per ridurre la dimensione dei file PNG:

```bash
# Installa pngquant
brew install pngquant

# Ottimizza tutti gli screenshot
pngquant --quality=65-80 --ext .png --force *.png
```

