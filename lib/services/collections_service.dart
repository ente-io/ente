import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/models/collection.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsDB _db;

  CollectionsService._privateConstructor() {
    _db = CollectionsDB.instance;
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
