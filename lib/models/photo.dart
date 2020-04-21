import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
  int generatedId;
  int uploadedFileId;
  String localId;
  String path;
  String localPath;
  String relativePath;
  String thumbnailPath;
  String hash;
  int createTimestamp;
  int syncTimestamp;

  Photo();

  Photo.fromJson(Map<String, dynamic> json)
      : uploadedFileId = json["fileId"],
        path = json["path"],
        hash = json["hash"],
        thumbnailPath = json["thumbnailPath"],
        createTimestamp = json["createTimestamp"],
        syncTimestamp = json["syncTimestamp"];

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    photo.uploadedFileId = -1;
    photo.localId = asset.id;
    var file = await asset.originFile;
    photo.localPath = file.path;
    if (Platform.isAndroid) {
      photo.relativePath = dirname((asset.relativePath.endsWith("/")
              ? asset.relativePath
              : asset.relativePath + "/") +
          asset.title);
    } else {
      photo.relativePath = dirname(photo.localPath);
    }
    photo.hash = getHash(file);
    photo.thumbnailPath = photo.localPath;
    photo.createTimestamp = asset.createDateTime.microsecondsSinceEpoch;
    return photo;
  }

  static String getHash(File file) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }

  int get hashCode => generatedId;

  @override
  bool operator ==(other) {
    return generatedId == other.generatedId;
  }
}
