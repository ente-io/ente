import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  static const endpointKey = "endpoint_7";
  static const tokenKey = "token";
  static const usernameKey = "username";
  static const passwordKey = "password";

  SharedPreferences preferences;

  Future<void> init() async {
    preferences = await SharedPreferences.getInstance();
  }

  String getEndpoint() {
    return preferences.getString(endpointKey);
  }

  String getHttpEndpoint() {
    return "http://" + getEndpoint() + ":8080";
  }

  void setEndpoint(String endpoint) async {
    await preferences.setString(endpointKey, endpoint);
  }

  String getToken() {
    return preferences.getString(tokenKey);
  }

  void setToken(String token) async {
    await preferences.setString(tokenKey, token);
  }

  String getUsername() {
    return preferences.getString(usernameKey);
  }

  void setUsername(String username) async {
    await preferences.setString(usernameKey, username);
  }

  String getPassword() {
    return preferences.getString(passwordKey);
  }

  void setPassword(String password) async {
    await preferences.setString(passwordKey, password);
  }
}
