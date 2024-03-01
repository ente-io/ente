import "dart:math";

import "package:flutter/material.dart";
import 'package:home_widget/home_widget.dart' as hw;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/preload_util.dart";

Future<int> countHomeWidgets() async {
  return await hw.HomeWidget.getWidgetCount(
        name: 'SlideshowWidgetProvider',
        androidName: 'SlideshowWidgetProvider',
        qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
        iOSName: 'SlideshowWidget',
      ) ??
      0;
}

Future<void> initHomeWidget() async {
  final Logger logger = Logger("initHomeWidget");
  final user = Configuration.instance.getUserID();

  if (user == null) {
    await clearHomeWidget();
    throw Exception("User not found");
  }

  final collectionID =
      await FavoritesService.instance.getFavoriteCollectionID();
  if (collectionID == null) {
    await clearHomeWidget();
    throw Exception("Collection not found");
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
    final files = res.files.where(
      (element) =>
          element.generatedID != previousGeneratedId &&
          element.fileType == FileType.image,
    );
    final randomNumber = Random().nextInt(files.length);
    final randomFile = files.elementAt(randomNumber);
    final fullImage = await getFileFromServer(randomFile);
    if (fullImage == null) throw Exception("File not found");

    Image img = Image.file(fullImage);
    var imgProvider = img.image;
    await PreloadImage.loadImage(imgProvider);

    img = Image.file(fullImage);
    imgProvider = img.image;

    final image = await decodeImageFromList(await fullImage.readAsBytes());
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final size = min(min(width, height), 1024.0);

    final widget = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(image: imgProvider, fit: BoxFit.cover),
        ),
      ),
    );

    await hw.HomeWidget.renderFlutterWidget(
      widget,
      logicalSize: Size(size, size),
      key: "slideshow",
    );

    await hw.HomeWidget.updateWidget(
      name: 'SlideshowWidgetProvider',
      androidName: 'SlideshowWidgetProvider',
      qualifiedAndroidName: 'io.ente.photos.SlideshowWidgetProvider',
      iOSName: 'SlideshowWidget',
    );

    if (randomFile.generatedID != null) {
      await hw.HomeWidget.saveWidgetData<int>(
        "home_widget_last_img",
        randomFile.generatedID!,
      );
    }

    logger.info(
      ">>> SlideshowWidget rendered with size ${width}x$height",
    );
  } catch (_) {
    throw Exception("Error rendering widget");
  }
}

Future<void> clearHomeWidget() async {
  final previousGeneratedId =
      await hw.HomeWidget.getWidgetData<int>("home_widget_last_img");
  if (previousGeneratedId == null) return;

  final Logger logger = Logger("clearHomeWidget");

  logger.info("Clearing SlideshowWidget");
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
  logger.info(">>> SlideshowWidget cleared");
}
