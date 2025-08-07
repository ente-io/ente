import "dart:convert";
import "dart:core";
import "dart:io";
import 'dart:typed_data';

import "package:computer/computer.dart";
import 'package:ente_crypto/ente_crypto.dart';
import "package:exif_reader/exif_reader.dart";
import 'package:logging/logging.dart';
import "package:motion_photos/motion_photos.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/db/remote/table/files_table.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/metadata.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/module/upload/model/media.dart";
import "package:photos/module/upload/model/upload_data.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/local/metadata/metadata.service.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/panorama_util.dart";

final _logger = Logger("FileUtil");
// in Version 1, live photo hash is stored as zip's hash.
// in V2: LivePhoto hash is stored as imgHash:vidHash
const kCurrentMetadataVersion = 2;

Future<int?> motionVideoIndex(Map<String, dynamic> args) async {
  final String path = args['path'];
  return (await MotionPhotos(path).getMotionVideoIndex())?.start;
}

Future<UploadMetadaData> getUploadMetadata(
  UploadMedia uploadMedia,
  EnteFile file,
) async {
  final FileType fileType = file.fileType;
  Map<String, IfdTag>? exifData;
  if (fileType == FileType.image) {
    exifData = await readExifAsync(uploadMedia.uploadFile);
  } else if (fileType == FileType.livePhoto) {
    final imageFile = File(uploadMedia.livePhotoImage!);
    exifData = await readExifAsync(imageFile);
  }
  final ParsedExifDateTime? exifTime =
      exifData != null ? parseExifTime(exifData) : null;
  bool? isPanorama;
  int? mviIndex;
  if (fileType == FileType.image) {
    isPanorama = isPanoFromExif(exifData);
    if (isPanorama != true) {
      try {
        final xmpData = await getXmp(uploadMedia.uploadFile);
        isPanorama = isPanoFromXmp(xmpData);
      } catch (_) {}
      isPanorama ??= false;
    }
    if (Platform.isAndroid) {
      try {
        mviIndex = await Computer.shared().compute(
          motionVideoIndex,
          param: {'path': uploadMedia.uploadFile.path},
          taskName: 'motionPhotoIndex',
        );
      } catch (e) {
        _logger.severe('error while detecthing motion photo start index', e);
      }
    }
  }
  final Map<String, dynamic> defaultMetadata = await getMetadata(
    uploadMedia,
    exifTime,
    exifData,
    file,
  );
  Metadata? existingPublicMetadata;
  if (file.rAsset != null) {
    final result =
        await remoteDB.getIDToMetadata({file.rAsset!.id}, public: true);
    existingPublicMetadata = result[file.rAsset!.id];
  }
  final Map<String, dynamic> publicMetadata = _buildPublicMagicData(
    exifTime,
    existingPublicMetadata,
    width: uploadMedia.localAsset?.width,
    height: uploadMedia.localAsset?.height,
    isPanorama: isPanorama,
    motionPhotoStartIndex: mviIndex,
    noThumbnail: uploadMedia.thumbnail == null,
  );

  return UploadMetadaData(
    defaultMetadata: defaultMetadata,
    publicMetadata: publicMetadata.isEmpty ? null : publicMetadata,
    currentPublicMetadataVersion: existingPublicMetadata?.version,
  );
}

Future<Map<String, dynamic>> getMetadata(
  UploadMedia uploadMedia,
  ParsedExifDateTime? exifTime,
  Map<String, IfdTag>? exifData,
  EnteFile file,
) async {
  final AssetEntity? asset = uploadMedia.localAsset;

  final FileType fileType = file.fileType;
  final String? deviceFolder = file.deviceFolder;

  int? duration;
  final (int creationTime, int modificationTime) =
      LocalMetadataService.computeCreationAndModification(
    asset,
    exifData,
  );
  String? title = file.title;
  final Location? location = await LocalMetadataService.detectLocation(
    fileType.isVideo,
    asset,
    uploadMedia.uploadFile,
    exifData,
  );
  // asset can be null for files shared to app
  if (asset != null) {
    if (asset.type == AssetType.video) {
      duration = asset.duration;
    }
    if (title == null || title.isEmpty) {
      _logger.warning("Title was missing ${file.tag}");
      title = await asset.titleAsync;
    }
  }

  final metadata = <String, dynamic>{
    "localID": asset?.id,
    "hash": uploadMedia.hash,
    "version": kCurrentMetadataVersion,
    "title": title,
    "deviceFolder": deviceFolder,
    "creationTime": creationTime,
    "modificationTime": modificationTime,
    "fileType": fileType.index,
  };

  if (asset != null) {
    metadata["subType"] = asset.subtype;
  }
  if (Location.isValidLocation(location)) {
    metadata["latitude"] = location!.latitude;
    metadata["longitude"] = location.longitude;
  }
  if (duration != null) {
    metadata["duration"] = duration;
  }

  return metadata;
}

Map<String, dynamic> _buildPublicMagicData(
  ParsedExifDateTime? parsedExifTime,
  Metadata? existingPublicMetadata, {
  required int? width,
  required int? height,
  required bool? isPanorama,
  required int? motionPhotoStartIndex,
  required bool noThumbnail,
}) {
  final Map<String, dynamic> pubMetadata = {};
  if ((height ?? 0) != 0 && (width ?? 0) != 0) {
    pubMetadata[heightKey] = height;
    pubMetadata[widthKey] = width;
  }
  pubMetadata[mediaTypeKey] = isPanorama == true ? 1 : 0;
  if (motionPhotoStartIndex != null) {
    pubMetadata[motionVideoIndexKey] = motionPhotoStartIndex;
  }
  if (noThumbnail) {
    pubMetadata[noThumbKey] = true;
  }
  if (parsedExifTime?.dateTime != null) {
    pubMetadata[dateTimeKey] = parsedExifTime!.dateTime;
  }
  if (parsedExifTime?.offsetTime != null) {
    pubMetadata[offsetTimeKey] = parsedExifTime!.offsetTime;
  }

  final Map<String, dynamic> jsonToUpdate =
      existingPublicMetadata?.data ?? <String, dynamic>{};
  pubMetadata.forEach((key, value) {
    jsonToUpdate[key] = value;
  });
  return jsonToUpdate;
}

Future<MetadataRequest?> getPubMetadataRequest(
  Map<String, dynamic> jsonToUpdate,
  Uint8List fileKey,
  int? publicMetadataVersion,
) async {
  if (jsonToUpdate.isEmpty) {
    return null;
  }
  final int currentVersion = (publicMetadataVersion ?? 0);
  final encryptedMMd = await CryptoUtil.encryptChaCha(
    utf8.encode(jsonEncode(jsonToUpdate)),
    fileKey,
  );
  return MetadataRequest(
    version: currentVersion == 0 ? 1 : currentVersion,
    count: jsonToUpdate.length,
    data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
    header: CryptoUtil.bin2base64(encryptedMMd.header!),
  );
}
