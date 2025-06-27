import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/errors.dart";
import "package:photos/utils/file_util.dart";

Logger _logger = Logger("UploadThumbnailService");
const kMaximumThumbnailCompressionAttempts = 2;
Future<Uint8List?> getThumbnailForUpload(
  AssetEntity asset,
) async {
  try {
    Uint8List? thumbnailData = await asset.thumbnailDataWithSize(
      const ThumbnailSize(thumbnailLarge512, thumbnailLarge512),
      quality: thumbnailQuality,
    );
    if (thumbnailData == null) {
      // allow videos to be uploaded without thumbnails
      if (asset.type == AssetType.video) {
        return null;
      }
      throw InvalidFileError(
        "no thumbnail : ${asset.type.name} ${asset.id}",
        InvalidReason.thumbnailMissing,
      );
    }
    int compressionAttempts = 0;
    while (thumbnailData!.length > thumbnailDataMaxSize &&
        compressionAttempts < kMaximumThumbnailCompressionAttempts) {
      _logger.info("Thumbnail size " + thumbnailData.length.toString());
      thumbnailData = await compressThumbnail(thumbnailData);
      _logger
          .info("Compressed thumbnail size " + thumbnailData.length.toString());
      compressionAttempts++;
    }
    return thumbnailData;
  } catch (e) {
    final String errMessage =
        "thumbErr id: ${asset.id} type: ${asset.type.name}, name: ${await asset.titleAsync}";
    _logger.warning(errMessage, e);
    // allow videos to be uploaded without thumbnails
    if (asset.type == AssetType.video) {
      return null;
    }
    throw InvalidFileError(errMessage, InvalidReason.thumbnailMissing);
  }
}
