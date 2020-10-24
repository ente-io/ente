import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final _favoritesCollectionIDKey = "favorites_collection_id";

  final _cachedFavoriteFiles = Set<File>();
  Configuration _config;
  CollectionsService _collectionsService;
  FileUploader _fileUploader;
  FilesDB _filesDB;

  FavoritesService._privateConstructor() {
    _config = Configuration.instance;
    _collectionsService = CollectionsService.instance;
    _fileUploader = FileUploader.instance;
    _filesDB = FilesDB.instance;
  }
  static FavoritesService instance = FavoritesService._privateConstructor();

  SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    if (_preferences.containsKey(_favoritesCollectionIDKey)) {
      final collectionID = _preferences.getInt(_favoritesCollectionIDKey);
      _cachedFavoriteFiles
          .addAll((await _filesDB.getAllInCollection(collectionID)).toSet());
    }
  }

  Set<File> getFavoriteFiles() {
    return _cachedFavoriteFiles;
  }

  bool isLiked(File file) {
    return _cachedFavoriteFiles.contains(file);
  }

  Future<void> addToFavorites(File file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    var fileID = file.uploadedFileID;
    if (fileID == null) {
      file.collectionID = collectionID;
      fileID = (await _fileUploader.encryptAndUploadFile(file)).uploadedFileID;
      await _filesDB.update(
        file.generatedID,
        file.uploadedFileID,
        file.ownerID,
        file.collectionID,
        file.updationTime,
        file.encryptedKey,
        file.keyDecryptionNonce,
        file.fileDecryptionHeader,
        file.thumbnailDecryptionHeader,
        file.metadataDecryptionHeader,
      );
    } else {
      await _collectionsService.addToCollection(collectionID, [file]);
      _cachedFavoriteFiles.add(file);
      Bus.instance.fire(LocalPhotosUpdatedEvent());
    }
  }

  Future<void> removeFromFavorites(File file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    var fileID = file.uploadedFileID;
    if (fileID == null) {
      // Do nothing, ignore
    } else {
      await _collectionsService.removeFromCollection(collectionID, [file]);
      _cachedFavoriteFiles.remove(file);
      Bus.instance.fire(LocalPhotosUpdatedEvent());
    }
  }

  Collection getFavoritesCollection() {
    if (!_preferences.containsKey(_favoritesCollectionIDKey)) {
      return null;
    }
    return _collectionsService
        .getOwnedCollectionByID(_preferences.getInt(_favoritesCollectionIDKey));
  }

  Future<int> _getOrCreateFavoriteCollectionID() async {
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
