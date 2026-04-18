# ente_icons

Custom icon font package for Ente apps (Photos, Auth, Locker).

## Usage

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  ente_icons:
    path: ../../packages/ente_icons
```

Import and use:

```dart
import 'package:ente_icons/ente_icons.dart';

Icon(EnteIcons.favoriteStroke)
Icon(EnteIcons.favoriteFilled, color: Colors.red)
```

## Adding New Icons

1. Go to [FlutterIcon.com](https://fluttericon.com)
2. Drag and drop `config.json` from this package to restore existing icons
3. Add your new icons (upload SVGs or select from available sets), then click each to select them
4. Click "Download" and extract the zip
5. Replace `fonts/EnteIcons.ttf` with the new font file
6. Update `config.json` with the new one from the download
7. Update `lib/src/ente_icons.dart`:
   - Add new `IconData` constants using camelCase naming
   - Get the code points (e.g., `0xe802`) from the generated Dart file
   - Keep `_kFontPkg = 'ente_icons'` (FlutterIcon generates `null`, but the package name is required for cross-package font loading)
8. Run `flutter analyze` in this package to verify
