import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:myapp/core/event_bus.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/events/user_authenticated_event.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/photo_provider.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/core/constants.dart' as Constants;

import 'events/remote_sync_event.dart';

class PhotoSyncManager {
  final _logger = Logger();
  final _dio = Dio();
  bool _isSyncInProgress = false;

  static final _lastSyncTimestampKey = "last_sync_timestamp_0";
  static final _lastDBUpdateTimestampKey = "last_db_update_timestamp";

  PhotoSyncManager._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final PhotoSyncManager instance =
      PhotoSyncManager._privateConstructor();

  Future<void> sync() async {
    if (_isSyncInProgress) {
      _logger.w("Sync already in progress, skipping.");
      return;
    }
    _isSyncInProgress = true;
    _logger.i("Syncing...");

    final prefs = await SharedPreferences.getInstance();
    var lastDBUpdateTimestamp = prefs.getInt(_lastDBUpdateTimestampKey);
    if (lastDBUpdateTimestamp == null) {
      lastDBUpdateTimestamp = 0;
      await _initializeDirectories();
    }

    await PhotoProvider.instance.refreshGalleryList();
    final pathEntities = PhotoProvider.instance.list;
    final photos = List<Photo>();
    for (AssetPathEntity pathEntity in pathEntities) {
      if (Platform.isIOS || pathEntity.name != "Recent") {
        // "Recents" contain duplicate information on Android
        var assetList = await pathEntity.assetList;
        for (AssetEntity entity in assetList) {
          if (entity.createDateTime.microsecondsSinceEpoch >
              lastDBUpdateTimestamp) {
            try {
              photos.add(await Photo.fromAsset(pathEntity, entity));
            } catch (e) {
              _logger.e(e);
            }
          }
        }
      }
    }
    if (photos.isEmpty) {
      _isSyncInProgress = false;
      _syncPhotos().then((_) {
        _deletePhotos();
      });
    } else {
      photos.sort((first, second) =>
          first.createTimestamp.compareTo(second.createTimestamp));
      _updateDatabase(photos, prefs, lastDBUpdateTimestamp).then((_) {
        _isSyncInProgress = false;
      });
    }
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

  _syncPhotos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    _logger.i("Last sync timestamp: " + lastSyncTimestamp.toString());

    _getDiff(lastSyncTimestamp).then((diff) {
      if (diff != null) {
        _downloadDiff(diff, prefs).then((_) {
          _uploadDiff(prefs);
        });
      }
    });

    // TODO:  Fix race conditions triggered due to concurrent syncs.
    //        Add device_id/last_sync_timestamp to the upload request?
  }

  Future _uploadDiff(SharedPreferences prefs) async {
    List<Photo> photosToBeUploaded =
        await DatabaseHelper.instance.getPhotosToBeUploaded();
    for (Photo photo in photosToBeUploaded) {
      var uploadedPhoto = await _uploadFile(photo);
      if (uploadedPhoto == null) {
        return;
      }
      await DatabaseHelper.instance.updatePhoto(photo.generatedId,
          uploadedPhoto.remotePath, uploadedPhoto.syncTimestamp);
      prefs.setInt(_lastSyncTimestampKey, uploadedPhoto.syncTimestamp);
    }
  }

  Future _downloadDiff(List<Photo> diff, SharedPreferences prefs) async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    var path = externalPath + "/photos/";
    for (Photo photo in diff) {
      var localPath = path + basename(photo.remotePath);
      await _dio
          .download(Constants.ENDPOINT + "/" + photo.remotePath, localPath)
          .catchError((e) => _logger.e(e));
      // TODO: Save path
      photo.pathName = localPath;
      await DatabaseHelper.instance.insertPhoto(photo);
      PhotoLoader.instance.reloadPhotos();
      await prefs.setInt(_lastSyncTimestampKey, photo.syncTimestamp);
    }
  }

  Future<List<Photo>> _getDiff(int lastSyncTimestamp) async {
    Response response = await _dio.get(Constants.ENDPOINT + "/diff",
        queryParameters: {
          "user": Constants.USER,
          "lastSyncTimestamp": lastSyncTimestamp
        }).catchError((e) => _logger.e(e));
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
      "file": MultipartFile.fromBytes(await localPhoto.getOriginalBytes()),
      "filename": localPhoto.title,
      "user": Constants.USER,
    });
    return _dio
        .post(Constants.ENDPOINT + "/upload", data: formData)
        .then((response) {
      _logger.i(response.toString());
      var photo = Photo.fromJson(response.data);
      return photo;
    }).catchError((e) => _logger.e(e));
  }

  Future<void> _deletePhotos() async {
    DatabaseHelper.instance.getAllDeletedPhotos().then((deletedPhotos) {
      for (Photo deletedPhoto in deletedPhotos) {
        _deletePhotoOnServer(deletedPhoto)
            .then((value) => DatabaseHelper.instance.deletePhoto(deletedPhoto));
      }
    });
  }

  Future<void> _deletePhotoOnServer(Photo photo) async {
    return _dio.post(Constants.ENDPOINT + "/delete", queryParameters: {
      "user": Constants.USER,
      "fileID": photo.uploadedFileId
    }).catchError((e) => _logger.e(e));
  }

  Future _initializeDirectories() async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    new Directory(externalPath + "/photos/thumbnails")
        .createSync(recursive: true);
  }

  Future<bool> _insertPhotosToDB(
      List<Photo> photos, SharedPreferences prefs, int timestamp) async {
    await DatabaseHelper.instance.insertPhotos(photos);
    _logger.i("Inserted " + photos.length.toString() + " photos.");
    PhotoLoader.instance.reloadPhotos();
    return await prefs.setInt(_lastDBUpdateTimestampKey, timestamp);
  }
}
