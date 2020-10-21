import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_file_item.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/shared_collection.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsDB _db;
  Configuration _config;
  final _localCollections = Map<String, Collection>();
  final _collectionIDToOwnedCollections = Map<int, Collection>();
  final _collectionIDToSharedCollections = Map<int, SharedCollection>();
  final _cachedKeys = Map<int, Uint8List>();

  CollectionsService._privateConstructor() {
    _db = CollectionsDB.instance;
    _config = Configuration.instance;
  }

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  Future<void> sync() async {
    final lastCollectionCreationTime =
        await _db.getLastCollectionCreationTime();
    var collections =
        await getOwnedCollections(lastCollectionCreationTime ?? 0);
    await _db.insert(collections);
    collections = await _db.getAllCollections();
    for (final collection in collections) {
      _cacheOwnedCollectionAttributes(collection);
    }

    final lastSharedCollectionCreationTime =
        await _db.getLastCollectionCreationTime();
    var sharedCollections =
        await getSharedCollections(lastSharedCollectionCreationTime ?? 0);
    await _db.insertSharedCollections(sharedCollections);
    sharedCollections = await _db.getAllSharedCollections();
    for (final collection in sharedCollections) {
      _collectionIDToSharedCollections[collection.id] = collection;
    }
  }

  Collection getCollectionForPath(String path) {
    return _localCollections[path];
  }

  Future<List<String>> getSharees(int collectionID) {
    return Dio()
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
      final emails = List<String>();
      for (final email in response.data["emails"]) {
        emails.add(email);
      }
      return emails;
    });
  }

  Future<void> share(int collectionID, String email, String publicKey) {
    final encryptedKey = CryptoUtil.sealSync(
        getCollectionKey(collectionID), Sodium.base642bin(publicKey));
    return Dio().post(
      Configuration.instance.getHttpEndpoint() + "/collections/share",
      data: {
        "collectionID": collectionID,
        "email": email,
        "encryptedKey": Sodium.bin2base64(encryptedKey),
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    );
  }

  Uint8List getCollectionKey(int collectionID) {
    if (!_cachedKeys.containsKey(collectionID)) {
      var key;
      if (_collectionIDToOwnedCollections.containsKey(collectionID)) {
        final collection = _collectionIDToOwnedCollections[collectionID];
        final encryptedKey = Sodium.base642bin(collection.encryptedKey);
        key = CryptoUtil.decryptSync(encryptedKey, _config.getKey(),
            Sodium.base642bin(collection.keyDecryptionNonce));
      } else {
        final collection = _collectionIDToSharedCollections[collectionID];
        final encryptedKey = Sodium.base642bin(collection.encryptedKey);
        key = CryptoUtil.openSealSync(
            encryptedKey,
            Sodium.base642bin(_config.getKeyAttributes().publicKey),
            _config.getSecretKey());
      }
      _cachedKeys[collectionID] = key;
    }
    return _cachedKeys[collectionID];
  }

  Future<List<Collection>> getOwnedCollections(int sinceTime) {
    return Dio()
        .get(
      Configuration.instance.getHttpEndpoint() + "/collections/owned",
      queryParameters: {
        "sinceTime": sinceTime,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      final collections = List<Collection>();
      if (response != null) {
        final c = response.data["collections"];
        for (final collection in c) {
          collections.add(Collection.fromMap(collection));
        }
      }
      return collections;
    });
  }

  Future<List<SharedCollection>> getSharedCollections(int sinceTime) {
    return Dio()
        .get(
      Configuration.instance.getHttpEndpoint() + "/collections/shared",
      queryParameters: {
        "sinceTime": sinceTime,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      final collections = List<SharedCollection>();
      if (response != null) {
        final c = response.data["collections"];
        for (final collection in c) {
          collections.add(SharedCollection.fromMap(collection));
        }
      }
      return collections;
    });
  }

  Future<Collection> getOrCreateForPath(String path) async {
    if (_localCollections.containsKey(path)) {
      return _localCollections[path];
    }
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedPath =
        CryptoUtil.encryptSync(utf8.encode(path), _config.getKey());
    final collection = await createAndCacheCollection(Collection(
      null,
      null,
      Sodium.bin2base64(encryptedKeyData.encryptedData),
      Sodium.bin2base64(encryptedKeyData.nonce),
      path,
      CollectionType.folder,
      Sodium.bin2base64(encryptedPath.encryptedData),
      Sodium.bin2base64(encryptedPath.nonce),
      null,
    ));
    return collection;
  }

  Future<void> addToCollection(int collectionID, List<File> files) {
    final items = List<CollectionFileItem>();
    for (final file in files) {
      final key = decryptFileKey(file);
      final encryptedKeyData =
          CryptoUtil.encryptSync(key, getCollectionKey(collectionID));
      items.add(CollectionFileItem(
        file.uploadedFileID,
        Sodium.bin2base64(encryptedKeyData.encryptedData),
        Sodium.bin2base64(encryptedKeyData.nonce),
      ));
    }
    return Dio().post(
      Configuration.instance.getHttpEndpoint() + "/collections/add-files",
      data: {
        "id": collectionID,
        "files": items,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    );
  }

  Future<Collection> createAndCacheCollection(Collection collection) async {
    return Dio()
        .post(
      Configuration.instance.getHttpEndpoint() + "/collections/",
      data: collection.toMap(),
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      final collection = Collection.fromMap(response.data["collection"]);
      _cacheOwnedCollectionAttributes(collection);
      return collection;
    });
  }

  void _cacheOwnedCollectionAttributes(Collection collection) {
    if (collection.encryptedPath != null) {
      var path = utf8.decode(CryptoUtil.decryptSync(
          Sodium.base642bin(collection.encryptedPath),
          _config.getKey(),
          Sodium.base642bin(collection.pathDecryptionNonce)));
      _localCollections[path] = collection;
    }
    _collectionIDToOwnedCollections[collection.id] = collection;
    getCollectionKey(collection.id);
  }
}
