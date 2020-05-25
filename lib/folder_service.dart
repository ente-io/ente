import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/folder_db.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/photo.dart';

class FolderSharingService {
  final _logger = Logger("FolderSharingService");
  final _dio = Dio();
  static final _diffLimit = 100;

  FolderSharingService._privateConstructor();
  static final FolderSharingService instance =
      FolderSharingService._privateConstructor();

  void sync() {
    getFolders().then((f) async {
      var folders = f.toSet();
      var currentFolders = await FolderDB.instance.getFolders();
      for (final currentFolder in currentFolders) {
        if (!folders.contains(currentFolder)) {
          await PhotoDB.instance.deletePhotosInRemoteFolder(currentFolder.id);
          await FolderDB.instance.deleteFolder(currentFolder);
        }
      }
      for (final folder in folders) {
        await syncDiff(folder);
        await FolderDB.instance.putFolder(folder);
      }
    });
  }

  Future<void> syncDiff(Folder folder) async {
    int lastSyncTimestamp = 0;
    try {
      Photo photo =
          await PhotoDB.instance.getLatestPhotoInRemoteFolder(folder.id);
      lastSyncTimestamp = photo.syncTimestamp;
    } catch (e) {
      // Folder has never been synced
    }
    var photos = await getDiff(folder.id, lastSyncTimestamp, _diffLimit);
    await PhotoDB.instance.insertPhotos(photos);
    if (photos.length == _diffLimit) {
      await syncDiff(folder);
    }
  }

  Future<List<Photo>> getDiff(
      int folderId, int sinceTimestamp, int limit) async {
    Response response = await _dio.get(
      Configuration.instance.getHttpEndpoint() +
          "/folders/diff/" +
          folderId.toString(),
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      queryParameters: {
        "sinceTimestamp": sinceTimestamp,
        "limit": limit,
      },
    ).catchError((e) => _logger.severe(e));
    if (response != null) {
      return (response.data["diff"] as List).map((p) {
        Photo photo = new Photo.fromJson(p);
        photo.localId = null;
        photo.remoteFolderId = folderId;
        return photo;
      }).toList();
    } else {
      return null;
    }
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

  Future<Folder> getFolder(String deviceFolder) async {
    return _dio
        .get(
          Configuration.instance.getHttpEndpoint() + "/folders/folder/",
          queryParameters: {
            "deviceFolder": deviceFolder,
          },
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .then((response) => Folder.fromMap(response.data));
  }

  Future<Map<String, bool>> getSharingStatus(Folder folder) async {
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/users",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      final users = (response.data["users"] as List).toList();
      final result = Map<String, bool>();
      for (final user in users) {
        if (user != Configuration.instance.getUsername()) {
          result[user] = folder.sharedWith.contains(user);
        }
      }
      return result;
    });
  }

  Future<void> updateFolder(Folder folder) {
    log("Updating folder: " + folder.toString());
    return _dio
        .put(Configuration.instance.getHttpEndpoint() + "/folders/",
            options: Options(
                headers: {"X-Auth-Token": Configuration.instance.getToken()}),
            data: folder.toMap())
        .then((response) => log(response.toString()))
        .catchError((error) => log(error.toString()));
  }
}
