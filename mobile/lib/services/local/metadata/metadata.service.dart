import "dart:async";
import "dart:io";

import "package:computer/computer.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:exif_reader/exif_reader.dart";
import "package:logging/logging.dart";
import "package:motion_photos/motion_photos.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/local/local_metadata.dart";
import "package:photos/models/location/location.dart";
import "package:photos/services/local/asset_entity.service.dart";
import "package:photos/utils/exif_util.dart";
import "package:wechat_assets_picker/wechat_assets_picker.dart";

class LocalMetadataService {
  static final Logger _logger = Logger("LocalMetadataService");

  static Future<DroidMetadata?> getMetadata(String id) async {
    try {
      final TimeLogger t = TimeLogger(context: "getDroidMetadata");
      final AssetEntity asset = await AssetEntityService.fromIDWithRetry(id);
      final sourceFile = await AssetEntityService.sourceFromAsset(asset);
      final String hash = await CryptoUtil.getHash(sourceFile);
      final latLng = await asset.latlngAsync();
      Location location =
          Location(latitude: latLng.latitude, longitude: latLng.longitude);
      final int size = sourceFile.lengthSync();
      final Map<String, IfdTag>? exifData = await tryExifFromFile(sourceFile);
      final int? mviIndex = asset.type != AssetType.image
          ? null
          : (await motionVideoIndex(sourceFile.path))?.start;

      if (!Location.isValidLocation(location) && exifData != null) {
        final exifLocation = locationFromExif(exifData);
        if (Location.isValidLocation(exifLocation)) {
          location = exifLocation!;
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
      final result = DroidMetadata(
        size: size,
        hash: hash,
        location: location,
        creationTime: createdAt,
        modificationTime: modifiedAt,
        mviIndex: mviIndex,
      );
      _logger.info(
        "getMetadata for ${asset.title} ${asset.relativePath} took ${t.elapsed}",
      );
      return result;
    } catch (e) {
      _logger.severe("failed to getMetadata for $id", e);
      rethrow;
    }
  }

  static (int, int) computeCreationAndModification(
    AssetEntity asset,
    Map<String, IfdTag>? exifData,
  ) {
    int createdAt = AssetEntityService.parseFileCreationTime(asset);
    final int modifiedAt = asset.modifiedDateTime.microsecondsSinceEpoch;
    final ParsedExifDateTime? parsedExifDateTime =
        exifData == null ? null : parseExifTime(exifData);
    if (parsedExifDateTime?.time != null) {
      createdAt = parsedExifDateTime!.time!.microsecondsSinceEpoch;
    }
    return (createdAt, modifiedAt);
  }

  static Future<VideoIndex?> motionVideoIndex(String sourceFile) async {
    return Computer.shared().compute<void, VideoIndex?>(
      MotionPhotos(sourceFile).getMotionVideoIndex,
      taskName: "motionVideoIndex",
    );
  }
}
