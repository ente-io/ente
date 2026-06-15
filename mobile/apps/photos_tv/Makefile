ANDROID_DIR := android
APK := build/app/outputs/apk/debug/app-debug.apk
PACKAGE := io.ente.photos_tv
DREAM_SERVICE := $(PACKAGE)/$(PACKAGE).PhotosTvDreamService
GRADLE := ./gradlew --no-daemon -Pkotlin.compiler.execution.strategy=in-process

.PHONY: build clean install lint screensaver-enable screensaver-start screensaver-stop uninstall

build:
	cd $(ANDROID_DIR) && $(GRADLE) :app:assembleDebug

lint:
	cd $(ANDROID_DIR) && $(GRADLE) :app:lintDebug

clean:
	cd $(ANDROID_DIR) && $(GRADLE) clean

install: build
	adb install -r $(APK)

uninstall:
	adb uninstall $(PACKAGE)

screensaver-enable:
	adb shell settings put secure screensaver_enabled 1
	adb shell settings put secure screensaver_components $(DREAM_SERVICE)
	adb shell settings put secure screensaver_default_component $(DREAM_SERVICE)
	adb shell settings put secure screensaver_activate_on_sleep 1
	adb shell settings put secure screensaver_activate_on_dock 1

screensaver-start:
	adb shell cmd dreams start-dreaming

screensaver-stop:
	adb shell input keyevent KEYCODE_WAKEUP
