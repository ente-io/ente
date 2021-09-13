import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'dart:io' as io;

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
  int fileSubType;
  int duration;
  String exif;
  String hash;
  int metadataVersion;
  String encryptedKey;
  String keyDecryptionNonce;
  String fileDecryptionHeader;
  String thumbnailDecryptionHeader;
  String metadataDecryptionHeader;

  static const kCurrentMetadataVersion = 1;

  File();

  static Future<File> fromAsset(String pathName, AssetEntity asset) async {
    File file = File();
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = pathName;
    file.location = Location(asset.latitude, asset.longitude);
    file.fileType = _fileTypeFromAsset(asset);
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
    file.fileSubType = asset.subTypes;
    file.metadataVersion = kCurrentMetadataVersion;
    return file;
  }

  static FileType _fileTypeFromAsset(AssetEntity asset) {
    FileType type = FileType.image;
    switch (asset.type) {
      case AssetType.image:
        type = FileType.image;
        // PHAssetMediaSubtype.photoLive.rawValue is 8
        // This hack should go away once photos_manager support livePhotos
        if (asset.subTypes != null &&
            asset.subTypes > -1 &&
            (asset.subTypes & 8) != 0) {
          type = FileType.livePhoto;
        }
        break;
      case AssetType.video:
        type = FileType.video;
        break;
      default:
        type = FileType.other;
        break;
    }
    return type;
  }

  Future<AssetEntity> getAsset() {
    if (localID == null) {
      return Future.value(null);
    }
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
    fileSubType = metadata["subType"] ?? -1;
    duration = metadata["duration"] ?? 0;
    exif = metadata["exif"];
    hash = metadata["hash"];
    metadataVersion = metadata["version"] ?? 0;
  }

  Future<Map<String, dynamic>> getMetadata(io.File sourceFile) async {
    final metadata = <String, dynamic>{};
    metadata["localID"] = isSharedMediaToAppSandbox() ? null : localID;
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
    final asset = await getAsset();
    // asset can be null for files shared to app
    if (asset != null) {
      fileSubType = asset.subTypes;
      metadata["subType"] = fileSubType;
      if (fileType == FileType.video) {
        duration = asset.duration;
        metadata["duration"] = duration;
      }
    }
    hash = Sodium.bin2base64(await CryptoUtil.getHash(sourceFile));
    metadata["hash"] = hash;
    metadata["version"] = metadataVersion;
    return metadata;
  }

  String getDownloadUrl() {
    if (kDebugMode || FeatureFlagService.instance.disableCFWorker()) {
      return Configuration.instance.getHttpEndpoint() +
          "/files/download/" +
          uploadedFileID.toString();
    } else {
      return "https://files.ente.workers.dev/?fileID=" +
          uploadedFileID.toString();
    }
  }

  String getThumbnailUrl() {
    if (kDebugMode || FeatureFlagService.instance.disableCFWorker()) {
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

  bool isSharedMediaToAppSandbox() {
    return localID != null && localID.startsWith(kSharedMediaIdentifier);
  }

  bool hasLocation() {
    return location != null &&
        (location.longitude != 0 || location.latitude != 0);
  }

  @override
  String toString() {
    return '''File(generatedID: $generatedID, localID: $localID, 
      uploadedFileId: $uploadedFileID, modificationTime: $modificationTime, 
      ownerID: $ownerID, collectionID: $collectionID, updationTime: $updationTime)''';
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
