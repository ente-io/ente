import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsService._privateConstructor() {}

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  Future<void> sync() async {
    // TODO
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
}
