import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final _favoritePhotoIdsKey = "favorite_photo_ids";
  static final _favoritesCollectionIDKey = "favorites_collection_id";

  Configuration _config;
  CollectionsService _collectionsService;
  FileUploader _fileUploader;

  FavoritesService._privateConstructor() {
    _config = Configuration.instance;
    _collectionsService = CollectionsService.instance;
    _fileUploader = FileUploader.instance;
  }
  static FavoritesService instance = FavoritesService._privateConstructor();

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

  Future<void> addToFavorites(File file) async {
    final collectionID = await getOrCreateFavoriteCollectionID();
    var fileID = file.uploadedFileID;
    if (fileID == null) {
      file.collectionID = collectionID;
      fileID = (await _fileUploader.encryptAndUploadFile(file)).uploadedFileID;
    }
    return _collectionsService.addToCollection(collectionID, [file]);
  }

  Future<int> getOrCreateFavoriteCollectionID() async {
    if (_preferences.containsKey(_favoritesCollectionIDKey)) {
      return _preferences.getInt(_favoritesCollectionIDKey);
    }
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final collection =
        await _collectionsService.createAndCacheCollection(Collection(
      null,
      null,
      Sodium.bin2base64(encryptedKeyData.encryptedData),
      Sodium.bin2base64(encryptedKeyData.nonce),
      "Favorites",
      CollectionType.favorites,
      CollectionAttributes(),
      null,
    ));
    await _preferences.setInt(_favoritesCollectionIDKey, collection.id);
    return collection.id;
  }
}
