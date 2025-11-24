import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:computer/computer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart' as hw;
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/album_home_widget_service.dart';
import 'package:photos/services/memory_home_widget_service.dart';
import 'package:photos/services/people_home_widget_service.dart';
import 'package:photos/services/smart_memories_service.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/thumbnail_util.dart';
import 'package:synchronized/synchronized.dart';

enum WidgetStatus {
  // notSynced means the widget is not initialized or has no data
  notSynced,
  // partially synced means some images were synced but not all
  // this can happen if some widgets were not installed but we did a sync regardless
  // or if the sync fails midway
  syncedPartially,
  // we purposefully set widget to empty, widget had data
  syncedEmpty,
  // all widgets were synced successfully
  syncedAll,
}

/// Service to manage home screen widgets across the application
/// Handles widget initialization, updates, and interaction with platform-specific widget APIs
class HomeWidgetService {
  // Constants
  static const int _widgetV2Size = 1024;
  static const double THUMBNAIL_SIZE = 512.0;
  static const double THUMBNAIL_SIZE_V2 = 1024.0;
  static const String WIDGET_DIRECTORY = 'home_widget';
  static const int WIDGET_IMAGE_LIMIT_V1 = 50;
  static const int WIDGET_IMAGE_LIMIT_V2 = 25;
  static const int WIDGET_IMAGE_LIMIT_MINIMAL = 5;

  // URI schemes for different widget types
  static const String MEMORY_WIDGET_SCHEME = 'memorywidget';
  static const String PEOPLE_WIDGET_SCHEME = 'peoplewidget';
  static const String ALBUM_WIDGET_SCHEME = 'albumwidget';

  // Query parameter keys
  static const String GENERATED_ID_PARAM = 'generatedId';
  static const String MAIN_KEY_PARAM = 'mainKey';

  // Widget data keys
  static const String DATA_SUFFIX = '_data';

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();
  HomeWidgetService._privateConstructor();

  final Logger _logger = Logger((HomeWidgetService).toString());
  final Computer _computer = Computer.shared();
  final computeLock = Lock();
  bool _isAppGroupSet = false;

  Future<void> setAppGroup({String id = iOSGroupIDMemory}) async {
    if (!Platform.isIOS || _isAppGroupSet) return;
    _logger.info("Setting app group id");
    await hw.HomeWidget.setAppGroupId(id).catchError(
      (error) {
        _logger.severe("Failed to set app group ID: $error");
        return null;
      },
    );
    _isAppGroupSet = true;
  }

  int getWidgetImageLimit() {
    return flagService.useWidgetV2
        ? WIDGET_IMAGE_LIMIT_V2
        : WIDGET_IMAGE_LIMIT_V1;
  }

  Future<void> initHomeWidget([bool isBg = false]) async {
    await setAppGroup();
    await AlbumHomeWidgetService.instance.initAlbumHomeWidget(isBg);
    await PeopleHomeWidgetService.instance.initPeopleHomeWidget();
    await MemoryHomeWidgetService.instance.initMemoryHomeWidget();
  }

  Future<bool?> updateWidget({
    required String androidClass,
    required String iOSClass,
  }) async {
    return await hw.HomeWidget.updateWidget(
      name: androidClass,
      androidName: androidClass,
      qualifiedAndroidName: 'io.ente.photos.$androidClass',
      iOSName: iOSClass,
    );
  }

  Future<T?> getData<T>(String key) async {
    return hw.HomeWidget.getWidgetData<T>(key);
  }

  Future<bool?> setData<T>(String key, T? data) async {
    return hw.HomeWidget.saveWidgetData<T>(key, data);
  }

  Future<Size?> renderFile(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    // Use V2 (1024x1024 rendering) with isolate-based image processing
    final bool useV2 = flagService.useWidgetV2;

    if (useV2) {
      final Size? v2Size = await _captureFileV2(file, key, title, mainKey);
      if (v2Size != null) {
        return v2Size;
      }
      _logger.info(
        "V2 capture failed for ${file.displayName}, falling back to legacy",
      );
    }

    // Use legacy capture (either useV2 is false, or V2 failed)
    final result = await _captureFileLegacy(file, key, title, mainKey);
    if (!result) {
      _logger.warning("Failed to capture file ${file.displayName}");
      return null;
    }

    return const Size(THUMBNAIL_SIZE, THUMBNAIL_SIZE);
  }

  Future<int> countHomeWidgets(
    String androidClass,
    String iOSClass,
  ) async {
    final installedWidgets = await getInstalledWidgets();
    final relevantWidgets = installedWidgets
        .where(
          (widget) =>
              (widget.androidClassName?.contains(androidClass) ?? false) ||
              widget.iOSKind == iOSClass,
        )
        .toList();

    return relevantWidgets.length;
  }

  Future<List<hw.HomeWidgetInfo>> getInstalledWidgets() async {
    return await hw.HomeWidget.getInstalledWidgets();
  }

  Future<Size?> _captureFileV2(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    if (file.fileType == FileType.video) {
      return null;
    }

    final _WidgetSourceBytes? source = await _resolveWidgetSourceBytes(file);
    if (source == null) {
      return null;
    }

    try {
      String decodeStrategy = 'package:image';
      _WidgetImageProcessResult? processed =
          await _computeWidgetImageResult(source.bytes);

      if (processed == null) {
        final Uint8List? pngBytes = await _decodeWithUiFallback(source.bytes);
        if (pngBytes != null) {
          decodeStrategy = 'ui-codec';
          processed = await _computeWidgetImageResult(pngBytes);
        }
      }

      if (processed == null) {
        _logger.warning(
          "[widget_capture_v2] Failed to decode image for ${file.displayName} using ${source.sourceLabel}",
        );
        return null;
      }

      final String widgetDirectory = await _getWidgetStorageDirectory();
      final String imagePath = '$widgetDirectory/$WIDGET_DIRECTORY/$key.png';
      final File outputFile = File(imagePath);
      if (!await outputFile.exists()) {
        await outputFile.create(recursive: true);
      }
      await outputFile.writeAsBytes(processed.pngBytes);
      await setData(key, imagePath);

      final subText = await SmartMemoriesService.getDateFormattedLocale(
        creationTime: file.creationTime!,
      );
      // TODO: Remove dimension display after confirmation that widget v2 works correctly
      final bool showDimensions = kDebugMode || flagService.internalUser;
      final String resolvedSubText = showDimensions
          ? '$subText · ${processed.finalWidth}x${processed.finalHeight} · ${source.sourceLabel}'
          : subText;
      final Map<String, dynamic> metadata = {
        "title": title,
        "subText": resolvedSubText,
        "generatedId": file.generatedID!,
        if (mainKey != null) "mainKey": mainKey,
      };
      await _saveWidgetMetadata(key, metadata);

      _logger.info(
        "[widget_capture_v2] key=$key source=${source.sourceLabel} original=${processed.originalWidth}x${processed.originalHeight} "
        "final=${processed.finalWidth}x${processed.finalHeight} cropped=${processed.croppedToSquare} downscaled=${processed.downscaled} strategy=$decodeStrategy",
      );

      return Size(
        processed.finalWidth.toDouble(),
        processed.finalHeight.toDouble(),
      );
    } catch (error, stackTrace) {
      _logger.severe(
        "[widget_capture_v2] Failed to capture widget for ${file.displayName}",
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<Uint8List?> _decodeWithUiFallback(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      codec.dispose();
      return data?.buffer.asUint8List();
    } catch (error, stackTrace) {
      _logger.fine(
        "[widget_capture_v2] ui codec decode failed",
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<_WidgetImageProcessResult?> _computeWidgetImageResult(
    Uint8List bytes,
  ) async {
    try {
      final Map<String, dynamic>? result = await _computer.compute(
        _processWidgetImage,
        param: {
          'bytes': bytes,
          'targetSize': _widgetV2Size,
        },
      );
      if (result == null) {
        return null;
      }
      return _WidgetImageProcessResult.fromMap(result);
    } catch (error, stackTrace) {
      _logger.fine(
        "[widget_capture_v2] isolate processing failed",
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<_WidgetSourceBytes?> _resolveWidgetSourceBytes(EnteFile file) async {
    if (!file.isRemoteFile) {
      try {
        final AssetEntity? asset = await file.getAsset;
        if (asset != null) {
          final Uint8List? assetBytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize.square(_widgetV2Size),
            quality: 90,
          );
          if (assetBytes != null && assetBytes.isNotEmpty) {
            return _WidgetSourceBytes(
              bytes: assetBytes,
              sourceLabel: 'asset.thumbnail',
            );
          }

          final File? originFile = await asset.originFile;
          if (originFile != null && await originFile.exists()) {
            final Uint8List originBytes = await originFile.readAsBytes();
            if (originBytes.isNotEmpty) {
              return _WidgetSourceBytes(
                bytes: originBytes,
                sourceLabel: 'asset.origin',
              );
            }
          }
        }
      } catch (error, stackTrace) {
        _logger.fine(
          "[widget_capture_v2] Failed to resolve local asset for ${file.displayName}",
          error,
          stackTrace,
        );
      }
    }

    if (file.uploadedFileID != null &&
        (file.isRemoteFile ||
            file.fileType == FileType.image ||
            file.fileType == FileType.livePhoto)) {
      // Check file size before downloading (skip very large files)
      const int maxFileSizeForWidget = 50 * 1024 * 1024; // 50MB
      if (file.fileSize != null && file.fileSize! > maxFileSizeForWidget) {
        _logger.info(
          "[widget_capture_v2] Skipping large file (${file.fileSize} bytes) for ${file.displayName}",
        );
        // Fall through to thumbnail fallback
      } else {
        // Use getFileFromServer to maintain caching behavior
        // This caches downloaded files so subsequent widget syncs can reuse them
        try {
          final File? cachedFile = await getFileFromServer(file);
          if (cachedFile != null && await cachedFile.exists()) {
            final Uint8List fileBytes = await cachedFile.readAsBytes();
            if (fileBytes.isNotEmpty) {
              final String sourceLabel = file.fileType == FileType.livePhoto
                  ? 'cached-live-image'
                  : 'cached-full';
              return _WidgetSourceBytes(
                bytes: fileBytes,
                sourceLabel: sourceLabel,
              );
            }
          }
        } catch (error, stackTrace) {
          _logger.warning(
            "[widget_capture_v2] Download failed for ${file.displayName}",
            error,
            stackTrace,
          );
        }
      }
    }

    final Uint8List? fallbackThumbnail = await getThumbnail(file);
    if (fallbackThumbnail != null && fallbackThumbnail.isNotEmpty) {
      return _WidgetSourceBytes(
        bytes: fallbackThumbnail,
        sourceLabel: 'legacy-thumbnail',
      );
    }

    return null;
  }

  Future<bool> _captureFileLegacy(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    try {
      // Get thumbnail data
      final thumbnail = await getThumbnail(file);
      if (thumbnail == null) {
        _logger.warning("Failed to get thumbnail for file ${file.displayName}");
        return false;
      }

      // Get appropriate directory for widget assets
      final String widgetDirectory = await _getWidgetStorageDirectory();

      // Save thumbnail to file
      final String thumbnailPath =
          '$widgetDirectory/$WIDGET_DIRECTORY/$key.png';
      final File thumbnailFile = File(thumbnailPath);

      if (!await thumbnailFile.exists()) {
        await thumbnailFile.create(recursive: true);
      }

      await thumbnailFile.writeAsBytes(thumbnail);
      await setData(key, thumbnailPath);

      // Format date for display
      final subText = await SmartMemoriesService.getDateFormattedLocale(
        creationTime: file.creationTime!,
      );

      // Create metadata
      final Map<String, dynamic> metadata = {
        "title": title,
        "subText": subText,
        "generatedId": file.generatedID!,
        if (mainKey != null) "mainKey": mainKey,
      };

      // Save metadata in platform-specific format
      await _saveWidgetMetadata(key, metadata);

      return true;
    } catch (error, stackTrace) {
      _logger.severe("Failed to save the thumbnail", error, stackTrace);
      return false;
    }
  }

  Future<void> _saveWidgetMetadata(
    String key,
    Map<String, dynamic> metadata,
  ) async {
    final String dataKey = key + DATA_SUFFIX;

    if (Platform.isIOS) {
      // iOS can store the map directly
      await hw.HomeWidget.saveWidgetData<Map<String, dynamic>>(
        dataKey,
        metadata,
      );
    } else {
      // Android needs the data as a JSON string
      await hw.HomeWidget.saveWidgetData<String>(
        dataKey,
        jsonEncode(metadata),
      );
    }
  }

  Future<String> _getWidgetStorageDirectory() async {
    if (Platform.isIOS) {
      final PathProviderFoundation provider = PathProviderFoundation();
      return (await provider.getContainerPath(
        appGroupIdentifier: iOSGroupIDMemory,
      ))!;
    } else {
      return (await getApplicationSupportDirectory()).path;
    }
  }

  Future<void> clearWidget(bool autoLogout) async {
    if (autoLogout) {
      await setAppGroup();
    }

    await Future.wait([
      AlbumHomeWidgetService.instance.clearWidget(),
      PeopleHomeWidgetService.instance.clearWidget(),
      MemoryHomeWidgetService.instance.clearWidget(),
    ]);

    try {
      final String widgetParent = await _getWidgetStorageDirectory();
      final String widgetPath = '$widgetParent/$WIDGET_DIRECTORY';
      final dir = Directory(widgetPath);

      await dir.delete(recursive: true);
      _logger.info("Widget directory cleared successfully");
    } catch (e) {
      _logger.severe("Failed to clear widget directory", e);
    }
  }

  /// Handle app launch from a widget
  Future<void> onLaunchFromWidget(Uri? uri, BuildContext context) async {
    if (uri == null) {
      _logger.warning("Widget launch failed: URI is null");
      return;
    }

    final generatedId =
        int.tryParse(uri.queryParameters[GENERATED_ID_PARAM] ?? "");
    if (generatedId == null) {
      _logger.warning("Widget launch failed: Invalid or missing generated ID");
      return;
    }

    // Route to appropriate handler based on widget scheme
    switch (uri.scheme) {
      case MEMORY_WIDGET_SCHEME:
        _logger.info("Launching app from memory widget");
        await MemoryHomeWidgetService.instance.onLaunchFromWidget(
          generatedId,
          context,
        );
        break;

      case PEOPLE_WIDGET_SCHEME:
        _logger.info("Launching app from people widget");
        final personId = uri.queryParameters[MAIN_KEY_PARAM] ?? "";
        await PeopleHomeWidgetService.instance.onLaunchFromWidget(
          generatedId,
          personId,
          context,
        );
        break;

      case ALBUM_WIDGET_SCHEME:
        _logger.info("Launching app from album widget");
        final collectionId =
            int.tryParse(uri.queryParameters[MAIN_KEY_PARAM] ?? "");
        if (collectionId == null) {
          _logger.warning(
            "Album widget launch failed: Invalid or missing collection ID",
          );
          return;
        }

        await AlbumHomeWidgetService.instance.onLaunchFromWidget(
          generatedId,
          collectionId,
          context,
        );
        break;

      default:
        _logger.warning(
          "Widget launch failed: Unknown widget scheme '${uri.scheme}'",
        );
        break;
    }
  }
}

class _WidgetImageProcessResult {
  const _WidgetImageProcessResult({
    required this.pngBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.finalWidth,
    required this.finalHeight,
    required this.croppedToSquare,
    required this.downscaled,
  });

  factory _WidgetImageProcessResult.fromMap(Map<String, dynamic> map) {
    return _WidgetImageProcessResult(
      pngBytes: map['pngBytes'] as Uint8List,
      originalWidth: map['originalWidth'] as int,
      originalHeight: map['originalHeight'] as int,
      finalWidth: map['finalWidth'] as int,
      finalHeight: map['finalHeight'] as int,
      croppedToSquare: map['croppedToSquare'] as bool,
      downscaled: map['downscaled'] as bool,
    );
  }

  final Uint8List pngBytes;
  final int originalWidth;
  final int originalHeight;
  final int finalWidth;
  final int finalHeight;
  final bool croppedToSquare;
  final bool downscaled;
}

Future<Map<String, dynamic>?> _processWidgetImage(
  Map<String, dynamic> param,
) async {
  try {
    final Uint8List bytes = param['bytes'] as Uint8List;
    final int targetSize = param['targetSize'] as int;

    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    // Apply EXIF orientation before cropping to prevent portrait photos from being rotated incorrectly
    final img.Image oriented = img.bakeOrientation(decoded);

    final int originalWidth = oriented.width;
    final int originalHeight = oriented.height;
    final int minSide = math.min(originalWidth, originalHeight);
    if (minSide <= 0) {
      return null;
    }

    img.Image working = oriented;
    bool croppedToSquare = false;
    if (originalWidth != originalHeight) {
      final int cropSize = minSide;
      final int left = ((originalWidth - cropSize) / 2).round();
      final int top = ((originalHeight - cropSize) / 2).round();
      working = img.copyCrop(
        oriented,
        x: math.max(0, left),
        y: math.max(0, top),
        width: cropSize,
        height: cropSize,
      );
      croppedToSquare = true;
    }

    img.Image finalImage = working;
    bool downscaled = false;
    if (working.width > targetSize) {
      finalImage = img.copyResize(
        working,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.linear,
      );
      downscaled = true;
    }

    final Uint8List pngBytes =
        Uint8List.fromList(img.encodePng(finalImage, level: 0));

    return <String, dynamic>{
      'pngBytes': pngBytes,
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'finalWidth': finalImage.width,
      'finalHeight': finalImage.height,
      'croppedToSquare': croppedToSquare,
      'downscaled': downscaled,
    };
  } catch (e) {
    // Catch errors from copyCrop, copyResize, encodePng (malformed images, OOM, etc.)
    return null;
  }
}

class _WidgetSourceBytes {
  const _WidgetSourceBytes({
    required this.bytes,
    required this.sourceLabel,
  });

  final Uint8List bytes;
  final String sourceLabel;
}
