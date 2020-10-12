import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/utils/crypto_util.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsDB _db;
  Configuration _config;
  final _localCollections = Map<String, Collection>();
  final _collectionIDToCollection = Map<int, Collection>();
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
    collections = await _db.getAll();
    for (final collection in collections) {
      _cacheCollectionAttributes(collection);
    }
  }

  Future<Collection> getFolder(String path) async {
    return Dio()
        .get(
      Configuration.instance.getHttpEndpoint() + "/collections/folder/",
      queryParameters: {
        "path": path,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      return Collection.fromMap(response.data);
    }).catchError((e) {
      if (e.response.statusCode == HttpStatus.notFound) {
        return Collection.emptyCollection();
      } else {
        throw e;
      }
    });
  }

  Uint8List getCollectionKey(int collectionID) {
    if (!_cachedKeys.containsKey(collectionID)) {
      final collection = _collectionIDToCollection[collectionID];
      final encryptedKey = Sodium.base642bin(collection.encryptedKey);
      var key;
      if (collection.ownerID == _config.getUserID()) {
        key = CryptoUtil.decryptSync(encryptedKey, _config.getKey(),
            Sodium.base642bin(collection.keyDecryptionNonce));
      } else {
        key = CryptoUtil.openSealSync(
            encryptedKey,
            Sodium.base642bin(_config.getKeyAttributes().publicKey),
            _config.getSecretKey());
      }
      _cachedKeys[collection.id] = key;
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

  Future<Collection> getOrCreateForPath(String path) async {
    if (_localCollections.containsKey(path)) {
      return _localCollections[path];
    }
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey());
    final encryptedPath =
        CryptoUtil.encryptSync(utf8.encode(path), _config.getKey());
    final collection = await createCollection(Collection(
      null,
      null,
      Sodium.bin2base64(encryptedKeyData.encryptedData),
      Sodium.bin2base64(encryptedKeyData.nonce),
      path,
      CollectionType.folder,
      Sodium.bin2base64(encryptedPath.encryptedData),
      Sodium.bin2base64(encryptedPath.nonce),
      null,
      null,
    ));
    _cacheCollectionAttributes(collection);
    return collection;
  }

  Future<Collection> createCollection(Collection collection) async {
    return Dio()
        .post(
      Configuration.instance.getHttpEndpoint() + "/collections/",
      data: collection.toMap(),
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      return Collection.fromMap(response.data["collection"]);
    });
  }

  void _cacheCollectionAttributes(Collection collection) {
    if (collection.ownerID == _config.getUserID()) {
      var path = utf8.decode(CryptoUtil.decryptSync(
          Sodium.base642bin(collection.encryptedPath),
          _config.getKey(),
          Sodium.base642bin(collection.pathDecryptionNonce)));
      _localCollections[path] = collection;
    }
    _collectionIDToCollection[collection.id] = collection;
    getCollectionKey(collection.id);
  }
}
