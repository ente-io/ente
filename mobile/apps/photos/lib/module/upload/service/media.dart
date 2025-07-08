import "dart:io";
import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/errors.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/module/upload/model/media.dart";
import "package:photos/services/local/asset_entity.service.dart";
import "package:photos/services/local/import/local_import.dart";
import "package:photos/services/local/livephoto.dart";
import "package:photos/services/local/shared_assert.service.dart";
import "package:photos/utils/file_util.dart";

Logger _logger = Logger("UploadMediaService");
const kMaximumThumbnailCompressionAttempts = 2;

Future<UploadMedia> getUploadMedia(EnteFile file) async {
  if (file.isSharedMediaToAppSandbox) {
    return _getUploadMediaFromSharedAsset(file);
  }
  return _getUploadMediaFromAsset(file);
}

Future<UploadMedia> _getUploadMediaFromAsset(EnteFile file) async {
  final asset = await AssetEntityService.fromIDWithRetry(file.lAsset!.id);
  AssetEntityService.assetType(asset, file.fileType);
  if (Platform.isIOS) {
    trackOriginFetchForUploadOrML.put(file.lAsset!.id, true);
  }
  final File sourceFile = await AssetEntityService.sourceFromAsset(asset);
  final Uint8List? thumbnail = await getThumbnailForUpload(asset);
  final fileHash = await CryptoUtil.getHash(sourceFile);
  if (file.fileType == FileType.livePhoto && Platform.isIOS) {
    final (videoUrl, videoHash) =
        await LivePhotoService.liveVideoAndHash(file.lAsset!.id);
    // imgHash:vidHash
    final livePhotoHash = '$fileHash$kHashSeprator$videoHash';
    final zippedPath = await LivePhotoService.zip(
      id: file.lAsset!.id,
      imagePath: sourceFile.path,
      videoPath: videoUrl.path,
    );
    final assetExists = await asset.exists;
    return UploadMedia(
      File(zippedPath),
      thumbnail,
      assetExists,
      file.fileType,
      livePhotoHash,
      livePhotoImage: sourceFile.path,
      livePhotoVideo: videoUrl.path,
      localAsset: file.lAsset,
    );
  }
  final assetExists = await asset.exists;
  return UploadMedia(
    sourceFile,
    thumbnail,
    assetExists,
    file.fileType,
    fileHash,
    localAsset: asset,
  );
}

Future<UploadMedia> _getUploadMediaFromSharedAsset(EnteFile file) async {
  final localPath = SharedAssetService.getPath(file.localID!);
  final sourceFile = File(localPath);
  final Uint8List? thumbnail = await SharedAssetService.getThumbnail(
    file.localID!,
    file.isVideo,
  );
  final fileHash = await CryptoUtil.getHash(sourceFile);
  return UploadMedia(
    sourceFile,
    thumbnail,
    true,
    file.fileType,
    fileHash,
    sharedAsset: file.sharedAsset,
  );
}

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
