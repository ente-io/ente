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
  static const keyAlbumGridSize = "album_grid_size";

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

  int getAlbumGridSize() {
    if (_prefs.containsKey(keyAlbumGridSize)) {
      return _prefs.getInt(keyAlbumGridSize)!;
    } else {
      return defaultAlbumGridSize;
    }
  }

  Future<void> setAlbumGridSize(int value) async {
    await _prefs.setInt(keyAlbumGridSize, value);
  }
}
