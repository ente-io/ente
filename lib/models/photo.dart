import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
  String url;
  String localPath;
  String thumbnailPath;
  String hash;
  int syncTimestamp;

  Photo();

  Photo.fromJson(Map<String, dynamic> json)
      : url = json["url"],
        hash = json["hash"],
        syncTimestamp = json["syncTimestamp"];

  Photo.fromRow(Map<String, dynamic> row)
      : localPath = row["local_path"],
        thumbnailPath = row["thumbnail_path"],
        url = row["url"],
        hash = row["hash"],
        syncTimestamp = row["sync_timestamp"] == null
            ? -1
            : int.parse(row["sync_timestamp"]);

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    var file = (await asset.originFile);
    photo.localPath = file.path;
    photo.thumbnailPath = getThumbnailPath(file.path);
    photo.hash = getHash(file);
    return photo;
  }

  static String getHash(File file) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }

  static String getThumbnailPath(String path) {
    Image image = decodeImage(File(path).readAsBytesSync());
    Image thumbnail = copyResize(image, width: 150);
    String thumbnailPath = path + ".thumbnail";
    File(thumbnailPath)..writeAsBytesSync(encodePng(thumbnail));
    return thumbnailPath;
  }
}
