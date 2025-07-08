import "dart:io";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/local/table/shared_assets.dart";
import "package:photos/module/upload/service/media.dart";
import "package:photos/service_locator.dart";
import "package:photos/utils/file_util.dart";
import "package:video_thumbnail/video_thumbnail.dart";

class SharedAssetService {
  static final _logger = Logger("SharedAssetService");

  static Future<File?> getFile(String sharedAssetID) async {
    final localFile = File(getPath(sharedAssetID));
    if (localFile.existsSync()) {
      return localFile;
    }
    return null;
  }

  static String getPath(String localID) {
    return Configuration.instance.getSharedMediaDirectory() +
        "/" +
        localID.replaceAll(sharedMediaIdentifier, '');
  }

  static Future<Uint8List?> getThumbnail(
    String sharedAssetID,
    bool isVideo,
  ) async {
    var localFile = File(getPath(sharedAssetID));
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

  static Future<List<String>> tryDelete(List<String> localIDs) {
    final List<String> actuallyDeletedIDs = [];
    try {
      return Future.forEach<String>(localIDs, (id) async {
        final String localPath = getPath(id);
        try {
          // verify the file exists as the OS may have already deleted it from cache
          if (File(localPath).existsSync()) {
            await File(localPath).delete();
          }
          actuallyDeletedIDs.add(id);
        } catch (e, s) {
          _logger.severe("Could not delete file ", e, s);
        }
      }).then((ignore) {
        return actuallyDeletedIDs;
      });
    } catch (e, s) {
      _logger.severe("Unexpected error while deleting share media files", e, s);
      return Future.value(actuallyDeletedIDs);
    }
  }

  static Future<void> cleanUpUntrackedItems() async {
    final sharedMediaDir =
        Configuration.instance.getSharedMediaDirectory() + "/";
    final sharedFiles = await Directory(sharedMediaDir).list().toList();
    if (sharedFiles.isNotEmpty) {
      _logger.info('Shared media directory cleanup ${sharedFiles.length}');
      final existingLocalFileIDs = await localDB.getSharedAssetsID();
      final Set<String> trackedSharedFilePaths = {};
      for (String localID in existingLocalFileIDs) {
        if (localID.contains(sharedMediaIdentifier)) {
          trackedSharedFilePaths.add(getPath(localID));
        }
      }
      for (final file in sharedFiles) {
        if (!trackedSharedFilePaths.contains(file.path)) {
          _logger.info('Deleting stale shared media file ${file.path}');
          await file.delete();
        }
      }
    }
  }
}
