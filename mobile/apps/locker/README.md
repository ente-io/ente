# Ente Locker

Ente's secure document storage app. An end-to-end encrypted app for storing
important documents in the cloud with secure sharing capabilities.

## 🧑‍💻 Build from source

1. [Install Flutter v3.32.8](https://flutter.dev/docs/get-started/install).

2. Pull in all submodules with `git submodule update --init --recursive`

3. Run `flutter pub get` to install dependencies, then run `flutter gen-l10n` to generate localization files

4. For Android, [setup your
   keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore)
   and run `flutter build apk --release --flavor independent`

5. For iOS, run `flutter build ios`

## ⚙️ Develop

For Android, use

```sh
flutter run -t lib/main.dart --flavor independent
```

For iOS, use `flutter run`

## TODOs

Refactor and merge
- [ ] Verify correctness for `PackageInfoUtil.getPackageName()` on Linux and Windows
- [ ] Update `file_url.dart` to download only via CF worker when necessary
