import "dart:async";
import "dart:io";

import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/errors.dart";

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
