import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart' as hw;
import 'package:home_widget/home_widget.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/album_home_widget_service.dart';
import 'package:photos/services/memory_home_widget_service.dart';
import 'package:photos/services/people_home_widget_service.dart';
import 'package:photos/services/smart_memories_service.dart';
import 'package:photos/services/widget_image_isolate.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/thumbnail_util.dart';
import "package:synchronized/synchronized.dart";

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
  // Target max dimension for widget images
  static const double WIDGET_IMAGE_SIZE = 1280.0;
  static const String WIDGET_DIRECTORY = 'home_widget';
  static const String WIDGET_CACHE_DIR = 'cache';
  static const int WIDGET_CACHE_MAX_FILES = 150;
  static const Duration _cacheMaintenanceInterval = Duration(minutes: 10);

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
  DateTime? _lastCacheMaintenance;
  Future<void>? _cacheMaintenanceFuture;

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
    final cacheKey = _cacheKeyForFile(file);
    if (cacheKey == null) {
      _logger.warning(
        'Skipping widget render for ${file.displayName} due to missing uploadedFileID',
      );
      return null;
    }

    final Size? capturedSize =
        await _captureFile(file, key, title, mainKey, cacheKey);
    if (capturedSize == null) {
      _logger.warning("Failed to capture file ${file.displayName}");
      return null;
    }

    return capturedSize;
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
    String cacheKey,
  ) async {
    try {
      final String widgetDirectory = await _getWidgetStorageDirectory();
      final String baseDir = '$widgetDirectory/$WIDGET_DIRECTORY';
      final String cacheDir = '$baseDir/$WIDGET_CACHE_DIR';
      await Directory(cacheDir).create(recursive: true);

      final imageInfo =
          await _ensureCachedWidgetImage(file, cacheDir, cacheKey);
      if (imageInfo == null) {
        _logger
            .warning("Failed to get image for widget for ${file.displayName}");
        return null;
      }

      await setData(key, imageInfo.path);

      // Format date for display
      final String baseSubText =
          await SmartMemoriesService.getDateFormattedLocale(
        creationTime: file.creationTime!,
      );
      final int widthPx = imageInfo.size.width.round();
      final int heightPx = imageInfo.size.height.round();
      final String subText = flagService.internalUser
          ? '$baseSubText, ${widthPx}x${heightPx}px'
          : baseSubText;

      // Create metadata
      final Map<String, dynamic> metadata = {
        "title": title,
        "subText": subText,
        "generatedId": file.generatedID!,
        if (mainKey != null) "mainKey": mainKey,
      };

      // Save metadata in platform-specific format
      await _saveWidgetMetadata(key, metadata);

      return imageInfo.size;
    } catch (error, stackTrace) {
      _logger.severe("Failed to save the thumbnail", error, stackTrace);
      return null;
    }
  }

  String? _cacheKeyForFile(EnteFile file) {
    final uploadedId = file.uploadedFileID;
    if (uploadedId == null) return null;

    final rawSig = (file.hash != null && file.hash!.isNotEmpty)
        ? file.hash!
        : (file.modificationTime ?? file.updationTime ?? 0).toString();
    final contentSig = _sanitizeFilename(rawSig);
    return 'u_${uploadedId}_$contentSig';
  }

  Future<File?> _resolveWidgetSource(EnteFile file) async {
    if (file.fileType == FileType.video) {
      return null;
    }
    if (file.isRemoteFile) {
      final File? remoteFile = await getFile(file);
      if (remoteFile == null) {
        _logger.warning(
          'Failed to fetch full-resolution file for widget ${file.displayName}',
        );
      }
      return remoteFile;
    }
    return getFile(file);
  }

  String _sanitizeFilename(String input) {
    // Allow only alnum, dot, underscore, dash; replace others (including '/') with '_'
    return input.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<void> _enforceCacheBudget(String cacheDirPath) async {
    try {
      final dir = Directory(cacheDirPath);
      if (!await dir.exists()) return;
      final entries = await dir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      if (entries.isEmpty) return;

      final files = entries;

      if (files.length <= WIDGET_CACHE_MAX_FILES) {
        return;
      }

      // Sort by last modified ascending (oldest first)
      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );

      final int filesToDelete = files.length - WIDGET_CACHE_MAX_FILES;
      for (var i = 0; i < filesToDelete; i++) {
        final file = files[i];
        try {
          await file.delete();
        } catch (_) {
          // Best-effort deletion; ignore failures.
        }
      }
    } catch (e, s) {
      _logger.warning('Failed to enforce widget cache budget', e, s);
    }
  }

  Future<({String path, Size size})?> _ensureCachedWidgetImage(
    EnteFile file,
    String cacheDir,
    String cacheKey,
  ) async {
    final String cachedPath = '$cacheDir/$cacheKey.jpg';
    final File cachedFile = File(cachedPath);

    if (await cachedFile.exists()) {
      final ({int width, int height})? dims =
          await WidgetImageIsolate.instance.readImageDimensions(cachedPath);
      final size = dims != null
          ? Size(dims.width.toDouble(), dims.height.toDouble())
          : const Size.square(WIDGET_IMAGE_SIZE);
      return (path: cachedPath, size: size);
    }

    final File? source = await _resolveWidgetSource(file);
    if (source != null) {
      final ({int width, int height})? dims =
          await WidgetImageIsolate.instance.generateWidgetImage(
        sourcePath: source.path,
        cachePath: cachedPath,
        targetShortSide: WIDGET_IMAGE_SIZE,
        quality: 80,
      );
      if (dims != null) {
        final size = Size(
          dims.width.toDouble(),
          dims.height.toDouble(),
        );
        _scheduleCacheMaintenance(cacheDir);
        return (path: cachedPath, size: size);
      }
    }

    final Uint8List? fallback = await getThumbnail(file);
    if (fallback == null) {
      return null;
    }

    await cachedFile.writeAsBytes(fallback, flush: true);
    _scheduleCacheMaintenance(cacheDir);

    final Size fallbackSize = Size.square(thumbnailLargeSize.toDouble());
    return (path: cachedPath, size: fallbackSize);
  }

  void _scheduleCacheMaintenance(String cacheDir) {
    if (_cacheMaintenanceFuture != null) {
      return;
    }
    final now = DateTime.now();
    if (_lastCacheMaintenance != null &&
        now.difference(_lastCacheMaintenance!) < _cacheMaintenanceInterval) {
      return;
    }
    _cacheMaintenanceFuture = _enforceCacheBudget(cacheDir).whenComplete(() {
      _lastCacheMaintenance = DateTime.now();
      _cacheMaintenanceFuture = null;
    });
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

    await clearWidgetCache();

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

  Future<void> clearWidgetCache() async {
    final Future<void>? pendingCleanup = _cacheMaintenanceFuture;
    if (pendingCleanup != null) {
      try {
        await pendingCleanup;
      } catch (_) {
        // ignore cleanup errors; we are about to delete the cache anyway
      }
    }
    _cacheMaintenanceFuture = null;
    _lastCacheMaintenance = null;

    try {
      final String widgetParent = await _getWidgetStorageDirectory();
      final String cachePath =
          '$widgetParent/$WIDGET_DIRECTORY/$WIDGET_CACHE_DIR';
      final Directory cacheDir = Directory(cachePath);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        _logger.info("Widget cache cleared successfully");
      }
    } catch (e, s) {
      _logger.warning("Failed to clear widget cache directory", e, s);
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
