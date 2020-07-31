import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  static const _endpointKey = "endpoint_7";
  static const _tokenKey = "token";
  static const _usernameKey = "username";
  static const _userIDKey = "user_id";
  static const _passwordKey = "password";

  SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  String getEndpoint() {
    return _preferences.getString(_endpointKey);
  }

  String getHttpEndpoint() {
    if (getEndpoint() == null) {
      return "";
    }
    return "http://" + getEndpoint() + ":8080";
  }

  void setEndpoint(String endpoint) async {
    await _preferences.setString(_endpointKey, endpoint);
  }

  String getToken() {
    return _preferences.getString(_tokenKey);
  }

  void setToken(String token) async {
    await _preferences.setString(_tokenKey, token);
  }

  String getUsername() {
    return _preferences.getString(_usernameKey);
  }

  void setUsername(String username) async {
    await _preferences.setString(_usernameKey, username);
  }

  int getUserID() {
    return _preferences.getInt(_userIDKey);
  }

  void setUserID(int userID) async {
    await _preferences.setInt(_userIDKey, userID);
  }

  String getPassword() {
    return _preferences.getString(_passwordKey);
  }

  void setPassword(String password) async {
    await _preferences.setString(_passwordKey, password);
  }

  bool hasConfiguredAccount() {
    return getEndpoint() != null && getToken() != null;
  }
}
