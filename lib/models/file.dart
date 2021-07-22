import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';

class File {
  int generatedID;
  int uploadedFileID;
  int ownerID;
  int collectionID;
  String localID;
  String title;
  String deviceFolder;
  int creationTime;
  int modificationTime;
  int updationTime;
  Location location;
  FileType fileType;
  String encryptedKey;
  String keyDecryptionNonce;
  String fileDecryptionHeader;
  String thumbnailDecryptionHeader;
  String metadataDecryptionHeader;

  File();

  static Future<File> fromAsset(String pathName, AssetEntity asset) async {
    File file = File();
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = pathName;
    file.location = Location(asset.latitude, asset.longitude);
    switch (asset.type) {
      case AssetType.image:
        file.fileType = FileType.image;
        break;
      case AssetType.video:
        file.fileType = FileType.video;
        break;
      default:
        file.fileType = FileType.other;
        break;
    }
    file.creationTime = asset.createDateTime.microsecondsSinceEpoch;
    if (file.creationTime == 0) {
      try {
        final parsedDateTime = DateTime.parse(
            basenameWithoutExtension(file.title)
                .replaceAll("IMG_", "")
                .replaceAll("DCIM_", "")
                .replaceAll("_", " "));
        file.creationTime = parsedDateTime.microsecondsSinceEpoch;
      } catch (e) {
        file.creationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
      }
    }
    file.modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    return file;
  }

  Future<AssetEntity> getAsset() {
    return AssetEntity.fromId(localID);
  }

  void applyMetadata(Map<String, dynamic> metadata) {
    localID = metadata["localID"];
    title = metadata["title"];
    deviceFolder = metadata["deviceFolder"];
    creationTime = metadata["creationTime"] ?? 0;
    modificationTime = metadata["modificationTime"] ?? creationTime;
    final latitude = double.tryParse(metadata["latitude"].toString());
    final longitude = double.tryParse(metadata["longitude"].toString());
    if (latitude == null || longitude == null) {
      location = null;
    } else {
      location = Location(latitude, longitude);
    }
    fileType = getFileType(metadata["fileType"]);
  }

  Map<String, dynamic> getMetadata() {
    final metadata = Map<String, dynamic>();
    metadata["localID"] = isCachedInAppSandbox() ? null : localID;
    metadata["title"] = title;
    metadata["deviceFolder"] = deviceFolder;
    metadata["creationTime"] = creationTime;
    metadata["modificationTime"] = modificationTime;
    if (location != null &&
        location.latitude != null &&
        location.longitude != null) {
      metadata["latitude"] = location.latitude;
      metadata["longitude"] = location.longitude;
    }
    metadata["fileType"] = fileType.index;
    return metadata;
  }

  String getDownloadUrl() {
    if (kDebugMode) {
      return Configuration.instance.getHttpEndpoint() +
          "/files/download/" +
          uploadedFileID.toString();
    } else {
      return "https://files.ente.workers.dev/?fileID=" +
          uploadedFileID.toString();
    }
  }

  // Passing token within the URL due to https://github.com/flutter/flutter/issues/16466
  String getStreamUrl() {
    return Configuration.instance.getHttpEndpoint() +
        "/streams/" +
        Configuration.instance.getToken() +
        "/" +
        uploadedFileID.toString() +
        "/index.m3u8";
  }

  String getThumbnailUrl() {
    if (kDebugMode) {
      return Configuration.instance.getHttpEndpoint() +
          "/files/preview/" +
          uploadedFileID.toString();
    } else {
      return "https://thumbnails.ente.workers.dev/?fileID=" +
          uploadedFileID.toString();
    }
  }

  // returns true if the file isn't available in the user's gallery
  bool isRemoteFile() {
    return localID == null && uploadedFileID != null;
  }

  bool isCachedInAppSandbox() {
    return localID != null && localID.startsWith("ente-upload-cache");
  }

  @override
  String toString() {
    return '''File(generatedId: $generatedID, uploadedFileId: $uploadedFileID, 
      localID: $localID, ownerID: $ownerID, collectionID: $collectionID,
      fileType: $fileType, creationTime: $creationTime, 
      modificationTime: $modificationTime, updationTime: $updationTime)''';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is File &&
        o.generatedID == generatedID &&
        o.uploadedFileID == uploadedFileID &&
        o.localID == localID;
  }

  @override
  int get hashCode {
    return generatedID.hashCode ^ uploadedFileID.hashCode ^ localID.hashCode;
  }

  String tag() {
    return "local_" +
        localID.toString() +
        ":remote_" +
        uploadedFileID.toString() +
        ":generated_" +
        generatedID.toString();
  }
}
