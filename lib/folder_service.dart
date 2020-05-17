import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/folder.dart';

class FolderSharingService {
  final _dio = Dio();

  FolderSharingService._privateConstructor();
  static final FolderSharingService instance =
      FolderSharingService._privateConstructor();

  Future<Map<String, bool>> getSharingStatus(String path) async {
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/users",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((usersResponse) {
      return _dio
          .get(
        Configuration.instance.getHttpEndpoint() + "/folders/",
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      )
          .then((foldersResponse) {
        var folders = (foldersResponse.data as List)
            .map((f) => Folder.fromMap(f))
            .toList();
        Folder sharedFolder;
        for (var folder in folders) {
          if (folder.owner == Configuration.instance.getUsername() &&
              folder.deviceFolder == path) {
            sharedFolder = folder;
            break;
          }
        }
        var sharedUsers = Set<String>();
        if (sharedFolder != null) {
          sharedUsers.addAll(sharedFolder.sharedWith);
        }
        final result = Map<String, bool>();
        (usersResponse.data["users"] as List).forEach((user) {
          if (user != Configuration.instance.getUsername()) {
            result[user] = sharedUsers.contains(user);
          }
        });
        return result;
      });
    });
  }

  void shareFolder(String path) {}
}
