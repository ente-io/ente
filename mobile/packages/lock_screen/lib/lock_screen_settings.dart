import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:ente_configuration/base_configuration.dart";
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_events/event_bus.dart";
import "package:ente_events/models/signed_out_event.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:privacy_screen/privacy_screen.dart";
import "package:shared_preferences/shared_preferences.dart";

class LockScreenSettings {
  LockScreenSettings._privateConstructor();

  static final LockScreenSettings instance =
      LockScreenSettings._privateConstructor();
  static const password = "ls_password";
  static const pin = "ls_pin";
  static const saltKey = "ls_salt";
  static const keyInvalidAttempts = "ls_invalid_attempts";
  static const lastInvalidAttemptTime = "ls_last_invalid_attempt_time";
  static const autoLockTime = "ls_auto_lock_time";
  static const keyHideAppContent = "ls_hide_app_content";
  static const keyAppLockSet = "ls_is_app_lock_set";
  static const keyHasMigratedLockScreenChanges =
      "ls_has_migrated_lock_screen_changes";
  static const keyShowOfflineModeWarning = "ls_show_offline_mode_warning";
  static const keyShouldShowLockScreen = "should_show_lock_screen";
  static const String kIsLightMode = "is_light_mode";

  final List<Duration> autoLockDurations = const [
    Duration(milliseconds: 650),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
  ];

  late BaseConfiguration _config;
  late SharedPreferences _preferences;
  late FlutterSecureStorage _secureStorage;

  Future<void> init(BaseConfiguration config) async {
    _config = config;
    _secureStorage = const FlutterSecureStorage();
    _preferences = await SharedPreferences.getInstance();

    ///Workaround for privacyScreen not working when app is killed and opened.
    await setHideAppContent(getShouldHideAppContent());

    /// Function to Check if the migration for lock screen changes has
    /// already been done by checking a stored boolean value.
    await runLockScreenChangesMigration();

    await _clearLsDataInKeychainIfFreshInstall();

    Bus.instance.on<SignedOutEvent>().listen((event) {
      removePinAndPassword();
    });
  }

  Future<void> setOfflineModeWarningStatus(bool value) async {
    await _preferences.setBool(keyShowOfflineModeWarning, value);
  }

  bool getOfflineModeWarningStatus() {
    return _preferences.getBool(keyShowOfflineModeWarning) ?? true;
  }

  Future<void> runLockScreenChangesMigration() async {
    if (_preferences.getBool(keyHasMigratedLockScreenChanges) != null) {
      return;
    }

    final bool passwordEnabled = await isPasswordSet();
    final bool pinEnabled = await isPinSet();
    final bool systemLockEnabled = shouldShowSystemLockScreen();

    if (passwordEnabled || pinEnabled || systemLockEnabled) {
      await setAppLockEnabled(true);
    }

    await _preferences.setBool(keyHasMigratedLockScreenChanges, true);
  }

  Future<void> setLightMode(bool isLightMode) async {
    if (isLightMode != (_preferences.getBool(kIsLightMode) ?? true)) {
      await _preferences.setBool(kIsLightMode, isLightMode);
    }
  }

  Future<void> setHideAppContent(bool hideContent) async {
    if (PlatformUtil.isDesktop()) return;
    !hideContent
        ? PrivacyScreen.instance.disable()
        : await PrivacyScreen.instance.enable(
            iosOptions: const PrivacyIosOptions(
              enablePrivacy: true,
            ),
            androidOptions: const PrivacyAndroidOptions(
              enableSecure: true,
            ),
            backgroundColor: const Color(0xff000000),
            blurEffect: PrivacyBlurEffect.extraLight,
          );
    await _preferences.setBool(keyHideAppContent, hideContent);
  }

  bool getShouldHideAppContent() {
    return _preferences.getBool(keyHideAppContent) ?? true;
  }

  Future<void> setAutoLockTime(Duration duration) async {
    await _preferences.setInt(autoLockTime, duration.inMilliseconds);
  }

  int getAutoLockTime() {
    return _preferences.getInt(autoLockTime) ?? 5000;
  }

  Future<void> setLastInvalidAttemptTime(int time) async {
    await _preferences.setInt(lastInvalidAttemptTime, time);
  }

  int getlastInvalidAttemptTime() {
    return _preferences.getInt(lastInvalidAttemptTime) ?? 0;
  }

  int getInvalidAttemptCount() {
    return _preferences.getInt(keyInvalidAttempts) ?? 0;
  }

  Future<void> setInvalidAttemptCount(int count) async {
    await _preferences.setInt(keyInvalidAttempts, count);
  }

  Future<void> setAppLockEnabled(bool value) async {
    await _preferences.setBool(keyAppLockSet, value);
  }

  bool getIsAppLockSet() {
    return _preferences.getBool(keyAppLockSet) ?? false;
  }

  static Uint8List _generateSalt() {
    return sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);
  }

  Future<void> setPin(String userPin) async {
    await _secureStorage.delete(key: saltKey);
    final salt = _generateSalt();

    final hash = cryptoPwHash(
      utf8.encode(userPin),
      salt,
      sodium.crypto.pwhash.memLimitInteractive,
      sodium.crypto.pwhash.opsLimitSensitive,
      sodium,
    );
    final String saltPin = base64Encode(salt);
    final String hashedPin = base64Encode(hash);

    await _secureStorage.write(key: saltKey, value: saltPin);
    await _secureStorage.write(key: pin, value: hashedPin);
    await _secureStorage.delete(key: password);

    return;
  }

  Future<Uint8List?> getSalt() async {
    final String? salt = await _secureStorage.read(key: saltKey);
    if (salt == null) return null;
    return base64Decode(salt);
  }

  Future<String?> getPin() async {
    return _secureStorage.read(key: pin);
  }

  Future<void> setPassword(String pass) async {
    await _secureStorage.delete(key: saltKey);
    final salt = _generateSalt();

    final hash = cryptoPwHash(
      utf8.encode(pass),
      salt,
      sodium.crypto.pwhash.memLimitInteractive,
      sodium.crypto.pwhash.opsLimitSensitive,
      sodium,
    );

    await _secureStorage.write(key: saltKey, value: base64Encode(salt));
    await _secureStorage.write(key: password, value: base64Encode(hash));
    await _secureStorage.delete(key: pin);

    return;
  }

  Future<String?> getPassword() async {
    return _secureStorage.read(key: password);
  }

  Future<void> removePinAndPassword() async {
    await _secureStorage.delete(key: saltKey);
    await _secureStorage.delete(key: pin);
    await _secureStorage.delete(key: password);
  }

  Future<bool> isPinSet() async {
    return await _secureStorage.containsKey(key: pin);
  }

  Future<bool> isPasswordSet() async {
    return await _secureStorage.containsKey(key: password);
  }

  Future<bool> shouldShowLockScreen() async {
    final bool isPin = await isPinSet();
    final bool isPass = await isPasswordSet();
    return isPin || isPass || shouldShowSystemLockScreen();
  }

  bool shouldShowSystemLockScreen() {
    if (_preferences.containsKey(keyShouldShowLockScreen)) {
      return _preferences.getBool(keyShouldShowLockScreen)!;
    } else {
      return false;
    }
  }

  Future<void> setSystemLockScreen(bool value) {
    return _preferences.setBool(keyShouldShowLockScreen, value);
  }

  // If the app was uninstalled (without logging out if it was used with
  // backups), keychain items of the app persist in the keychain. To avoid using
  // old keychain items, we delete them on reinstall.
  Future<void> _clearLsDataInKeychainIfFreshInstall() async {
    if ((Platform.isIOS || Platform.isMacOS) && !_config.isLoggedIn()) {
      await _secureStorage.delete(key: password);
      await _secureStorage.delete(key: pin);
      await _secureStorage.delete(key: saltKey);
    }
  }
}
