import 'dart:io';
import 'dart:typed_data';

import 'package:computer/computer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/isolate/widget_image_operations.dart';
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("WidgetImageUtil");

// Track failed attempts for files to avoid infinite retries
final Map<String, int> _failedAttempts = {};
const int _maxRetries = 3;

// Custom cache manager for widget images with 7-day retention
class WidgetCacheManager extends CacheManager {
  static const String key = 'widgetImageCache';
  static WidgetCacheManager? _instance;

  factory WidgetCacheManager() {
    _instance ??= WidgetCacheManager._();
    return _instance!;
  }

  WidgetCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
          ),
        );
}

/// Fetches and processes images for home screen widgets
/// Prioritizes quality for 1280px widgets, uses thumbnails as fallback
Future<Uint8List?> getWidgetImage(
  EnteFile file, {
  double maxSize = 1280.0,
  int quality = WidgetImageOperations.kDefaultQuality,
}) async {
  _logger.info("DEBUG: getWidgetImage called for ${file.displayName}");
  _logger.info("getWidgetImage START for ${file.displayName}");

  // Check if this file has failed too many times
  final fileKey = '${file.uploadedFileID ?? file.localID}_${file.displayName}';
  final failCount = _failedAttempts[fileKey] ?? 0;
  if (failCount >= _maxRetries) {
    // Don't retry files that have consistently failed
    _logger.info(
      "Skipping ${file.displayName} - exceeded max retries ($failCount/$_maxRetries)",
    );
    return null;
  }

  _logger.info(
    "Processing widget image for ${file.displayName} "
    "(type: ${file.fileType}, localID: ${file.localID}, "
    "uploadedID: ${file.uploadedFileID}, isRemote: ${file.isRemoteFile})",
  );

  try {
    // 1. Check memory cache first (fastest)
    final memCached = ThumbnailInMemoryLruCache.get(file, maxSize.toInt());
    if (memCached != null && memCached.isNotEmpty) {
      _logger.info("Found ${file.displayName} in memory cache");
      return memCached;
    }

    // 2. Check disk cache (fast)
    if (file.uploadedFileID != null) {
      final cacheKey = 'widget_${file.uploadedFileID}_${maxSize.toInt()}';
      final cachedFile = await WidgetCacheManager().getFileFromCache(cacheKey);

      if (cachedFile != null) {
        _logger.info("Found ${file.displayName} in disk cache");
        final bytes = await cachedFile.file.readAsBytes();
        ThumbnailInMemoryLruCache.put(file, bytes, maxSize.toInt());
        return bytes;
      }
    }

    // 3. Process the image based on file location
    Uint8List? processedImage;

    if (!file.isRemoteFile) {
      // Local file: Process directly
      _logger.info("Processing local file ${file.displayName}");
      processedImage = await _processLocalFile(file, maxSize, quality);
      if (processedImage == null) {
        _logger.warning(
          "Local file processing returned null for ${file.displayName}",
        );
      }
    } else if (maxSize > 512) {
      // Remote file requesting high quality: Download and process
      _logger
          .info("Downloading and processing remote file ${file.displayName}");
      processedImage =
          await _downloadAndProcessRemoteFile(file, maxSize, quality);
    }

    // 4. Fallback to server thumbnail for remote files
    if (processedImage == null && file.isRemoteFile) {
      _logger.info("Falling back to server thumbnail for ${file.displayName}");
      processedImage = await getThumbnail(file);
    }

    // 5. Cache the result if we got something
    if (processedImage != null && file.uploadedFileID != null) {
      _logger
          .info("Successfully processed ${file.displayName}, caching result");
      final cacheKey = 'widget_${file.uploadedFileID}_${maxSize.toInt()}';
      await WidgetCacheManager().putFile(
        cacheKey,
        processedImage,
        fileExtension: 'jpg',
      );
      ThumbnailInMemoryLruCache.put(file, processedImage, maxSize.toInt());
    } else if (processedImage == null) {
      _logger.warning("Failed to get any image data for ${file.displayName}");
    }

    return processedImage;
  } catch (e, stackTrace) {
    // Track failed attempts to prevent infinite retries
    final fileKey =
        '${file.uploadedFileID ?? file.localID}_${file.displayName}';
    _failedAttempts[fileKey] = (_failedAttempts[fileKey] ?? 0) + 1;

    // Log detailed error information
    if (_failedAttempts[fileKey]! <= 2) {
      _logger.severe(
        "Error getting widget image for ${file.displayName} "
        "(attempt ${_failedAttempts[fileKey]}/$_maxRetries, "
        "type: ${file.fileType}, localID: ${file.localID}, "
        "uploadedID: ${file.uploadedFileID}, isRemote: ${file.isRemoteFile})",
        e,
        stackTrace,
      );
    }
    return null;
  }
}

/// Process a local file from device storage
Future<Uint8List?> _processLocalFile(
  EnteFile file,
  double maxSize,
  int quality,
) async {
  try {
    final AssetEntity? asset = await file.getAsset;
    if (asset == null || !(await asset.exists)) {
      _logger.warning(
        "Asset not found or doesn't exist for ${file.displayName} "
        "(asset null: ${asset == null})",
      );
      return null;
    }

    // HEIC handling improvement for enhanced widget feature
    if (flagService.enhancedWidgetImage) {
      // Check if this is a HEIC/HEIF file which the image package can't decode
      final isHeic = file.displayName.toUpperCase().endsWith('.HEIC') ||
          file.displayName.toUpperCase().endsWith('.HEIF');

      if (isHeic) {
        // For HEIC files, use photo_manager's thumbnail generation
        // which properly handles iOS HEIC format
        _logger.info(
          "[Enhanced] Using photo_manager for HEIC file: ${file.displayName}",
        );
        try {
          // Use thumbnailDataWithSize for HEIC files - it handles conversion to JPEG
          final thumbData = await asset.thumbnailDataWithSize(
            ThumbnailSize(maxSize.toInt(), maxSize.toInt()),
            quality: quality,
          );

          if (thumbData != null) {
            _logger.info(
              "[Enhanced] Successfully got thumbnail for HEIC file ${file.displayName} (${thumbData.length} bytes)",
            );
            return thumbData;
          } else {
            _logger.warning(
              "[Enhanced] photo_manager returned null thumbnail for ${file.displayName}",
            );
          }
        } catch (e) {
          _logger.warning(
            "[Enhanced] Failed to get thumbnail via photo_manager for ${file.displayName}: $e",
          );
        }
      }
    }

    // For non-HEIC files, try to get file path first (better for processing)
    final File? originFile = await asset.originFile;
    if (originFile != null && originFile.existsSync()) {
      return _processImageInIsolate(originFile.path, null, maxSize, quality);
    }

    // Fallback to bytes if file path not available
    final bytes = await asset.originBytes;
    if (bytes != null) {
      return _processImageInIsolate(null, bytes, maxSize, quality);
    }

    _logger
        .warning("No origin file or bytes available for ${file.displayName}");
    return null;
  } catch (e, stackTrace) {
    _logger.severe(
      "Error processing local file ${file.displayName}",
      e,
      stackTrace,
    );
    return null;
  }
}

/// Download and process a remote file with retry logic
Future<Uint8List?> _downloadAndProcessRemoteFile(
  EnteFile file,
  double maxSize,
  int quality,
) async {
  const maxAttempts = 2;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final originalFile = await getFile(file, isOrigin: true);
      if (originalFile == null) {
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        break;
      }

      final processedImage = await _processImageInIsolate(
        originalFile.path,
        null,
        maxSize,
        quality,
      );

      // Clean up downloaded file
      if (originalFile.existsSync()) {
        await originalFile.delete();
      }

      if (processedImage != null) {
        return processedImage;
      }
    } catch (e) {
      // Don't retry on network errors
      if (e.toString().contains('network') ||
          e.toString().contains('Failed host lookup')) {
        _logger.warning("Network error downloading ${file.displayName}");
        break;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  return null;
}

/// Process image in isolate to avoid blocking UI
Future<Uint8List?> _processImageInIsolate(
  String? imagePath,
  Uint8List? imageBytes,
  double maxSize,
  int quality,
) async {
  try {
    final params = <String, dynamic>{
      if (imagePath != null) 'imagePath': imagePath,
      if (imageBytes != null) 'imageBytes': imageBytes,
      'maxSize': maxSize.toInt(),
      'quality': quality,
    };

    return await Computer.shared().compute(
      WidgetImageOperations.processWidgetImage,
      param: params,
    );
  } catch (e) {
    _logger.severe("Error processing image in isolate", e);
    return null;
  }
}

/// Batch refresh widget images
Future<void> refreshWidgetImages(List<EnteFile> files) async {
  _logger.info("Refreshing ${files.length} widget images");

  // Clear failed attempts periodically to allow retries after app restart
  if (_failedAttempts.length > 100) {
    _failedAttempts.clear();
  }

  final futures = files.map(
    (file) => getWidgetImage(file).catchError((e) {
      _logger.warning("Failed to refresh ${file.displayName}", e);
      return null;
    }),
  );

  await Future.wait(futures, eagerError: false);
  _logger.info("Completed refreshing widget images");
}

/// Clear failed attempts cache for specific file
void clearFailedAttemptsForFile(EnteFile file) {
  final fileKey = '${file.uploadedFileID ?? file.localID}_${file.displayName}';
  _failedAttempts.remove(fileKey);
}

/// Clear all failed attempts cache
void clearAllFailedAttempts() {
  _failedAttempts.clear();
}