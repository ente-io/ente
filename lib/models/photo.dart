import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
  int uploadedFileId;
  String localId;
  String path;
  String localPath;
  String thumbnailPath;
  String hash;
  int syncTimestamp;

  Photo();

  Photo.fromJson(Map<String, dynamic> json)
      : uploadedFileId = json["fileId"],
        path = json["path"],
        hash = json["hash"],
        thumbnailPath = json["thumbnailPath"],
        syncTimestamp = json["syncTimestamp"];

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    var file = (await asset.originFile);
    photo.uploadedFileId = -1;
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
