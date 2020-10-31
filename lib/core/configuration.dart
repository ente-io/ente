import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/models/private_key_attributes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:photos/utils/crypto_util.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  static const endpointKey = "endpoint";
  static const userIDKey = "user_id";
  static const emailKey = "email";
  static const nameKey = "name";
  static const tokenKey = "token";
  static const hasOptedForE2EKey = "has_opted_for_e2e_encryption";
  static const foldersToBackUpKey = "folders_to_back_up";
  static const keyKey = "key";
  static const secretKeyKey = "secret_key";
  static const keyAttributesKey = "key_attributes";

  SharedPreferences _preferences;
  FlutterSecureStorage _secureStorage;
  String _key;
  String _secretKey;
  String _documentsDirectory;
  String _tempDirectory;
  String _thumbnailsDirectory;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = FlutterSecureStorage();
    _documentsDirectory = (await getApplicationDocumentsDirectory()).path;
    _tempDirectory = _documentsDirectory + "/temp/";
    _thumbnailsDirectory = _documentsDirectory + "/thumbnails/";
    new io.Directory(_tempDirectory).createSync(recursive: true);
    new io.Directory(_thumbnailsDirectory).createSync(recursive: true);
    _key = await _secureStorage.read(key: keyKey);
    _secretKey = await _secureStorage.read(key: secretKeyKey);
  }

  Future<KeyGenResult> generateKey(String passphrase) async {
    // Create a master key
    final key = CryptoUtil.generateKey();

    // Derive a key from the passphrase that will be used to encrypt and
    // decrypt the master key
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final kek = CryptoUtil.deriveKey(utf8.encode(passphrase), kekSalt);

    // Encrypt the key with this derived key
    final encryptedKeyData = CryptoUtil.encryptSync(key, kek);

    // Hash the passphrase so that its correctness can be compared later
    final kekHash = await CryptoUtil.hash(kek);

    // Generate a public-private keypair and encrypt the latter
    final keyPair = await CryptoUtil.generateKeyPair();
    final encryptedSecretKeyData = CryptoUtil.encryptSync(keyPair.sk, kek);

    final attributes = KeyAttributes(
      Sodium.bin2base64(kekSalt),
      kekHash,
      Sodium.bin2base64(encryptedKeyData.encryptedData),
      Sodium.bin2base64(encryptedKeyData.nonce),
      Sodium.bin2base64(keyPair.pk),
      Sodium.bin2base64(encryptedSecretKeyData.encryptedData),
      Sodium.bin2base64(encryptedSecretKeyData.nonce),
    );
    final privateAttributes = PrivateKeyAttributes(
        Sodium.bin2base64(key), Sodium.bin2base64(keyPair.sk));
    return KeyGenResult(attributes, privateAttributes);
  }

  Future<void> decryptAndSaveKey(
      String passphrase, KeyAttributes attributes) async {
    final kek = CryptoUtil.deriveKey(
        utf8.encode(passphrase), Sodium.base642bin(attributes.kekSalt));
    bool correctPassphrase =
        await CryptoUtil.verifyHash(kek, attributes.kekHash);
    if (!correctPassphrase) {
      throw Exception("Incorrect passphrase");
    }
    final key = CryptoUtil.decryptSync(
        Sodium.base642bin(attributes.encryptedKey),
        kek,
        Sodium.base642bin(attributes.keyDecryptionNonce));
    final secretKey = CryptoUtil.decryptSync(
        Sodium.base642bin(attributes.encryptedSecretKey),
        kek,
        Sodium.base642bin(attributes.secretKeyDecryptionNonce));
    await setKey(Sodium.bin2base64(key));
    await setSecretKey(Sodium.bin2base64(secretKey));
  }

  String getHttpEndpoint() {
    if (kDebugMode) {
      return "http://192.168.0.100";
    }
    return "https://api.staging.ente.io";
  }

  Future<void> setEndpoint(String endpoint) async {
    await _preferences.setString(endpointKey, endpoint);
  }

  String getToken() {
    return _preferences.getString(tokenKey);
  }

  Future<void> setToken(String token) async {
    await _preferences.setString(tokenKey, token);
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

  Future<void> setOptInForE2E(bool hasOptedForE2E) async {
    await _preferences.setBool(hasOptedForE2EKey, hasOptedForE2E);
  }

  bool hasOptedForE2E() {
    return true;
    // return _preferences.getBool(hasOptedForE2EKey);
  }

  Set<String> getPathsToBackUp() {
    if (_preferences.containsKey(foldersToBackUpKey)) {
      return _preferences.getStringList(foldersToBackUpKey).toSet();
    } else {
      final foldersToBackUp = Set<String>();
      foldersToBackUp.add("Camera");
      foldersToBackUp.add("Recents");
      foldersToBackUp.add("DCIM");
      foldersToBackUp.add("Download");
      foldersToBackUp.add("Screenshot");
      return foldersToBackUp;
    }
  }

  Future<void> setPathsToBackUp(Set<String> folders) async {
    await _preferences.setStringList(foldersToBackUpKey, folders.toList());
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

  String getDocumentsDirectory() {
    return _documentsDirectory;
  }

  String getThumbnailsDirectory() {
    return _thumbnailsDirectory;
  }

  String getTempDirectory() {
    return _tempDirectory;
  }

  bool hasConfiguredAccount() {
    return getToken() != null && getKey() != null;
  }
}
