## Developer docs

### iOS

```sh
sudo gem install cocoapods
cd ios && pod install && cd ..
```

####  iOS Simulator missing in flutter devices

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```