import "dart:async";
import "dart:io";

import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/errors.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/standalone/date_time.dart";

class AssetEntityService {
  static final Logger _logger = Logger("AssetEntityService");
  static Future<AssetEntity> fromIDWithRetry(String localID) async {
    final asset = await AssetEntity.fromId(localID)
        .timeout(const Duration(seconds: 3))
        .catchError((e) async {
      if (e is TimeoutException) {
        _logger.info("Asset fetch timed out for id $localID ");
        return await AssetEntity.fromId(localID);
      } else {
        throw e;
      }
    });

    if (asset == null) {
      throw InvalidFileError("asset null", InvalidReason.assetDeleted);
    }
    return asset;
  }

  // Use this time if exif data is not available
  static int estimateCreationTime(AssetEntity asset) {
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
    }
    if (!Platform.isAndroid) {
      return creationTime;
    }
    try {
      final parsedDateTime = parseDateTimeFromName(
        basenameWithoutExtension(asset.title ?? ""),
      );
      // only use timeFromFileName if the existing creationTime and
      // timeFromFilename belongs to different date.
      // This is done because many times the fileTimeStamp will only give us
      // the date, not time value but the photo_manager's creation time will
      // contain the time.
      if (parsedDateTime != null &&
          !areFromSameDay(
            creationTime,
            parsedDateTime.microsecondsSinceEpoch,
          )) {
        creationTime = parsedDateTime.microsecondsSinceEpoch;
      }
    } catch (e) {
      // ignore
    }
    return creationTime;
  }

  static Future<File> sourceFromAsset(AssetEntity asset) async {
    final sourceFile = await asset.originFile
        .timeout(const Duration(seconds: 15))
        .catchError((e) async {
      if (e is TimeoutException) {
        _logger.info("Origin file fetch timed out for ${asset.id}");
        return await asset.originFile;
      } else {
        throw e;
      }
    });
    if (sourceFile == null || !sourceFile.existsSync()) {
      throw InvalidFileError(
        "id: ${asset.id}",
        InvalidReason.sourceFileMissing,
      );
    }
    return sourceFile;
  }

// check if the assetType is still the same. This can happen for livePhotos
// if the user turns off the video using native photos app
  static void assetType(AssetEntity asset, FileType type) {
    final assetType = enteTypeFromAsset(asset);
    if (assetType == type) {
      return;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      if (assetType == FileType.image && type == FileType.livePhoto) {
        throw InvalidFileError(
          'id ${asset.id}',
          InvalidReason.livePhotoToImageTypeChanged,
        );
      } else if (assetType == FileType.livePhoto && type == FileType.image) {
        throw InvalidFileError(
          'id ${asset.id}',
          InvalidReason.imageToLivePhotoTypeChanged,
        );
      }
    }
    throw InvalidFileError(
      'fileType mismatch for id ${asset.id} assetType $assetType fileType ${type.name}',
      InvalidReason.unknown,
    );
  }
}
