import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';
import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/errors.dart';
import 'package:ente_auth/core/event_bus.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:ente_auth/events/signed_in_event.dart';
import 'package:ente_auth/events/signed_out_event.dart';
import 'package:ente_auth/models/key_attributes.dart';
import 'package:ente_auth/models/key_gen_result.dart';
import 'package:ente_auth/models/private_key_attributes.dart';
import 'package:ente_auth/store/authenticator_db.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  Configuration._privateConstructor();

  static final Configuration instance = Configuration._privateConstructor();
  static const endpoint = String.fromEnvironment(
    "endpoint",
    defaultValue: kDefaultProductionEndpoint,
  );
  static const emailKey = "email";
  static const keyAttributesKey = "key_attributes";
  static const keyKey = "key";
  static const keyShouldHideFromRecents = "should_hide_from_recents";
  static const keyShouldShowLockScreen = "should_show_lock_screen";
  static const lastTempFolderClearTimeKey = "last_temp_folder_clear_time";
  static const secretKeyKey = "secret_key";
  static const authSecretKeyKey = "auth_secret_key";
  static const tokenKey = "token";
  static const encryptedTokenKey = "encrypted_token";
  static const userIDKey = "user_id";
  static const hasMigratedSecureStorageToFirstUnlockKey =
      "has_migrated_secure_storage_to_first_unlock";

  final kTempFolderDeletionTimeBuffer = const Duration(days: 1).inMicroseconds;

  static final _logger = Logger("Configuration");

  String? _cachedToken;
  late String _documentsDirectory;
  String? _key;
  late SharedPreferences _preferences;
  String? _secretKey;
  String? _authSecretKey;
  late FlutterSecureStorage _secureStorage;
  late String _tempDirectory;
  late String _thumbnailCacheDirectory;

  // 6th July 22: Remove this after 3 months. Hopefully, active users
  // will migrate to newer version of the app, where shared media is stored
  // on appSupport directory which OS won't clean up automatically
  late String _sharedTempMediaDirectory;

  late String _sharedDocumentsMediaDirectory;
  String? _volatilePassword;

  final _secureStorageOptionsIOS =
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  // const IOSOptions(accessibility: IOSAccessibility.first_unlock);

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
    final tempDirectoryPath = (await getTemporaryDirectory()).path;
    _thumbnailCacheDirectory = tempDirectoryPath + "/thumbnail-cache";
    io.Directory(_thumbnailCacheDirectory).createSync(recursive: true);
    _sharedTempMediaDirectory = tempDirectoryPath + "/ente-shared-media";
    io.Directory(_sharedTempMediaDirectory).createSync(recursive: true);
    _sharedDocumentsMediaDirectory = _documentsDirectory + "/ente-shared-media";
    io.Directory(_sharedDocumentsMediaDirectory).createSync(recursive: true);
    if (!_preferences.containsKey(tokenKey)) {
      await _secureStorage.deleteAll(iOptions: _secureStorageOptionsIOS);
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
      await _migrateSecurityStorageToFirstUnlock();
    }
  }

  Future<void> logout({bool autoLogout = false}) async {
    _logger.info("Logging out");
    await _preferences.clear();
    await _secureStorage.deleteAll(iOptions: _secureStorageOptionsIOS);
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
    final encryptedMasterKey = await CryptoUtil.encrypt(masterKey, recoveryKey);
    final encryptedRecoveryKey =
        await CryptoUtil.encrypt(recoveryKey, masterKey);

    // Derive a key from the password that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
      utf8.encode(password) as Uint8List,
      kekSalt,
    );

    // Encrypt the key with this derived key
    final encryptedKeyData =
        await CryptoUtil.encrypt(masterKey, derivedKeyResult.key);

    // Generate a public-private keypair and encrypt the latter
    final keyPair = await CryptoUtil.generateKeyPair();
    final encryptedSecretKeyData =
        await CryptoUtil.encrypt(keyPair.secretKey.extractBytes(), masterKey);

    final attributes = KeyAttributes(
      base64Encode(kekSalt),
      base64Encode(encryptedKeyData.encryptedData!),
      base64Encode(encryptedKeyData.nonce!),
      base64Encode(keyPair.publicKey),
      base64Encode(encryptedSecretKeyData.encryptedData!),
      base64Encode(encryptedSecretKeyData.nonce!),
      derivedKeyResult.memLimit,
      derivedKeyResult.opsLimit,
      base64Encode(encryptedMasterKey.encryptedData!),
      base64Encode(encryptedMasterKey.nonce!),
      base64Encode(encryptedRecoveryKey.encryptedData!),
      base64Encode(encryptedRecoveryKey.nonce!),
    );
    final privateAttributes = PrivateKeyAttributes(
      base64Encode(masterKey),
      hex.encode(recoveryKey),
      base64Encode(keyPair.secretKey.extractBytes()),
    );
    return KeyGenResult(attributes, privateAttributes);
  }

  Future<KeyAttributes> updatePassword(String password) async {
    // Get master key
    final masterKey = getKey();

    // Derive a key from the password that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
      utf8.encode(password) as Uint8List,
      kekSalt,
    );

    // Encrypt the key with this derived key
    final encryptedKeyData =
        await CryptoUtil.encrypt(masterKey!, derivedKeyResult.key);

    final existingAttributes = getKeyAttributes();

    return existingAttributes!.copyWith(
      kekSalt: base64Encode(kekSalt),
      encryptedKey: base64Encode(encryptedKeyData.encryptedData!),
      keyDecryptionNonce: base64Encode(encryptedKeyData.nonce!),
      memLimit: derivedKeyResult.memLimit,
      opsLimit: derivedKeyResult.opsLimit,
    );
  }

  Future<void> decryptAndSaveSecrets(
    String password,
    KeyAttributes attributes,
  ) async {
    _logger.info('Start decryptAndSaveSecrets');
    // validatePreVerificationStateCheck(
    //   attributes,
    //   password,
    //   getEncryptedToken(),
    // );
    _logger.info('state validation done');
    final kek = await CryptoUtil.deriveKey(
      utf8.encode(password) as Uint8List,
      base64.decode(attributes.kekSalt),
      attributes.memLimit,
      attributes.opsLimit,
    ).onError((e, s) {
      _logger.severe('deriveKey failed', e, s);
      throw KeyDerivationError();
    });

    _logger.info('user-key done');
    Uint8List key;
    try {
      key = await CryptoUtil.decrypt(
        base64.decode(attributes.encryptedKey),
        kek,
        base64.decode(attributes.keyDecryptionNonce),
      );
    } catch (e) {
      _logger.severe('master-key failed, incorrect password?', e);
      throw Exception("Incorrect password");
    }
    _logger.info("master-key done");
    await setKey(base64Encode(key));
    final secretKey = await CryptoUtil.decrypt(
      base64.decode(attributes.encryptedSecretKey),
      key,
      base64.decode(attributes.secretKeyDecryptionNonce),
    );
    _logger.info("secret-key done");
    await setSecretKey(base64Encode(secretKey));
    final token = CryptoUtil.openSealSync(
      base64.decode(getEncryptedToken()!),
      base64.decode(attributes.publicKey),
      secretKey,
    );
    _logger.info('appToken done');
    await setToken(base64Url.encode(token));
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
        base64.decode(attributes!.masterKeyEncryptedWithRecoveryKey),
        Uint8List.fromList(hex.decode(recoveryKey)),
        base64.decode(attributes.masterKeyDecryptionNonce),
      );
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
    await setKey(base64Encode(masterKey));
    final secretKey = await CryptoUtil.decrypt(
      base64.decode(attributes.encryptedSecretKey),
      masterKey,
      base64.decode(attributes.secretKeyDecryptionNonce),
    );
    await setSecretKey(base64Encode(secretKey));
    final token = CryptoUtil.openSealSync(
      base64.decode(getEncryptedToken()!),
      base64.decode(attributes.publicKey),
      secretKey,
    );
    await setToken(base64Url.encode(token));
  }

  String getHttpEndpoint() {
    return endpoint;
  }

  String? getToken() {
    _cachedToken ??= _preferences.getString(tokenKey);
    return _cachedToken;
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

  Future<void> setKey(String? key) async {
    _key = key;
    if (key == null) {
      await _secureStorage.delete(
        key: keyKey,
        iOptions: _secureStorageOptionsIOS,
      );
    } else {
      await _secureStorage.write(
        key: keyKey,
        value: key,
        iOptions: _secureStorageOptionsIOS,
      );
    }
  }

  Future<void> setSecretKey(String? secretKey) async {
    _secretKey = secretKey;
    if (secretKey == null) {
      await _secureStorage.delete(
        key: secretKeyKey,
        iOptions: _secureStorageOptionsIOS,
      );
    } else {
      await _secureStorage.write(
        key: secretKeyKey,
        value: secretKey,
        iOptions: _secureStorageOptionsIOS,
      );
    }
  }

  Future<void> setAuthSecretKey(String? authSecretKey) async {
    _authSecretKey = authSecretKey;
    if (authSecretKey == null) {
      await _secureStorage.delete(
        key: authSecretKeyKey,
        iOptions: _secureStorageOptionsIOS,
      );
    } else {
      await _secureStorage.write(
        key: authSecretKeyKey,
        value: authSecretKey,
        iOptions: _secureStorageOptionsIOS,
      );
    }
  }

  Uint8List? getKey() {
    return _key == null ? null : base64.decode(_key!);
  }

  Uint8List? getSecretKey() {
    return _secretKey == null ? null : base64.decode(_secretKey!);
  }

  Uint8List? getAuthSecretKey() {
    return _authSecretKey == null ? null : base64.decode(_authSecretKey!);
  }

  Future<Uint8List> getRecoveryKey() async {
    final keyAttributes = getKeyAttributes()!;
    return CryptoUtil.decrypt(
      base64.decode(keyAttributes.recoveryKeyEncryptedWithMasterKey),
      getKey()!,
      base64.decode(keyAttributes.recoveryKeyDecryptionNonce),
    );
  }

  // Caution: This directory is cleared on app start
  String getTempDirectory() {
    return _tempDirectory;
  }

  String getThumbnailCacheDirectory() {
    return _thumbnailCacheDirectory;
  }

  String getOldSharedMediaCacheDirectory() {
    return _sharedTempMediaDirectory;
  }

  String getSharedMediaDirectory() {
    return _sharedDocumentsMediaDirectory;
  }

  bool hasConfiguredAccount() {
    return getToken() != null && _key != null;
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

  bool shouldHideFromRecents() {
    return _preferences.getBool(keyShouldHideFromRecents) ?? false;
  }

  Future<void> setShouldHideFromRecents(bool value) {
    return _preferences.setBool(keyShouldHideFromRecents, value);
  }

  void setVolatilePassword(String volatilePassword) {
    _volatilePassword = volatilePassword;
  }

  String? getVolatilePassword() {
    return _volatilePassword;
  }

  Future<void> _migrateSecurityStorageToFirstUnlock() async {
    final hasMigratedSecureStorageToFirstUnlock =
        _preferences.getBool(hasMigratedSecureStorageToFirstUnlockKey) ?? false;
    if (!hasMigratedSecureStorageToFirstUnlock &&
        _key != null &&
        _secretKey != null) {
      await _secureStorage.write(
        key: keyKey,
        value: _key,
        iOptions: _secureStorageOptionsIOS,
      );
      await _secureStorage.write(
        key: secretKeyKey,
        value: _secretKey,
        iOptions: _secureStorageOptionsIOS,
      );
      await _preferences.setBool(
        hasMigratedSecureStorageToFirstUnlockKey,
        true,
      );
    }
  }
}
