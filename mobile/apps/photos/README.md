# Mobile app for Ente Photos

Source code for our flagship mobile app. For us, this is our most important
client app. This is where Ente started. This is what had the [first
commit](https://github.com/ente-io/ente/commit/a8cdc811fd20ca4289d8e779c97f08ef5d276e37).

    commit a8cdc811fd20ca4289d8e779c97f08ef5d276e37
    Author: Vishnu Mohandas <v****@****.***>
    Date:   Wed Mar 25 01:29:36 2020 +0530

        Hello world

To know more about Ente, see [our main README](../../../README.md) or visit
[ente.io](https://ente.io).

To use Ente Photos on the web, see [../../../web](../../../web/README.md). To use Ente
Photos on the desktop, see [../../../desktop](../../../desktop/README.md). There is a also a
[CLI tool](../../../cli/README.md) for easy / automated exports.

If you're looking for Ente Auth instead, see [../auth](../auth/README.md).

## 📲 Installation

### Android

The [GitHub
releases](https://github.com/ente-io/ente/releases?q=photos-v1) contain
APKs, built straight from source. The latest build is available at
[ente.io/apk](https://ente.io/apk). These builds keep themselves updated,
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

2. Install [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/) with `cargo install flutter_rust_bridge_codegen` and run `flutter_rust_bridge_codegen generate` to generate the Rust bindings.

3. Pull in all submodules with `git submodule update --init --recursive`

4. Enable repo git hooks `git config core.hooksPath hooks`

5. If using Visual Studio Code, add the [Flutter
   Intl](https://marketplace.visualstudio.com/items?itemName=localizely.flutter-intl)
   extension

6. On Android:

   - For development, run `flutter run -t lib/main.dart --flavor independent`

   - For building APK, [setup your
     keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore)
     and run `flutter build apk --release --flavor independent`

7. For iOS, run `flutter build ios`

Some common issues and troubleshooting tips are in [docs/dev](docs/dev.md).

VSCode users might find it useful to copy [docs/vscode](docs/vscode) into a top
level `.vscode`.

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

## Certificate Fingerprints

- **SHA1**: E1:60:10:18:B6:B0:2E:A3:74:6F:90:67:50:30:29:75:0E:EF:6D:39
- **SHA256**: 35:ED:56:81:B7:0B:B3:BD:35:D9:0D:85:6A:F5:69:4C:50:4D:EF:46:AA:D8:3F:77:7B:1C:67:5C:F4:51:35:0B

To verify these fingerprints, use the following command:

```bash
apksigner verify --print-certs <path_to_apk>
```

## 💚 Contribute

For more ways to contribute, see [../../../CONTRIBUTING.md](../../../CONTRIBUTING.md).
