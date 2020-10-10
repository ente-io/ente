import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/utils/crypto_util.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsDB _db;
  Configuration _config;
  UserService _userService;

  CollectionsService._privateConstructor() {
    _db = CollectionsDB.instance;
    _config = Configuration.instance;
    _userService = UserService.instance;
  }

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  Future<void> sync() async {
    final lastCollectionCreationTime =
        await _db.getLastCollectionCreationTime();
    final collections = await getCollections(lastCollectionCreationTime ?? 0);
    await _db.insert(collections);
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

  Uint8List getCollectionKey(Collection collection) {
    final encryptedKey = Sodium.base642bin(collection.encryptedKey);
    if (collection.ownerID == _config.getUserID()) {
      return CryptoUtil.decryptSync(encryptedKey, _config.getKey(),
          Sodium.base642bin(collection.keyDecryptionNonce));
    } else {
      return CryptoUtil.openSealSync(
          encryptedKey,
          Sodium.base642bin(_config.getKeyAttributes().publicKey),
          _config.getSecretKey());
    }
  }

  Future<List<Collection>> getCollections(int sinceTime) {
    return Dio()
        .get(
      Configuration.instance.getHttpEndpoint() + "/collections/",
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
}
