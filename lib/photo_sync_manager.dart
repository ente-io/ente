import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/photo_loader.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/core/constants.dart' as Constants;

class PhotoSyncManager {
  final _logger = Logger();
  final _dio = Dio();
  final List<AssetEntity> _assets;
  static final _lastSyncTimestampKey = "last_sync_timestamp_0";
  static final _lastDBUpdateTimestampKey = "last_db_update_timestamp";

  PhotoSyncManager(this._assets) {
    _logger.i("PhotoSyncManager init");
    _assets.sort((first, second) => second
        .modifiedDateTime.microsecondsSinceEpoch
        .compareTo(first.modifiedDateTime.microsecondsSinceEpoch));
  }

  Future<void> init() async {
    _updateDatabase().then((_) {
      _syncPhotos().then((_) {
        _deletePhotos();
      });
    });
  }

  Future<bool> _updateDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    var lastDBUpdateTimestamp = prefs.getInt(_lastDBUpdateTimestampKey);
    if (lastDBUpdateTimestamp == null) {
      lastDBUpdateTimestamp = 0;
      await _initializeDirectories();
    }
    var photos = List<Photo>();
    var bufferLimit = 10;
    final maxBufferLimit = 1000;
    for (AssetEntity asset in _assets) {
      if (asset.createDateTime.microsecondsSinceEpoch > lastDBUpdateTimestamp) {
        photos.add(await Photo.fromAsset(asset));
        if (photos.length > bufferLimit) {
          await _insertPhotosToDB(
              photos, prefs, asset.createDateTime.microsecondsSinceEpoch);
          photos.clear();
          bufferLimit = min(maxBufferLimit, bufferLimit * 2);
        }
      }
    }
    return await _insertPhotosToDB(
        photos, prefs, DateTime.now().microsecondsSinceEpoch);
  }

  _syncPhotos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    _logger.i("Last sync timestamp: " + lastSyncTimestamp.toString());

    _getDiff(lastSyncTimestamp).then((diff) {
      _downloadDiff(diff, prefs).then((_) {
        _uploadDiff(prefs);
      });
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
      await DatabaseHelper.instance.updatePhoto(uploadedPhoto);
      prefs.setInt(_lastSyncTimestampKey, uploadedPhoto.syncTimestamp);
    }
  }

  Future _downloadDiff(List<Photo> diff, SharedPreferences prefs) async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    _logger.i("External path: " + externalPath);
    var path = externalPath + "/photos/";
    for (Photo photo in diff) {
      var localPath = path + basename(photo.path);
      await _dio
          .download(Constants.ENDPOINT + "/" + photo.path, localPath)
          .catchError(_onError);
      photo.localPath = localPath;
      photo.thumbnailPath = localPath;
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
        }).catchError(_onError);
    _logger.i(response.toString());
    if (response != null) {
      return (response.data["diff"] as List)
          .map((photo) => new Photo.fromJson(photo))
          .toList();
    } else {
      return List<Photo>();
    }
  }

  Future<Photo> _uploadFile(Photo localPhoto) async {
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(localPhoto.localPath,
          filename: basename(localPhoto.localPath)),
      "user": Constants.USER,
    });
    return _dio
        .post(Constants.ENDPOINT + "/upload", data: formData)
        .then((response) {
      _logger.i(response.toString());
      var photo = Photo.fromJson(response.data);
      photo.localPath = localPhoto.localPath;
      photo.localId = localPhoto.localId;
      return photo;
    }).catchError(_onError);
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
    }).catchError((e) => _onError(e));
  }

  void _onError(error) {
    _logger.e(error);
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
