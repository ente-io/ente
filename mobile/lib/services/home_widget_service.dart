import "dart:convert";
import "dart:io";

import "package:crypto/crypto.dart";
import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:fluttertoast/fluttertoast.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/memories_service.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/preload_util.dart";
import "package:photos/utils/thumbnail_util.dart";

class HomeWidgetService {
  final Logger _logger = Logger((HomeWidgetService).toString());

  HomeWidgetService._privateConstructor();

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();

  Future<void> initHomeWidget(bool isBackground, {bool bypass = false}) async {
    if (isBackground) {
      _logger.warning("app is running in background");
      return;
    }

    await hw.HomeWidget.setAppGroupId(iOSGroupID);

    final homeWidgetCount = await HomeWidgetService.instance.countHomeWidgets();
    if (homeWidgetCount == 0) {
      _logger.warning("no home widget active");
      return;
    }

    final isLoggedIn = Configuration.instance.isLoggedIn();
    if (!isLoggedIn) {
      await clearHomeWidget();
      _logger.warning("user not logged in");
      return;
    }

    final memoriesEnabled = MemoriesService.instance.showMemories;
    if (!memoriesEnabled) {
      _logger.warning("memories not enabled");
      await clearHomeWidget();
      return;
    }

    await _lockAndLoadMemories(bypass: bypass);
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
    await _setFilesHash(null);
    await _setTotal(0);
    await _updateWidget();
    _logger.info(">>> SlideshowWidget cleared");
  }

  Future<String?> _getFilesHash() async {
    return await hw.HomeWidget.getWidgetData<String>("filesHash");
  }

  Future<void> _setFilesHash(String? fileHash) async {
    await hw.HomeWidget.saveWidgetData("filesHash", fileHash);
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
      await initHomeWidget(false);
      return;
    }

    final generatedId = int.tryParse(uri.queryParameters["generatedId"] ?? "");
    _logger.info("onLaunchFromWidget: $uri, $generatedId");

    final res = generatedId != null
        ? await FilesDB.instance.getFile(generatedId)
        : null;

    if (res == null) {
      return;
    }

    final page = DetailPage(
      DetailPageConfiguration(List.unmodifiable([res]), 0, "collection"),
    );
    routeToPage(context, page, forceCustomPageRoute: true).ignore();
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

  String _getFilesKey(Map<String, Iterable<EnteFile>> files) {
    // 1: file1_file2_file3, 2: file4_file5_file6 -> md5 hash
    final key = files.entries
        .map(
          (entry) =>
              entry.key + ": " + entry.value.map((e) => e.cacheKey()).join("_"),
        )
        .join(", ");
    final hash = md5.convert(key.codeUnits).toString();
    return hash;
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

  Future<void> _lockAndLoadMemories({bool bypass = false}) async {
    final files = await _getMemories();

    if (files.isEmpty) {
      _logger.warning("No files found, clearing everything");
      await clearHomeWidget();
      return;
    }

    final keyHash = _getFilesKey(files);

    final value = await _getFilesHash();
    if (value != null && value == keyHash) {
      _logger.info("No changes detected in memories");
      await _updateWidget(text: "[i] No changes, refreshing from same set");
      _logger.info(">>> Refreshing memory from same set");
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
              text: bypass
                  ? "[i] First memory after bypass, updating widget"
                  : "[i] First memory fetched. updating widget",
            );
          }
          index++;
        }
      }
    }

    if (index == 0) {
      return;
    }

    await _setFilesHash(keyHash);

    await _updateWidget(
      text: bypass ? "[i] Bypassing memory set check, updated widget" : null,
    );
    _logger.info(">>> Switching to next memory set");
  }
}
