import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
  String localId;
  String path;
  String localPath;
  String thumbnailPath;
  String hash;
  int syncTimestamp;

  Photo();

  Photo.fromJson(Map<String, dynamic> json)
      : path = json["path"],
        hash = json["hash"],
        thumbnailPath = json["thumbnailPath"],
        syncTimestamp = json["syncTimestamp"];

  Photo.fromRow(Map<String, dynamic> row)
      : localId = row["local_id"],
        localPath = row["local_path"],
        thumbnailPath = row["thumbnail_path"],
        path = row["path"],
        hash = row["hash"],
        syncTimestamp = row["sync_timestamp"] == null
            ? -1
            : int.parse(row["sync_timestamp"]);

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    var file = (await asset.originFile);
    photo.localId = asset.id;
    photo.localPath = file.path;
    photo.hash = getHash(file);
    photo.thumbnailPath = file.path;
    return photo;
  }

  static String getHash(File file) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }
}
