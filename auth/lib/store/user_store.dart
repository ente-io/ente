import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  UserStore._privateConstructor();

  // ignore: unused_field
  late SharedPreferences _preferences;

  static final UserStore instance = UserStore._privateConstructor();

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
}
