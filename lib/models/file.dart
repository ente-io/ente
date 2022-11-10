import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/ente_file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/magic_metadata.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/utils/date_time_util.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/utils/exif_util.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/utils/file_uploader_util.dart';

class File extends EnteFile {
  int? generatedID;
  int? uploadedFileID;
  int? ownerID;
  int? collectionID;
  String? localID;
  String? title;
  String? deviceFolder;
  int? creationTime;
  int? modificationTime;
  int? updationTime;
  Location? location;
  late FileType fileType;
  int? fileSubType;
  int? duration;
  String? exif;
  String? hash;
  int? metadataVersion;
  String? encryptedKey;
  String? keyDecryptionNonce;
  String? fileDecryptionHeader;
  String? thumbnailDecryptionHeader;
  String? metadataDecryptionHeader;
  int? fileSize;

  String? mMdEncodedJson;
  int mMdVersion = 0;
  MagicMetadata? _mmd;

  MagicMetadata get magicMetadata =>
      _mmd ?? MagicMetadata.fromEncodedJson(mMdEncodedJson ?? '{}');

  set magicMetadata(val) => _mmd = val;

  // public magic metadata is shared if during file/album sharing
  String? pubMmdEncodedJson;
  int pubMmdVersion = 0;
  PubMagicMetadata? _pubMmd;

  PubMagicMetadata? get pubMagicMetadata =>
      _pubMmd ?? PubMagicMetadata.fromEncodedJson(pubMmdEncodedJson ?? '{}');

  set pubMagicMetadata(val) => _pubMmd = val;

  // in Version 1, live photo hash is stored as zip's hash.
  // in V2: LivePhoto hash is stored as imgHash:vidHash
  static const kCurrentMetadataVersion = 2;

  static final _logger = Logger('File');

  File();

  static Future<File> fromAsset(String pathName, AssetEntity asset) async {
    final File file = File();
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = pathName;
    file.location = Location(asset.latitude, asset.longitude);
    file.fileType = _fileTypeFromAsset(asset);
    file.creationTime = fileCreationTime(file.title, asset);
    file.modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    file.fileSubType = asset.subtype;
    file.metadataVersion = kCurrentMetadataVersion;
    return file;
  }

  static int fileCreationTime(String? fileTitle, AssetEntity asset) {
    int creationTime = asset.createDateTime.microsecondsSinceEpoch;
    if (creationTime >= jan011981Time) {
      // assuming that fileSystem is returning correct creationTime.
      // During upload, this might get overridden with exif Creation time
      return creationTime;
    } else {
      if (asset.modifiedDateTime.microsecondsSinceEpoch >= jan011981Time) {
        creationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
      } else {
        creationTime = DateTime.now().toUtc().microsecondsSinceEpoch;
      }
      try {
        final parsedDateTime = parseDateTimeFromFileNameV2(
          basenameWithoutExtension(fileTitle ?? ""),
        );
        if (parsedDateTime != null) {
          creationTime = parsedDateTime.microsecondsSinceEpoch;
        }
      } catch (e) {
        // ignore
      }
    }

    return creationTime;
  }

  static FileType _fileTypeFromAsset(AssetEntity asset) {
    FileType type = FileType.image;
    switch (asset.type) {
      case AssetType.image:
        type = FileType.image;
        // PHAssetMediaSubtype.photoLive.rawValue is 8
        // This hack should go away once photos_manager support livePhotos
        if (asset.subtype > -1 && (asset.subtype & 8) != 0) {
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

  Future<AssetEntity?> get getAsset {
    if (localID == null) {
      return Future.value(null);
    }
    return AssetEntity.fromId(localID!);
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
    // handle past live photos upload from web client
    if (hash == null &&
        fileType == FileType.livePhoto &&
        metadata.containsKey('imgHash') &&
        metadata.containsKey('vidHash')) {
      // convert to imgHash:vidHash
      hash =
          '${metadata['imgHash']}$kLivePhotoHashSeparator${metadata['vidHash']}';
    }
    metadataVersion = metadata["version"] ?? 0;
  }

  Future<Map<String, dynamic>> getMetadataForUpload(
    MediaUploadData mediaUploadData,
  ) async {
    final asset = await getAsset;
    // asset can be null for files shared to app
    if (asset != null) {
      fileSubType = asset.subtype;
      if (fileType == FileType.video) {
        duration = asset.duration;
      }
    }
    if (fileType == FileType.image && mediaUploadData.sourceFile != null) {
      final exifTime =
          await getCreationTimeFromEXIF(mediaUploadData.sourceFile!);
      if (exifTime != null) {
        creationTime = exifTime.microsecondsSinceEpoch;
      }
    }
    hash = mediaUploadData.hashData?.fileHash;
    return metadata;
  }

  Map<String, dynamic> get metadata {
    final metadata = <String, dynamic>{};
    metadata["localID"] = isSharedMediaToAppSandbox ? null : localID;
    metadata["title"] = title;
    metadata["deviceFolder"] = deviceFolder;
    metadata["creationTime"] = creationTime;
    metadata["modificationTime"] = modificationTime;
    metadata["fileType"] = fileType.index;
    if (location != null &&
        location!.latitude != null &&
        location!.longitude != null) {
      metadata["latitude"] = location!.latitude;
      metadata["longitude"] = location!.longitude;
    }
    if (fileSubType != null) {
      metadata["subType"] = fileSubType;
    }
    if (duration != null) {
      metadata["duration"] = duration;
    }
    if (hash != null) {
      metadata["hash"] = hash;
    }
    if (metadataVersion != null) {
      metadata["version"] = metadataVersion;
    }
    return metadata;
  }

  String get downloadUrl {
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint ||
        FeatureFlagService.instance.disableCFWorker()) {
      return endpoint + "/files/download/" + uploadedFileID.toString();
    } else {
      return "https://files.ente.io/?fileID=" + uploadedFileID.toString();
    }
  }

  String? get caption {
    return pubMagicMetadata?.caption;
  }

  String get thumbnailUrl {
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint ||
        FeatureFlagService.instance.disableCFWorker()) {
      return endpoint + "/files/preview/" + uploadedFileID.toString();
    } else {
      return "https://thumbnails.ente.io/?fileID=" + uploadedFileID.toString();
    }
  }

  String get displayName {
    if (pubMagicMetadata != null && pubMagicMetadata!.editedName != null) {
      return pubMagicMetadata!.editedName!;
    }
    if (title == null) _logger.severe('File title is null');
    return title ?? '';
  }

  // returns true if the file isn't available in the user's gallery
  bool get isRemoteFile {
    return localID == null && uploadedFileID != null;
  }

  bool get isSharedMediaToAppSandbox {
    return localID != null &&
        (localID!.startsWith(oldSharedMediaIdentifier) ||
            localID!.startsWith(sharedMediaIdentifier));
  }

  bool get hasLocation {
    return location != null &&
        (location!.longitude != 0 || location!.latitude != 0);
  }

  @override
  String toString() {
    return '''File(generatedID: $generatedID, localID: $localID, title: $title, 
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

  String get tag {
    return "local_" +
        localID.toString() +
        ":remote_" +
        uploadedFileID.toString() +
        ":generated_" +
        generatedID.toString();
  }

  @override
  String cacheKey() {
    // todo: Neeraj: 19thJuly'22: evaluate and add fileHash as the key?
    return localID ?? uploadedFileID?.toString() ?? generatedID.toString();
  }
}
