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
  static const kEnableMagicSearch = "enable_magic_search";
  static const kEnableFaceIndexing = "enable_face_indexing";
  static const kEnableFaceClustering = "enable_face_clustering";
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

  Future<void> setPhotoGridSize(int value) async {
    await _prefs.setInt(kPhotoGridSize, value);
  }

  bool hasEnabledMagicSearch() {
    // TODO: change this back by uncommenting the line below
    // if (_prefs.containsKey(kEnableMagicSearch)) {
    //   return _prefs.getBool(kEnableMagicSearch)!;
    // }
    return false;
  }

  Future<void> setShouldEnableMagicSearch(bool value) async {
    await _prefs.setBool(kEnableMagicSearch, value);
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

  bool get isFaceIndexingEnabled =>
      _prefs.getBool(kEnableFaceIndexing) ?? false;

  bool get isFaceClusteringEnabled =>
      _prefs.getBool(kEnableFaceIndexing) ?? false;

  /// toggleFaceIndexing toggles the face indexing setting and returns the new value
  Future<bool> toggleFaceIndexing() async {
    await _prefs.setBool(kEnableFaceIndexing, !isFaceIndexingEnabled);
    return isFaceIndexingEnabled;
  }

  /// toggleFaceClustering toggles the face clustering setting and returns the new value
  Future<bool> toggleFaceClustering() async {
    await _prefs.setBool(kEnableFaceClustering, !isFaceClusteringEnabled);
    return isFaceClusteringEnabled;
  }
}
