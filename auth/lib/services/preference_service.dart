import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/icons_changed_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CodeSortKey {
  issuerName,
  accountName,
  mostFrequentlyUsed,
  recentlyUsed,
  manual,
}

class PreferenceService {
  PreferenceService._privateConstructor();
  static final PreferenceService instance =
      PreferenceService._privateConstructor();

  late final SharedPreferences _prefs;

  static const kHasShownCoachMarkKey = "has_shown_coach_mark_v2";
  static const kShouldShowLargeIconsKey = "should_show_large_icons";
  static const kShouldHideCodesKey = "should_hide_codes";
  static const kShouldAutoFocusOnSearchBar = "should_auto_focus_on_search_bar";
  static const kShouldMinimizeOnCopy = "should_minimize_on_copy";
  static const kCompactMode = "vi.compactMode";
  static const kAppInstallTime = "appInstallTime";

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

  CodeSortKey codeSortKey() {
    return CodeSortKey
        .values[_prefs.getInt("codeSortKey") ?? CodeSortKey.issuerName.index];
  }

  Future<void> setCodeSortKey(CodeSortKey key) async {
    await _prefs.setInt("codeSortKey", key.index);
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

  Future<void> setShowLargeIcons(bool value) async {
    await _prefs.setBool(kShouldShowLargeIconsKey, value);
    Bus.instance.fire(IconsChangedEvent());
  }

  bool shouldHideCodes() {
    return _prefs.getBool(kShouldHideCodesKey) ?? false;
  }

  bool isCompactMode() {
    return _prefs.getBool(kCompactMode) ?? false;
  }

  Future<void> setCompactMode(bool value) async {
    await _prefs.setBool(kCompactMode, value);
  }

  Future<void> setHideCodes(bool value) async {
    await _prefs.setBool(kShouldHideCodesKey, value);
    Bus.instance.fire(IconsChangedEvent());
  }

  bool shouldAutoFocusOnSearchBar() {
    if (_prefs.containsKey(kShouldAutoFocusOnSearchBar)) {
      return _prefs.getBool(kShouldAutoFocusOnSearchBar)!;
    } else {
      return false;
    }
  }

  Future<void> setAutoFocusOnSearchBar(bool value) async {
    await _prefs.setBool(kShouldAutoFocusOnSearchBar, value);
    Bus.instance.fire(IconsChangedEvent());
  }

  bool shouldMinimizeOnCopy() {
    if (_prefs.containsKey(kShouldMinimizeOnCopy)) {
      return _prefs.getBool(kShouldMinimizeOnCopy)!;
    } else {
      return false;
    }
  }

  Future<void> setShouldMinimizeOnCopy(bool value) async {
    await _prefs.setBool(kShouldMinimizeOnCopy, value);
  }

  int getAppInstalledTime() {
    if (_prefs.containsKey(kAppInstallTime)) {
      return _prefs.getInt(kAppInstallTime)!;
    } else {
      int installedTimeinMillis = DateTime.now().millisecondsSinceEpoch;
      _prefs.setInt(kAppInstallTime, installedTimeinMillis).ignore();
      return installedTimeinMillis;
    }
  }
}
