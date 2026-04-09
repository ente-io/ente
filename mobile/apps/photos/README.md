# Mobile app for Ente Photos

Source code for our flagship mobile app. For us, this is our most important
client app. This is where Ente started. This is what had the [first
commit](https://github.com/ente-io/ente/commit/a8cdc811fd20ca4289d8e779c97f08ef5d276e37).

    commit a8cdc811fd20ca4289d8e779c97f08ef5d276e37
    Author: Vishnu Mohandas <v****@****.***>
    Date:   Wed Mar 25 01:29:36 2020 +0530

        Hello world

To know more about Ente, see [our main README](../../../README.md) or visit
[ente.com](https://ente.com).

To use Ente Photos on the web, see [web](../../../web/README.md). To use Ente
Photos on the desktop, see [desktop](../../../desktop/README.md). There is a also a
[CLI tool](../../../cli/README.md) for easy / automated exports.

If you're looking for Ente Auth instead, see [auth](../auth/README.md).

## 📲 Installation

### Android

The [GitHub
releases](https://github.com/ente-io/ente/releases?q=photos-v1) contain
APKs, built straight from source. The latest build is available at
[ente.com/apk](https://ente.com/apk). These builds keep themselves updated,
without relying on third party stores.

You can alternatively install the build from PlayStore or F-Droid.

<a href="https://play.google.com/store/apps/details?id=io.ente.photos">
  <img height="59" src="../../../.github/assets/play-store-badge.png">
</a>
<a href="https://f-droid.org/packages/io.ente.photos.fdroid/">
  <img height="59" src="../../../.github/assets/f-droid-badge.png">
</a>

### iOS

<a href="https://apps.apple.com/in/app/ente-photos/id1542026904">
  <img height="59" src="../../../.github/assets/app-store-badge.svg">
</a>

## 🧑‍💻 Building from source

1. Install [Flutter v3.32.8](https://flutter.dev/docs/get-started/install) and [Rust](https://www.rust-lang.org/tools/install).

2. Install dependencies using one of these methods:
   - **Using Melos (recommended):** Install Melos with `dart pub global activate melos`, then from any folder inside `mobile/`, run `melos run codegen:rust`. This will install dependencies and generate Rust bindings.
   - **Using Flutter directly:** Run `flutter pub get`, then install [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/) with `cargo install flutter_rust_bridge_codegen` and run `flutter_rust_bridge_codegen generate` in both this folder and in `mobile/packages/rust`.

3. On Android, [setup your keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore) and run `flutter build apk --release --flavor independent`

4. For iOS, run `flutter build ios`

## ⚙️ Develop

For Android, use

```sh
flutter run -t lib/main.dart --flavor independent
```

For iOS, use `flutter run`

## 📝 Localization

This project uses Flutter's built-in localization system configured via `l10n.yaml`.

- Localization files are auto-generated when you run `flutter pub get`
- The base localization file is `lib/l10n/intl_en.arb`
- Generated code appears in `lib/generated/intl/`
- To manually regenerate: `flutter gen-l10n`

See [docs/translations.md](docs/translations.md) for contributing translations.

## 🏙️ Attributions

City coordinates from [Simple Maps](https://simplemaps.com/data/world-cities)

## 🌍 Translate

[![Crowdin](https://badges.crowdin.net/ente-photos-app/localized.svg)](https://crowdin.com/project/ente-photos-app)

If you're interested in helping out with translation, please visit our [Crowdin
project](https://crowdin.com/project/ente-photos-app) to get started. Thank you
for your support.

If your language is not listed for translation, please [create a GitHub
issue](https://github.com/ente-io/ente/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A)
to have it added.

## 💚 Contribute

For more ways to contribute, see [CONTRIBUTING.md](../../../CONTRIBUTING.md).
