# Ente Locker

An end-to-end encrypted, cross-platform app
for storing your important documents, credentials, and personal information with
cloud backups. Built on the same zero-knowledge architecture that powers Ente
Photos.

## Features

- End-to-end encrypted document storage
- Store credentials, notes, emergency contacts, and physical item locations
- Share documents securely
- Cloud sync with zero-knowledge encryption

## 📲 Download

Ente Locker is currently available for existing Ente users. You can create an
account on Ente Photos to use Locker.

### Android

<a href="https://play.google.com/store/apps/details?id=io.ente.locker">
  <img height="59" src="../../../.github/assets/play-store-badge.png">
</a>

### iOS

<a href="https://testflight.apple.com/join/rbmJYPz1">
  <img height="59" src="../../../.github/assets/app-store-badge.svg">
</a>

## 🧑‍💻 Build from source

1. [Install Flutter v3.32.8](https://flutter.dev/docs/get-started/install).

2. Pull in all submodules with `git submodule update --init --recursive`

3. From the `mobile/` directory, run `melos bootstrap` to set up all packages

4. On Android:

   - For development, run `flutter run -t lib/main.dart --flavor independent`

   - For building APK, [setup your
     keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore)
     and run `flutter build apk --release --flavor independent`

5. For iOS, run `flutter build ios`

## 🔩 Architecture

Locker is built on the Ente platform and shares core packages with Ente Photos
and Ente Auth:

## 🌍 Translate

If you're interested in helping out with translation, please visit our Crowdin
project to get started. Thank you for your support.

If your language is not listed for translation, please [create a GitHub
issue](https://github.com/ente-io/ente/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A)
to have it added.

## ⭐️ About

To know more about Ente and the ways to get in touch or seek help, see [our main
README](../../../README.md) or visit [ente.io](https://ente.io).
