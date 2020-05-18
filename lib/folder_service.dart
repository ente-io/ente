import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/folder.dart';

class FolderSharingService {
  final _dio = Dio();

  FolderSharingService._privateConstructor();
  static final FolderSharingService instance =
      FolderSharingService._privateConstructor();

  void sync() {
    // TODO
  }

  Future<List<Folder>> getFolders() async {
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/folders/",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((foldersResponse) {
      return (foldersResponse.data as List)
          .map((f) => Folder.fromMap(f))
          .toList();
    });
  }

  Future<Map<String, bool>> getSharingStatus(String path) async {
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/users",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((usersResponse) {
      return getFolders().then((folders) {
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

  Future<void> shareFolder(String name, String path, Set<String> users) {
    var folder = Folder(0, name, Configuration.instance.getUsername(), path,
        users.toList(), -1);
    return _dio
        .put(Configuration.instance.getHttpEndpoint() + "/folders/",
            options: Options(
                headers: {"X-Auth-Token": Configuration.instance.getToken()}),
            data: folder.toMap())
        .then((response) => log(response.toString()));
  }
}
