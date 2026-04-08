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

## Certificate Fingerprints

- **SHA1**: EF:BA:46:7F:BE:E2:F7:9A:0C:A7:76:A2:9D:AA:70:13:B9:B7:AE:D2
- **SHA256**: 6E:5B:71:61:B0:FA:F1:01:B6:AF:3D:33:C6:B0:8C:AD:AC:4A:8B:DF:85:E5:BE:A5:06:83:AA:FA:74:05:0D:B1

To verify these fingerprints, use the following command:
```bash
apksigner verify --print-certs <path_to_apk>
```
