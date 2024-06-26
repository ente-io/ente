import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sodium/flutter_sodium.dart";
import "package:photos/utils/crypto_util.dart";

class LockscreenSetting {
  LockscreenSetting._privateConstructor();

  static final LockscreenSetting instance =
      LockscreenSetting._privateConstructor();
  static const password = "user_pass";
  static const pin = "user_pin";
  static const saltKey = "user_salt";

  late FlutterSecureStorage _secureStorage;

  void init(FlutterSecureStorage secureStorage) {
    _secureStorage = secureStorage;
  }

  static Uint8List generateSalt() {
    return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  }

  Future<void> setPin(String userPin) async {
    await _secureStorage.delete(key: saltKey);

    final salt = generateSalt();
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

    final salt = generateSalt();
    final hash = cryptoPwHash({
      "password": utf8.encode(pass),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

    final String saltPassword = base64Encode(salt);
    final String hashPassword = base64Encode(hash);

    await _secureStorage.write(key: saltKey, value: saltPassword);
    await _secureStorage.write(key: password, value: hashPassword);
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
