import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/location/location.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/service_locator.dart";
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/exif_util.dart';
import 'package:photos/utils/file_uploader_util.dart';
import "package:photos/utils/panorama_util.dart";

//Todo: files with no location data have lat and long set to 0.0. This should ideally be null.
class EnteFile {
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
  int? addedTime;
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

  EnteFile();

  static Future<EnteFile> fromAsset(String pathName, AssetEntity asset) async {
    final EnteFile file = EnteFile();
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = pathName;
    file.location =
        Location(latitude: asset.latitude, longitude: asset.longitude);
    file.fileType = fileTypeFromAsset(asset);
    file.creationTime = parseFileCreationTime(file.title, asset);
    file.modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    file.fileSubType = asset.subtype;
    file.metadataVersion = kCurrentMetadataVersion;
    return file;
  }

  static int parseFileCreationTime(String? fileTitle, AssetEntity asset) {
    int creationTime = asset.createDateTime.microsecondsSinceEpoch;
    final int modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    if (creationTime >= jan011981Time) {
      // assuming that fileSystem is returning correct creationTime.
      // During upload, this might get overridden with exif Creation time
      // When the assetModifiedTime is less than creationTime, than just use
      // that as creationTime. This is to handle cases where file might be
      // copied to the fileSystem from somewhere else See #https://superuser.com/a/1091147
      if (modificationTime >= jan011981Time &&
          modificationTime < creationTime) {
        _logger.info(
          'LocalID: ${asset.id} modification time is less than creation time. Using modification time as creation time',
        );
        creationTime = modificationTime;
      }
      return creationTime;
    } else {
      if (modificationTime >= jan011981Time) {
        creationTime = modificationTime;
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
      location = Location(latitude: latitude, longitude: longitude);
    }
    fileType = getFileType(metadata["fileType"] ?? -1);
    fileSubType = metadata["subType"] ?? -1;
    duration = metadata["duration"] ?? 0;
    exif = metadata["exif"];
    hash = metadata["hash"];
    // handle past live photos upload from web client
    if (hash == null &&
        fileType == FileType.livePhoto &&
        metadata.containsKey('imageHash') &&
        metadata.containsKey('videoHash')) {
      // convert to imgHash:vidHash
      hash =
          '${metadata['imageHash']}$kLivePhotoHashSeparator${metadata['videoHash']}';
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
    bool hasExifTime = false;
    if ((fileType == FileType.image || fileType == FileType.video) &&
        mediaUploadData.sourceFile != null) {
      final exifData = await getExifFromSourceFile(mediaUploadData.sourceFile!);
      if (exifData != null) {
        if (fileType == FileType.image) {
          final exifTime = await getCreationTimeFromEXIF(null, exifData);
          if (exifTime != null) {
            hasExifTime = true;
            creationTime = exifTime.microsecondsSinceEpoch;
          }
          mediaUploadData.isPanorama = checkPanoramaFromEXIF(null, exifData);

          if (mediaUploadData.isPanorama != true) {
            try {
              final xmpData = await getXmp(mediaUploadData.sourceFile!);
              mediaUploadData.isPanorama = checkPanoramaFromXMP(xmpData);
            } catch (_) {}

            mediaUploadData.isPanorama ??= false;
          }
        }
        if (Platform.isAndroid) {
          //Fix for missing location data in lower android versions.
          final Location? exifLocation = locationFromExif(exifData);
          if (Location.isValidLocation(exifLocation)) {
            location = exifLocation;
          }
        }
      }
    }
    // Try to get the timestamp from fileName. In case of iOS, file names are
    // generic IMG_XXXX, so only parse it on Android devices
    if (!hasExifTime && Platform.isAndroid && title != null) {
      final timeFromFileName = parseDateTimeFromFileNameV2(title!);
      if (timeFromFileName != null) {
        // only use timeFromFileName if the existing creationTime and
        // timeFromFilename belongs to different date.
        // This is done because many times the fileTimeStamp will only give us
        // the date, not time value but the photo_manager's creation time will
        // contain the time.
        final bool useFileTimeStamp = creationTime == null ||
            !areFromSameDay(
              creationTime!,
              timeFromFileName.microsecondsSinceEpoch,
            );
        if (useFileTimeStamp) {
          creationTime = timeFromFileName.microsecondsSinceEpoch;
        }
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
    if (localFileServer.isNotEmpty) {
      return "$localFileServer/$uploadedFileID";
    }
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint || flagService.disableCFWorker) {
      return endpoint + "/files/download/" + uploadedFileID.toString();
    } else {
      return "https://files.ente.io/?fileID=" + uploadedFileID.toString();
    }
  }

  String get publicDownloadUrl {
    if (localFileServer.isNotEmpty) {
      return "$localFileServer/$uploadedFileID";
    }
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint || flagService.disableCFWorker) {
      return endpoint +
          "/public-collection/files/download/" +
          uploadedFileID.toString();
    } else {
      return "https://public-albums.ente.io/download/?fileID=" +
          uploadedFileID.toString();
    }
  }

  String get pubPreviewUrl {
    if (localFileServer.isNotEmpty) {
      return "$localFileServer/thumb/$uploadedFileID";
    }
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint || flagService.disableCFWorker) {
      return endpoint +
          "/public-collection/files/preview/" +
          uploadedFileID.toString();
    } else {
      return "https://public-albums.ente.io/preview/?fileID=" +
          uploadedFileID.toString();
    }
  }

  String? get caption {
    return pubMagicMetadata?.caption;
  }

  String? debugCaption;

  String get thumbnailUrl {
    if (localFileServer.isNotEmpty) {
      return "$localFileServer/thumb/$uploadedFileID";
    }
    final endpoint = Configuration.instance.getHttpEndpoint();
    if (endpoint != kDefaultProductionEndpoint || flagService.disableCFWorker) {
      return endpoint + "/files/preview/" + uploadedFileID.toString();
    } else {
      return "https://thumbnails.ente.io/?fileID=" + uploadedFileID.toString();
    }
  }

  String get displayName {
    if (pubMagicMetadata != null && pubMagicMetadata!.editedName != null) {
      return pubMagicMetadata!.editedName!;
    }
    if (title == null && kDebugMode) _logger.severe('File title is null');
    return title ?? '';
  }

  // return 0 if the height is not available
  int get height {
    return pubMagicMetadata?.h ?? 0;
  }

  int get width {
    return pubMagicMetadata?.w ?? 0;
  }

  bool get hasDimensions {
    return height != 0 && width != 0;
  }

  // returns true if the file isn't available in the user's gallery
  bool get isRemoteFile {
    return localID == null && uploadedFileID != null;
  }

  bool get isUploaded {
    return uploadedFileID != null;
  }

  bool get isSharedMediaToAppSandbox {
    return localID != null &&
        (localID!.startsWith(oldSharedMediaIdentifier) ||
            localID!.startsWith(sharedMediaIdentifier));
  }

  bool get hasLocation {
    return location != null &&
        ((location!.longitude ?? 0) != 0 || (location!.latitude ?? 0) != 0);
  }

  @override
  String toString() {
    return '''File(generatedID: $generatedID, localID: $localID, title: $title, 
      type: $fileType, uploadedFileId: $uploadedFileID, modificationTime: $modificationTime, 
      ownerID: $ownerID, collectionID: $collectionID, updationTime: $updationTime)''';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is EnteFile &&
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

  String cacheKey() {
    // todo: Neeraj: 19thJuly'22: evaluate and add fileHash as the key?
    return localID ?? uploadedFileID?.toString() ?? generatedID.toString();
  }

  EnteFile copyWith({
    int? generatedID,
    int? uploadedFileID,
    int? ownerID,
    int? collectionID,
    String? localID,
    String? title,
    String? deviceFolder,
    int? creationTime,
    int? modificationTime,
    int? updationTime,
    int? addedTime,
    Location? location,
    FileType? fileType,
    int? fileSubType,
    int? duration,
    String? exif,
    String? hash,
    int? metadataVersion,
    String? encryptedKey,
    String? keyDecryptionNonce,
    String? fileDecryptionHeader,
    String? thumbnailDecryptionHeader,
    String? metadataDecryptionHeader,
    int? fileSize,
    String? mMdEncodedJson,
    int? mMdVersion,
    MagicMetadata? magicMetadata,
    String? pubMmdEncodedJson,
    int? pubMmdVersion,
    PubMagicMetadata? pubMagicMetadata,
  }) {
    return EnteFile()
      ..generatedID = generatedID ?? this.generatedID
      ..uploadedFileID = uploadedFileID ?? this.uploadedFileID
      ..ownerID = ownerID ?? this.ownerID
      ..collectionID = collectionID ?? this.collectionID
      ..localID = localID ?? this.localID
      ..title = title ?? this.title
      ..deviceFolder = deviceFolder ?? this.deviceFolder
      ..creationTime = creationTime ?? this.creationTime
      ..modificationTime = modificationTime ?? this.modificationTime
      ..updationTime = updationTime ?? this.updationTime
      ..addedTime = addedTime ?? this.addedTime
      ..location = location ?? this.location
      ..fileType = fileType ?? this.fileType
      ..fileSubType = fileSubType ?? this.fileSubType
      ..duration = duration ?? this.duration
      ..exif = exif ?? this.exif
      ..hash = hash ?? this.hash
      ..metadataVersion = metadataVersion ?? this.metadataVersion
      ..encryptedKey = encryptedKey ?? this.encryptedKey
      ..keyDecryptionNonce = keyDecryptionNonce ?? this.keyDecryptionNonce
      ..fileDecryptionHeader = fileDecryptionHeader ?? this.fileDecryptionHeader
      ..thumbnailDecryptionHeader =
          thumbnailDecryptionHeader ?? this.thumbnailDecryptionHeader
      ..metadataDecryptionHeader =
          metadataDecryptionHeader ?? this.metadataDecryptionHeader
      ..fileSize = fileSize ?? this.fileSize
      ..mMdEncodedJson = mMdEncodedJson ?? this.mMdEncodedJson
      ..mMdVersion = mMdVersion ?? this.mMdVersion
      ..magicMetadata = magicMetadata ?? this.magicMetadata
      ..pubMmdEncodedJson = pubMmdEncodedJson ?? this.pubMmdEncodedJson
      ..pubMmdVersion = pubMmdVersion ?? this.pubMmdVersion
      ..pubMagicMetadata = pubMagicMetadata ?? this.pubMagicMetadata;
  }
}
