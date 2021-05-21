cd thirdparty/transistor-background-fetch/android
gradle :tsbackgroundfetch:publishRelease
cd ../../../
mkdir android/app/libs
cp -rf thirdparty/transistor-background-fetch/android/tsbackgroundfetch/build/repo/* android/app/libs
flutter build apk
rm -rf android/app/libs
