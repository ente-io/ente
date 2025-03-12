import "dart:io";
import "dart:math";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/preload_util.dart";

class HomeWidgetService {
  final Logger _logger = Logger((HomeWidgetService).toString());

  HomeWidgetService._privateConstructor();

  static final HomeWidgetService instance =
      HomeWidgetService._privateConstructor();

  Future<void> initHomeWidget(bool isBackground) async {
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

    if (Platform.isIOS) {
      Future.delayed(const Duration(seconds: 4), lockAndLoadMemories);
      return;
    }

    final collectionID =
        await FavoritesService.instance.getFavoriteCollectionID();
    if (collectionID == null) {
      await clearHomeWidget();
      _logger.warning("Favorite collection not found");
      return;
    }

    try {
      final res = await FilesDB.instance.getFilesInCollection(
        collectionID,
        galleryLoadStartTime,
        galleryLoadEndTime,
      );

      final previousGeneratedId =
          await hw.HomeWidget.getWidgetData<int>("home_widget_last_img");

      final files = res.files.where(
        (element) =>
            element.generatedID != previousGeneratedId &&
            element.fileType == FileType.image,
      );

      if (files.isEmpty) {
        await clearHomeWidget();
        _logger.warning("No new images found");
        return;
      }

      final randomNumber = Random().nextInt(files.length);
      final randomFile = files.elementAt(randomNumber);

      final value = await _renderFile(randomFile, "slideshow");
      if (value == null) {
        return;
      }

      final width = value.$1.width;
      final height = value.$1.height;
      final cacheWidth = value.$2.width;
      final cacheHeight = value.$2.height;

      if (randomFile.generatedID != null) {
        await hw.HomeWidget.saveWidgetData<int>(
          "home_widget_last_img",
          randomFile.generatedID!,
        );
      }

      await hw.HomeWidget.updateWidget(
        name: 'SlideshowWidgetProvider',
        androidName: 'SlideshowWidgetProvider',
        qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
        iOSName: 'SlideshowWidget',
      );
      _logger.info(
        ">>> OG size of SlideshowWidget image: $width x $height",
      );
      _logger.info(
        ">>> SlideshowWidget image rendered with size $cacheWidth x $cacheHeight",
      );
    } catch (e, sT) {
      _logger.severe("Error rendering widget", e, sT);
    }
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
    final size = min(min(width, height), 200.0);
    final aspectRatio = width / height;
    late final int cacheWidth;
    late final int cacheHeight;
    if (aspectRatio > 1) {
      cacheWidth = 1024;
      cacheHeight = (1024 / aspectRatio).round();
    } else if (aspectRatio < 1) {
      cacheHeight = 1024;
      cacheWidth = (1024 * aspectRatio).round();
    } else {
      cacheWidth = 1024;
      cacheHeight = 1024;
    }
    final Image img = Image.file(
      fullImage,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );

    await PreloadImage.loadImage(img.image);

    final widget = ClipSmoothRect(
      radius: SmoothBorderRadius(cornerRadius: 32, cornerSmoothing: 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          image: DecorationImage(image: img.image, fit: BoxFit.cover),
        ),
      ),
    );

    await hw.HomeWidget.renderFlutterWidget(
      widget,
      logicalSize: Size(size, size),
      key: key,
    );

    return (
      Size(width, height),
      Size(cacheWidth.toDouble(), cacheHeight.toDouble())
    );
  }

  Future<int> countHomeWidgets() async {
    return (await hw.HomeWidget.getInstalledWidgets()).length;
  }

  Future<void> clearHomeWidget() async {
    final previousGeneratedId =
        await hw.HomeWidget.getWidgetData<int>("home_widget_last_img");
    if (previousGeneratedId == null) return;

    _logger.info("Clearing SlideshowWidget");
    await hw.HomeWidget.saveWidgetData(
      "slideshow",
      null,
    );

    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );
    await hw.HomeWidget.saveWidgetData<int>(
      "home_widget_last_img",
      null,
    );
    _logger.info(">>> SlideshowWidget cleared");
  }

  Future<void> onLaunchFromWidget(Uri? uri, BuildContext context) async {
    if (uri == null) return;

    final collectionID =
        await FavoritesService.instance.getFavoriteCollectionID();
    if (collectionID == null) {
      return;
    }

    final collection = CollectionsService.instance.getCollectionByID(
      collectionID,
    );
    if (collection == null) {
      return;
    }

    final thumbnail = await CollectionsService.instance.getCover(collection);

    final previousGeneratedId =
        await hw.HomeWidget.getWidgetData<int>("home_widget_last_img");

    final res = previousGeneratedId != null
        ? await FilesDB.instance.getFile(
            previousGeneratedId,
          )
        : null;

    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(
          collection,
          thumbnail,
        ),
      ),
    ).ignore();

    if (res == null) return;

    final page = DetailPage(
      DetailPageConfiguration(List.unmodifiable([res]), 0, "collection"),
    );
    routeToPage(context, page, forceCustomPageRoute: true).ignore();
  }

  Future<List<EnteFile>> getFiles(bool isMemory) async {
    if (isMemory) {
      final memories = await memoriesCacheService.getMemories(100);
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

  Future<void> lockAndLoadMemories() async {
    final files = await getFiles(false);

    int index = 0;

    for (final file in files) {
      final value = await _renderFile(file, "memory_$index").catchError(
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
    await hw.HomeWidget.saveWidgetData<int>("totalMemories", index);

    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );
    _logger.info(">>> SlideshowWidget params done");
  }
}
