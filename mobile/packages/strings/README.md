# Ente Strings

A Flutter package containing shared localization strings for Ente apps.

## Purpose

This package provides common localization strings that are shared across multiple Ente applications (Auth, Photos, etc.). It centralizes the translations for common UI elements, error messages, and other shared text to ensure consistency across the apps.

## Usage

### 1. Add to pubspec.yaml

```yaml
dependencies:
  ente_strings:
    path: ../packages/strings
```

### 2. Configure in your app

Add the strings localizations delegate to your app:

```dart
import 'package:ente_strings/ente_strings.dart';

MaterialApp(
  localizationsDelegates: [
    ...StringsLocalizations.localizationsDelegates,
    // Your other delegates...
  ],
  supportedLocales: StringsLocalizations.supportedLocales,
  // ...
)
```

### 3. Use in your widgets

Use the convenient extension to access strings:

```dart
import 'package:ente_strings/ente_strings.dart';

Widget build(BuildContext context) {
  return Text(context.strings.networkHostLookUpErr);
}
```

Or use the traditional approach:

```dart
import 'package:ente_strings/ente_strings.dart';

Widget build(BuildContext context) {
  return Text(StringsLocalizations.of(context).networkHostLookUpErr);
}
```

## Available Strings

Currently available strings:

- `networkHostLookUpErr`: Error message for network host lookup failures

## Adding New Strings

1. Add the string to `lib/l10n/arb/strings_en.arb` (template file)
2. Add translations to all other `strings_*.arb` files
3. Run `flutter gen-l10n` to regenerate the localization files
4. Move generated files from `lib/l10n/arb/` to `lib/l10n/` if needed

## Supported Languages

Currently supported languages include:
- Arabic (ar)
- Bulgarian (bg)
- Czech (cs)
- Danish (da)
- Greek (el)
- English (en)
- French (fr)
- Indonesian (id)
- Japanese (ja)
- Korean (ko)
- Lithuanian (lt)
- Dutch (nl)
- Polish (pl)
- Portuguese (pt)
- Russian (ru)
- Slovak (sk)
- Serbian (sr)
- Swedish (sv)
- Turkish (tr)
- Vietnamese (vi)
- Chinese Simplified (zh)
- Chinese Traditional (zh_TW)
