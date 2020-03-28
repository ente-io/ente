import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
  String url;
  String localPath;
  String hash;
  int syncTimestamp;

  Photo();

  Photo.fromJson(Map<String, dynamic> json)
      : url = json["url"],
        hash = json["hash"],
        syncTimestamp = json["syncTimestamp"];

  Photo.fromRow(Map<String, dynamic> row)
      : localPath = row["local_path"],
        url = row["url"],
        hash = row["hash"],
        syncTimestamp = row["sync_timestamp"] == null
            ? -1
            : int.parse(row["sync_timestamp"]);

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    var file = (await asset.originFile);
    photo.localPath = file.path;
    photo.hash = getHash(file);
    return photo;
  }

  static String getHash(File file) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }
}
