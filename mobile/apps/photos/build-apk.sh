cd thirdparty/transistor-background-fetch/android
gradle :tsbackgroundfetch:publishRelease
cd ../../../
flutter config --no-analytics
flutter packages pub get
flutter packages pub run flutter_launcher_icons:main
flutter build apk
