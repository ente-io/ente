import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/models/collection.dart';

class CollectionsService {
  final _logger = Logger("CollectionsService");

  CollectionsService._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      // TODO: sync();
    });
  }

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

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
