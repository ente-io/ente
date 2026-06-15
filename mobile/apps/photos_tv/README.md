# photos_tv

Minimal Ente Photos TV receiver.

## Set as Android TV screensaver with adb

Install app, then run:

```sh
adb shell settings put secure screensaver_enabled 1
adb shell settings put secure screensaver_components io.ente.photos_tv/io.ente.photos_tv.PhotosTvDreamService
adb shell settings put secure screensaver_default_component io.ente.photos_tv/io.ente.photos_tv.PhotosTvDreamService
adb shell settings put secure screensaver_activate_on_sleep 1
adb shell settings put secure screensaver_activate_on_dock 1
```

Start screensaver immediately for testing:

```sh
adb shell cmd dreams start-dreaming
```

Stop screensaver:

```sh
adb shell input keyevent KEYCODE_WAKEUP
```
