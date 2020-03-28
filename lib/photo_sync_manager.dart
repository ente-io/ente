import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/photo_loader.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:myapp/models/photo.dart';

class PhotoSyncManager {
  final _logger = Logger();
  final _dio = Dio();
  final _endpoint = "http://192.168.0.106:8080";
  final _user = "umbu";
  final List<AssetEntity> _assets;
  static final _lastSyncTimestampKey = "last_sync_timestamp_0";
  static final _lastDBUpdateTimestampKey = "last_db_update_timestamp";

  PhotoSyncManager(this._assets) {
    _logger.i("PhotoSyncManager init");
    _assets.sort((first, second) => second
        .modifiedDateTime.millisecondsSinceEpoch
        .compareTo(first.modifiedDateTime.millisecondsSinceEpoch));
  }

  Future<void> init() async {
    await _updateDatabase();
    try {
      _syncPhotos();
    } catch (e) {
      _logger.e(e);
    }
  }

  Future<bool> _updateDatabase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastDBUpdateTimestamp = prefs.getInt(_lastDBUpdateTimestampKey);
    if (lastDBUpdateTimestamp == null) {
      lastDBUpdateTimestamp = 0;
    }
    for (AssetEntity asset in _assets) {
      if (asset.createDateTime.millisecondsSinceEpoch > lastDBUpdateTimestamp) {
        await DatabaseHelper.instance.insertPhoto(await Photo.fromAsset(asset));
      }
    }
    return await prefs.setInt(
        _lastDBUpdateTimestampKey, DateTime.now().millisecondsSinceEpoch);
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
    var uploadedCount = 0;
    List<Photo> photosToBeUploaded =
        await DatabaseHelper.instance.getPhotosToBeUploaded();
    for (Photo photo in photosToBeUploaded) {
      // TODO: Fix me
      if (uploadedCount == 100) {
        return;
      }
      var uploadedPhoto = await _uploadFile(photo.localPath, photo.hash);
      await DatabaseHelper.instance.updateUrlAndTimestamp(photo.hash,
          uploadedPhoto.url, uploadedPhoto.syncTimestamp.toString());
      prefs.setInt(_lastSyncTimestampKey, uploadedPhoto.syncTimestamp);
      uploadedCount++;
    }
  }

  Future _downloadDiff(List<Photo> diff, SharedPreferences prefs) async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    _logger.i("External path: " + externalPath);
    var path = externalPath + "/photos/";
    for (Photo photo in diff) {
      if (await DatabaseHelper.instance.containsPhotoHash(photo.hash)) {
        await DatabaseHelper.instance.updateUrlAndTimestamp(
            photo.hash, photo.url, photo.syncTimestamp.toString());
        continue;
      } else {
        var localPath = path + basename(photo.url);
        await _dio.download(_endpoint + photo.url, localPath);
        photo.localPath = localPath;
        await insertPhotoToDB(photo);
      }
      await prefs.setInt(_lastSyncTimestampKey, photo.syncTimestamp);
    }
  }

  Future<List<Photo>> _getDiff(int lastSyncTimestamp) async {
    Response response = await _dio.get(_endpoint + "/diff", queryParameters: {
      "user": _user,
      "lastSyncTimestamp": lastSyncTimestamp
    });
    _logger.i(response.toString());
    return (response.data["diff"] as List)
        .map((photo) => new Photo.fromJson(photo))
        .toList();
  }

  Future<Photo> _uploadFile(String path, String hash) async {
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(path, filename: basename(path)),
      "user": _user,
    });
    var response = await _dio.post(_endpoint + "/upload", data: formData);
    _logger.i(response.toString());
    var photo = Photo.fromJson(response.data);
    _logger.i("Locally computed hash for " + path + ": " + hash);
    _logger.i("Server computed hash for " + path + ": " + photo.hash);
    photo.localPath = path;
    return photo;
  }

  Future<void> insertPhotoToDB(Photo photo) async {
    _logger.i("Inserting to DB");
    await DatabaseHelper.instance.insertPhoto(photo);
    PhotoLoader.instance.reloadPhotos();
  }
}
