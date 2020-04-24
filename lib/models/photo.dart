import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart';

class Photo {
  int generatedId;
  int uploadedFileId;
  String localId;
  String title;
  String pathName;
  String remotePath;
  int createTimestamp;
  int syncTimestamp;

  Photo();
  Photo.fromJson(Map<String, dynamic> json)
      : uploadedFileId = json["fileId"],
        remotePath = json["path"],
        createTimestamp = json["createTimestamp"],
        syncTimestamp = json["syncTimestamp"];

  static Future<Photo> fromAsset(
      AssetPathEntity pathEntity, AssetEntity asset) async {
    Photo photo = Photo();
    photo.uploadedFileId = -1;
    photo.localId = asset.id;
    photo.title = asset.title;
    photo.pathName = pathEntity.name;
    photo.createTimestamp = asset.createDateTime.microsecondsSinceEpoch;
    return photo;
  }

  Future<Uint8List> getBytes() {
    final asset = AssetEntity(id: localId);
    if (extension(title) == ".HEIC") {
      return asset.originBytes.then((bytes) =>
          FlutterImageCompress.compressWithList(bytes)
              .then((result) => Uint8List.fromList(result)));
    } else {
      return asset.originBytes;
    }
  }

  Future<Uint8List> getOriginalBytes() {
    return AssetEntity(id: localId).originBytes;
  }

  @override
  String toString() {
    return 'Photo(generatedId: $generatedId, uploadedFileId: $uploadedFileId, localId: $localId, title: $title, pathName: $pathName, remotePath: $remotePath, createTimestamp: $createTimestamp, syncTimestamp: $syncTimestamp)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Photo &&
        o.generatedId == generatedId &&
        o.uploadedFileId == uploadedFileId &&
        o.localId == localId &&
        o.title == title &&
        o.pathName == pathName &&
        o.remotePath == remotePath &&
        o.createTimestamp == createTimestamp &&
        o.syncTimestamp == syncTimestamp;
  }

  @override
  int get hashCode {
    return generatedId.hashCode ^
        uploadedFileId.hashCode ^
        localId.hashCode ^
        title.hashCode ^
        pathName.hashCode ^
        remotePath.hashCode ^
        createTimestamp.hashCode ^
        syncTimestamp.hashCode;
  }
}
