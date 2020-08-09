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
  static const keyKey = "key";

  SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
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

  void generateAndSaveKey(String passphrase) async {
    final key = CryptoUtil.createCryptoRandomString();
    await _preferences.setString(keyKey, CryptoUtil.encrypt(key, passphrase));
  }

  String getKey(String passphrase) {
    return CryptoUtil.decrypt(_preferences.getString(keyKey), passphrase);
  }

  bool hasConfiguredAccount() {
    return getEndpoint() != null && getToken() != null;
  }
}
