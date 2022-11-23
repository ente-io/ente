import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  PreferenceService._privateConstructor();
  static final PreferenceService instance =
      PreferenceService._privateConstructor();

  late final SharedPreferences _prefs;

  static const kHasShownCoachMarkKey = "has_shown_coach_mark";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool hasShownCoachMark() {
    if (_prefs.containsKey(kHasShownCoachMarkKey)) {
      return _prefs.getBool(kHasShownCoachMarkKey)!;
    } else {
      return false;
    }
  }

  Future<void> setHasShownCoachMark(bool value) {
    return _prefs.setBool(kHasShownCoachMarkKey, value);
  }
}
