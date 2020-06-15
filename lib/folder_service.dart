import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/folder_db.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/photo.dart';

import 'core/event_bus.dart';

class FolderSharingService {
  final _logger = Logger("FolderSharingService");
  final _dio = Dio();
  static final _diffLimit = 100;

  FolderSharingService._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final FolderSharingService instance =
      FolderSharingService._privateConstructor();

  void sync() {
    if (!Configuration.instance.hasConfiguredAccount()) {
      return;
    }
    getFolders().then((f) async {
      var folders = f.toSet();
      var currentFolders = await FolderDB.instance.getFolders();
      for (final currentFolder in currentFolders) {
        if (!folders.contains(currentFolder)) {
          _logger.info("Folder deleted: " + currentFolder.toString());
          await PhotoDB.instance.deletePhotosInRemoteFolder(currentFolder.id);
          await FolderDB.instance.deleteFolder(currentFolder);
        }
      }
      for (final folder in folders) {
        if (folder.owner != Configuration.instance.getUsername()) {
          await syncDiff(folder);
          await FolderDB.instance.putFolder(folder);
        }
      }
      Bus.instance.fire(RemoteSyncEvent(true));
    });
  }

  Future<void> syncDiff(Folder folder) async {
    int lastSyncTimestamp = 0;
    try {
      Photo photo =
          await PhotoDB.instance.getLastSyncedPhotoInRemoteFolder(folder.id);
      lastSyncTimestamp = photo.updateTimestamp;
    } catch (e) {
      // Folder has never been synced
    }
    var diff = await getDiff(folder.id, lastSyncTimestamp, _diffLimit);
    for (Photo photo in diff) {
      try {
        var existingPhoto =
            await PhotoDB.instance.getMatchingRemotePhoto(photo.uploadedFileId);
        await PhotoDB.instance.updatePhoto(
            existingPhoto.generatedId,
            photo.uploadedFileId,
            photo.remotePath,
            photo.updateTimestamp,
            photo.thumbnailPath);
      } catch (e) {
        await PhotoDB.instance.insertPhoto(photo);
      }
    }
    if (diff.length == _diffLimit) {
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
      return List<Photo>();
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
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      return Folder.fromMap(response.data);
    }).catchError((e) {
      return Folder(
        null,
        Configuration.instance.getUsername() + "s " + deviceFolder,
        Configuration.instance.getUsername(),
        deviceFolder,
        Set<String>(),
        null,
      );
    });
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
