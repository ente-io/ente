import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  UserStore._privateConstructor();

  late SharedPreferences _preferences;

  static final UserStore instance = UserStore._privateConstructor();
  static const endpoint = String.fromEnvironment(
    "endpoint",
    defaultValue: "https://api.ente.io",
  );

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
}
