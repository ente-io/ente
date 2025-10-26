import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart' as hw;
import 'package:home_widget/home_widget.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/album_home_widget_service.dart';
import 'package:photos/services/memory_home_widget_service.dart';
import 'package:photos/services/people_home_widget_service.dart';
import 'package:photos/services/smart_memories_service.dart';
import 'package:photos/utils/thumbnail_util.dart';
import 'package:photos/utils/file_util.dart';
import "package:synchronized/synchronized.dart";
import 'package:flutter/painting.dart' as paint;

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

// Top-level function for isolate to decode image
Future<ui.Image> _decodeImageInIsolate(Uint8List imageBytes) async {
  return await paint.decodeImageFromList(imageBytes);
}

/// Service to manage home screen widgets across the application
/// Handles widget initialization, updates, and interaction with platform-specific widget APIs
class HomeWidgetService {
  // Constants
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
    // Use V2 (1024x1024 rendering) only in debug mode for now
    final bool useV2 = flagService.useWidgetV2;

    if (useV2) {
      // Try V2 first, fallback to V1 if it fails (e.g., for videos, live photos)
      final result = await _captureFileV2(file, key, title, mainKey);
      if (result) {
        return const Size(THUMBNAIL_SIZE_V2, THUMBNAIL_SIZE_V2);
      }
      _logger.info(
        "V2 capture failed for ${file.displayName}, falling back to V1",
      );
    }

    // Use V1 (either useV2 is false, or V2 failed)
    final result = await _captureFile(file, key, title, mainKey);
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

  Future<List<HomeWidgetInfo>> getInstalledWidgets() async {
    return await hw.HomeWidget.getInstalledWidgets();
  }

  Future<bool> _captureFile(
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

  Future<bool> _captureFileV2(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    try {
      // For images, use full file decoding for highest quality
      if (file.fileType == FileType.image) {
        return await _captureImageV2(file, key, title, mainKey);
      }

      // For videos and live photos, use high-res thumbnails (local only)
      if (file.fileType == FileType.video || file.fileType == FileType.livePhoto) {
        // Only local files can get high-res thumbnails from PhotoManager
        // Remote files would require downloading full video, which is too expensive
        if (!file.isRemoteFile) {
          return await _captureVideoOrLivePhotoV2(file, key, title, mainKey);
        } else {
          _logger.info(
            "Skipping V2 for remote ${file.fileType} file: ${file.displayName}",
          );
          return false;
        }
      }

      // Other file types fall back to V1
      _logger.info("Skipping V2 for file type: ${file.fileType}");
      return false;
    } catch (error, stackTrace) {
      _logger.severe("Failed to save V2 widget", error, stackTrace);
      return false;
    }
  }

  Future<bool> _captureImageV2(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    try {
      // Get full image file or high quality version
      final File? imageFile = file.isRemoteFile
          ? await getFileFromServer(file)
          : await getFile(file);

      if (imageFile == null) {
        _logger.warning("Failed to get file for V2 widget ${file.displayName}");
        return false;
      }

      // Read image bytes and decode to get dimensions
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image in isolate to avoid UI jank
      final ui.Image decodedImage = await compute(
        _decodeImageInIsolate,
        imageBytes,
      );

      final width = decodedImage.width.toDouble();
      final height = decodedImage.height.toDouble();
      final minDimension = width < height ? width : height;
      final size = minDimension < THUMBNAIL_SIZE_V2 ? minDimension : THUMBNAIL_SIZE_V2;

      // Clean up decoded image
      decodedImage.dispose();

      // Create image provider from file
      final imageProvider = FileImage(imageFile);

      // Create widget with image
      final widget = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      // Render widget using home_widget package
      await hw.HomeWidget.renderFlutterWidget(
        widget,
        logicalSize: Size(size, size),
        key: key,
      );

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
      _logger.severe("Failed to save image V2", error, stackTrace);
      return false;
    }
  }

  Future<bool> _captureVideoOrLivePhotoV2(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    try {
      // Request high-quality thumbnail from PhotoManager (1024px instead of 512px)
      final Uint8List? thumbnail = await getThumbnailFromLocal(
        file,
        size: THUMBNAIL_SIZE_V2.toInt(),
      );

      if (thumbnail == null) {
        _logger.warning(
          "Failed to get high-res thumbnail for V2 widget ${file.displayName}",
        );
        return false;
      }

      // PhotoManager already returns thumbnail at requested size, no need to decode for dimensions
      final imageProvider = MemoryImage(thumbnail);

      // Create widget with image
      final widget = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: THUMBNAIL_SIZE_V2,
          height: THUMBNAIL_SIZE_V2,
          decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      // Render widget using home_widget package
      await hw.HomeWidget.renderFlutterWidget(
        widget,
        logicalSize: const Size(THUMBNAIL_SIZE_V2, THUMBNAIL_SIZE_V2),
        key: key,
      );

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
      _logger.severe("Failed to save video/live photo V2", error, stackTrace);
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
