import 'package:shared_preferences/shared_preferences.dart';

enum AlbumSortKey {
  albumName,
  lastUpdated,
  recentPhoto,
}

class LocalSettings {
  LocalSettings._privateConstructor();

  static final LocalSettings instance = LocalSettings._privateConstructor();
  static const kCollectionSortPref = "collection_sort_pref";
  SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AlbumSortKey albumSortKey() {
    return AlbumSortKey.values[_prefs?.getInt(kCollectionSortPref) ?? 0] ??
        AlbumSortKey.lastUpdated;
  }

  void setAlbumSortKey(AlbumSortKey key) {
    _prefs?.setInt(kCollectionSortPref, key.index);
  }
}
