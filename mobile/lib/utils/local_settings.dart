import 'package:photos/core/constants.dart';
import "package:photos/utils/ram_check_util.dart";
import 'package:shared_preferences/shared_preferences.dart';

enum AlbumSortKey {
  albumName,
  newestPhoto,
  lastUpdated,
}

class LocalSettings {
  static const kCollectionSortPref = "collection_sort_pref";
  static const kPhotoGridSize = "photo_grid_size";
  static const _kisMLLocalIndexingEnabled = "ls.ml_local_indexing";
  static const kRateUsShownCount = "rate_us_shown_count";
  static const kEnableMultiplePart = "ls.enable_multiple_part";
  static const kRateUsPromptThreshold = 2;
  static const shouldLoopVideoKey = "video.should_loop";
  static const onGuestViewKey = "on_guest_view";

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

  bool get isMLLocalIndexingEnabled =>
      _prefs.getBool(_kisMLLocalIndexingEnabled) ?? enoughRamForLocalIndexing;

  bool get userEnabledMultiplePart =>
      _prefs.getBool(kEnableMultiplePart) ?? false;

  Future<bool> setUserEnabledMultiplePart(bool value) async {
    await _prefs.setBool(kEnableMultiplePart, value);
    return value;
  }

  /// toggleFaceIndexing toggles the face indexing setting and returns the new value
  Future<bool> toggleLocalMLIndexing() async {
    await _prefs.setBool(_kisMLLocalIndexingEnabled, !isMLLocalIndexingEnabled);
    return isMLLocalIndexingEnabled;
  }

  //#region todo:(NG) remove this section, only needed for internal testing to see
  // if the OS stops the app during indexing
  bool get remoteFetchEnabled => _prefs.getBool("remoteFetchEnabled") ?? true;
  Future<void> toggleRemoteFetch() async {
    await _prefs.setBool("remoteFetchEnabled", !remoteFetchEnabled);
  }
  //#endregion

  Future<void> setShouldLoopVideo(bool value) async {
    await _prefs.setBool(shouldLoopVideoKey, value);
  }

  bool shouldLoopVideo() {
    return _prefs.getBool(shouldLoopVideoKey) ?? true;
  }

  Future<void> setOnGuestView(bool value) {
    return _prefs.setBool(onGuestViewKey, value);
  }

  bool isOnGuestView() {
    return _prefs.getBool(onGuestViewKey) ?? false;
  }
}
