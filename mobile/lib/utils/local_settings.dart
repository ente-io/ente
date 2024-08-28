import 'package:photos/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlbumSortKey {
  albumName,
  newestPhoto,
  lastUpdated,
}

class LocalSettings {
  static const kCollectionSortPref = "collection_sort_pref";
  static const kPhotoGridSize = "photo_grid_size";
  static const _kisMLIndexingEnabled = "ls.enable_ml_idx";
  static const kRateUsShownCount = "rate_us_shown_count";
  static const kEnableMultiplePart = "ls.enable_multiple_part";
  static const kRateUsPromptThreshold = 2;

  final SharedPreferences _prefs;

  LocalSettings(this._prefs);

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

  Future<void> setPhotoGridSize(int value) async {
    await _prefs.setInt(kPhotoGridSize, value);
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

  //  remove `enable_face_indexing`fallback after sometime, affects internal users only
  bool get isMLIndexingEnabled =>
      _prefs.getBool(_kisMLIndexingEnabled) ??
      _prefs.getBool('enable_face_indexing') ??
      false;

  bool get userEnabledMultiplePart =>
      _prefs.getBool(kEnableMultiplePart) ?? false;

  Future<bool> setUserEnabledMultiplePart(bool value) async {
    await _prefs.setBool(kEnableMultiplePart, value);
    return value;
  }

  /// toggleFaceIndexing toggles the face indexing setting and returns the new value
  Future<bool> toggleMLIndexing() async {
    await _prefs.setBool(_kisMLIndexingEnabled, !isMLIndexingEnabled);
    return isMLIndexingEnabled;
  }

  //#region todo:(NG) remove this section, only needed for internal testing to see
  // if the OS stops the app during indexing
  bool get remoteFetchEnabled => _prefs.getBool("remoteFetchEnabled") ?? true;
  Future<void> toggleRemoteFetch() async {
    await _prefs.setBool("remoteFetchEnabled", !remoteFetchEnabled);
  }
  //#endregion
}
