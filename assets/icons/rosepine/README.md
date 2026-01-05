# Rosepine Icons

A set of minimalist SVG icons inspired by the [Rosé Pine](https://rosepinetheme.com/) color palette. Designed for medical/health applications with clean lines and subtle aesthetics.

## Icon Style

- **Dimensions**: 24x24px viewBox
- **Stroke width**: 1.5-2px
- **Line caps/joins**: Round
- **Style**: Outline only (no fills)
- **Color**: `currentColor` for theme adaptability

## Categories

### Body (`body/`)
Icons representing body zones for injection sites:
- `thigh-left.svg` / `thigh-right.svg`
- `arm-left.svg` / `arm-right.svg`
- `abdomen-left.svg` / `abdomen-right.svg`
- `buttock-left.svg` / `buttock-right.svg`

### Actions (`actions/`)
User action icons:
- `add.svg`, `edit.svg`, `delete.svg`
- `save.svg`, `cancel.svg`
- `schedule.svg`, `complete.svg`, `skip.svg`

### Status (`status/`)
State indicators:
- `completed.svg`, `scheduled.svg`, `pending.svg`
- `skipped.svg`, `missed.svg`, `warning.svg`

### Navigation (`navigation/`)
App navigation:
- `home.svg`, `calendar.svg`, `stats.svg`
- `settings.svg`, `info.svg`

### Patterns (`patterns/`)
Rotation pattern indicators:
- `ai-smart.svg`, `sequential.svg`, `alternate.svg`
- `weekly.svg`, `clockwise.svg`, `counter-clockwise.svg`
- `custom.svg`

### Misc (`misc/`)
General purpose:
- `notification.svg`, `export.svg`, `import.svg`
- `syringe.svg`, `medical.svg`

## Usage

### Flutter
```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/rosepine/actions/add.svg',
  colorFilter: ColorFilter.mode(
    Theme.of(context).iconTheme.color!,
    BlendMode.srcIn,
  ),
);
```

### Web (CSS)
```css
.icon {
  color: var(--icon-color);
  width: 24px;
  height: 24px;
}
```

## License

MIT License - See LICENSE file for details.

## Contributing

1. Follow the existing style guidelines
2. Keep icons simple and recognizable at small sizes
3. Use `currentColor` for fill/stroke colors
4. Test in both light and dark themes

