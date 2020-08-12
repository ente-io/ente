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

  SharedPreferences _preferences;
  String _documentsDirectory;
  String _tempDirectory;
  String _thumbnailsDirectory;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _documentsDirectory = (await getApplicationDocumentsDirectory()).path;
    _tempDirectory = _documentsDirectory + "/temp/";
    _thumbnailsDirectory = _documentsDirectory + "/thumbnails/";
    new io.Directory(_tempDirectory).createSync(recursive: true);
    new io.Directory(_thumbnailsDirectory).createSync(recursive: true);
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

  Future<void> generateAndSaveKey(String passphrase) async {
    final key = CryptoUtil.getBase64EncodedSecureRandomString(length: 32);
    await _preferences.setString(keyKey, key);
  }

  // TODO: Encrypt with a passphrase and store in secure storage
  String getKey() {
    return "8qD++K3xkgjIl3dIsGiTze5PhYtxiS5AtOeZw+Bl1z0=";
    // return _preferences.getString(keyKey);
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
