import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/endpoint_updated_event.dart';
import 'package:ente_auth/events/signed_in_event.dart';
import 'package:ente_auth/events/signed_out_event.dart';
import 'package:ente_auth/models/key_attributes.dart';
import 'package:ente_auth/models/key_gen_result.dart';
import 'package:ente_auth/models/private_key_attributes.dart';
import 'package:ente_auth/store/authenticator_db.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

class Configuration {
  Configuration._privateConstructor();

  static final Configuration instance = Configuration._privateConstructor();
  static const endpoint = String.fromEnvironment(
    "endpoint",
    defaultValue: kDefaultProductionEndpoint,
  );
  static const emailKey = "email";
  static const keyAttributesKey = "key_attributes";

  static const keyShouldShowLockScreen = "should_show_lock_screen";
  static const lastTempFolderClearTimeKey = "last_temp_folder_clear_time";
  static const keyKey = "key";
  static const secretKeyKey = "secret_key";
  static const authSecretKeyKey = "auth_secret_key";
  static const offlineAuthSecretKey = "offline_auth_secret_key";
  static const tokenKey = "token";
  static const encryptedTokenKey = "encrypted_token";
  static const userIDKey = "user_id";
  static const hasMigratedSecureStorageKey = "has_migrated_secure_storage";
  static const hasOptedForOfflineModeKey = "has_opted_for_offline_mode";
  static const endPointKey = "endpoint";
  final List<String> onlineSecureKeys = [
    keyKey,
    secretKeyKey,
    authSecretKeyKey,
  ];

  final kTempFolderDeletionTimeBuffer = const Duration(days: 1).inMicroseconds;

  static final _logger = Logger("Configuration");

  String? _cachedToken;
  late String _documentsDirectory;
  late SharedPreferences _preferences;
  String? _key;
  String? _secretKey;
  String? _authSecretKey;
  String? _offlineAuthKey;
  late FlutterSecureStorage _secureStorage;
  late String _tempDirectory;

  String? _volatilePassword;

  final _secureStorageOptionsIOS = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
    _documentsDirectory = (await getApplicationDocumentsDirectory()).path;
    _tempDirectory = _documentsDirectory + "/temp/";
    final tempDirectory = io.Directory(_tempDirectory);
    try {
      final currentTime = DateTime.now().microsecondsSinceEpoch;
      if (tempDirectory.existsSync() &&
          (_preferences.getInt(lastTempFolderClearTimeKey) ?? 0) <
              (currentTime - kTempFolderDeletionTimeBuffer)) {
        await tempDirectory.delete(recursive: true);
        await _preferences.setInt(lastTempFolderClearTimeKey, currentTime);
        _logger.info("Cleared temp folder");
      } else {
        _logger.info("Skipping temp folder clear");
      }
    } catch (e) {
      _logger.warning(e);
    }
    tempDirectory.createSync(recursive: true);
    await _initOnlineAccount();
    await _initOfflineAccount();
  }

  Future<void> _initOfflineAccount() async {
    _offlineAuthKey = await _secureStorage.read(
      key: offlineAuthSecretKey,
      iOptions: _secureStorageOptionsIOS,
    );
  }

  Future<void> _initOnlineAccount() async {
    if (!_preferences.containsKey(tokenKey)) {
      for (final key in onlineSecureKeys) {
        unawaited(
          _secureStorage.delete(
            key: key,
            iOptions: _secureStorageOptionsIOS,
          ),
        );
      }
    } else {
      _key = await _secureStorage.read(
        key: keyKey,
        iOptions: _secureStorageOptionsIOS,
      );
      _secretKey = await _secureStorage.read(
        key: secretKeyKey,
        iOptions: _secureStorageOptionsIOS,
      );
      _authSecretKey = await _secureStorage.read(
        key: authSecretKeyKey,
        iOptions: _secureStorageOptionsIOS,
      );
      if (_key == null) {
        await logout(autoLogout: true);
      }
    }
  }

  Future<void> logout({bool autoLogout = false}) async {
    await _preferences.clear();
    for (String key in onlineSecureKeys) {
      await _secureStorage.delete(
        key: key,
        iOptions: _secureStorageOptionsIOS,
      );
    }
    await AuthenticatorDB.instance.clearTable();
    _key = null;
    _cachedToken = null;
    _secretKey = null;
    _authSecretKey = null;
    Bus.instance.fire(SignedOutEvent());
  }

  Future<KeyGenResult> generateKey(String password) async {
    // Create a master key
    final masterKey = CryptoUtil.generateKey();

    // Create a recovery key
    final recoveryKey = CryptoUtil.generateKey();

    // Encrypt master key and recovery key with each other
    final encryptedMasterKey = CryptoUtil.encryptSync(masterKey, recoveryKey);
    final encryptedRecoveryKey = CryptoUtil.encryptSync(recoveryKey, masterKey);

    // Derive a key from the password that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
      utf8.encode(password) as Uint8List,
      kekSalt,
    );
    final loginKey = await CryptoUtil.deriveLoginKey(derivedKeyResult.key);

    // Encrypt the key with this derived key
    final encryptedKeyData =
        CryptoUtil.encryptSync(masterKey, derivedKeyResult.key);

    // Generate a public-private keypair and encrypt the latter
    final keyPair = await CryptoUtil.generateKeyPair();
    final encryptedSecretKeyData =
        CryptoUtil.encryptSync(keyPair.sk, masterKey);

    final attributes = KeyAttributes(
      Sodium.bin2base64(kekSalt),
      Sodium.bin2base64(encryptedKeyData.encryptedData!),
      Sodium.bin2base64(encryptedKeyData.nonce!),
      Sodium.bin2base64(keyPair.pk),
      Sodium.bin2base64(encryptedSecretKeyData.encryptedData!),
      Sodium.bin2base64(encryptedSecretKeyData.nonce!),
      derivedKeyResult.memLimit,
      derivedKeyResult.opsLimit,
      Sodium.bin2base64(encryptedMasterKey.encryptedData!),
      Sodium.bin2base64(encryptedMasterKey.nonce!),
      Sodium.bin2base64(encryptedRecoveryKey.encryptedData!),
      Sodium.bin2base64(encryptedRecoveryKey.nonce!),
    );
    final privateAttributes = PrivateKeyAttributes(
      Sodium.bin2base64(masterKey),
      Sodium.bin2hex(recoveryKey),
      Sodium.bin2base64(keyPair.sk),
    );
    return KeyGenResult(attributes, privateAttributes, loginKey);
  }

  Future<Tuple2<KeyAttributes, Uint8List>> getAttributesForNewPassword(
    String password,
  ) async {
    // Get master key
    final masterKey = getKey();

    // Derive a key from the password that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
      utf8.encode(password) as Uint8List,
      kekSalt,
    );
    final loginKey = await CryptoUtil.deriveLoginKey(derivedKeyResult.key);

    // Encrypt the key with this derived key
    final encryptedKeyData =
        CryptoUtil.encryptSync(masterKey!, derivedKeyResult.key);

    final existingAttributes = getKeyAttributes();

    final updatedAttributes = existingAttributes!.copyWith(
      kekSalt: Sodium.bin2base64(kekSalt),
      encryptedKey: Sodium.bin2base64(encryptedKeyData.encryptedData!),
      keyDecryptionNonce: Sodium.bin2base64(encryptedKeyData.nonce!),
      memLimit: derivedKeyResult.memLimit,
      opsLimit: derivedKeyResult.opsLimit,
    );
    return Tuple2(updatedAttributes, loginKey);
  }

  // decryptSecretsAndGetLoginKey decrypts the master key and recovery key
  // with the given password and save them in local secure storage.
  // This method also returns the keyEncKey that can be used for performing
  // SRP setup for existing users.
  Future<Uint8List> decryptSecretsAndGetKeyEncKey(
    String password,
    KeyAttributes attributes, {
    Uint8List? keyEncryptionKey,
  }) async {
    _logger.info('Start decryptAndSaveSecrets');
    keyEncryptionKey ??= await CryptoUtil.deriveKey(
      utf8.encode(password) as Uint8List,
      Sodium.base642bin(attributes.kekSalt),
      attributes.memLimit,
      attributes.opsLimit,
    );

    _logger.info('user-key done');
    Uint8List key;
    try {
      key = CryptoUtil.decryptSync(
        Sodium.base642bin(attributes.encryptedKey),
        keyEncryptionKey,
        Sodium.base642bin(attributes.keyDecryptionNonce),
      );
    } catch (e) {
      _logger.severe('master-key failed, incorrect password?', e);
      throw Exception("Incorrect password");
    }
    _logger.info("master-key done");
    await setKey(Sodium.bin2base64(key));
    final secretKey = CryptoUtil.decryptSync(
      Sodium.base642bin(attributes.encryptedSecretKey),
      key,
      Sodium.base642bin(attributes.secretKeyDecryptionNonce),
    );
    _logger.info("secret-key done");
    await setSecretKey(Sodium.bin2base64(secretKey));
    final token = CryptoUtil.openSealSync(
      Sodium.base642bin(getEncryptedToken()!),
      Sodium.base642bin(attributes.publicKey),
      secretKey,
    );
    _logger.info('appToken done');
    await setToken(
      Sodium.bin2base64(token, variant: Sodium.base64VariantUrlsafe),
    );
    return keyEncryptionKey;
  }

  Future<void> recover(String recoveryKey) async {
    // check if user has entered mnemonic code
    if (recoveryKey.contains(' ')) {
      if (recoveryKey.split(' ').length != mnemonicKeyWordCount) {
        throw AssertionError(
          'recovery code should have $mnemonicKeyWordCount words',
        );
      }
      recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
    }
    final attributes = getKeyAttributes();
    Uint8List masterKey;
    try {
      masterKey = await CryptoUtil.decrypt(
        Sodium.base642bin(attributes!.masterKeyEncryptedWithRecoveryKey),
        Sodium.hex2bin(recoveryKey),
        Sodium.base642bin(attributes.masterKeyDecryptionNonce),
      );
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
    await setKey(Sodium.bin2base64(masterKey));
    final secretKey = CryptoUtil.decryptSync(
      Sodium.base642bin(attributes.encryptedSecretKey),
      masterKey,
      Sodium.base642bin(attributes.secretKeyDecryptionNonce),
    );
    await setSecretKey(Sodium.bin2base64(secretKey));
    final token = CryptoUtil.openSealSync(
      Sodium.base642bin(getEncryptedToken()!),
      Sodium.base642bin(attributes.publicKey),
      secretKey,
    );
    await setToken(
      Sodium.bin2base64(token, variant: Sodium.base64VariantUrlsafe),
    );
  }

  String getHttpEndpoint() {
    return _preferences.getString(endPointKey) ?? endpoint;
  }

  Future<void> setHttpEndpoint(String endpoint) async {
    await _preferences.setString(endPointKey, endpoint);
    Bus.instance.fire(EndpointUpdatedEvent());
  }

  String? getToken() {
    _cachedToken ??= _preferences.getString(tokenKey);
    return _cachedToken;
  }

  bool isLoggedIn() {
    return getToken() != null;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _preferences.setString(tokenKey, token);
    Bus.instance.fire(SignedInEvent());
  }

  Future<void> setEncryptedToken(String encryptedToken) async {
    await _preferences.setString(encryptedTokenKey, encryptedToken);
  }

  String? getEncryptedToken() {
    return _preferences.getString(encryptedTokenKey);
  }

  String? getEmail() {
    return _preferences.getString(emailKey);
  }

  Future<void> setEmail(String email) async {
    await _preferences.setString(emailKey, email);
  }

  int? getUserID() {
    return _preferences.getInt(userIDKey);
  }

  Future<void> setUserID(int userID) async {
    await _preferences.setInt(userIDKey, userID);
  }

  Future<void> setKeyAttributes(KeyAttributes attributes) async {
    await _preferences.setString(keyAttributesKey, attributes.toJson());
  }

  KeyAttributes? getKeyAttributes() {
    final jsonValue = _preferences.getString(keyAttributesKey);
    if (jsonValue == null) {
      return null;
    } else {
      return KeyAttributes.fromJson(jsonValue);
    }
  }

  Future<void> setKey(String key) async {
    _key = key;
    await _secureStorage.write(
      key: keyKey,
      value: key,
      iOptions: _secureStorageOptionsIOS,
    );
  }

  Future<void> setSecretKey(String? secretKey) async {
    _secretKey = secretKey;
    await _secureStorage.write(
      key: secretKeyKey,
      value: secretKey,
      iOptions: _secureStorageOptionsIOS,
    );
  }

  Future<void> setAuthSecretKey(String? authSecretKey) async {
    _authSecretKey = authSecretKey;
    await _secureStorage.write(
      key: authSecretKeyKey,
      value: authSecretKey,
      iOptions: _secureStorageOptionsIOS,
    );
  }

  Uint8List? getKey() {
    return _key == null ? null : Sodium.base642bin(_key!);
  }

  Uint8List? getSecretKey() {
    return _secretKey == null ? null : Sodium.base642bin(_secretKey!);
  }

  Uint8List? getAuthSecretKey() {
    return _authSecretKey == null ? null : Sodium.base642bin(_authSecretKey!);
  }

  Uint8List? getOfflineSecretKey() {
    return _offlineAuthKey == null ? null : Sodium.base642bin(_offlineAuthKey!);
  }

  Uint8List getRecoveryKey() {
    final keyAttributes = getKeyAttributes()!;
    return CryptoUtil.decryptSync(
      Sodium.base642bin(keyAttributes.recoveryKeyEncryptedWithMasterKey),
      getKey()!,
      Sodium.base642bin(keyAttributes.recoveryKeyDecryptionNonce),
    );
  }

  // Caution: This directory is cleared on app start
  String getTempDirectory() {
    return _tempDirectory;
  }

  bool hasConfiguredAccount() {
    return getToken() != null && _key != null;
  }

  bool hasOptedForOfflineMode() {
    return _preferences.getBool(hasOptedForOfflineModeKey) ?? false;
  }

  Future<void> optForOfflineMode() async {
    if ((await _secureStorage.containsKey(
      key: offlineAuthSecretKey,
      iOptions: _secureStorageOptionsIOS,
    ))) {
      _offlineAuthKey = await _secureStorage.read(
        key: offlineAuthSecretKey,
        iOptions: _secureStorageOptionsIOS,
      );
    } else {
      _offlineAuthKey = Sodium.bin2base64(CryptoUtil.generateKey());
      await _secureStorage.write(
        key: offlineAuthSecretKey,
        value: _offlineAuthKey,
        iOptions: _secureStorageOptionsIOS,
      );
    }
    await _preferences.setBool(hasOptedForOfflineModeKey, true);
  }

  bool shouldShowLockScreen() {
    if (_preferences.containsKey(keyShouldShowLockScreen)) {
      return _preferences.getBool(keyShouldShowLockScreen)!;
    } else {
      return false;
    }
  }

  Future<void> setShouldShowLockScreen(bool value) {
    return _preferences.setBool(keyShouldShowLockScreen, value);
  }

  void setVolatilePassword(String volatilePassword) {
    _volatilePassword = volatilePassword;
  }

  void resetVolatilePassword() {
    _volatilePassword = null;
  }

  String? getVolatilePassword() {
    return _volatilePassword;
  }
}
