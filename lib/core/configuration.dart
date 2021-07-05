import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/models/private_key_attributes.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photos/utils/crypto_util.dart';

class Configuration {
  Configuration._privateConstructor();

  static final Configuration instance = Configuration._privateConstructor();

  static const emailKey = "email";
  static const foldersToBackUpKey = "folders_to_back_up";
  static const keyAttributesKey = "key_attributes";
  static const keyKey = "key";
  static const keyShouldBackupOverMobileData = "should_backup_over_mobile_data";
  static const keyShouldHideFromRecents = "should_hide_from_recents";
  static const keyShouldShowLockScreen = "should_show_lock_screen";
  static const keyHasSkippedBackupFolderSelection =
      "has_skipped_backup_folder_selection";
  static const lastTempFolderClearTimeKey = "last_temp_folder_clear_time";
  static const nameKey = "name";
  static const secretKeyKey = "secret_key";
  static const tokenKey = "token";
  static const encryptedTokenKey = "encrypted_token";
  static const userIDKey = "user_id";

  final kTempFolderDeletionTimeBuffer = Duration(days: 1).inMicroseconds;

  static final _logger = Logger("Configuration");

  String _cachedToken;
  String _documentsDirectory;
  String _key;
  SharedPreferences _preferences;
  String _secretKey;
  FlutterSecureStorage _secureStorage;
  String _tempDirectory;
  String _thumbnailCacheDirectory;
  String _volatilePassword;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = FlutterSecureStorage();
    _documentsDirectory = (await getApplicationDocumentsDirectory()).path;
    _tempDirectory = _documentsDirectory + "/temp/";
    final tempDirectory = new io.Directory(_tempDirectory);
    try {
      final currentTime = DateTime.now().microsecondsSinceEpoch;
      if (tempDirectory.existsSync() &&
          (_preferences.getInt(lastTempFolderClearTimeKey) ?? 0) <
              (currentTime - kTempFolderDeletionTimeBuffer)) {
        tempDirectory.deleteSync(recursive: true);
        await _preferences.setInt(lastTempFolderClearTimeKey, currentTime);
        _logger.info("Cleared temp folder");
      } else {
        _logger.info("Skipping temp folder clear");
      }
    } catch (e) {
      _logger.warning(e);
    }
    tempDirectory.createSync(recursive: true);
    _thumbnailCacheDirectory =
        (await getTemporaryDirectory()).path + "/thumbnail-cache";
    io.Directory(_thumbnailCacheDirectory).createSync(recursive: true);
    if (!_preferences.containsKey(tokenKey)) {
      await _secureStorage.deleteAll();
    } else {
      _key = await _secureStorage.read(key: keyKey);
      _secretKey = await _secureStorage.read(key: secretKeyKey);
    }
  }

  Future<void> logout() async {
    if (SyncService.instance.isSyncInProgress()) {
      SyncService.instance.stopSync();
      try {
        await SyncService.instance.existingSync();
      } catch (e) {
        // ignore
      }
    }
    await _preferences.clear();
    await _secureStorage.deleteAll();
    _key = null;
    _cachedToken = null;
    _secretKey = null;
    await FilesDB.instance.clearTable();
    await CollectionsDB.instance.clearTable();
    await MemoriesDB.instance.clearTable();
    await PublicKeysDB.instance.clearTable();
    await UploadLocksDB.instance.clearTable();
    CollectionsService.instance.clearCache();
    FavoritesService.instance.clearCache();
    MemoriesService.instance.clearCache();
    BillingService.instance.clearCache();
    Bus.instance.fire(UserLoggedOutEvent());
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
    final derivedKeyResult =
        await CryptoUtil.deriveSensitiveKey(utf8.encode(password), kekSalt);

    // Encrypt the key with this derived key
    final encryptedKeyData =
        CryptoUtil.encryptSync(masterKey, derivedKeyResult.key);

    // Generate a public-private keypair and encrypt the latter
    final keyPair = await CryptoUtil.generateKeyPair();
    final encryptedSecretKeyData =
        CryptoUtil.encryptSync(keyPair.sk, masterKey);

    final attributes = KeyAttributes(
      Sodium.bin2base64(kekSalt),
      Sodium.bin2base64(encryptedKeyData.encryptedData),
      Sodium.bin2base64(encryptedKeyData.nonce),
      Sodium.bin2base64(keyPair.pk),
      Sodium.bin2base64(encryptedSecretKeyData.encryptedData),
      Sodium.bin2base64(encryptedSecretKeyData.nonce),
      derivedKeyResult.memLimit,
      derivedKeyResult.opsLimit,
      Sodium.bin2base64(encryptedMasterKey.encryptedData),
      Sodium.bin2base64(encryptedMasterKey.nonce),
      Sodium.bin2base64(encryptedRecoveryKey.encryptedData),
      Sodium.bin2base64(encryptedRecoveryKey.nonce),
    );
    final privateAttributes = PrivateKeyAttributes(Sodium.bin2base64(masterKey),
        Sodium.bin2hex(recoveryKey), Sodium.bin2base64(keyPair.sk));
    return KeyGenResult(attributes, privateAttributes);
  }

  Future<KeyAttributes> updatePassword(String password) async {
    // Get master key
    final masterKey = getKey();

    // Derive a key from the password that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult =
        await CryptoUtil.deriveSensitiveKey(utf8.encode(password), kekSalt);

    // Encrypt the key with this derived key
    final encryptedKeyData =
        CryptoUtil.encryptSync(masterKey, derivedKeyResult.key);

    final existingAttributes = getKeyAttributes();

    return existingAttributes.copyWith(
      kekSalt: Sodium.bin2base64(kekSalt),
      encryptedKey: Sodium.bin2base64(encryptedKeyData.encryptedData),
      keyDecryptionNonce: Sodium.bin2base64(encryptedKeyData.nonce),
      memLimit: derivedKeyResult.memLimit,
      opsLimit: derivedKeyResult.opsLimit,
    );
  }

  Future<void> decryptAndSaveSecrets(
      String password, KeyAttributes attributes) async {
    final kek = await CryptoUtil.deriveKey(
      utf8.encode(password),
      Sodium.base642bin(attributes.kekSalt),
      attributes.memLimit,
      attributes.opsLimit,
    );
    var key;
    try {
      key = CryptoUtil.decryptSync(Sodium.base642bin(attributes.encryptedKey),
          kek, Sodium.base642bin(attributes.keyDecryptionNonce));
    } catch (e) {
      throw Exception("Incorrect password");
    }
    final secretKey = CryptoUtil.decryptSync(
        Sodium.base642bin(attributes.encryptedSecretKey),
        key,
        Sodium.base642bin(attributes.secretKeyDecryptionNonce));
    await setKey(Sodium.bin2base64(key));
    await setSecretKey(Sodium.bin2base64(secretKey));
    final token = CryptoUtil.openSealSync(
        Sodium.base642bin(getEncryptedToken()),
        Sodium.base642bin(attributes.publicKey),
        secretKey);
    await setToken(
        Sodium.bin2base64(token, variant: Sodium.base64VariantUrlsafe));
  }

  Future<KeyAttributes> createNewRecoveryKey() async {
    final masterKey = getKey();
    final existingAttributes = getKeyAttributes();

    // Create a recovery key
    final recoveryKey = CryptoUtil.generateKey();

    // Encrypt master key and recovery key with each other
    final encryptedMasterKey = CryptoUtil.encryptSync(masterKey, recoveryKey);
    final encryptedRecoveryKey = CryptoUtil.encryptSync(recoveryKey, masterKey);

    return existingAttributes.copyWith(
      masterKeyEncryptedWithRecoveryKey:
          Sodium.bin2base64(encryptedMasterKey.encryptedData),
      masterKeyDecryptionNonce: Sodium.bin2base64(encryptedMasterKey.nonce),
      recoveryKeyEncryptedWithMasterKey:
          Sodium.bin2base64(encryptedRecoveryKey.encryptedData),
      recoveryKeyDecryptionNonce: Sodium.bin2base64(encryptedRecoveryKey.nonce),
    );
  }

  Future<void> recover(String recoveryKey) async {
    final keyAttributes = getKeyAttributes();
    var masterKey;
    try {
      masterKey = await CryptoUtil.decrypt(
          Sodium.base642bin(keyAttributes.masterKeyEncryptedWithRecoveryKey),
          Sodium.hex2bin(recoveryKey),
          Sodium.base642bin(keyAttributes.masterKeyDecryptionNonce));
    } catch (e) {
      _logger.severe(e);
      throw e;
    }
    await setKey(Sodium.bin2base64(masterKey));
  }

  String getHttpEndpoint() {
    if (kDebugMode) {
      return "http://192.168.1.123:8080";
    }
    return "https://api.ente.io";
  }

  String getToken() {
    if (_cachedToken == null) {
      _cachedToken = _preferences.getString(tokenKey);
    }
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _preferences.setString(tokenKey, token);
  }

  Future<void> setEncryptedToken(String encryptedToken) async {
    await _preferences.setString(encryptedTokenKey, encryptedToken);
  }

  String getEncryptedToken() {
    return _preferences.getString(encryptedTokenKey);
  }

  String getEmail() {
    return _preferences.getString(emailKey);
  }

  Future<void> setEmail(String email) async {
    await _preferences.setString(emailKey, email);
  }

  String getName() {
    return _preferences.getString(nameKey);
  }

  Future<void> setName(String name) async {
    await _preferences.setString(nameKey, name);
  }

  int getUserID() {
    return _preferences.getInt(userIDKey);
  }

  Future<void> setUserID(int userID) async {
    await _preferences.setInt(userIDKey, userID);
  }

  Set<String> getPathsToBackUp() {
    if (_preferences.containsKey(foldersToBackUpKey)) {
      return _preferences.getStringList(foldersToBackUpKey).toSet();
    } else {
      return Set<String>();
    }
  }

  Future<void> setPathsToBackUp(Set<String> newPaths) async {
    final currentPaths = getPathsToBackUp();
    List<String> added = [], removed = [];
    for (final path in newPaths) {
      if (!currentPaths.contains(path)) {
        added.add(path);
      }
    }
    for (final path in currentPaths) {
      if (!newPaths.contains(path)) {
        removed.add(path);
      }
    }
    await _preferences.setStringList(foldersToBackUpKey, newPaths.toList());
    if (added.isNotEmpty) {
      SyncService.instance.onFoldersAdded(added);
    }
    if (removed.isNotEmpty) {
      SyncService.instance.onFoldersRemoved(removed);
    }
  }

  Future<void> addPathToFoldersToBeBackedUp(String path) async {
    final currentPaths = getPathsToBackUp();
    currentPaths.add(path);
    return setPathsToBackUp(currentPaths);
  }

  Future<void> setKeyAttributes(KeyAttributes attributes) async {
    await _preferences.setString(
        keyAttributesKey, attributes == null ? null : attributes.toJson());
  }

  KeyAttributes getKeyAttributes() {
    final jsonValue = _preferences.getString(keyAttributesKey);
    if (jsonValue == null) {
      return null;
    } else {
      return KeyAttributes.fromJson(jsonValue);
    }
  }

  Future<void> setKey(String key) async {
    _key = key;
    if (key == null) {
      await _secureStorage.delete(key: keyKey);
    } else {
      await _secureStorage.write(key: keyKey, value: key);
    }
  }

  Future<void> setSecretKey(String secretKey) async {
    _secretKey = secretKey;
    if (secretKey == null) {
      await _secureStorage.delete(key: secretKeyKey);
    } else {
      await _secureStorage.write(key: secretKeyKey, value: secretKey);
    }
  }

  Uint8List getKey() {
    return _key == null ? null : Sodium.base642bin(_key);
  }

  Uint8List getSecretKey() {
    return _secretKey == null ? null : Sodium.base642bin(_secretKey);
  }

  Uint8List getRecoveryKey() {
    final keyAttributes = getKeyAttributes();
    return CryptoUtil.decryptSync(
        Sodium.base642bin(keyAttributes.recoveryKeyEncryptedWithMasterKey),
        getKey(),
        Sodium.base642bin(keyAttributes.recoveryKeyDecryptionNonce));
  }

  String getDocumentsDirectory() {
    return _documentsDirectory;
  }

  // Caution: This directory is cleared on app start
  String getTempDirectory() {
    return _tempDirectory;
  }

  String getThumbnailCacheDirectory() {
    return _thumbnailCacheDirectory;
  }

  bool hasConfiguredAccount() {
    return getToken() != null && _key != null;
  }

  bool shouldBackupOverMobileData() {
    if (_preferences.containsKey(keyShouldBackupOverMobileData)) {
      return _preferences.getBool(keyShouldBackupOverMobileData);
    } else {
      return false;
    }
  }

  Future<void> setBackupOverMobileData(bool value) async {
    await _preferences.setBool(keyShouldBackupOverMobileData, value);
    if (value) {
      SyncService.instance.sync();
    }
  }

  bool shouldShowLockScreen() {
    if (_preferences.containsKey(keyShouldShowLockScreen)) {
      return _preferences.getBool(keyShouldShowLockScreen);
    } else {
      return false;
    }
  }

  Future<void> setShouldShowLockScreen(bool value) {
    return _preferences.setBool(keyShouldShowLockScreen, value);
  }

  bool shouldHideFromRecents() {
    if (_preferences.containsKey(keyShouldHideFromRecents)) {
      return _preferences.getBool(keyShouldHideFromRecents);
    } else {
      return false;
    }
  }

  Future<void> setShouldHideFromRecents(bool value) {
    return _preferences.setBool(keyShouldHideFromRecents, value);
  }

  void setVolatilePassword(String volatilePassword) {
    _volatilePassword = volatilePassword;
  }

  String getVolatilePassword() {
    return _volatilePassword;
  }

  Future<void> skipBackupFolderSelection() async {
    await _preferences.setBool(keyHasSkippedBackupFolderSelection, true);
  }

  bool hasSkippedBackupFolderSelection() {
    return _preferences.getBool(keyHasSkippedBackupFolderSelection) ?? false;
  }
}
