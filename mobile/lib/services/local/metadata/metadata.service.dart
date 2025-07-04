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
      final int size = sourceFile.lengthSync();
      final Map<String, IfdTag>? exifData = await tryExifFromFile(sourceFile);
      final Location? location = await detectLocation(
        asset.type == AssetType.video,
        asset,
        sourceFile,
        exifData,
      );
      final int? mviIndex = asset.type != AssetType.image
          ? null
          : (await motionVideoIndex(sourceFile.path))?.start;
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

  static Future<Location?> detectLocation(
    bool isVideo,
    AssetEntity? asset,
    File sourceFile,
    Map<String, IfdTag>? exifData,
  ) async {
    final Location assetLocation = Location(
      latitude: asset?.latitude,
      longitude: asset?.longitude,
    );
    if (Location.isValidLocation(assetLocation)) {
      return assetLocation;
    }

    if (asset != null &&
        !Location.isValidLocation(assetLocation) &&
        Platform.isAndroid) {
      // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
      final latLong = await asset.latlngAsync();
      if (latLong.latitude != 0 && latLong.longitude != 0) {
        _logger.finest('[assetID-${asset.id}] detected lat/lng via async');
        return Location(
          latitude: latLong.latitude,
          longitude: latLong.longitude,
        );
      }
    }
    if (!Location.isValidLocation(assetLocation) &&
        isVideo &&
        Platform.isAndroid) {
      final FFProbeProps? props = await getVideoPropsAsync(sourceFile);
      if (Location.isValidLocation(props?.location)) {
        _logger.finest('detected lat/long from props');
        return props!.location!;
      }
    }
    if (Platform.isAndroid && exifData != null) {
      //Fix for missing location data in lower android versions.
      final Location? exifLocation = locationFromExif(exifData);
      if (Location.isValidLocation(exifLocation)) {
        _logger.finest('deleted lag/lng from exif data');
        return exifLocation!;
      }
    }
    return null;
  }

  static (int, int) computeCreationAndModification(
    AssetEntity? asset,
    Map<String, IfdTag>? exifData,
  ) {
    late final int createdAt;
    final ParsedExifDateTime? parsedExifDateTime =
        exifData == null ? null : parseExifTime(exifData);
    if (parsedExifDateTime?.time != null) {
      createdAt = parsedExifDateTime!.time!.microsecondsSinceEpoch;
    } else {
      if (asset == null) {
        _logger.warning("Asset is null, using current time for creation");
        createdAt = DateTime.now().toUtc().microsecondsSinceEpoch;
      } else {
        createdAt = AssetEntityService.estimateCreationTime(asset);
      }
    }
    final int modifiedAt =
        asset?.modifiedDateTime.microsecondsSinceEpoch ?? createdAt;
    return (createdAt, modifiedAt);
  }

  static Future<VideoIndex?> motionVideoIndex(String sourceFile) async {
    return Computer.shared().compute<void, VideoIndex?>(
      MotionPhotos(sourceFile).getMotionVideoIndex,
      taskName: "motionVideoIndex",
    );
  }
}
