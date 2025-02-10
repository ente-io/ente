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
import "package:photos/models/file/file_type.dart";
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

  Future<void> initHomeWidget() async {
    final isLoggedIn = Configuration.instance.isLoggedIn();

    if (!isLoggedIn) {
      await clearHomeWidget();
      _logger.info("user not logged in");
      return;
    }

    final collectionID =
        await FavoritesService.instance.getFavoriteCollectionID();
    if (collectionID == null) {
      await clearHomeWidget();
      _logger.info("Favorite collection not found");
      return;
    }

    try {
      await hw.HomeWidget.setAppGroupId(iOSGroupID);
      final res = await FilesDB.instance.getFilesInCollection(
        collectionID,
        galleryLoadStartTime,
        galleryLoadEndTime,
      );

      final previousGeneratedId =
          await hw.HomeWidget.getWidgetData<int>("home_widget_last_img");

      if (res.files.length == 1 &&
          res.files[0].generatedID == previousGeneratedId) {
        _logger
            .info("Only one image found and it's the same as the previous one");
        return;
      }
      if (res.files.isEmpty) {
        await clearHomeWidget();
        _logger.info("No images found");
        return;
      }
      final files = res.files.where(
        (element) =>
            element.generatedID != previousGeneratedId &&
            element.fileType == FileType.image,
      );

      if (files.isEmpty) {
        await clearHomeWidget();
        _logger.info("No images found");
        return;
      }

      final randomNumber = Random().nextInt(files.length);
      final randomFile = files.elementAt(randomNumber);
      final fullImage = await getFileFromServer(randomFile);
      if (fullImage == null) throw Exception("File not found");

      final image = await decodeImageFromList(await fullImage.readAsBytes());
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      final size = min(min(width, height), 1024.0);
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

      final platformBrightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;

      final widget = ClipSmoothRect(
        radius: SmoothBorderRadius(cornerRadius: 32, cornerSmoothing: 1),
        child: Container(
          width: size,
          height: size,
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
        logicalSize: Size(size, size),
        key: "slideshow",
      );

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
    } catch (e) {
      _logger.severe("Error rendering widget", e);
    }
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
}
