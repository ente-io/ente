import "dart:convert";

import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sodium/flutter_sodium.dart";
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
  static const keyHideAppContent = "ls_hide_app_content";
  static const autoLockTime = "ls_auto_lock_time";
  late FlutterSecureStorage _secureStorage;
  late SharedPreferences _preferences;
  static const List<Duration> autoLockDurations = [
    Duration(milliseconds: 650),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
  ];
  Future<void> init(SharedPreferences prefs) async {
    _secureStorage = const FlutterSecureStorage();
    _preferences = prefs;

    /// Workaround to check if "lateinit property activity has not been
    ///  initialized" PlatformException goes away.
    await Future.delayed(const Duration(milliseconds: 500), () {
      ///Workaround for privacyScreen not working when app is killed and opened.
      setHideAppContent(getShouldHideAppContent());
    });
  }

  Future<void> setHideAppContent(bool hideContent) async {
    !hideContent
        ? await PrivacyScreen.instance.disable()
        : await PrivacyScreen.instance.enable(
            iosOptions: const PrivacyIosOptions(
              enablePrivacy: true,
              lockTrigger: IosLockTrigger.didEnterBackground,
            ),
            androidOptions: const PrivacyAndroidOptions(
              enableSecure: true,
            ),
            blurEffect: PrivacyBlurEffect.extraLight,
          );
    await _preferences.setBool(keyHideAppContent, hideContent);
  }

  bool getShouldHideAppContent() {
    return _preferences.getBool(keyHideAppContent) ?? false;
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

  static Uint8List _generateSalt() {
    return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  }

  Future<void> setPin(String userPin) async {
    await _secureStorage.delete(key: saltKey);

    final salt = _generateSalt();
    final hash = cryptoPwHash({
      "password": utf8.encode(userPin),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

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
    final hash = cryptoPwHash({
      "password": utf8.encode(pass),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

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
}
