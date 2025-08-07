import 'dart:async';
import "dart:io";
import "dart:typed_data";

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import "package:photo_manager/photo_manager.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/local/shared_asset.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/local/shared_assert.service.dart";
import "package:photos/ui/sharing/show_images_prevew.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/exif_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/standalone/date_time.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import "package:screenshot/screenshot.dart";
import 'package:share_plus/share_plus.dart';
import "package:uuid/uuid.dart";

final _logger = Logger("ShareUtil");

/// share is used to share media/files from ente to other apps
Future<void> share(
  BuildContext context,
  List<EnteFile> files, {
  GlobalKey? shareButtonKey,
}) async {
  final remoteFileCount = files.where((element) => element.isRemoteFile).length;
  final dialog = createProgressDialog(
    context,
    "Preparing...",
    isDismissible: remoteFileCount > 2,
  );
  await dialog.show();
  try {
    final List<Future<String?>> pathFutures = [];
    for (EnteFile file in files) {
      // Note: We are requesting the origin file for performance reasons on iOS.
      // This will eat up storage, which will be reset only when the app restarts.
      // We could have cleared the cache had there been a callback to the share API.
      pathFutures.add(
        getFile(file, isOrigin: true).then((fetchedFile) => fetchedFile?.path),
      );
    }
    final paths = await Future.wait(pathFutures);
    await dialog.hide();
    paths.removeWhere((element) => element == null);
    final xFiles = <XFile>[];
    for (String? path in paths) {
      if (path == null) continue;
      xFiles.add(XFile(path));
    }
    await Share.shareXFiles(
      xFiles,
      // required for ipad https://github.com/flutter/flutter/issues/47220#issuecomment-608453383
      sharePositionOrigin: shareButtonRect(context, shareButtonKey),
    );
  } catch (e, s) {
    _logger.severe(
      "failed to fetch files for system share ${files.length}",
      e,
      s,
    );
    await dialog.hide();
    await showGenericErrorDialog(context: context, error: e);
  }
}

/// Returns the rect of button if context and key are not null
/// If key is null, returned rect will be at the center of the screen
Rect shareButtonRect(BuildContext context, GlobalKey? shareButtonKey) {
  Size size = MediaQuery.sizeOf(context);
  final RenderObject? renderObject =
      shareButtonKey?.currentContext?.findRenderObject();
  RenderBox? renderBox;
  if (renderObject != null && renderObject is RenderBox) {
    renderBox = renderObject;
  }
  if (renderBox == null) {
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }
  size = renderBox.size;
  final Offset position = renderBox.localToGlobal(Offset.zero);
  return Rect.fromCenter(
    center: position + Offset(size.width / 2, size.height / 2),
    width: size.width,
    height: size.height,
  );
}

Future<ShareResult> shareText(
  String text, {
  BuildContext? context,
  GlobalKey? key,
}) async {
  try {
    final sharePosOrigin = _sharePosOrigin(context, key);
    return Share.share(
      text,
      sharePositionOrigin: sharePosOrigin,
    );
  } catch (e, s) {
    _logger.severe("failed to share text", e, s);
    return ShareResult.unavailable;
  }
}

Future<List<SharedAsset>> convertIncomingSharedMediaToFile(
  List<SharedMediaFile> sharedMedia,
  int collectionID,
  int ownerID,
) async {
  final List<SharedAsset> sharedAssets = [];
  for (var media in sharedMedia) {
    if (!(media.type == SharedMediaType.image ||
        media.type == SharedMediaType.video)) {
      _logger.warning(
        "ignore unsupported file type ${media.type.toString()} path: ${media.path}",
      );
      continue;
    }
    final sharedLocalId = const Uuid().v4();
    // fileName: img_x.jpg
    final String name = basename(media.path);
    int creationTime = 0;
    int durationInSeconds = 0;
    final fileType =
        media.type == SharedMediaType.image ? FileType.image : FileType.video;
    final ioFile = await SharedAssetService.moveToSharedDir(
      File(media.path),
      sharedLocalId,
    );

    if (fileType == FileType.image) {
      final dateResult = await tryParseExifDateTime(ioFile, null);
      if (dateResult != null && dateResult.time != null) {
        creationTime = dateResult.time!.microsecondsSinceEpoch;
      }
    } else if (fileType == FileType.video) {
      durationInSeconds = (media.duration ?? 0) ~/ 1000;
    }
    if (creationTime == 0) {
      final parsedDateTime =
          parseDateTimeFromName(basenameWithoutExtension(media.path));
      if (parsedDateTime != null) {
        creationTime = parsedDateTime.microsecondsSinceEpoch;
      } else {
        creationTime = DateTime.now().microsecondsSinceEpoch;
      }
    }
    sharedAssets.add(
      SharedAsset(
        id: sharedLocalId,
        name: name,
        type: fileType,
        creationTime: creationTime,
        durationInSeconds: durationInSeconds,
        destCollectionID: collectionID,
        ownerID: ownerID,
      ),
    );
  }
  return sharedAssets;
}

Future<List<EnteFile>> convertPicketAssets(
  List<AssetEntity> pickedAssets,
  int collectionID,
) async {
  final List<EnteFile> localFiles = [];
  for (var asset in pickedAssets) {
    final enteFile = await EnteFile.fromAsset('', asset);
    localFiles.add(enteFile);
  }
  return localFiles;
}

void shareSelected(
  BuildContext context,
  GlobalKey shareButtonKey,
  List<EnteFile> selectedFiles,
) {
  share(
    context,
    selectedFiles.toList(),
    shareButtonKey: shareButtonKey,
  );
}

Future<void> shareImageAndUrl(
  Uint8List imageBytes,
  String url, {
  BuildContext? context,
  GlobalKey? key,
}) async {
  final sharePosOrigin = _sharePosOrigin(context, key);
  await Share.shareXFiles(
    [
      XFile.fromData(
        imageBytes,
        name: 'placeholder_image.png',
        mimeType: 'image/png',
      ),
    ],
    text: url,
    sharePositionOrigin: sharePosOrigin,
  );
}

Future<void> shareAlbumLinkWithPlaceholder(
  BuildContext context,
  Collection collection,
  String url,
  GlobalKey key,
) async {
  final ScreenshotController screenshotController = ScreenshotController();
  final List<EnteFile> filesInCollection = await remoteCache.getCollectionFiles(
    FilterQueryParam(
      collectionID: collection.id,
    ),
  );

  final dialog = createProgressDialog(
    context,
    S.of(context).creatingLink,
    isDismissible: true,
  );
  await dialog.show();

  if (filesInCollection.isEmpty) {
    await dialog.hide();
    await shareText(url);
    return;
  } else {
    final placeholderBytes = await _createAlbumPlaceholder(
      filesInCollection,
      screenshotController,
      context,
    );
    await dialog.hide();

    await shareImageAndUrl(
      placeholderBytes,
      url,
      context: context,
      key: key,
    );
  }
}

/// required for ipad https://github.com/flutter/flutter/issues/47220#issuecomment-608453383
/// This returns the position of the share button if context and key are not null
/// and if not, it returns a default position so that the share sheet on iPad has
/// some position to show up.
Rect _sharePosOrigin(BuildContext? context, GlobalKey? key) {
  late final Rect rect;
  if (context != null) {
    rect = shareButtonRect(context, key);
  } else {
    rect = const Offset(20.0, 20.0) & const Size(10, 10);
  }
  return rect;
}

Future<Uint8List> _createAlbumPlaceholder(
  List<EnteFile> files,
  ScreenshotController screenshotController,
  BuildContext context,
) async {
  final Widget imageWidget = LinkPlaceholder(
    files: files,
  );
  final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
  final bytesOfImageToWidget = await screenshotController.captureFromWidget(
    imageWidget,
    pixelRatio: pixelRatio,
    targetSize: MediaQuery.sizeOf(context),
    delay: const Duration(milliseconds: 300),
  );
  return bytesOfImageToWidget;
}
