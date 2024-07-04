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

  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
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

  // static Uint8List _generateSalt() {
  //   return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  // }

  Future<void> setPin(String userPin) async {
    //await _secureStorage.delete(key: saltKey);
    await _preferences.setString(pin, userPin);
    await _preferences.remove(password);
    // final salt = _generateSalt();
    // final hash = cryptoPwHash({
    //   "password": utf8.encode(userPin),
    //   "salt": salt,
    //   "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
    //   "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    // });

    // final String saltPin = base64Encode(salt);
    // final String hashedPin = base64Encode(hash);

    // await _secureStorage.write(key: saltKey, value: saltPin);
    // await _secureStorage.write(key: pin, value: hashedPin);
    // await _secureStorage.delete(key: password);

    return;
  }

  // Future<Uint8List?> getSalt() async {
  //   final String? salt = await _secureStorage.read(key: saltKey);
  //   if (salt == null) return null;
  //   return base64Decode(salt);
  // }

  Future<String?> getPin() async {
    return _preferences.getString(pin);
    // return _secureStorage.read(key: pin);
  }

  Future<void> setPassword(String pass) async {
    await _preferences.setString(password, pass);
    await _preferences.remove(pin);
    // await _secureStorage.delete(key: saltKey);

    // final salt = _generateSalt();
    // final hash = cryptoPwHash({
    //   "password": utf8.encode(pass),
    //   "salt": salt,
    //   "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
    //   "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    // });

    // final String saltPassword = base64Encode(salt);
    // final String hashPassword = base64Encode(hash);

    // await _secureStorage.write(key: saltKey, value: saltPassword);
    // await _secureStorage.write(key: password, value: hashPassword);
    // await _secureStorage.delete(key: pin);

    return;
  }

  Future<String?> getPassword() async {
    return _preferences.getString(password);
    // return _secureStorage.read(key: password);
  }

  Future<void> removePinAndPassword() async {
    await _preferences.remove(pin);
    await _preferences.remove(password);
    // await _secureStorage.delete(key: saltKey);
    // await _secureStorage.delete(key: pin);
    // await _secureStorage.delete(key: password);
  }

  Future<bool> isPinSet() async {
    return _preferences.containsKey(pin);
    // return await _secureStorage.containsKey(key: pin);
  }

  Future<bool> isPasswordSet() async {
    return _preferences.containsKey(password);
    // return await _secureStorage.containsKey(key: password);
  }
}
