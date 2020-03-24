import 'package:logger/logger.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class PhotoSyncManager {
  final logger = Logger();
  final dio = Dio();
  final uploadUrl = "http://192.168.0.106:8080/upload";
  static final lastUploadedItemTimestampKey = "last_uploaded_item_timestamp_5";

  PhotoSyncManager(List<AssetEntity> assets) {
    logger.i("PhotoSyncManager init");
    _syncPhotos(assets);
  }

  _syncPhotos(List<AssetEntity> assets) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastSyncTimestamp = prefs.getInt(lastUploadedItemTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    logger.i("Last sync timestamp: " + lastSyncTimestamp.toString());
    assets.sort((a, b) => a.modifiedDateTime.millisecondsSinceEpoch
        .compareTo(b.modifiedDateTime.millisecondsSinceEpoch));
    for (AssetEntity asset in assets) {
      if (asset.modifiedDateTime.millisecondsSinceEpoch > lastSyncTimestamp) {
        var response = await _uploadFile(asset);
        if (response.statusCode == 200) {
          prefs.setInt(lastUploadedItemTimestampKey,
              asset.modifiedDateTime.millisecondsSinceEpoch);
          logger.i("Updated for: " + asset.id);
        }
      }
    }
  }

  Future<Response<Object>> _uploadFile(AssetEntity entity) async {
    logger.i("Uploading: " + entity.id);
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile((await entity.originFile).path,
          filename: entity.title),
      "user": "umbu",
      "timestamp": entity.modifiedDateTime.millisecondsSinceEpoch
    });
    var response = await dio.post(uploadUrl, data: formData);
    logger.i(response.toString());
    return response;
  }
}
