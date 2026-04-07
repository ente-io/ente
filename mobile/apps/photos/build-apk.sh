cd thirdparty/transistor-background-fetch/android
gradle :tsbackgroundfetch:publishRelease
cd ../../../
flutter config --no-analytics
flutter pub get --enforce-lockfile
flutter packages pub run flutter_launcher_icons:main
flutter build apk
