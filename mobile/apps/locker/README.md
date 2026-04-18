# Ente Locker

Ente's secure document storage app. An end-to-end encrypted app for storing
important documents in the cloud with secure sharing capabilities.

## 🧑‍💻 Build from source

1. [Install Flutter v3.32.8](https://flutter.dev/docs/get-started/install).

2. Install dependencies using one of these methods:
   - **Using Melos (recommended):** Install Melos with `dart pub global activate melos`, then from any folder inside `mobile/`, run `melos bootstrap`. This will install dependencies.
   - **Using Flutter directly:** Run `flutter pub get` in `packages/strings` and this folder

3. Run the app:
   - Android: `flutter run --flavor independent`
   - iOS: `flutter run`

To build a release APK, [setup your keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore) and run `flutter build apk --release --flavor independent`. For iOS, use `flutter build ios`.

## 🌍 Translate

[![Crowdin](https://badges.crowdin.net/ente-locker/localized.svg)](https://crowdin.com/project/ente-locker)

If you're interested in helping out with translation, please visit our [Crowdin
project](https://crowdin.com/project/ente-locker) to get started. Thank you for
your support.

If your language is not listed for translation, please [create a GitHub
issue](https://github.com/ente-io/ente/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A)
to have it added.
