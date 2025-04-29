import 'dart:async';
import 'dart:convert';

import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import "package:photos/events/favorites_service_init_complete_event.dart";
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/api/collection/create_request.dart';
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';

class FavoritesService {
  late Configuration _config;

  late CollectionsService _collectionsService;
  late CollectionActions _collectionActions;
  late FilesDB _filesDB;
  int? _cachedFavoritesCollectionID;
  final Set<int> _cachedFavUploadedIDs = {};
  final Map<String, int> _cachedFavFileHases = {};
  final Set<String> _cachedPendingLocalIDs = {};
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;

  FavoritesService._privateConstructor();
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
    Bus.instance.fire(FavoritesServiceInitCompleteEvent());
  }

  void dispose() {
    _collectionUpdatesSubscription.cancel();
  }

  Future<void> _warmUpCache() async {
    final favCollection = await _getFavoritesCollection();
    if (favCollection != null) {
      Set<int> uploadedIDs;
      Map<String, int> fileHashes;
      (uploadedIDs, fileHashes) =
          await FilesDB.instance.getUploadAndHash(favCollection.id);
      _cachedFavUploadedIDs.addAll(uploadedIDs);
      _cachedFavFileHases.addAll(fileHashes);
    }
  }

  bool hasFavorites() {
    return _cachedFavUploadedIDs.isNotEmpty;
  }

  static FavoritesService instance = FavoritesService._privateConstructor();

  void clearCache() {
    _cachedFavoritesCollectionID = null;
  }

  bool isFavoriteCache(EnteFile file, {bool checkOnlyAlbum = false}) {
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
      if (file.ownerID != _config.getUserID() && file.hash != null) {
        return _cachedFavFileHases.containsKey(file.hash!);
      }
      return _cachedFavUploadedIDs.contains(file.uploadedFileID);
    } else if (file.localID != null) {
      return _cachedPendingLocalIDs.contains(file.localID);
    }
    return false;
  }

  Future<bool> isFavorite(EnteFile file) async {
    final collection = await _getFavoritesCollection();
    if (collection == null || file.uploadedFileID == null) {
      return false;
    }
    if (file.ownerID != _config.getUserID() && file.hash != null) {
      return _cachedFavFileHases.containsKey(file.hash!);
    }
    return _filesDB.doesFileExistInCollection(
      file.uploadedFileID!,
      collection.id,
    );
  }

  void _updateFavoriteFilesCache(
    List<EnteFile> files, {
    required bool favFlag,
  }) {
    final Set<int> updatedIDs = {};
    final Map<String, int> hashes = {};
    final Set<String> localIDs = {};
    for (var file in files) {
      if (file.uploadedFileID != null) {
        updatedIDs.add(file.uploadedFileID!);
        if (file.hash != null) {
          hashes[file.hash!] = file.uploadedFileID!;
        }
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
      _cachedFavFileHases.addAll(hashes);
    } else {
      _cachedFavUploadedIDs.removeAll(updatedIDs);
      for (var hash in hashes.keys) {
        _cachedFavFileHases.remove(hash);
      }
    }
  }

  Future<void> addToFavorites(BuildContext context, EnteFile file) async {
    final collectionID = await _getOrCreateFavoriteCollectionID();
    final List<EnteFile> files = [file];
    if (file.uploadedFileID == null) {
      throw AssertionError("Can only favorite uploaded items");
    } else {
      await _collectionsService.addOrCopyToCollection(collectionID, files);
    }
    _updateFavoriteFilesCache(files, favFlag: true);
    RemoteSyncService.instance.sync(silently: true).ignore();
  }

  Future<void> updateFavorites(
    BuildContext context,
    List<EnteFile> files,
    bool favFlag,
  ) async {
    final int currentUserID = Configuration.instance.getUserID()!;
    if (files.any((f) => f.uploadedFileID == null)) {
      throw AssertionError("Can only favorite uploaded items");
    }
    if (files.any((f) => f.ownerID != currentUserID)) {
      throw AssertionError("Can not favorite files owned by others");
    }
    final collectionID = await _getOrCreateFavoriteCollectionID();
    if (favFlag) {
      await _collectionsService.addOrCopyToCollection(collectionID, files);
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

  Future<void> removeFromFavorites(
    BuildContext context,
    EnteFile file,
  ) async {
    final inUploadID = file.uploadedFileID;
    if (inUploadID == null) {
      // Do nothing, ignore
    } else {
      final Collection? favCollection = await _getFavoritesCollection();
      // The file might be part of another collection. For unfav, we need to
      // move file from the fav collection to the .
      if (file.ownerID != _config.getUserID() &&
          _cachedFavFileHases.containsKey(file.hash!)) {
        final EnteFile? favFile = await FilesDB.instance.getUploadedFile(
          _cachedFavFileHases[file.hash!]!,
          favCollection!.id,
        );
        if (favFile != null) {
          file = favFile;
        }
      }
      if (file.collectionID != favCollection!.id) {
        final EnteFile? favFile = await FilesDB.instance.getUploadedFile(
          file.uploadedFileID!,
          favCollection.id,
        );
        if (favFile != null) {
          file = favFile;
        }
      }
      await _collectionActions.moveFilesFromCurrentCollection(
        context,
        favCollection,
        [file],
      );
    }
    _updateFavoriteFilesCache([file], favFlag: false);
  }

  Future<Collection?> _getFavoritesCollection() async {
    if (_cachedFavoritesCollectionID == null) {
      final collections = _collectionsService.getActiveCollections();
      for (final collection in collections) {
        if (collection.owner.id == _config.getUserID() &&
            collection.type == CollectionType.favorites) {
          _cachedFavoritesCollectionID = collection.id;
          return collection;
        }
      }
      return null;
    }
    return _collectionsService.getCollectionByID(_cachedFavoritesCollectionID!);
  }

  Future<int?> getFavoriteCollectionID() async {
    final collection = await _getFavoritesCollection();
    return collection?.id;
  }

  Future<int> _getOrCreateFavoriteCollectionID() async {
    if (_cachedFavoritesCollectionID != null) {
      return _cachedFavoritesCollectionID!;
    }
    final favoriteCollectionKey = CryptoUtil.generateKey();
    final encryptedKeyResult =
        CryptoUtil.encryptSync(favoriteCollectionKey, _config.getKey()!);
    final encName = CryptoUtil.encryptSync(
      utf8.encode("Favorites"),
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
