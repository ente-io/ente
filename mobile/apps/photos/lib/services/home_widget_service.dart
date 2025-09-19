import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import "package:synchronized/synchronized.dart";

import 'package:photos/utils/widget_image_util.dart';

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
  static const double THUMBNAIL_SIZE = 512.0; // Legacy size for compatibility
  static const double WIDGET_IMAGE_SIZE =
      1280.0; // Optimal size for mobile widgets (xxxhdpi screens)
  static const String WIDGET_DIRECTORY = 'home_widget';

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

  // Track separate operations for each widget type
  final Map<String, CancelableOperation> _widgetOperations = {};

  // Track last widget sync time to prevent rapid consecutive syncs
  DateTime? _lastWidgetSyncTime;
  static const Duration _minSyncInterval = Duration(seconds: 10);

  // Global circuit breaker for widget operations
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;
  DateTime? _circuitBreakerOpenedAt;
  static const Duration _circuitBreakerResetDuration = Duration(minutes: 5);

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

  Future<void> initHomeWidget([bool isBg = false]) async {
    // Prevent rapid consecutive widget syncs
    final now = DateTime.now();
    if (_lastWidgetSyncTime != null) {
      final timeSinceLastSync = now.difference(_lastWidgetSyncTime!);
      if (timeSinceLastSync < _minSyncInterval) {
        _logger.info(
          "Skipping widget sync, too soon since last sync "
          "(${timeSinceLastSync.inSeconds}s < ${_minSyncInterval.inSeconds}s)",
        );
        return;
      }
    }
    _lastWidgetSyncTime = now;

    // Circuit breaker improvements for enhanced widget feature
    if (flagService.enhancedWidgetImage) {
      // Clear failed attempts for HEIC files to allow retrying with new fix
      clearAllFailedAttempts();
      // Reset circuit breaker if it was triggered
      if (_circuitBreakerOpenedAt != null) {
        _logger.info("[Enhanced] Resetting circuit breaker for widget sync");
        _resetCircuitBreaker();
      }
    }

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
    // Check circuit breaker (enhanced widget feature)
    if (flagService.enhancedWidgetImage) {
      if (_circuitBreakerOpenedAt != null) {
        final timeSinceOpened =
            DateTime.now().difference(_circuitBreakerOpenedAt!);
        if (timeSinceOpened < _circuitBreakerResetDuration) {
          _logger.info(
            "[Enhanced] Widget circuit breaker is open, skipping render "
            "(${timeSinceOpened.inSeconds}s / ${_circuitBreakerResetDuration.inSeconds}s)",
          );
          return null;
        } else {
          // Reset circuit breaker
          _logger.info(
            "[Enhanced] Resetting widget circuit breaker after timeout",
          );
          _circuitBreakerOpenedAt = null;
          _consecutiveFailures = 0;
        }
      }
    }
    final actualSize = await _captureFile(file, key, title, mainKey);
    if (actualSize == null) {
      _consecutiveFailures++;
      _logger.warning(
        "Failed to capture file ${file.displayName} "
        "(consecutive failures: $_consecutiveFailures/$_maxConsecutiveFailures)",
      );

      // Open circuit breaker if too many failures (enhanced widget feature)
      if (flagService.enhancedWidgetImage &&
          _consecutiveFailures >= _maxConsecutiveFailures) {
        _circuitBreakerOpenedAt = DateTime.now();
        _logger.severe(
          "[Enhanced] Too many consecutive widget failures, opening circuit breaker for "
          "${_circuitBreakerResetDuration.inMinutes} minutes",
        );
      }
      return null;
    }

    // Reset failure count on success
    _consecutiveFailures = 0;
    return actualSize;
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

  Future<Size?> _captureFile(
    EnteFile file,
    String key,
    String title,
    String? mainKey,
  ) async {
    try {
      // Get widget image with proper EXIF handling
      const imageSize = WIDGET_IMAGE_SIZE; // 1280px for optimal quality
      _logger.info("Calling getWidgetImage for ${file.displayName}");

      Uint8List? imageData;
      try {
        imageData = await getWidgetImage(
          file,
          maxSize: imageSize,
          quality: 100,
        );
      } catch (e, stackTrace) {
        _logger.severe(
          "Exception in getWidgetImage for ${file.displayName}",
          e,
          stackTrace,
        );
        return null;
      }

      if (imageData == null) {
        _logger.severe(
          "Failed to get widget image for file ${file.displayName} "
          "(type: ${file.fileType}, localID: ${file.localID}, "
          "uploadedID: ${file.uploadedFileID}, isRemote: ${file.isRemoteFile})",
        );
        return null;
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

      await thumbnailFile.writeAsBytes(imageData);
      await setData(key, thumbnailPath);

      // Format date for display
      final baseSubText = await SmartMemoriesService.getDateFormattedLocale(
        creationTime: file.creationTime!,
      );

      // In debug mode, show actual image size with (i) suffix
      String subText = baseSubText;
      if (kDebugMode) {
        final qualityIndicator = "${imageSize.toInt()}px";
        subText = "$baseSubText • $qualityIndicator (i)";
      }

      // Create metadata
      final Map<String, dynamic> metadata = {
        "title": title,
        "subText": subText,
        "generatedId": file.generatedID!,
        if (mainKey != null) "mainKey": mainKey,
      };

      // Save metadata in platform-specific format
      await _saveWidgetMetadata(key, metadata);

      return const Size(imageSize, imageSize);
    } catch (error, stackTrace) {
      _logger.severe("Failed to save the thumbnail", error, stackTrace);
      return null;
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
    // Cancel all ongoing widget operations
    for (final widgetType in _widgetOperations.keys.toList()) {
      await cancelWidgetOperation(widgetType);
    }

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

    // Clear widget image cache
    try {
      await WidgetCacheManager().emptyCache();
      _logger.info("Widget cache cleared successfully");
    } catch (e) {
      _logger.severe("Failed to clear widget cache", e);
    }

    // Reset circuit breaker when clearing widget
    _resetCircuitBreaker();
  }

  /// Reset the circuit breaker (useful after fixing issues)
  void _resetCircuitBreaker() {
    _consecutiveFailures = 0;
    _circuitBreakerOpenedAt = null;
    clearAllFailedAttempts(); // Also clear failed attempts when resetting
    _logger.info("Circuit breaker and failed attempts cache reset");
  }

  /// Cancel ongoing widget operation for a specific widget type
  Future<void> cancelWidgetOperation(String widgetType) async {
    final operation = _widgetOperations[widgetType];
    if (operation != null && !operation.isCompleted) {
      _logger.info("Cancelling ongoing $widgetType widget operation");
      await operation.cancel();
      _widgetOperations.remove(widgetType);
    }
  }

  /// Set the widget operation for a specific widget type
  void setWidgetOperation(String widgetType, CancelableOperation operation) {
    _widgetOperations[widgetType] = operation;
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
