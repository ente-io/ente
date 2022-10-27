// @dart=2.9

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/api/collection/create_request.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_file_item.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionsService {
  static const _collectionSyncTimeKeyPrefix = "collection_sync_time_";
  static const _collectionsSyncTimeKey = "collections_sync_time_x";

  static const int kMaximumWriteAttempts = 5;

  final _logger = Logger("CollectionsService");

  CollectionsDB _db;
  FilesDB _filesDB;
  Configuration _config;
  SharedPreferences _prefs;
  Future<List<File>> _cachedLatestFiles;
  final _enteDio = Network.instance.enteDio;
  final _localPathToCollectionID = <String, int>{};
  final _collectionIDToCollections = <int, Collection>{};
  final _cachedKeys = <int, Uint8List>{};
  Collection cachedDefaultHiddenCollection;

  CollectionsService._privateConstructor() {
    _db = CollectionsDB.instance;
    _filesDB = FilesDB.instance;
    _config = Configuration.instance;
  }

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final collections = await _db.getAllCollections();

    for (final collection in collections) {
      _cacheCollectionAttributes(collection);
    }
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _cachedLatestFiles = null;
      getLatestCollectionFiles();
    });
    Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _cachedLatestFiles = null;
      getLatestCollectionFiles();
    });
  }

  @protected
  Configuration get config => _config;

  @protected
  Map<int, Collection> get collectionIDToCollections =>
      _collectionIDToCollections;

  @protected
  FilesDB get filesDB => _filesDB;

  // sync method fetches just sync the collections, not the individual files
  // within the collection.
  Future<List<Collection>> sync() async {
    _logger.info("Syncing collections");
    final lastCollectionUpdationTime =
        _prefs.getInt(_collectionsSyncTimeKey) ?? 0;

    // Might not have synced the collection fully
    final fetchedCollections =
        await _fetchCollections(lastCollectionUpdationTime);
    final updatedCollections = <Collection>[];
    int maxUpdationTime = lastCollectionUpdationTime;
    final ownerID = _config.getUserID();
    for (final collection in fetchedCollections) {
      if (collection.isDeleted) {
        await _filesDB.deleteCollection(collection.id);
        await setCollectionSyncTime(collection.id, null);
        Bus.instance.fire(LocalPhotosUpdatedEvent(List<File>.empty()));
      }
      // remove reference for incoming collections when unshared/deleted
      if (collection.isDeleted && ownerID != collection?.owner?.id) {
        await _db.deleteCollection(collection.id);
      } else {
        // keep entry for deletedCollection as collectionKey may be used during
        // trash file decryption
        updatedCollections.add(collection);
      }
      maxUpdationTime = collection.updationTime > maxUpdationTime
          ? collection.updationTime
          : maxUpdationTime;
    }
    await _updateDB(updatedCollections);
    _prefs.setInt(_collectionsSyncTimeKey, maxUpdationTime);
    final collections = await _db.getAllCollections();
    for (final collection in collections) {
      _cacheCollectionAttributes(collection);
    }
    if (fetchedCollections.isNotEmpty) {
      _logger.info("Collections updated");
      Bus.instance.fire(CollectionUpdatedEvent(null, List<File>.empty()));
    }
    return collections;
  }

  void clearCache() {
    _localPathToCollectionID.clear();
    _collectionIDToCollections.clear();
    _cachedKeys.clear();
  }

  Future<List<Collection>> getCollectionsToBeSynced() async {
    final collections = await _db.getAllCollections();
    final updatedCollections = <Collection>[];
    for (final c in collections) {
      if (c.updationTime > getCollectionSyncTime(c.id) && !c.isDeleted) {
        updatedCollections.add(c);
      }
    }
    return updatedCollections;
  }

  Set<int> getArchivedCollections() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => element.isArchived())
        .map((e) => e.id)
        .toSet();
  }

  Set<int> getHiddenCollections() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => element.isHidden())
        .map((e) => e.id)
        .toSet();
  }

  Set<int> collectionsHiddenFromTimeline() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => element.isHidden() || element.isArchived())
        .map((e) => e.id)
        .toSet();
  }

  int getCollectionSyncTime(int collectionID) {
    return _prefs
            .getInt(_collectionSyncTimeKeyPrefix + collectionID.toString()) ??
        0;
  }

  Future<List<File>> getLatestCollectionFiles() {
    _cachedLatestFiles ??= _filesDB.getLatestCollectionFiles();
    return _cachedLatestFiles;
  }

  Future<void> setCollectionSyncTime(int collectionID, int time) async {
    final key = _collectionSyncTimeKeyPrefix + collectionID.toString();
    if (time == null) {
      return _prefs.remove(key);
    }
    return _prefs.setInt(key, time);
  }

  // getActiveCollections returns list of collections which are not deleted yet
  List<Collection> getActiveCollections() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => !element.isDeleted)
        .toList();
  }

  Future<List<User>> getSharees(int collectionID) {
    return _enteDio.get(
      "/collections/sharees",
      queryParameters: {
        "collectionID": collectionID,
      },
    ).then((response) {
      _logger.info(response.toString());
      final sharees = <User>[];
      for (final user in response.data["sharees"]) {
        sharees.add(User.fromMap(user));
      }
      return sharees;
    });
  }

  Future<void> share(int collectionID, String email, String publicKey) async {
    final encryptedKey = CryptoUtil.sealSync(
      getCollectionKey(collectionID),
      Sodium.base642bin(publicKey),
    );
    try {
      await _enteDio.post(
        "/collections/share",
        data: {
          "collectionID": collectionID,
          "email": email,
          "encryptedKey": Sodium.bin2base64(encryptedKey),
        },
      );
    } on DioError catch (e) {
      if (e.response.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    }
    RemoteSyncService.instance.sync(silently: true);
  }

  Future<void> unshare(int collectionID, String email) async {
    try {
      await _enteDio.post(
        "/collections/unshare",
        data: {
          "collectionID": collectionID,
          "email": email,
        },
      );
      _collectionIDToCollections[collectionID]
          .sharees
          .removeWhere((user) => user.email == email);
      _db.insert([_collectionIDToCollections[collectionID]]);
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
    RemoteSyncService.instance.sync(silently: true);
  }

  Future<void> trashCollection(Collection collection) async {
    try {
      final deviceCollections = await _filesDB.getDeviceCollections();
      final Map<String, bool> deivcePathIDsToUnsync = Map.fromEntries(
        deviceCollections
            .where((e) => e.shouldBackup && e.collectionID == collection.id)
            .map((e) => MapEntry(e.id, false)),
      );

      if (deivcePathIDsToUnsync.isNotEmpty) {
        _logger.info(
          'turning off backup status for folders $deivcePathIDsToUnsync',
        );
        await RemoteSyncService.instance
            .updateDeviceFolderSyncStatus(deivcePathIDsToUnsync);
      }
      await _enteDio.delete(
        "/collections/v2/${collection.id}",
      );
      await _filesDB.deleteCollection(collection.id);
      final deletedCollection = collection.copyWith(isDeleted: true);
      _collectionIDToCollections[collection.id] = deletedCollection;
      _db.insert([deletedCollection]);
      unawaited(LocalSyncService.instance.syncAll());
    } catch (e) {
      _logger.severe('failed to trash collection', e);
      rethrow;
    }
  }

  Uint8List getCollectionKey(int collectionID) {
    if (!_cachedKeys.containsKey(collectionID)) {
      final collection = _collectionIDToCollections[collectionID];
      if (collection == null) {
        // Async fetch for collection. A collection might be
        // missing from older clients when we used to delete the collection
        // from db. For trashed files, we need collection data for decryption.
        fetchCollectionByID(collectionID);
        throw AssertionError('collectionID $collectionID is not cached');
      }
      _cachedKeys[collectionID] = _getDecryptedKey(collection);
    }
    return _cachedKeys[collectionID];
  }

  Uint8List _getDecryptedKey(Collection collection) {
    debugPrint("Finding collection decryption key for ${collection.id}");
    final encryptedKey = Sodium.base642bin(collection.encryptedKey);
    if (collection.owner.id == _config.getUserID()) {
      if (_config.getKey() == null) {
        throw Exception("key can not be null");
      }
      return CryptoUtil.decryptSync(
        encryptedKey,
        _config.getKey(),
        Sodium.base642bin(collection.keyDecryptionNonce),
      );
    } else {
      return CryptoUtil.openSealSync(
        encryptedKey,
        Sodium.base642bin(_config.getKeyAttributes().publicKey),
        _config.getSecretKey(),
      );
    }
  }

  Future<void> rename(Collection collection, String newName) async {
    try {
      final encryptedName = CryptoUtil.encryptSync(
        utf8.encode(newName),
        getCollectionKey(collection.id),
      );
      await _enteDio.post(
        "/collections/rename",
        data: {
          "collectionID": collection.id,
          "encryptedName": Sodium.bin2base64(encryptedName.encryptedData),
          "nameDecryptionNonce": Sodium.bin2base64(encryptedName.nonce)
        },
      );
      // trigger sync to fetch the latest name from server
      sync();
    } catch (e, s) {
      _logger.severe("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<void> leaveAlbum(Collection collection) async {
    try {
      await _enteDio.post(
        "/collections/leave/${collection.id}",
      );
      // trigger sync to fetch the latest name from server
      sync();
    } catch (e, s) {
      _logger.severe("failed to leave collection", e, s);
      rethrow;
    }
  }

  Future<void> updateMagicMetadata(
    Collection collection,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final int ownerID = Configuration.instance.getUserID();
    try {
      if (collection.owner.id != ownerID) {
        throw AssertionError("cannot modify albums not owned by you");
      }
      // read the existing magic metadata and apply new updates to existing data
      // current update is simple replace. This will be enhanced in the future,
      // as required.
      final Map<String, dynamic> jsonToUpdate =
          jsonDecode(collection.mMdEncodedJson ?? '{}');
      newMetadataUpdate.forEach((key, value) {
        jsonToUpdate[key] = value;
      });

      // update the local information so that it's reflected on UI
      collection.mMdEncodedJson = jsonEncode(jsonToUpdate);
      collection.magicMetadata = CollectionMagicMetadata.fromJson(jsonToUpdate);

      final key = getCollectionKey(collection.id);
      final encryptedMMd = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(jsonToUpdate)),
        key,
      );
      // for required field, the json validator on golang doesn't treat 0 as valid
      // value. Instead of changing version to ptr, decided to start version with 1.
      final int currentVersion = max(collection.mMdVersion, 1);
      final params = UpdateMagicMetadataRequest(
        id: collection.id,
        magicMetadata: MetadataRequest(
          version: currentVersion,
          count: jsonToUpdate.length,
          data: Sodium.bin2base64(encryptedMMd.encryptedData),
          header: Sodium.bin2base64(encryptedMMd.header),
        ),
      );
      await _enteDio.put(
        "/collections/magic-metadata",
        data: params,
      );
      collection.mMdVersion = currentVersion + 1;
      _cacheCollectionAttributes(collection);
      // trigger sync to fetch the latest collection state from server
      sync();
    } on DioError catch (e) {
      if (e.response != null && e.response.statusCode == 409) {
        _logger.severe('collection magic data out of sync');
        sync();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }

  Future<void> createShareUrl(Collection collection) async {
    try {
      final response = await _enteDio.post(
        "/collections/share-url",
        data: {
          "collectionID": collection.id,
        },
      );
      collection.publicURLs?.add(PublicURL.fromMap(response.data["result"]));
      await _db.insert(List.from([collection]));
      _cacheCollectionAttributes(collection);
      Bus.instance.fire(CollectionUpdatedEvent(collection.id, <File>[]));
    } on DioError catch (e) {
      if (e.response.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<void> updateShareUrl(
    Collection collection,
    Map<String, dynamic> prop,
  ) async {
    prop.putIfAbsent('collectionID', () => collection.id);
    try {
      final response = await _enteDio.put(
        "/collections/share-url",
        data: json.encode(prop),
      );
      // remove existing url information
      collection.publicURLs?.clear();
      collection.publicURLs?.add(PublicURL.fromMap(response.data["result"]));
      await _db.insert(List.from([collection]));
      _cacheCollectionAttributes(collection);
      Bus.instance.fire(CollectionUpdatedEvent(collection.id, <File>[]));
    } on DioError catch (e) {
      if (e.response.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<void> disableShareUrl(Collection collection) async {
    try {
      await _enteDio.delete(
        "/collections/share-url/" + collection.id.toString(),
      );
      collection.publicURLs.clear();
      await _db.insert(List.from([collection]));
      _cacheCollectionAttributes(collection);
      Bus.instance.fire(CollectionUpdatedEvent(collection.id, <File>[]));
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<List<Collection>> _fetchCollections(int sinceTime) async {
    try {
      final response = await _enteDio.get(
        "/collections",
        queryParameters: {
          "sinceTime": sinceTime,
          "source": AppLifecycleService.instance.isForeground ? "fg" : "bg",
        },
      );
      final List<Collection> collections = [];
      if (response != null) {
        final c = response.data["collections"];
        for (final collectionData in c) {
          final collection = Collection.fromMap(collectionData);
          if (collectionData['magicMetadata'] != null) {
            final decryptionKey = _getDecryptedKey(collection);
            final utfEncodedMmd = await CryptoUtil.decryptChaCha(
              Sodium.base642bin(collectionData['magicMetadata']['data']),
              decryptionKey,
              Sodium.base642bin(collectionData['magicMetadata']['header']),
            );
            collection.mMdEncodedJson = utf8.decode(utfEncodedMmd);
            collection.mMdVersion = collectionData['magicMetadata']['version'];
            collection.magicMetadata = CollectionMagicMetadata.fromEncodedJson(
              collection.mMdEncodedJson,
            );
          }
          collections.add(collection);
        }
      }
      return collections;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      rethrow;
    }
  }

  Collection getCollectionByID(int collectionID) {
    return _collectionIDToCollections[collectionID];
  }

  Future<Collection> createAlbum(String albumName) async {
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedName = CryptoUtil.encryptSync(utf8.encode(albumName), key);
    final collection = await createAndCacheCollection(
      Collection(
        null,
        null,
        Sodium.bin2base64(encryptedKeyData.encryptedData),
        Sodium.bin2base64(encryptedKeyData.nonce),
        null,
        Sodium.bin2base64(encryptedName.encryptedData),
        Sodium.bin2base64(encryptedName.nonce),
        CollectionType.album,
        CollectionAttributes(),
        null,
        null,
        null,
      ),
    );
    return collection;
  }

  Future<Collection> fetchCollectionByID(int collectionID) async {
    try {
      _logger.fine('fetching collectionByID $collectionID');
      final response = await _enteDio.get(
        "/collections/$collectionID",
      );
      assert(response != null && response.data != null);
      final collectionData = response.data["collection"];
      final collection = Collection.fromMap(collectionData);
      if (collectionData['magicMetadata'] != null) {
        final decryptionKey = _getDecryptedKey(collection);
        final utfEncodedMmd = await CryptoUtil.decryptChaCha(
          Sodium.base642bin(collectionData['magicMetadata']['data']),
          decryptionKey,
          Sodium.base642bin(collectionData['magicMetadata']['header']),
        );
        collection.mMdEncodedJson = utf8.decode(utfEncodedMmd);
        collection.mMdVersion = collectionData['magicMetadata']['version'];
        collection.magicMetadata =
            CollectionMagicMetadata.fromEncodedJson(collection.mMdEncodedJson);
      }
      await _db.insert(List.from([collection]));
      _cacheCollectionAttributes(collection);
      return collection;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      _logger.severe('failed to fetch collection: $collectionID', e);
      rethrow;
    }
  }

  Future<Collection> getOrCreateForPath(String path) async {
    if (_localPathToCollectionID.containsKey(path)) {
      final Collection cachedCollection =
          _collectionIDToCollections[_localPathToCollectionID[path]];
      if (cachedCollection != null &&
          !cachedCollection.isDeleted &&
          cachedCollection.owner.id == _config.getUserID()) {
        return cachedCollection;
      }
    }
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedPath = CryptoUtil.encryptSync(utf8.encode(path), key);
    final collection = await createAndCacheCollection(
      Collection(
        null,
        null,
        Sodium.bin2base64(encryptedKeyData.encryptedData),
        Sodium.bin2base64(encryptedKeyData.nonce),
        null,
        Sodium.bin2base64(encryptedPath.encryptedData),
        Sodium.bin2base64(encryptedPath.nonce),
        CollectionType.folder,
        CollectionAttributes(
          encryptedPath: Sodium.bin2base64(encryptedPath.encryptedData),
          pathDecryptionNonce: Sodium.bin2base64(encryptedPath.nonce),
          version: 1,
        ),
        null,
        null,
        null,
      ),
    );
    return collection;
  }

  Future<void> addToCollection(int collectionID, List<File> files) async {
    final containsUploadedFile = files.firstWhere(
          (element) => element.uploadedFileID != null,
          orElse: () => null,
        ) !=
        null;
    if (containsUploadedFile) {
      final existingFileIDsInCollection =
          await FilesDB.instance.getUploadedFileIDs(collectionID);
      files.removeWhere(
        (element) =>
            element.uploadedFileID != null &&
            existingFileIDsInCollection.contains(element.uploadedFileID),
      );
    }
    if (files.isEmpty || !containsUploadedFile) {
      _logger.info("nothing to add to the collection");
      return;
    }

    final params = <String, dynamic>{};
    params["collectionID"] = collectionID;
    for (final file in files) {
      final key = decryptFileKey(file);
      file.generatedID = null; // So that a new entry is created in the FilesDB
      file.collectionID = collectionID;
      final encryptedKeyData =
          CryptoUtil.encryptSync(key, getCollectionKey(collectionID));
      file.encryptedKey = Sodium.bin2base64(encryptedKeyData.encryptedData);
      file.keyDecryptionNonce = Sodium.bin2base64(encryptedKeyData.nonce);
      if (params["files"] == null) {
        params["files"] = [];
      }
      params["files"].add(
        CollectionFileItem(
          file.uploadedFileID,
          file.encryptedKey,
          file.keyDecryptionNonce,
        ).toMap(),
      );
    }

    try {
      await _enteDio.post(
        "/collections/add-files",
        data: params,
      );
      await _filesDB.insertMultiple(files);
      Bus.instance.fire(CollectionUpdatedEvent(collectionID, files));
    } catch (e) {
      rethrow;
    }
  }

  Future<File> linkLocalFileToExistingUploadedFileInAnotherCollection(
    int destCollectionID, {
    @required File localFileToUpload,
    @required File existingUploadedFile,
  }) async {
    final params = <String, dynamic>{};
    params["collectionID"] = destCollectionID;
    params["files"] = [];
    final int uploadedFileID = existingUploadedFile.uploadedFileID;

    // encrypt the fileKey with destination collection's key
    final fileKey = decryptFileKey(existingUploadedFile);
    final encryptedKeyData =
        CryptoUtil.encryptSync(fileKey, getCollectionKey(destCollectionID));

    localFileToUpload.encryptedKey =
        Sodium.bin2base64(encryptedKeyData.encryptedData);
    localFileToUpload.keyDecryptionNonce =
        Sodium.bin2base64(encryptedKeyData.nonce);

    params["files"].add(
      CollectionFileItem(
        uploadedFileID,
        localFileToUpload.encryptedKey,
        localFileToUpload.keyDecryptionNonce,
      ).toMap(),
    );

    try {
      await _enteDio.post(
        "/collections/add-files",
        data: params,
      );
      localFileToUpload.collectionID = destCollectionID;
      localFileToUpload.uploadedFileID = uploadedFileID;
      await _filesDB.insertMultiple([localFileToUpload]);
      return localFileToUpload;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restore(int toCollectionID, List<File> files) async {
    final params = <String, dynamic>{};
    params["collectionID"] = toCollectionID;
    params["files"] = [];
    final toCollectionKey = getCollectionKey(toCollectionID);
    for (final file in files) {
      final key = decryptFileKey(file);
      file.generatedID = null; // So that a new entry is created in the FilesDB
      file.collectionID = toCollectionID;
      final encryptedKeyData = CryptoUtil.encryptSync(key, toCollectionKey);
      file.encryptedKey = Sodium.bin2base64(encryptedKeyData.encryptedData);
      file.keyDecryptionNonce = Sodium.bin2base64(encryptedKeyData.nonce);
      params["files"].add(
        CollectionFileItem(
          file.uploadedFileID,
          file.encryptedKey,
          file.keyDecryptionNonce,
        ).toMap(),
      );
    }
    try {
      await _enteDio.post(
        "/collections/restore-files",
        data: params,
      );
      await _filesDB.insertMultiple(files);
      await TrashDB.instance
          .delete(files.map((e) => e.uploadedFileID).toList());
      Bus.instance.fire(CollectionUpdatedEvent(toCollectionID, files));
      Bus.instance.fire(FilesUpdatedEvent(files));
      // Remove imported local files which are imported but not uploaded.
      // This handles the case where local file was trashed -> imported again
      // but not uploaded automatically as it was trashed.
      final localIDs = files
          .where((e) => e.localID != null)
          .map((e) => e.localID)
          .toSet()
          .toList();
      if (localIDs.isNotEmpty) {
        await _filesDB.deleteUnSyncedLocalFiles(localIDs);
      }
      // Force reload home gallery to pull in the restored files
      Bus.instance.fire(ForceReloadHomeGalleryEvent());
    } catch (e, s) {
      _logger.severe("failed to restore files", e, s);
      rethrow;
    }
  }

  Future<void> move(
    int toCollectionID,
    int fromCollectionID,
    List<File> files,
  ) async {
    _validateMoveRequest(toCollectionID, fromCollectionID, files);
    files.removeWhere((element) => element.uploadedFileID == null);
    if (files.isEmpty) {
      _logger.info("nothing to move to collection");
      return;
    }
    final params = <String, dynamic>{};
    params["toCollectionID"] = toCollectionID;
    params["fromCollectionID"] = fromCollectionID;
    params["files"] = [];
    for (final file in files) {
      final fileKey = decryptFileKey(file);
      file.generatedID = null; // So that a new entry is created in the FilesDB
      file.collectionID = toCollectionID;
      final encryptedKeyData =
          CryptoUtil.encryptSync(fileKey, getCollectionKey(toCollectionID));
      file.encryptedKey = Sodium.bin2base64(encryptedKeyData.encryptedData);
      file.keyDecryptionNonce = Sodium.bin2base64(encryptedKeyData.nonce);
      params["files"].add(
        CollectionFileItem(
          file.uploadedFileID,
          file.encryptedKey,
          file.keyDecryptionNonce,
        ).toMap(),
      );
    }
    await _enteDio.post(
      "/collections/move-files",
      data: params,
    );

    // remove files from old collection
    await _filesDB.removeFromCollection(
      fromCollectionID,
      files.map((e) => e.uploadedFileID).toList(),
    );
    Bus.instance.fire(
      CollectionUpdatedEvent(
        fromCollectionID,
        files,
        type: EventType.deletedFromRemote,
      ),
    );
    // insert new files in the toCollection which are not part of the toCollection
    final existingUploadedIDs =
        await FilesDB.instance.getUploadedFileIDs(toCollectionID);
    files.removeWhere(
      (element) => existingUploadedIDs.contains(element.uploadedFileID),
    );
    await _filesDB.insertMultiple(files);
    Bus.instance.fire(CollectionUpdatedEvent(toCollectionID, files));
  }

  void _validateMoveRequest(
    int toCollectionID,
    int fromCollectionID,
    List<File> files,
  ) {
    if (toCollectionID == fromCollectionID) {
      throw AssertionError("can't move to same album");
    }
    for (final file in files) {
      if (file.uploadedFileID == null) {
        throw AssertionError("can only move uploaded memories");
      }
      if (file.collectionID != fromCollectionID) {
        throw AssertionError("all memories should belong to the same album");
      }
      if (file.ownerID != Configuration.instance.getUserID()) {
        throw AssertionError("can only move memories uploaded by you");
      }
    }
  }

  Future<void> removeFromCollection(int collectionID, List<File> files) async {
    final params = <String, dynamic>{};
    params["collectionID"] = collectionID;
    for (final file in files) {
      if (params["fileIDs"] == null) {
        params["fileIDs"] = <int>[];
      }
      params["fileIDs"].add(file.uploadedFileID);
    }
    await _enteDio.post(
      "/collections/v2/remove-files",
      data: params,
    );
    await _filesDB.removeFromCollection(collectionID, params["fileIDs"]);
    Bus.instance.fire(CollectionUpdatedEvent(collectionID, files));
    Bus.instance.fire(LocalPhotosUpdatedEvent(files));
    RemoteSyncService.instance.sync(silently: true);
  }

  Future<Collection> createAndCacheCollection(
    Collection collection, {
    CreateRequest createRequest,
  }) async {
    final dynamic payload =
        createRequest != null ? createRequest.toJson() : collection.toMap();
    return _enteDio
        .post(
      "/collections",
      data: payload,
    )
        .then((response) {
      final collection = Collection.fromMap(response.data["collection"]);
      return _cacheCollectionAttributes(collection);
    });
  }

  Collection _cacheCollectionAttributes(Collection collection) {
    final collectionWithDecryptedName =
        _getCollectionWithDecryptedName(collection);
    if (collection.attributes.encryptedPath != null &&
        !collection.isDeleted &&
        collection.owner.id == _config.getUserID()) {
      _localPathToCollectionID[decryptCollectionPath(collection)] =
          collection.id;
    }
    _collectionIDToCollections[collection.id] = collectionWithDecryptedName;
    return collectionWithDecryptedName;
  }

  String decryptCollectionPath(Collection collection) {
    final key = collection.attributes.version == 1
        ? _getDecryptedKey(collection)
        : _config.getKey();
    return utf8.decode(
      CryptoUtil.decryptSync(
        Sodium.base642bin(collection.attributes.encryptedPath),
        key,
        Sodium.base642bin(collection.attributes.pathDecryptionNonce),
      ),
    );
  }

  bool hasSyncedCollections() {
    return _prefs.containsKey(_collectionsSyncTimeKey);
  }

  Collection _getCollectionWithDecryptedName(Collection collection) {
    if (collection.encryptedName != null &&
        collection.encryptedName.isNotEmpty) {
      String name;
      try {
        final result = CryptoUtil.decryptSync(
          Sodium.base642bin(collection.encryptedName),
          _getDecryptedKey(collection),
          Sodium.base642bin(collection.nameDecryptionNonce),
        );
        name = utf8.decode(result);
      } catch (e, s) {
        _logger.severe(
          "failed to decrypt collection name: ${collection.id}",
          e,
          s,
        );
        name = "Unknown Album";
      }
      return collection.copyWith(name: name);
    } else {
      return collection;
    }
  }

  Future _updateDB(List<Collection> collections, {int attempt = 1}) async {
    try {
      await _db.insert(collections);
    } catch (e) {
      if (attempt < kMaximumWriteAttempts) {
        return _updateDB(collections, attempt: ++attempt);
      } else {
        rethrow;
      }
    }
  }
}

class SharingNotPermittedForFreeAccountsError extends Error {}
