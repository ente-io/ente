import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class RemotePhoto {
  String photoID;
  int syncTimestamp;
  String url;

  RemotePhoto.fromJson(Map<String, dynamic> json)
      : photoID = json["photoID"],
        syncTimestamp = json["syncTimestamp"],
        url = json["url"];
}

class PhotoSyncManager {
  final logger = Logger();
  final dio = Dio();
  final endpoint = "http://192.168.0.106:8080";
  final user = "umbu";
  static final lastSyncTimestampKey = "last_sync_timestamp_0";

  PhotoSyncManager(List<AssetEntity> assets) {
    logger.i("PhotoSyncManager init");
    _syncPhotos(assets);
  }

  _syncPhotos(List<AssetEntity> assets) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastSyncTimestamp = prefs.getInt(lastSyncTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    logger.i("Last sync timestamp: " + lastSyncTimestamp.toString());

    await _downloadDiff(lastSyncTimestamp, prefs);

    await _uploadDiff(assets, prefs);

    // TODO:  Fix race conditions triggered due to concurrent syncs.
    //        Add device_id/last_sync_timestamp to the upload request?
  }

  Future _uploadDiff(List<AssetEntity> assets, SharedPreferences prefs) async {
    assets.sort((first, second) => second
        .modifiedDateTime.millisecondsSinceEpoch
        .compareTo(first.modifiedDateTime.millisecondsSinceEpoch));
    for (AssetEntity asset in assets) {
      DatabaseHelper.instance
          .containsPath((await asset.originFile).path)
          .then((containsPath) async {
        if (!containsPath) {
          var response = await _uploadFile(asset);
          prefs.setInt(lastSyncTimestampKey, response.syncTimestamp);
        }
      });
    }
  }

  Future _downloadDiff(int lastSyncTimestamp, SharedPreferences prefs) async {
    Response response = await dio.get(endpoint + "/diff", queryParameters: {
      "user": user,
      "lastSyncTimestamp": lastSyncTimestamp
    });
    var externalPath = (await getExternalStorageDirectory()).path;
    logger.i("External path: " + externalPath);
    var path = externalPath + "/photos/";

    List<RemotePhoto> photos = (response.data["diff"] as List)
        .map((photo) => new RemotePhoto.fromJson(photo))
        .toList();
    for (RemotePhoto photo in photos) {
      logger.i("Downloading " + endpoint + photo.url + " to " + path);
      await dio.download(endpoint + photo.url, path + basename(photo.url));
      prefs.setInt(lastSyncTimestampKey, photo.syncTimestamp);
      logger.i("Downloaded " + photo.url + " to " + path);
    }
  }

  Future<RemotePhoto> _uploadFile(AssetEntity entity) async {
    logger.i("Uploading: " + entity.id);
    var path = (await entity.originFile).path;
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(path, filename: entity.title),
      "user": user,
    });
    var response = await dio.post(endpoint + "/upload", data: formData);
    logger.i(response.toString());
    var remotePhoto = RemotePhoto.fromJson(response.data);
    // TODO: Compute hash
    DatabaseHelper.instance.insertPhoto(
        remotePhoto.photoID, path, "hash", remotePhoto.syncTimestamp);
    return remotePhoto;
  }
}
