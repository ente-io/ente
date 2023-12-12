import 'package:photos/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlbumSortKey {
  albumName,
  newestPhoto,
  lastUpdated,
}

class LocalSettings {
  LocalSettings._privateConstructor();

  static final LocalSettings instance = LocalSettings._privateConstructor();
  static const kCollectionSortPref = "collection_sort_pref";
  static const kPhotoGridSize = "photo_grid_size";
  static const kHideSharedItem = "hide_shared_item";
  static const kRateUsShownCount = "rate_us_shown_count";
  static const kRateUsPromptThreshold = 2;

  late SharedPreferences _prefs;

  void init(SharedPreferences preferences) {
    _prefs = preferences;
  }

  AlbumSortKey albumSortKey() {
    return AlbumSortKey.values[_prefs.getInt(kCollectionSortPref) ?? 0];
  }

  Future<bool> setAlbumSortKey(AlbumSortKey key) {
    return _prefs.setInt(kCollectionSortPref, key.index);
  }

  int getPhotoGridSize() {
    if (_prefs.containsKey(kPhotoGridSize)) {
      return _prefs.getInt(kPhotoGridSize)!;
    } else {
      return photoGridSizeDefault;
    }
  }

  bool getHideSharedItem() {
    if (_prefs.containsKey(kHideSharedItem)) {
      return _prefs.getBool(kHideSharedItem)!;
    } else {
      return false;
    }
  }

  Future<void> setPhotoGridSize(int value) async {
    await _prefs.setInt(kPhotoGridSize, value);
  }

  Future<void> setHideSharedItem(bool value) async {
    await _prefs.setBool(kHideSharedItem, value);
  }

  int getRateUsShownCount() {
    if (_prefs.containsKey(kRateUsShownCount)) {
      return _prefs.getInt(kRateUsShownCount)!;
    } else {
      return 0;
    }
  }

  Future<void> setRateUsShownCount(int value) async {
    await _prefs.setInt(kRateUsShownCount, value);
  }

  bool shouldPromptToRateUs() {
    return getRateUsShownCount() < kRateUsPromptThreshold;
  }
}
