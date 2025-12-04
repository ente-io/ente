# Ente Locker

An end-to-end encrypted, cross-platform app
for storing your important documents, credentials, and personal information with
cloud backups. Built on the same zero-knowledge architecture that powers Ente
Photos.

## Features

- End-to-end encrypted document storage
- Store credentials, notes, emergency contacts, and physical item locations
- Share documents and collections securely
- Cross-platform support (iOS, Android, macOS, Windows, Linux)
- Cloud sync with zero-knowledge encryption

## 📲 Download

Ente Locker is currently available for existing Ente users. You can create an
account on Ente Photos to use Locker.

### Android

<a href="https://play.google.com/store/apps/details?id=io.ente.locker">
  <img height="59" src="../../../.github/assets/play-store-badge.png">
</a>

### iOS (TestFlight Beta)

<a href="https://testflight.apple.com/join/rbmJYPz1">
  <img height="59" src="../../../.github/assets/app-store-badge.svg">
</a>

### Desktop

Desktop builds for Windows, Linux, and macOS are coming soon.

## 🧑‍💻 Build from source

1. [Install Flutter v3.32.8](https://flutter.dev/docs/get-started/install).

2. Pull in all submodules with `git submodule update --init --recursive`

3. From the `mobile/` directory, run `melos bootstrap` to set up all packages

4. For Android, run `flutter run` from this directory

5. For iOS, run `cd ios && pod install && cd .. && flutter run`

## ⚙️ Develop

```sh
# Run the app
flutter run

# Format code
dart format .

# Analyze code
flutter analyze
```

VSCode users might find it useful to copy the `docs/vscode` folder from the
photos app into a top level `.vscode`.

## 🔩 Architecture

Locker is built on the Ente platform and shares core packages with Ente Photos
and Ente Auth:

- `ente_accounts` - User authentication and account management
- `ente_crypto_dart` - Encryption/decryption primitives
- `ente_network` - HTTP client and network layer
- `ente_sharing` - Sharing models and utilities
- `ente_ui` - Common UI components and theming

### Key Services

- **CollectionService** - Manages collections (folders) and files
- **LinksService** - Handles shareable public links
- **TrashService** - Manages deleted files and trash operations
- **InfoFileService** - Handles structured information (notes, credentials, etc.)

## 🌍 Translate

If you're interested in helping out with translation, please visit our Crowdin
project to get started. Thank you for your support.

If your language is not listed for translation, please [create a GitHub
issue](https://github.com/ente-io/ente/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A)
to have it added.

## 💚 Contribute

For more ways to contribute, see [../../../CONTRIBUTING.md](../../../CONTRIBUTING.md).

## ⭐️ About

To know more about Ente and the ways to get in touch or seek help, see [our main
README](../../../README.md) or visit [ente.io](https://ente.io).
