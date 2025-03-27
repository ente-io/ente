import "dart:async";
import "dart:io";

import "package:computer/computer.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:exif/exif.dart";
import "package:logging/logging.dart";
import "package:motion_photos/motion_photos.dart";
import "package:photos/core/errors.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/local/local_metadata.dart";
import "package:photos/models/location/location.dart";
import "package:photos/utils/exif_util.dart";
import "package:wechat_assets_picker/wechat_assets_picker.dart";

class LocalMetadataService {
  static final Logger _logger = Logger("LocalMetadataService");

  static Future<DroidMetadata?> getMetadata(String id) async {
    try {
      final TimeLogger t = TimeLogger(context: "getDroidMetadata");
      final AssetEntity asset = await fromIDWithRetry(id);
      final sourceFile = await sourceFromAsset(asset);
      final latLng = await asset.latlngAsync();
      Location location =
          Location(latitude: latLng.latitude, longitude: latLng.longitude);

      final int size = await sourceFile.length();
      final String hash =
          CryptoUtil.bin2base64(await CryptoUtil.getHash(sourceFile));
      final Map<String, IfdTag>? exifData = await tryExifFromFile(sourceFile);
      final int? mviIndex = asset.type != AssetType.image
          ? null
          : (await motionVideoIndex(sourceFile.path))?.start;

      if (!Location.isValidLocation(location) && exifData != null) {
        final exifLocation = locationFromExif(exifData)!;
        if (Location.isValidLocation(exifLocation)) {
          location = exifLocation;
        }
      }
      if (!Location.isValidLocation(location) &&
          asset.type == AssetType.video &&
          Platform.isAndroid) {
        final FFProbeProps? props = await getVideoPropsAsync(sourceFile);
        if (props != null && props.location != null) {
          location = props.location!;
        }
      }
      final (createdAt, modifiedAt) =
          computeCreationAndModification(asset, exifData);
      _logger.info(
        "getMetadata for ${asset.title} took ${t.elapsed}",
      );
      return DroidMetadata(
        size: size,
        hash: hash,
        location: location,
        creationTime: createdAt,
        modificationTime: modifiedAt,
        mviIndex: mviIndex,
      );
    } catch (e) {
      _logger.severe("failed to getMetadata", e);
      rethrow;
    }
  }

  static (int, int) computeCreationAndModification(
    AssetEntity asset,
    Map<String, IfdTag>? exifData,
  ) {
    int createdAt = EnteFile.parseFileCreationTime(asset);
    final int modifiedAt = asset.modifiedDateTime.millisecondsSinceEpoch;
    final ParsedExifDateTime? parsedExifDateTime =
        exifData == null ? null : parseExifTime(exifData);
    if (parsedExifDateTime?.time != null) {
      createdAt = parsedExifDateTime!.time!.millisecondsSinceEpoch;
    }
    return (createdAt, modifiedAt);
  }

  static Future<VideoIndex?> motionVideoIndex(String sourceFile) async {
    return Computer.shared().compute<String, VideoIndex?>(
      MotionPhotos(sourceFile).getMotionVideoIndex,
      param: sourceFile,
      taskName: "motionVideoIndex",
    );
  }

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
      throw InvalidFileError("", InvalidReason.assetDeleted);
    }
    return asset;
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
}
