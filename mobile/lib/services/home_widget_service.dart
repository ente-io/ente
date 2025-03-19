import "dart:convert";
import "dart:io";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:fluttertoast/fluttertoast.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:photos/utils/preload_util.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class HomeWidgetService {
  final Logger _logger = Logger((HomeWidgetService).toString());

  HomeWidgetService._privateConstructor();

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();

  init(SharedPreferences prefs) {
    hw.HomeWidget.setAppGroupId(iOSGroupID).ignore();
    _prefs = prefs;
  }

  static const memoryChangedKey = "memoryChanged.widget";

  late final SharedPreferences _prefs;

  Future<void> checkPendingMemorySync() async {
    final memoryChanged = _prefs.getBool(memoryChangedKey);
    final total = await _getTotal();

    final changeMemories = memoryChanged == true || total == 0 || total == null;

    await initHomeWidget(changeMemories: changeMemories);
  }

  Future<void> updateMemoryChanged(bool value) async {
    await _prefs.setBool(memoryChangedKey, value);
  }

  Future<void> initHomeWidget({
    bool bypassCount = false,
    bool changeMemories = false,
  }) async {
    final isLoggedIn = Configuration.instance.isLoggedIn();
    if (!isLoggedIn) {
      _logger.warning("user not logged in");
      return;
    }

    final areMemoriesShown = memoriesCacheService.showAnyMemories;
    if (!areMemoriesShown) {
      _logger.warning("memories not enabled");
      await clearHomeWidget();
      return;
    }

    if (changeMemories) {
      await _forceMemoryUpdate();
    } else {
      final total = await _getTotal();
      if (total == 0 || total == null) {
        _logger.warning(
          "sync stopped because no memory is cached yet, so nothing to sync",
        );
        return;
      }
      await _memorySync(
        bypassCount: bypassCount,
      );
    }
  }

  Future<void> _forceMemoryUpdate() async {
    await _lockAndLoadMemories();
    await updateMemoryChanged(false);
  }

  Future<void> _memorySync({
    bool bypassCount = false,
  }) async {
    final homeWidgetCount = await HomeWidgetService.instance.countHomeWidgets();
    if (!bypassCount && homeWidgetCount == 0) {
      _logger.warning("no home widget active");
      return;
    }

    await _updateWidget(text: "[i] refreshing from same set");
    _logger.info(">>> Refreshing memory from same set");
  }

  Future<Size?> _renderFile(
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

  Future<void> clearHomeWidget() async {
    final total = await _getTotal();
    if (total == 0 || total == null) return;

    _logger.info("Clearing SlideshowWidget");

    await _setTotal(0);

    await _updateWidget(text: "[i] SlideshowWidget cleared & updated");
    _logger.info(">>> SlideshowWidget cleared");
  }

  Future<bool> _captureFile(
    EnteFile ogFile,
    String key,
    String title,
  ) async {
    try {
      final thumbnail = await getThumbnail(ogFile);

      final decoded = await decodeImageFromList(thumbnail!);
      final double width = decoded.width.toDouble();
      final double height = decoded.height.toDouble();

      final Image img = Image.memory(
        thumbnail,
        fit: BoxFit.cover,
        cacheWidth: width.toInt(),
        cacheHeight: height.toInt(),
      );

      await PreloadImage.loadImage(img.image);

      final platformBrightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;

      final widget = ClipSmoothRect(
        radius: SmoothBorderRadius(cornerRadius: 32, cornerSmoothing: 1),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: platformBrightness == Brightness.light
                ? const Color.fromRGBO(251, 251, 251, 1)
                : const Color.fromRGBO(27, 27, 27, 1),
            image: DecorationImage(image: img.image, fit: BoxFit.cover),
          ),
        ),
      );
      await hw.HomeWidget.renderFlutterWidget(
        widget,
        logicalSize: Size(width, height),
        key: key,
      );

      final data = {
        "title": title,
        "subText": SmartMemoriesService.getDateFormatted(
          creationTime: ogFile.creationTime!,
        ),
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

  Future<void> onLaunchFromWidget(Uri? uri, BuildContext context) async {
    if (uri == null) {
      _logger.warning("onLaunchFromWidget: uri is null");
      return;
    }

    final generatedId = int.tryParse(uri.queryParameters["generatedId"] ?? "");
    _logger.info("onLaunchFromWidget: $uri, $generatedId");

    if (generatedId == null) {
      _logger.warning("onLaunchFromWidget: generatedId is null");
      return;
    }

    await memoriesCacheService.goToMemoryFromGeneratedFileID(
      context,
      generatedId,
    );
  }

  Future<Map<String, Iterable<EnteFile>>> _getMemories() async {
    // if (fetchMemory) {
    final memories = await memoriesCacheService.getMemories();
    if (memories.isEmpty) {
      return {};
    }

    // flatten the list to list of ente files
    final files = memories.asMap().map(
          (k, v) => MapEntry(
            v.title,
            v.memories.map((e) => e.file),
          ),
        );

    return files;
  }

  Future<void> _updateWidget({String? text}) async {
    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );
    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: text ?? "[i] SlideshowWidget updated",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    _logger.info(">>> Home Widget updated");
  }

  Future<int?> _getTotal() async {
    return await hw.HomeWidget.getWidgetData<int>("totalSet");
  }

  Future<void> _setTotal(int total) async {
    await hw.HomeWidget.saveWidgetData("totalSet", total);
  }

  Future<void> _lockAndLoadMemories() async {
    final files = await _getMemories();

    if (files.isEmpty) {
      _logger.warning("No files found, clearing everything");
      await clearHomeWidget();
      return;
    }

    int index = 0;

    for (final i in files.entries) {
      for (final file in i.value) {
        final value =
            await _renderFile(file, "slideshow_$index", i.key).catchError(
          (e, sT) {
            _logger.severe("Error rendering widget", e, sT);
            return null;
          },
        );

        if (value != null) {
          await _setTotal(index);
          if (index == 1) {
            await _updateWidget(
              text: "[i] First memory fetched. updating widget",
            );
          }
          index++;
        }
      }
    }

    if (index == 0) {
      return;
    }

    await _updateWidget();
    _logger.info(">>> Switching to next memory set");
  }
}
