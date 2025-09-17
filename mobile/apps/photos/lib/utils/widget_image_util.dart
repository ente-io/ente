import 'dart:io';
import 'dart:typed_data';

import 'package:computer/computer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/isolate/widget_image_operations.dart';
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("WidgetImageUtil");

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
  try {
    // 1. Check memory cache first (fastest)
    final memCached = ThumbnailInMemoryLruCache.get(file, maxSize.toInt());
    if (memCached != null && memCached.isNotEmpty) {
      return memCached;
    }

    // 2. Check disk cache (fast)
    if (file.uploadedFileID != null) {
      final cacheKey = 'widget_${file.uploadedFileID}_${maxSize.toInt()}';
      final cachedFile = await WidgetCacheManager().getFileFromCache(cacheKey);

      if (cachedFile != null) {
        final bytes = await cachedFile.file.readAsBytes();
        ThumbnailInMemoryLruCache.put(file, bytes, maxSize.toInt());
        return bytes;
      }
    }

    // 3. Process the image based on file location
    Uint8List? processedImage;

    if (!file.isRemoteFile) {
      // Local file: Process directly
      processedImage = await _processLocalFile(file, maxSize, quality);
    } else if (maxSize > 512) {
      // Remote file requesting high quality: Download and process
      processedImage = await _downloadAndProcessRemoteFile(file, maxSize, quality);
    }

    // 4. Fallback to server thumbnail for remote files
    if (processedImage == null && file.isRemoteFile) {
      processedImage = await getThumbnail(file);
    }

    // 5. Cache the result if we got something
    if (processedImage != null && file.uploadedFileID != null) {
      final cacheKey = 'widget_${file.uploadedFileID}_${maxSize.toInt()}';
      await WidgetCacheManager().putFile(
        cacheKey,
        processedImage,
        fileExtension: 'jpg',
      );
      ThumbnailInMemoryLruCache.put(file, processedImage, maxSize.toInt());
    }

    return processedImage;
  } catch (e) {
    _logger.severe("Error getting widget image for ${file.displayName}", e);
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
      return null;
    }

    // Try to get file path first (better for processing)
    final File? originFile = await asset.originFile;
    if (originFile != null && originFile.existsSync()) {
      return _processImageInIsolate(originFile.path, null, maxSize, quality);
    }

    // Fallback to bytes if file path not available
    final bytes = await asset.originBytes;
    if (bytes != null) {
      return _processImageInIsolate(null, bytes, maxSize, quality);
    }

    return null;
  } catch (e) {
    _logger.warning("Error processing local file", e);
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
  final futures = files.map((file) =>
    getWidgetImage(file).catchError((e) {
      _logger.warning("Failed to refresh ${file.displayName}", e);
      return null;
    })
  );

  await Future.wait(futures, eagerError: false);
  _logger.info("Completed refreshing widget images");
}