import 'package:photos/models/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePhotosRepository {
  static final _favoritePhotoIdsKey = "favorite_photo_ids";
  FavoritePhotosRepository._privateConstructor();
  static FavoritePhotosRepository instance =
      FavoritePhotosRepository._privateConstructor();

  SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  bool isLiked(Photo photo) {
    return _getLiked().contains(photo.generatedId.toString());
  }

  Future<bool> setLiked(Photo photo, bool isLiked) {
    final liked = _getLiked();
    if (isLiked) {
      liked.add(photo.generatedId.toString());
    } else {
      liked.remove(photo.generatedId.toString());
    }
    return _preferences
        .setStringList(_favoritePhotoIdsKey, liked.toList())
        .then((_) => isLiked);
  }

  Set<String> _getLiked() {
    final value = _preferences.getStringList(_favoritePhotoIdsKey);
    if (value == null) {
      return Set<String>();
    } else {
      return value.toSet();
    }
  }
}
