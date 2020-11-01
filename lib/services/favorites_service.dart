import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_uploader.dart';

class FavoritesService {
  Configuration _config;
  CollectionsService _collectionsService;
  FileUploader _fileUploader;
  FilesDB _filesDB;
  int _cachedFavoritesCollectionID;

  FavoritesService._privateConstructor() {
    _config = Configuration.instance;
    _collectionsService = CollectionsService.instance;
    _fileUploader = FileUploader.instance;
    _filesDB = FilesDB.instance;
  }
  static FavoritesService instance = FavoritesService._privateConstructor();

  Future<bool> isFavorite(File file) async {
    final collection = await _getFavoritesCollection();
    if (collection == null) {
      return false;
    }
    return _filesDB.doesFileExistInCollection(
        file.uploadedFileID, collection.id);
  }

  Future<void> addToFavorites(File file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    if (file.uploadedFileID == null) {
      file.collectionID = collectionID;
      final uploadedFile = (await _fileUploader.encryptAndUploadFile(file));
      await _filesDB.update(uploadedFile);
    } else {
      await _collectionsService.addToCollection(collectionID, [file]);
    }
  }

  Future<void> removeFromFavorites(File file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    var fileID = file.uploadedFileID;
    if (fileID == null) {
      // Do nothing, ignore
    } else {
      await _collectionsService.removeFromCollection(collectionID, [file]);
    }
  }

  Future<Collection> _getFavoritesCollection() async {
    if (_cachedFavoritesCollectionID == null) {
      final collections = _collectionsService.getCollections();
      for (final collection in collections) {
        if (collection.type == CollectionType.favorites) {
          _cachedFavoritesCollectionID = collection.id;
          return collection;
        }
      }
      return null;
    }
    return _collectionsService.getCollectionByID(_cachedFavoritesCollectionID);
  }

  Future<int> _getOrCreateFavoriteCollectionID() async {
    if (_cachedFavoritesCollectionID != null) {
      return _cachedFavoritesCollectionID;
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
    _cachedFavoritesCollectionID = collection.id;
    return collection.id;
  }
}
