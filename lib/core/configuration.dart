import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  static const endpointKey = "endpoint";
  static const tokenKey = "token";
  static const usernameKey = "username";
  static const userIDKey = "user_id";
  static const passwordKey = "password";
  static const hasOptedForE2EKey = "has_opted_for_e2e_encryption";
  static const keyKey = "key";
  static const keyEncryptedKey = "encrypted_key";

  static final String iv = base64.encode(List.filled(16, 0));

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

  Future<void> generateAndSaveKey(String passphrase) async {
    final key = CryptoUtil.getBase64EncodedSecureRandomString(length: 32);
    await setKey(key);
    final hashedPassphrase = sha256.convert(passphrase.codeUnits);
    final encryptedKey = CryptoUtil.encryptToBase64(
        key, base64.encode(hashedPassphrase.bytes), iv);
    await setEncryptedKey(encryptedKey);
  }

  String getEndpoint() {
    return _preferences.getString(endpointKey);
  }

  String getHttpEndpoint() {
    if (getEndpoint() == null) {
      return "";
    }
    return "http://" + getEndpoint() + ":8080";
  }

  void setEndpoint(String endpoint) async {
    await _preferences.setString(endpointKey, endpoint);
  }

  String getToken() {
    return _preferences.getString(tokenKey);
  }

  void setToken(String token) async {
    await _preferences.setString(tokenKey, token);
  }

  String getUsername() {
    return _preferences.getString(usernameKey);
  }

  void setUsername(String username) async {
    await _preferences.setString(usernameKey, username);
  }

  int getUserID() {
    return _preferences.getInt(userIDKey);
  }

  void setUserID(int userID) async {
    await _preferences.setInt(userIDKey, userID);
  }

  String getPassword() {
    return _preferences.getString(passwordKey);
  }

  void setPassword(String password) async {
    await _preferences.setString(passwordKey, password);
  }

  void setOptInForE2E(bool hasOptedForE2E) async {
    await _preferences.setBool(hasOptedForE2EKey, hasOptedForE2E);
  }

  bool hasOptedForE2E() {
    return true;
    // return _preferences.getBool(hasOptedForE2EKey);
  }

  Future<void> setEncryptedKey(String encryptedKey) async {
    await _preferences.setString(keyEncryptedKey, encryptedKey);
  }

  String getEncryptedKey() {
    return _preferences.getString(keyEncryptedKey);
  }

  Future<void> setKey(String key) async {
    await _secureStorage.write(key: keyKey, value: key);
    _key = key;
  }

  Future<void> decryptEncryptedKey(String passphrase) async {
    final hashedPassphrase = sha256.convert(passphrase.codeUnits);
    final encryptedKey = getEncryptedKey();
    final key = CryptoUtil.decryptFromBase64(
        encryptedKey, base64.encode(hashedPassphrase.bytes), iv);
    await setKey(key);
  }

  String getKey() {
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
    return getEndpoint() != null && getToken() != null;
  }
}
