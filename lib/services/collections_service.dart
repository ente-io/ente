import 'dart:convert';
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
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_file_item.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionsService {
  static final _collectionSyncTimeKeyPrefix = "collection_sync_time_";
  static final _collectionsSyncTimeKey = "collections_sync_time";

  static const int kMaximumWriteAttempts = 5;

  final _logger = Logger("CollectionsService");

  CollectionsDB _db;
  FilesDB _filesDB;
  Configuration _config;
  SharedPreferences _prefs;
  Future<List<File>> _cachedLatestFiles;
  final _dio = Network.instance.getDio();
  final _localCollections = Map<String, Collection>();
  final _collectionIDToCollections = Map<int, Collection>();
  final _cachedKeys = Map<int, Uint8List>();

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

  Future<List<Collection>> sync() async {
    _logger.info("Syncing");
    final lastCollectionUpdationTime =
        _prefs.getInt(_collectionsSyncTimeKey) ?? 0;

    // Might not have synced the collection fully
    final fetchedCollections =
        await _fetchCollections(lastCollectionUpdationTime ?? 0);
    final updatedCollections = List<Collection>();
    int maxUpdationTime = lastCollectionUpdationTime;
    for (final collection in fetchedCollections) {
      if (collection.isDeleted) {
        await _filesDB.deleteCollection(collection.id);
        await _db.deleteCollection(collection.id);
        await setCollectionSyncTime(collection.id, null);
        Bus.instance.fire(LocalPhotosUpdatedEvent(List<File>.empty()));
      } else {
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

  Future<void> clearCache() {
    _localCollections.clear();
    _collectionIDToCollections.clear();
    _cachedKeys.clear();
  }

  Future<List<Collection>> getCollectionsToBeSynced() async {
    final collections = await _db.getAllCollections();
    final updatedCollections = List<Collection>();
    for (final c in collections) {
      if (c.updationTime > getCollectionSyncTime(c.id)) {
        updatedCollections.add(c);
      }
    }
    return updatedCollections;
  }

  int getCollectionSyncTime(int collectionID) {
    var syncTime =
        _prefs.getInt(_collectionSyncTimeKeyPrefix + collectionID.toString());
    if (syncTime == null) {
      syncTime = 0;
    }
    return syncTime;
  }

  Future<List<File>> getLatestCollectionFiles() {
    if (_cachedLatestFiles == null) {
      _cachedLatestFiles = _filesDB.getLatestCollectionFiles();
    }
    return _cachedLatestFiles;
  }

  Future<void> setCollectionSyncTime(int collectionID, int time) async {
    final key = _collectionSyncTimeKeyPrefix + collectionID.toString();
    if (time == null) {
      return _prefs.remove(key);
    }
    return _prefs.setInt(key, time);
  }

  Collection getCollectionForPath(String path) {
    return _localCollections[path];
  }

  List<Collection> getCollections() {
    return _collectionIDToCollections.values.toList();
  }

  Future<List<User>> getSharees(int collectionID) {
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/collections/sharees",
      queryParameters: {
        "collectionID": collectionID,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      _logger.info(response.toString());
      final sharees = List<User>();
      for (final user in response.data["sharees"]) {
        sharees.add(User.fromMap(user));
      }
      return sharees;
    });
  }

  Future<void> share(int collectionID, String email, String publicKey) async {
    final encryptedKey = CryptoUtil.sealSync(
        getCollectionKey(collectionID), Sodium.base642bin(publicKey));
    try {
      await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/collections/share",
        data: {
          "collectionID": collectionID,
          "email": email,
          "encryptedKey": Sodium.bin2base64(encryptedKey),
        },
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      );
    } on DioError catch (e) {
      if (e.response.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      throw e;
    }
    SyncService.instance.syncWithRemote(silently: true);
  }

  Future<void> unshare(int collectionID, String email) async {
    try {
      await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/collections/unshare",
        data: {
          "collectionID": collectionID,
          "email": email,
        },
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      );
      _collectionIDToCollections[collectionID]
          .sharees
          .removeWhere((user) => user.email == email);
      _db.insert([_collectionIDToCollections[collectionID]]);
    } catch (e) {
      _logger.severe(e);
      throw e;
    }
    SyncService.instance.syncWithRemote(silently: true);
  }

  Uint8List getCollectionKey(int collectionID) {
    if (!_cachedKeys.containsKey(collectionID)) {
      final collection = _collectionIDToCollections[collectionID];
      _cachedKeys[collectionID] = _getDecryptedKey(collection);
    }
    return _cachedKeys[collectionID];
  }

  Uint8List _getDecryptedKey(Collection collection) {
    final encryptedKey = Sodium.base642bin(collection.encryptedKey);
    if (collection.owner.id == _config.getUserID()) {
      return CryptoUtil.decryptSync(encryptedKey, _config.getKey(),
          Sodium.base642bin(collection.keyDecryptionNonce));
    } else {
      return CryptoUtil.openSealSync(
          encryptedKey,
          Sodium.base642bin(_config.getKeyAttributes().publicKey),
          _config.getSecretKey());
    }
  }

  Future<List<Collection>> _fetchCollections(int sinceTime) async {
    try {
      final response = await _dio.get(
        Configuration.instance.getHttpEndpoint() + "/collections",
        queryParameters: {
          "sinceTime": sinceTime,
        },
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      );
      final List<Collection> collections = [];
      if (response != null) {
        final c = response.data["collections"];
        for (final collection in c) {
          collections.add(Collection.fromMap(collection));
        }
      }
      return collections;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      throw e;
    }
  }

  Collection getCollectionByID(int collectionID) {
    return _collectionIDToCollections[collectionID];
  }

  Future<Collection> createAlbum(String albumName) async {
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedName = CryptoUtil.encryptSync(utf8.encode(albumName), key);
    final collection = await createAndCacheCollection(Collection(
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
    ));
    return collection;
  }

  Future<Collection> getOrCreateForPath(String path) async {
    if (_localCollections.containsKey(path)) {
      return _localCollections[path];
    }
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedPath = CryptoUtil.encryptSync(utf8.encode(path), key);
    final collection = await createAndCacheCollection(Collection(
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
    ));
    return collection;
  }

  Future<void> addToCollection(int collectionID, List<File> files) {
    final params = Map<String, dynamic>();
    params["collectionID"] = collectionID;
    for (final file in files) {
      final key = decryptFileKey(file);
      file.collectionID = collectionID;
      final encryptedKeyData =
          CryptoUtil.encryptSync(key, getCollectionKey(collectionID));
      file.encryptedKey = Sodium.bin2base64(encryptedKeyData.encryptedData);
      file.keyDecryptionNonce = Sodium.bin2base64(encryptedKeyData.nonce);
      if (params["files"] == null) {
        params["files"] = [];
      }
      params["files"].add(CollectionFileItem(
              file.uploadedFileID, file.encryptedKey, file.keyDecryptionNonce)
          .toMap());
    }
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/collections/add-files",
      data: params,
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((value) async {
      await _filesDB.insertMultiple(files);
      Bus.instance.fire(CollectionUpdatedEvent(collectionID, files));
      SyncService.instance.syncWithRemote(silently: true);
    });
  }

  Future<void> removeFromCollection(int collectionID, List<File> files) async {
    final params = Map<String, dynamic>();
    params["collectionID"] = collectionID;
    for (final file in files) {
      if (params["fileIDs"] == null) {
        params["fileIDs"] = List<int>();
      }
      params["fileIDs"].add(file.uploadedFileID);
    }
    await _dio.post(
      Configuration.instance.getHttpEndpoint() + "/collections/remove-files",
      data: params,
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    );
    await _filesDB.removeFromCollection(collectionID, params["fileIDs"]);
    Bus.instance.fire(CollectionUpdatedEvent(collectionID, files));
    SyncService.instance.syncWithRemote(silently: true);
  }

  Future<Collection> createAndCacheCollection(Collection collection) async {
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/collections",
      data: collection.toMap(),
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      final collection = Collection.fromMap(response.data["collection"]);
      return _cacheCollectionAttributes(collection);
    });
  }

  Collection _cacheCollectionAttributes(Collection collection) {
    final collectionWithDecryptedName =
        _getCollectionWithDecryptedName(collection);
    if (collection.attributes.encryptedPath != null) {
      _localCollections[decryptCollectionPath(collection)] =
          collectionWithDecryptedName;
    }
    _collectionIDToCollections[collection.id] = collectionWithDecryptedName;
    return collectionWithDecryptedName;
  }

  String decryptCollectionPath(Collection collection) {
    final key = collection.attributes.version == 1
        ? _getDecryptedKey(collection)
        : _config.getKey();
    return utf8.decode(CryptoUtil.decryptSync(
        Sodium.base642bin(collection.attributes.encryptedPath),
        key,
        Sodium.base642bin(collection.attributes.pathDecryptionNonce)));
  }

  Collection _getCollectionWithDecryptedName(Collection collection) {
    if (collection.encryptedName != null &&
        collection.encryptedName.isNotEmpty) {
      var result = CryptoUtil.decryptSync(
          Sodium.base642bin(collection.encryptedName),
          _getDecryptedKey(collection),
          Sodium.base642bin(collection.nameDecryptionNonce));
      var name;
      try {
        name = utf8.decode(result);
      } catch (e) {
        _logger.severe(e);
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
        return _updateDB(collections, attempt: attempt++);
      } else {
        throw e;
      }
    }
  }
}

class AddFilesRequest {
  final int collectionID;
  final List<CollectionFileItem> files;

  AddFilesRequest(
    this.collectionID,
    this.files,
  );

  AddFilesRequest copyWith({
    int collectionID,
    List<CollectionFileItem> files,
  }) {
    return AddFilesRequest(
      collectionID ?? this.collectionID,
      files ?? this.files,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collectionID': collectionID,
      'files': files?.map((x) => x?.toMap())?.toList(),
    };
  }

  factory AddFilesRequest.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return AddFilesRequest(
      map['collectionID'],
      List<CollectionFileItem>.from(
          map['files']?.map((x) => CollectionFileItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory AddFilesRequest.fromJson(String source) =>
      AddFilesRequest.fromMap(json.decode(source));

  @override
  String toString() =>
      'AddFilesRequest(collectionID: $collectionID, files: $files)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is AddFilesRequest &&
        o.collectionID == collectionID &&
        listEquals(o.files, files);
  }

  @override
  int get hashCode => collectionID.hashCode ^ files.hashCode;
}

class SharingNotPermittedForFreeAccountsError extends Error {}
