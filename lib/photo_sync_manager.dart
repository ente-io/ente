import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/photo_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:photos/models/photo.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/events/remote_sync_event.dart';

class PhotoSyncManager {
  final _logger = Logger("PhotoSyncManager");
  final _dio = Dio();
  final _db = PhotoDB.instance;
  bool _isSyncInProgress = false;

  static final _lastSyncTimestampKey = "last_sync_timestamp_0";
  static final _lastDBUpdateTimestampKey = "last_db_update_timestamp";
  static final _diffLimit = 100;

  PhotoSyncManager._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final PhotoSyncManager instance =
      PhotoSyncManager._privateConstructor();

  Future<void> sync() async {
    if (_isSyncInProgress) {
      _logger.warning("Sync already in progress, skipping.");
      return;
    }
    _isSyncInProgress = true;
    _logger.info("Syncing...");

    final prefs = await SharedPreferences.getInstance();
    var lastDBUpdateTimestamp = prefs.getInt(_lastDBUpdateTimestampKey);
    if (lastDBUpdateTimestamp == null) {
      lastDBUpdateTimestamp = 0;
      await _initializeDirectories();
    }

    await PhotoProvider.instance.refreshGalleryList();
    final pathEntities = PhotoProvider.instance.list;
    final photos = List<Photo>();
    AssetPathEntity recents;
    for (AssetPathEntity pathEntity in pathEntities) {
      if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
        recents = pathEntity;
      } else {
        await _addToPhotos(pathEntity, lastDBUpdateTimestamp, photos);
      }
    }
    if (recents != null) {
      await _addToPhotos(recents, lastDBUpdateTimestamp, photos);
    }

    if (photos.isEmpty) {
      _isSyncInProgress = false;
      _syncWithRemote(prefs);
    } else {
      photos.sort((first, second) =>
          first.createTimestamp.compareTo(second.createTimestamp));
      _updateDatabase(photos, prefs, lastDBUpdateTimestamp).then((_) {
        _isSyncInProgress = false;
        _syncWithRemote(prefs);
      });
    }
  }

  Future _addToPhotos(AssetPathEntity pathEntity, int lastDBUpdateTimestamp,
      List<Photo> photos) async {
    final assetList = await pathEntity.assetList;
    for (AssetEntity entity in assetList) {
      if (max(entity.createDateTime.microsecondsSinceEpoch,
              entity.modifiedDateTime.microsecondsSinceEpoch) >
          lastDBUpdateTimestamp) {
        try {
          final photo = await Photo.fromAsset(pathEntity, entity);
          if (!photos.contains(photo)) {
            photos.add(photo);
          }
        } catch (e) {
          _logger.severe(e);
        }
      }
    }
  }

  _syncWithRemote(SharedPreferences prefs) {
    // TODO:  Fix race conditions triggered due to concurrent syncs.
    //        Add device_id/last_sync_timestamp to the upload request?
    if (!Configuration.instance.hasConfiguredAccount()) {
      return;
    }
    _downloadDiff(prefs).then((_) {
      _uploadDiff(prefs).then((_) {
        _deletePhotosOnServer();
      });
    });
  }

  Future<bool> _updateDatabase(final List<Photo> photos,
      SharedPreferences prefs, int lastDBUpdateTimestamp) async {
    var photosToBeAdded = List<Photo>();
    for (Photo photo in photos) {
      if (photo.createTimestamp > lastDBUpdateTimestamp) {
        photosToBeAdded.add(photo);
      }
    }
    return await _insertPhotosToDB(
        photosToBeAdded, prefs, DateTime.now().microsecondsSinceEpoch);
  }

  Future<void> _downloadDiff(SharedPreferences prefs) async {
    int lastSyncTimestamp = _getLastSyncTimestamp(prefs);
    var diff = await _getDiff(lastSyncTimestamp, _diffLimit);
    if (diff != null && diff.isNotEmpty) {
      await _storeDiff(diff, prefs);
      PhotoRepository.instance.reloadPhotos();
      if (diff.length == _diffLimit) {
        return await _downloadDiff(prefs);
      }
    }
  }

  int _getLastSyncTimestamp(SharedPreferences prefs) {
    var lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    return lastSyncTimestamp;
  }

  Future _uploadDiff(SharedPreferences prefs) async {
    List<Photo> photosToBeUploaded = await _db.getPhotosToBeUploaded();
    for (Photo photo in photosToBeUploaded) {
      try {
        var uploadedPhoto = await _uploadFile(photo);
        if (uploadedPhoto == null) {
          return;
        }
        await _db.updatePhoto(photo.generatedId, uploadedPhoto.uploadedFileId,
            uploadedPhoto.remotePath, uploadedPhoto.updateTimestamp);
        prefs.setInt(_lastSyncTimestampKey, uploadedPhoto.updateTimestamp);
      } catch (e) {
        _logger.severe(e);
      }
    }
  }

  Future _storeDiff(List<Photo> diff, SharedPreferences prefs) async {
    for (Photo photo in diff) {
      try {
        var existingPhoto = await _db.getMatchingPhoto(photo.localId,
            photo.title, photo.deviceFolder, photo.createTimestamp);
        await _db.updatePhoto(existingPhoto.generatedId, photo.uploadedFileId,
            photo.remotePath, photo.updateTimestamp, photo.thumbnailPath);
      } catch (e) {
        await _db.insertPhoto(photo);
      }
      await prefs.setInt(_lastSyncTimestampKey, photo.updateTimestamp);
    }
  }

  Future<List<Photo>> _getDiff(int lastSyncTimestamp, int limit) async {
    Response response = await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/files/diff",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      queryParameters: {
        "sinceTimestamp": lastSyncTimestamp,
        "limit": limit,
      },
    ).catchError((e) => _logger.severe(e));
    if (response != null) {
      Bus.instance.fire(RemoteSyncEvent(true));
      return (response.data["diff"] as List)
          .map((photo) => new Photo.fromJson(photo))
          .toList();
    } else {
      Bus.instance.fire(RemoteSyncEvent(false));
      return null;
    }
  }

  Future<Photo> _uploadFile(Photo localPhoto) async {
    var formData = FormData.fromMap({
      "file": MultipartFile.fromBytes((await localPhoto.getBytes()),
          filename: localPhoto.title),
      "deviceFileID": localPhoto.localId,
      "deviceFolder": localPhoto.deviceFolder,
      "title": extension(localPhoto.title) == ".HEIC"
          ? basenameWithoutExtension(localPhoto.title) + ".JPG"
          : localPhoto.title,
      "createTimestamp": localPhoto.createTimestamp,
    });
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: formData,
    )
        .then((response) {
      return Photo.fromJson(response.data);
    }).catchError((e) {
      _logger.severe("Error in uploading ", e);
    });
  }

  Future<void> _deletePhotosOnServer() async {
    _db.getAllDeletedPhotos().then((deletedPhotos) {
      for (Photo deletedPhoto in deletedPhotos) {
        _deletePhotoOnServer(deletedPhoto)
            .then((value) => _db.deletePhoto(deletedPhoto));
      }
    });
  }

  Future<void> _deletePhotoOnServer(Photo photo) async {
    return _dio
        .delete(
          Configuration.instance.getHttpEndpoint() +
              "/files/" +
              photo.uploadedFileId.toString(),
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .catchError((e) => _logger.severe(e));
  }

  Future _initializeDirectories() async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    new Directory(externalPath + "/photos/thumbnails")
        .createSync(recursive: true);
  }

  Future<bool> _insertPhotosToDB(
      List<Photo> photos, SharedPreferences prefs, int timestamp) async {
    await _db.insertPhotos(photos);
    _logger.info("Inserted " + photos.length.toString() + " photos.");
    PhotoRepository.instance.reloadPhotos();
    return await prefs.setInt(_lastDBUpdateTimestampKey, timestamp);
  }
}
