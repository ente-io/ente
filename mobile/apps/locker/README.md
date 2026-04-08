# Ente Locker

Ente's secure document storage app. An end-to-end encrypted app for storing
important documents in the cloud with secure sharing capabilities.

## 🧑‍💻 Build from source

1. [Install Flutter v3.32.8](https://flutter.dev/docs/get-started/install).

2. Install dependencies using one of these methods:
   - **Using Melos (recommended):** Install Melos with `dart pub global activate melos`, then from any folder inside `mobile/`, run `melos bootstrap`. This will install dependencies.
   - **Using Flutter directly:** Run `flutter pub get` in `packages/strings` and this folder

3. For Android, [setup your
   keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore)
   and run `flutter build apk --release --flavor independent`

4. For iOS, run `flutter build ios`

## ⚙️ Develop

For Android, use

```sh
flutter run -t lib/main.dart --flavor independent
```

For iOS, use `flutter run`
