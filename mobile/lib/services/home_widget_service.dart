import "dart:io";
import "dart:math";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:image/image.dart" as img;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:path_provider_foundation/path_provider_foundation.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/preload_util.dart";

class HomeWidgetService {
  final Logger _logger = Logger((HomeWidgetService).toString());

  HomeWidgetService._privateConstructor();

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();

  Future<void> initHomeWidget(bool isBackground, [bool syncIt = false]) async {
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

    if (syncIt) {
      final value = await hw.HomeWidget.getWidgetData<int>("totalSet");
      if (value == null) {
        _logger.warning("no home widget active");
        return;
      }

      await hw.HomeWidget.updateWidget(
        name: 'SlideshowWidgetProvider',
        androidName: 'SlideshowWidgetProvider',
        qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
        iOSName: 'SlideshowWidget',
      );
      return;
    }

    await lockAndLoadMemories();
  }

  Future<(Size, Size)?> _renderFile(EnteFile randomFile, String key) async {
    final fullImage = await getFile(randomFile);
    if (fullImage == null) {
      _logger.warning("Can't fetch file");
      return null;
    }

    final image = await decodeImageFromList(await fullImage.readAsBytes());
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final ogSize = Size(width, height);

    final size = min(min(width, height), 1024.0);
    final aspectRatio = width / height;

    late final double cacheWidth;
    late final double cacheHeight;
    if (aspectRatio > 1) {
      cacheWidth = size;
      cacheHeight = (size / aspectRatio);
    } else if (aspectRatio < 1) {
      cacheHeight = size;
      cacheWidth = (size * aspectRatio);
    } else {
      cacheWidth = size;
      cacheHeight = size;
    }

    final cacheSize = Size(cacheWidth, cacheHeight);

    if (Platform.isAndroid) {
      await captureFile2(randomFile, cacheSize, ogSize, key);
      return (ogSize, cacheSize);
    }

    final result = await captureFile(randomFile, cacheSize, ogSize, key);

    if (result == null) {
      _logger.warning("Can't capture file");
      return null;
    }

    await hw.HomeWidget.saveWidgetData(
      key,
      result.path,
    );

    return (ogSize, cacheSize);
  }

  Future<int> countHomeWidgets() async {
    return (await hw.HomeWidget.getInstalledWidgets()).length;
  }

  Future<void> clearHomeWidget() async {
    _logger.info("Clearing SlideshowWidget");

    await hw.HomeWidget.saveWidgetData("totalSet", 0);
    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );
    _logger.info(">>> SlideshowWidget cleared");
  }

  Future captureFile2(
    EnteFile file,
    Size size,
    Size ogSize,
    String key,
  ) async {
    final ogFile = await getFile(file);

    if (ogFile == null) {
      return null;
    }

    final minSize = min(size.width, size.height);
    final Image img = Image.file(
      ogFile,
      fit: BoxFit.cover,
      cacheWidth: size.width.toInt(),
      cacheHeight: size.height.toInt(),
    );

    await PreloadImage.loadImage(img.image);

    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    final widget = ClipSmoothRect(
      radius: SmoothBorderRadius(cornerRadius: 32, cornerSmoothing: 1),
      child: Container(
        width: minSize,
        height: minSize,
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
      logicalSize: Size(minSize, minSize),
      key: key,
    );
    return;
  }

  Future<File?> captureFile(
    EnteFile file,
    Size size,
    Size ogSize,
    String key,
  ) async {
    final ogFile = await getFile(file);

    if (ogFile == null) {
      return null;
    }

    try {
      final dir = await imagePath();
      final String path = '$dir/$key.png';

      final File file = File(path);
      file.createSync(recursive: true);
      final image = img.decodeImage(ogFile.readAsBytesSync());
      final resizedImage = img.copyResize(
        image!,
        width: size.width.toInt(),
        height: size.height.toInt(),
      );
      await file.writeAsBytes(img.encodePng(resizedImage));
      return file;
    } catch (_, __) {
      _logger.severe("Failed to save the capture", _, __);
    }

    return null;
  }

  Future<void> onLaunchFromWidget(Uri? uri, BuildContext context) async {
    if (uri == null) return;

    // final res = previousGeneratedId != null
    //     ? await FilesDB.instance.getFile(
    //         previousGeneratedId,
    //       )
    //     : null;

    // final page = DetailPage(
    //   DetailPageConfiguration(List.unmodifiable([res]), 0, "collection"),
    // );
    // routeToPage(context, page, forceCustomPageRoute: true).ignore();
  }

  Future<List<EnteFile>> getFiles({required bool fetchMemory}) async {
    if (fetchMemory) {
      final memories = await memoriesCacheService.getMemories();
      if (memories.isEmpty) {
        return [];
      }

      // flatten the list to list of ente files
      final files = memories
          .map((e) => e.memories.map((e) => e.file))
          .expand((element) => element)
          .where((element) => element.fileType == FileType.image)
          .toList();

      return files;
    }

    final collectionID =
        await FavoritesService.instance.getFavoriteCollectionID();
    if (collectionID == null) {
      await clearHomeWidget();
      _logger.warning("Favorite collection not found");
      throw "Favorite collection not found";
    }

    final res = await FilesDB.instance.getFilesInCollection(
      collectionID,
      galleryLoadStartTime,
      galleryLoadEndTime,
    );

    return res.files
        .where((element) => element.fileType == FileType.image)
        .toList();
  }

  Future<String> imagePath() async {
    String? directory;
    // coverage:ignore-start
    if (Platform.isIOS) {
      final PathProviderFoundation provider = PathProviderFoundation();

      directory = await provider.getContainerPath(
        appGroupIdentifier: iOSGroupID,
      );
    } else {
      // coverage:ignore-end
      directory = (await getApplicationSupportDirectory()).path;
    }

    if (directory == null) {
      throw "Directory is null";
    }

    final String path = '$directory/home_widget';

    return path;
  }

  Future<void> lockAndLoadMemories() async {
    final files = await getFiles(fetchMemory: true);

    int index = 0;

    for (final file in files) {
      final value = await _renderFile(file, "slideshow_$index").catchError(
        (e, sT) {
          _logger.severe("Error rendering widget", e, sT);
          return null;
        },
      );

      if (value != null) {
        index++;
      }
    }

    if (index == 0) {
      return;
    }

    _logger.info(">>> SlideshowWidget params doing");
    await hw.HomeWidget.saveWidgetData<int>("totalSet", index);

    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );
    _logger.info(">>> SlideshowWidget params done");
  }
}
