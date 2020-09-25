import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/decryption_params.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';

class File {
  int generatedID;
  int uploadedFileID;
  int ownerID;
  String localID;
  String title;
  String deviceFolder;
  int remoteFolderID;
  bool isEncrypted;
  int creationTime;
  int modificationTime;
  int updationTime;
  Location location;
  FileType fileType;
  DecryptionParams fileDecryptionParams;
  DecryptionParams thumbnailDecryptionParams;
  DecryptionParams metadataDecryptionParams;

  File();

  File.fromJson(Map<String, dynamic> json) {
    uploadedFileID = json["id"];
    ownerID = json["ownerID"];
    localID = json["deviceFileID"];
    deviceFolder = json["deviceFolder"];
    title = json["title"];
    fileType = getFileType(json["fileType"]);
    creationTime = json["creationTime"];
    modificationTime = json["modificationTime"];
    updationTime = json["updationTime"];
  }

  static Future<File> fromAsset(
      AssetPathEntity pathEntity, AssetEntity asset) async {
    File file = File();
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = pathEntity.name;
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
    file.isEncrypted = false;
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
    creationTime = metadata["creationTime"];
    modificationTime = metadata["modificationTime"];
    final latitude = metadata["latitude"];
    final longitude = metadata["longitude"];
    location = Location(latitude, longitude);
    fileType = getFileType(metadata["fileType"]);
  }

  Map<String, dynamic> getMetadata() {
    final metadata = Map<String, dynamic>();
    metadata["localID"] = localID;
    metadata["title"] = title;
    metadata["deviceFolder"] = deviceFolder;
    metadata["creationTime"] = creationTime;
    metadata["modificationTime"] = modificationTime;
    metadata["latitude"] = location.latitude;
    metadata["longitude"] = location.longitude;
    metadata["fileType"] = fileType.index;
    return metadata;
  }

  String getDownloadUrl() {
    final api = isEncrypted ? "encrypted-files" : "files";
    return Configuration.instance.getHttpEndpoint() +
        "/" +
        api +
        "/download/" +
        uploadedFileID.toString() +
        "?token=" +
        Configuration.instance.getToken();
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
    final api = isEncrypted ? "encrypted-files" : "files";
    return Configuration.instance.getHttpEndpoint() +
        "/" +
        api +
        "/preview/" +
        uploadedFileID.toString() +
        "?token=" +
        Configuration.instance.getToken();
  }

  @override
  String toString() {
    return '''File(generatedId: $generatedID, uploadedFileId: $uploadedFileID, 
      localId: $localID, title: $title, deviceFolder: $deviceFolder, 
      location: $location, fileType: $fileType, creationTime: $creationTime, 
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
