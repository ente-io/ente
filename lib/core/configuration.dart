import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:photos/utils/crypto_util.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  static const endpointKey = "endpoint";
  static const userIDKey = "user_id";
  static const emailKey = "email";
  static const tokenKey = "token";
  static const hasOptedForE2EKey = "has_opted_for_e2e_encryption";
  static const foldersToBackUpKey = "folders_to_back_up";
  static const keyKey = "key";
  static const keyEncryptedKey = "encrypted_key";
  static const keyKekSalt = "kek_salt";
  static const keyKekHash = "kek_hash";
  static const keyKekHashSalt = "kek_hash_salt";
  static const keyEncryptedKeyIV = "encrypted_key_iv";

  SharedPreferences _preferences;
  FlutterSecureStorage _secureStorage;
  String _key;
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
  }

  Future<KeyAttributes> generateAndSaveKey(String passphrase) async {
    final key = CryptoUtil.getSecureRandomBytes(length: 32);
    final kekSalt = CryptoUtil.getSecureRandomBytes(length: 32);
    final kek = CryptoUtil.scrypt(utf8.encode(passphrase), kekSalt);
    final kekHashSalt = CryptoUtil.getSecureRandomBytes(length: 32);
    final kekHash = CryptoUtil.scrypt(kek, kekHashSalt);
    final iv = CryptoUtil.getSecureRandomBytes(length: 16);
    final encryptedKey = CryptoUtil.aesEncrypt(key, kek, iv);
    final attributes = KeyAttributes(
        base64.encode(kekSalt),
        base64.encode(kekHash),
        base64.encode(kekHashSalt),
        base64.encode(encryptedKey),
        base64.encode(iv));
    await setKey(base64.encode(key));
    await setKeyAttributes(attributes);
    return attributes;
  }

  Future<void> decryptAndSaveKey(
      String passphrase, KeyAttributes attributes) async {
    final kek = CryptoUtil.scrypt(
        utf8.encode(passphrase), base64.decode(attributes.kekSalt));
    final calculatedKekHash =
        CryptoUtil.scrypt(kek, base64.decode(attributes.kekHashSalt));
    bool correctPassphrase =
        base64.encode(calculatedKekHash) == attributes.kekHash;
    if (!correctPassphrase) {
      throw Exception("Incorrect passphrase");
    }
    final key = CryptoUtil.aesDecrypt(base64.decode(attributes.encryptedKey),
        kek, base64.decode(attributes.encryptedKeyIV));
    await setKey(base64.encode(key));
  }

  String getHttpEndpoint() {
    return "http://192.168.0.100";
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

  Set<String> getFoldersToBackUp() {
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

  Future<void> setFoldersToBackUp(Set<String> folders) async {
    await _preferences.setStringList(foldersToBackUpKey, folders.toList());
  }

  Future<void> setKeyAttributes(KeyAttributes attributes) async {
    await _preferences.setString(
        keyKekSalt, attributes == null ? null : attributes.kekSalt);
    await _preferences.setString(
        keyKekHash, attributes == null ? null : attributes.kekHash);
    await _preferences.setString(
        keyKekHashSalt, attributes == null ? null : attributes.kekHashSalt);
    await _preferences.setString(
        keyEncryptedKey, attributes == null ? null : attributes.encryptedKey);
    await _preferences.setString(keyEncryptedKeyIV,
        attributes == null ? null : attributes.encryptedKeyIV);
  }

  KeyAttributes getKeyAttributes() {
    if (_preferences.getString(keyEncryptedKey) == null) {
      return null;
    }
    return KeyAttributes(
        _preferences.getString(keyKekSalt),
        _preferences.getString(keyKekHash),
        _preferences.getString(keyKekHashSalt),
        _preferences.getString(keyEncryptedKey),
        _preferences.getString(keyEncryptedKeyIV));
  }

  String getEncryptedKey() {
    return _preferences.getString(keyEncryptedKey);
  }

  Future<void> setKey(String key) async {
    await _secureStorage.write(key: keyKey, value: key);
    _key = key;
  }

  Uint8List getKey() {
    return base64.decode(_key);
  }

  String getBase64EncodedKey() {
    return _key;
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
    return getToken() != null && getBase64EncodedKey() != null;
  }
}
