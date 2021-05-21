cd thirdparty/transistor-background-fetch/android
gradle :tsbackgroundfetch:publishRelease
cd ../../../
mkdir android/app/libs
cp -rf thirdparty/transistor-background-fetch/android/tsbackgroundfetch/build/repo/* android/app/libs
flutter config --no-analytics
flutter packages pub get
flutter packages pub run flutter_launcher_icons:main
flutter build apk
rm -rf android/app/libs
