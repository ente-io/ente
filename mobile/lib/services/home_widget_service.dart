import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:path_provider_foundation/path_provider_foundation.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/memory_home_widget_service.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class HomeWidgetService {
  final Logger _logger = Logger((HomeWidgetService).toString());

  HomeWidgetService._privateConstructor();

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();

  init(SharedPreferences prefs) {
    setAppGroupID(iOSGroupID);
    MemoryHomeWidgetService.instance.init(prefs);
  }

  void setAppGroupID(String id) {
    hw.HomeWidget.setAppGroupId(id).ignore();
  }

  Future<void> initHomeWidget() async {
    await MemoryHomeWidgetService.instance.initMemoryHW(null);
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

  Future<T?> getData<T>(String key) async =>
      await hw.HomeWidget.getWidgetData<T>(key);

  Future<bool?> setData<T>(String key, T? data) async =>
      await hw.HomeWidget.saveWidgetData<T>(key, data);

  Future<Size?> renderFile(
    EnteFile randomFile,
    String key,
    String title,
  ) async {
    const size = 512.0;

    final result = await _captureFile(randomFile, key, title);
    if (!result) {
      _logger.warning("can't capture file ${randomFile.displayName}");
      return null;
    }

    return const Size(size, size);
  }

  Future<int> countHomeWidgets() async {
    return (await hw.HomeWidget.getInstalledWidgets()).length;
  }

  Future<bool> _captureFile(
    EnteFile ogFile,
    String key,
    String title,
  ) async {
    try {
      final thumbnail = await getThumbnail(ogFile);

      late final String? directory;

      // coverage:ignore-start
      if (Platform.isIOS) {
        final PathProviderFoundation provider = PathProviderFoundation();
        directory = await provider.getContainerPath(
          appGroupIdentifier: iOSGroupID,
        );
      } else {
        directory = (await getApplicationSupportDirectory()).path;
      }

      final String path = '$directory/home_widget/$key.png';
      final File file = File(path);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(thumbnail!);

      await setData(key, path);

      final subText = await SmartMemoriesService.getDateFormattedLocale(
        creationTime: ogFile.creationTime!,
      );

      final data = {
        "title": title,
        "subText": subText,
        "generatedId": ogFile.generatedID!,
      };
      if (Platform.isIOS) {
        await hw.HomeWidget.saveWidgetData<Map<String, dynamic>>(
          key + "_data",
          data,
        );
      } else {
        await hw.HomeWidget.saveWidgetData<String>(
          key + "_data",
          jsonEncode(data),
        );
      }
    } catch (_, __) {
      _logger.severe("Failed to save the capture", _, __);
      return false;
    }
    return true;
  }

  Future<void> clearWidget(bool autoLogout) async {
    if (autoLogout) {
      setAppGroupID(iOSGroupID);
    }
    await MemoryHomeWidgetService.instance.clearWidget();
  }

  Future<void> onLaunchFromWidget(Uri? uri, BuildContext context) async {
    if (uri == null) {
      _logger.warning("onLaunchFromWidget: uri is null");
      return;
    }

    final generatedId = int.tryParse(uri.queryParameters["generatedId"] ?? "");

    if (generatedId == null) {
      _logger.warning("onLaunchFromWidget: generatedId is null");
      return;
    }

    if (uri.scheme == "memorywidget") {
      _logger.info("onLaunchFromWidget: redirecting to memory widget");
      await MemoryHomeWidgetService.instance.onLaunchFromWidget(
        generatedId,
        context,
      );
    }
  }
}
