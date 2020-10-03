import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final _favoritePhotoIdsKey = "favorite_photo_ids";
  FavoritesService._privateConstructor();
  static FavoritesService instance =
      FavoritesService._privateConstructor();

  SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  bool isLiked(File photo) {
    return getLiked().contains(photo.generatedID.toString());
  }

  bool hasFavorites() {
    return getLiked().isNotEmpty;
  }

  Future<bool> setLiked(File photo, bool isLiked) {
    final liked = getLiked();
    if (isLiked) {
      liked.add(photo.generatedID.toString());
    } else {
      liked.remove(photo.generatedID.toString());
    }
    Bus.instance.fire(LocalPhotosUpdatedEvent());
    return _preferences
        .setStringList(_favoritePhotoIdsKey, liked.toList())
        .then((_) => isLiked);
  }

  Set<String> getLiked() {
    final value = _preferences.getStringList(_favoritePhotoIdsKey);
    if (value == null) {
      return Set<String>();
    } else {
      return value.toSet();
    }
  }
}
