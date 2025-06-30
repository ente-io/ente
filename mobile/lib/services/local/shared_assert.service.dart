import "dart:io";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/constants.dart";
import "package:photos/image/thumnail/upload_thumb.dart";
import "package:photos/utils/file_util.dart";
import "package:video_thumbnail/video_thumbnail.dart";

class SharedAssertService {
  static final _logger = Logger("SharedAssertService");
  static Future<Uint8List?> getThumbnailFromInAppCacheFile(
    String sharedAssetID,
    bool isVideo,
  ) async {
    var localFile = File(getSharedMediaPathFromLocalID(sharedAssetID));
    if (!localFile.existsSync()) {
      return null;
    }
    if (isVideo) {
      try {
        final thumbnailFilePath = await VideoThumbnail.thumbnailFile(
          video: localFile.path,
          imageFormat: ImageFormat.JPEG,
          thumbnailPath: (await getTemporaryDirectory()).path,
          maxWidth: thumbnailLarge512,
          quality: 80,
        );
        localFile = File(thumbnailFilePath!);
      } catch (e) {
        _logger.warning('Failed to generate video thumbnail', e);
        return null;
      }
    }
    var thumbnailData = await localFile.readAsBytes();
    int compressionAttempts = 0;
    while (thumbnailData.length > thumbnailDataMaxSize &&
        compressionAttempts < kMaximumThumbnailCompressionAttempts) {
      _logger.info("Thumbnail size " + thumbnailData.length.toString());
      thumbnailData = await compressThumbnail(thumbnailData);
      _logger
          .info("Compressed thumbnail size " + thumbnailData.length.toString());
      compressionAttempts++;
    }
    return thumbnailData;
  }
}
