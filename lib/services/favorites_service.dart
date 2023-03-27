import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/api/collection/create_request.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/utils/crypto_util.dart';

class FavoritesService {
  late Configuration _config;

  late CollectionsService _collectionsService;
  late CollectionActions _collectionActions;
  late FilesDB _filesDB;
  int? _cachedFavoritesCollectionID;
  final Set<int> _cachedFavUploadedIDs = {};
  final Set<String> _cachedPendingLocalIDs = {};
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;

  FavoritesService._privateConstructor() {}
  Future<void> initFav() async {
    _config = Configuration.instance;
    _collectionsService = CollectionsService.instance;
    _collectionActions = CollectionActions(_collectionsService);
    _filesDB = FilesDB.instance;
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      if (event.collectionID != null &&
          _cachedFavoritesCollectionID != null &&
          _cachedFavoritesCollectionID == event.collectionID) {
        if (event.type == EventType.addedOrUpdated) {
          // Note: This source check is a ugly hack because currently we
          // don't have any event type related to remove from collection
          final bool isAdded = !event.source.contains("remove");
          _updateFavoriteFilesCache(event.updatedFiles, favFlag: isAdded);
        } else if (event.type == EventType.deletedFromEverywhere ||
            event.type == EventType.deletedFromRemote) {
          _updateFavoriteFilesCache(event.updatedFiles, favFlag: false);
        }
      }
    });
    await _warmUpCache();
  }

  void dispose() {
    _collectionUpdatesSubscription.cancel();
  }

  Future<void> _warmUpCache() async {
    final favCollection = await _getFavoritesCollection();
    if (favCollection != null) {
      final uploadedIDs =
          await FilesDB.instance.getUploadedFileIDs(favCollection.id);
      _cachedFavUploadedIDs.addAll(uploadedIDs);
    }
  }

  static FavoritesService instance = FavoritesService._privateConstructor();

  void clearCache() {
    _cachedFavoritesCollectionID = null;
  }

  bool isFavoriteCache(File file, {bool checkOnlyAlbum = false}) {
    if (file.collectionID != null &&
        _cachedFavoritesCollectionID != null &&
        file.collectionID == _cachedFavoritesCollectionID) {
      debugPrint("File ${file.uploadedFileID} is part of favorite collection");
      return true;
    }
    if (checkOnlyAlbum) {
      return false;
    }
    if (file.uploadedFileID != null) {
      return _cachedFavUploadedIDs.contains(file.uploadedFileID);
    } else if (file.localID != null) {
      return _cachedPendingLocalIDs.contains(file.localID);
    }
    return false;
  }

  Future<bool> isFavorite(File file) async {
    final collection = await _getFavoritesCollection();
    if (collection == null || file.uploadedFileID == null) {
      return false;
    }
    return _filesDB.doesFileExistInCollection(
      file.uploadedFileID!,
      collection.id,
    );
  }

  void _updateFavoriteFilesCache(List<File> files, {required bool favFlag}) {
    final Set<int> updatedIDs = {};
    final Set<String> localIDs = {};
    for (var file in files) {
      if (file.uploadedFileID != null) {
        updatedIDs.add(file.uploadedFileID!);
      } else if (file.localID != null || file.localID != "") {
        /* Note: Favorite un-uploaded files
        For such files, as we don't have uploaded IDs yet, we will cache
        cache the local ID for showing the fav icon in the gallery
         */
        localIDs.add(file.localID!);
      }
    }
    if (favFlag) {
      _cachedFavUploadedIDs.addAll(updatedIDs);
    } else {
      _cachedFavUploadedIDs.removeAll(updatedIDs);
    }
  }

  Future<void> addToFavorites(BuildContext context, File file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    final List<File> files = [file];
    if (file.uploadedFileID == null) {
      file.collectionID = collectionID;
      await _filesDB.insert(file);
      Bus.instance.fire(CollectionUpdatedEvent(collectionID, files, "addTFav"));
    } else {
      await _collectionsService.addToCollection(collectionID, files);
    }
    _updateFavoriteFilesCache(files, favFlag: true);
    RemoteSyncService.instance.sync(silently: true).ignore();
  }

  Future<void> updateFavorites(
    BuildContext context,
    List<File> files,
    bool favFlag,
  ) async {
    final int currentUserID = Configuration.instance.getUserID()!;
    if (files.any((f) => f.uploadedFileID == null)) {
      throw AssertionError("Can only favorite uploaded items");
    }
    if (files.any((f) => f.ownerID != currentUserID)) {
      throw AssertionError("Can not favortie files owned by others");
    }
    final collectionID = await _getOrCreateFavoriteCollectionID();
    if (favFlag) {
      await _collectionsService.addToCollection(collectionID, files);
    } else {
      final Collection? favCollection = await _getFavoritesCollection();
      await _collectionActions.moveFilesFromCurrentCollection(
        context,
        favCollection!,
        files,
      );
    }
    _updateFavoriteFilesCache(files, favFlag: favFlag);
  }

  Future<void> removeFromFavorites(BuildContext context, File file) async {
    final fileID = file.uploadedFileID;
    if (fileID == null) {
      // Do nothing, ignore
    } else {
      final Collection? favCollection = await _getFavoritesCollection();
      await _collectionActions.moveFilesFromCurrentCollection(
        context,
        favCollection!,
        [file],
      );
    }
    _updateFavoriteFilesCache([file], favFlag: false);
  }

  Future<Collection?> _getFavoritesCollection() async {
    if (_cachedFavoritesCollectionID == null) {
      final collections = _collectionsService.getActiveCollections();
      for (final collection in collections) {
        if (collection.owner!.id == _config.getUserID() &&
            collection.type == CollectionType.favorites) {
          _cachedFavoritesCollectionID = collection.id;
          return collection;
        }
      }
      return null;
    }
    return _collectionsService.getCollectionByID(_cachedFavoritesCollectionID!);
  }

  Future<int> _getOrCreateFavoriteCollectionID() async {
    if (_cachedFavoritesCollectionID != null) {
      return _cachedFavoritesCollectionID!;
    }
    final favoriteCollectionKey = CryptoUtil.generateKey();
    final encryptedKeyResult =
        CryptoUtil.encryptSync(favoriteCollectionKey, _config.getKey()!);
    final encName = CryptoUtil.encryptSync(
      utf8.encode("Favorites") as Uint8List,
      favoriteCollectionKey,
    );
    final collection = await _collectionsService.createAndCacheCollection(
      CreateRequest(
        encryptedKey: CryptoUtil.bin2base64(encryptedKeyResult.encryptedData!),
        keyDecryptionNonce: CryptoUtil.bin2base64(encryptedKeyResult.nonce!),
        encryptedName: CryptoUtil.bin2base64(encName.encryptedData!),
        nameDecryptionNonce: CryptoUtil.bin2base64(encName.nonce!),
        type: CollectionType.favorites,
        attributes: CollectionAttributes(),
      ),
    );
    _cachedFavoritesCollectionID = collection.id;
    return collection.id;
  }
}
