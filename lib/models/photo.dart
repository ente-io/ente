import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';

class Photo {
  int generatedId;
  int uploadedFileId;
  String localId;
  String title;
  String deviceFolder;
  int remoteFolderId;
  String remotePath;
  String thumbnailPath;
  int createTimestamp;
  int updateTimestamp;

  Photo();
  Photo.fromJson(Map<String, dynamic> json)
      : uploadedFileId = json["fileID"],
        localId = json["deviceFileID"],
        deviceFolder = json["deviceFolder"],
        title = json["title"],
        remotePath = json["path"],
        thumbnailPath = json["previewURL"],
        createTimestamp = json["createTimestamp"],
        updateTimestamp = json["updateTimestamp"];

  static Future<Photo> fromAsset(
      AssetPathEntity pathEntity, AssetEntity asset) async {
    Photo photo = Photo();
    photo.uploadedFileId = -1;
    photo.localId = asset.id;
    photo.title = asset.title;
    photo.deviceFolder = pathEntity.name;
    photo.createTimestamp = asset.createDateTime.microsecondsSinceEpoch;
    if (photo.createTimestamp == 0) {
      try {
        final parsedDateTime = DateTime.parse(
            basenameWithoutExtension(photo.title)
                .replaceAll("IMG_", "")
                .replaceAll("DCIM_", "")
                .replaceAll("_", " "));
        photo.createTimestamp = parsedDateTime.microsecondsSinceEpoch;
      } catch (e) {
        photo.createTimestamp = asset.modifiedDateTime.microsecondsSinceEpoch;
      }
    }
    return photo;
  }

  AssetEntity getAsset() {
    return AssetEntity(id: localId);
  }

  Future<Uint8List> getBytes({int quality = 100}) {
    final asset = getAsset();
    if (extension(title) == ".HEIC" || quality != 100) {
      return asset.originBytes.then((bytes) =>
          FlutterImageCompress.compressWithList(bytes, quality: quality)
              .then((result) => Uint8List.fromList(result)));
    } else {
      return asset.originBytes;
    }
  }

  String getRemoteUrl() {
    return Configuration.instance.getHttpEndpoint() + "/" + remotePath;
  }

  String getThumbnailUrl() {
    return Configuration.instance.getHttpEndpoint() + "/" + thumbnailPath;
  }

  Future<Uint8List> getOriginalBytes() {
    return getAsset().originBytes;
  }

  @override
  String toString() {
    return 'Photo(generatedId: $generatedId, uploadedFileId: $uploadedFileId, localId: $localId, title: $title, deviceFolder: $deviceFolder, remotePath: $remotePath, createTimestamp: $createTimestamp, updateTimestamp: $updateTimestamp)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Photo &&
        o.generatedId == generatedId &&
        o.uploadedFileId == uploadedFileId &&
        o.localId == localId &&
        o.title == title &&
        o.deviceFolder == deviceFolder &&
        o.remotePath == remotePath &&
        o.createTimestamp == createTimestamp &&
        o.updateTimestamp == updateTimestamp;
  }

  @override
  int get hashCode {
    return generatedId.hashCode ^
        uploadedFileId.hashCode ^
        localId.hashCode ^
        title.hashCode ^
        deviceFolder.hashCode ^
        remotePath.hashCode ^
        createTimestamp.hashCode ^
        updateTimestamp.hashCode;
  }
}
