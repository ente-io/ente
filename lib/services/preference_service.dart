import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  PreferenceService._privateConstructor();
  static final PreferenceService instance =
      PreferenceService._privateConstructor();

  late final SharedPreferences _prefs;

  static const kHasShownCoachMarkKey = "has_shown_coach_mark";
  static const kShouldShowLargeIconsKey = "should_show_large_icons";

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

  bool shouldShowLargeIcons() {
    if (_prefs.containsKey(kShouldShowLargeIconsKey)) {
      return _prefs.getBool(kShouldShowLargeIconsKey)!;
    } else {
      return false;
    }
  }

  Future<void> setShowLargeIcons(bool value) {
    return _prefs.setBool(kShouldShowLargeIconsKey, value);
  }
}
