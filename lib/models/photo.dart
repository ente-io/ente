import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class Photo {
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
      : localPath = row["local_path"],
        thumbnailPath = row["thumbnail_path"],
        path = row["path"],
        hash = row["hash"],
        syncTimestamp = row["sync_timestamp"] == null
            ? -1
            : int.parse(row["sync_timestamp"]);

  static Future<Photo> fromAsset(AssetEntity asset) async {
    Photo photo = Photo();
    var file = (await asset.originFile);
    photo.localPath = file.path;
    photo.hash = getHash(file);
    photo.thumbnailPath = file.path;
    return photo;
  }

  static Future<Photo> setThumbnail(Photo photo) async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    var thumbnailPath =
        externalPath + "/photos/thumbnails/" + photo.hash + ".thumbnail";
    var args = Map<String, String>();
    args["assetPath"] = photo.localPath;
    args["thumbnailPath"] = thumbnailPath;
    photo.thumbnailPath = thumbnailPath;
    return compute(getThumbnailPath, args).then((value) => photo);
  }

  static String getHash(File file) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }
}

Future<void> getThumbnailPath(Map<String, String> args) async {
  return File(args["thumbnailPath"])
    ..writeAsBytes(_getThumbnail(args["assetPath"]));
}

List<int> _getThumbnail(String path) {
  Image image = decodeImage(File(path).readAsBytesSync());
  return encodePng(copyResize(image, width: 250));
}
