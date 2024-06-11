import 'dart:async';
import "dart:io";
import "dart:typed_data";

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import "package:photo_manager/photo_manager.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/exif_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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
      if (file.fileType == FileType.livePhoto) {
        pathFutures.add(
          getFile(file, liveVideo: true)
              .then((fetchedFile) => fetchedFile?.path),
        );
      }
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

Future<List<EnteFile>> convertIncomingSharedMediaToFile(
  List<SharedMediaFile> sharedMedia,
  int collectionID,
) async {
  final List<EnteFile> localFiles = [];
  for (var media in sharedMedia) {
    if (!(media.type == SharedMediaType.image ||
        media.type == SharedMediaType.video)) {
      _logger.warning(
        "ignore unsupported file type ${media.type.toString()} path: ${media.path}",
      );
      continue;
    }
    final enteFile = EnteFile();
    final sharedLocalId = const Uuid().v4();
    // fileName: img_x.jpg
    enteFile.title = basename(media.path);
    var ioFile = File(media.path);
    try {
      ioFile = ioFile.renameSync(
        Configuration.instance.getSharedMediaDirectory() + "/" + sharedLocalId,
      );
    } catch (e) {
      if (e is FileSystemException) {
        //from renameSync docs:
        //On some platforms, a rename operation cannot move a file between
        //different file systems. If that is the case, instead copySync the
        //file to the new location and then deleteSync the original.
        _logger.info("Creating new copy of file in path ${ioFile.path}");
        final newIoFile = ioFile.copySync(
          Configuration.instance.getSharedMediaDirectory() +
              "/" +
              sharedLocalId,
        );
        if (media.path.contains("io.ente.photos")) {
          _logger.info("delete original file in path ${ioFile.path}");
          ioFile.deleteSync();
        }
        ioFile = newIoFile;
      } else {
        rethrow;
      }
    }
    enteFile.localID = sharedMediaIdentifier + sharedLocalId;
    enteFile.collectionID = collectionID;
    enteFile.fileType =
        media.type == SharedMediaType.image ? FileType.image : FileType.video;
    if (enteFile.fileType == FileType.image) {
      final exifTime = await getCreationTimeFromEXIF(ioFile, null);
      if (exifTime != null) {
        enteFile.creationTime = exifTime.microsecondsSinceEpoch;
      }
    } else if (enteFile.fileType == FileType.video) {
      enteFile.duration = (media.duration ?? 0) ~/ 1000;
    }
    if (enteFile.creationTime == null || enteFile.creationTime == 0) {
      final parsedDateTime =
          parseDateTimeFromFileNameV2(basenameWithoutExtension(media.path));
      if (parsedDateTime != null) {
        enteFile.creationTime = parsedDateTime.microsecondsSinceEpoch;
      } else {
        enteFile.creationTime = DateTime.now().microsecondsSinceEpoch;
      }
    }
    enteFile.modificationTime = enteFile.creationTime;
    enteFile.metadataVersion = EnteFile.kCurrentMetadataVersion;
    localFiles.add(enteFile);
  }
  return localFiles;
}

Future<List<EnteFile>> convertPicketAssets(
  List<AssetEntity> pickedAssets,
  int collectionID,
) async {
  final List<EnteFile> localFiles = [];
  for (var asset in pickedAssets) {
    final enteFile = await EnteFile.fromAsset('', asset);
    enteFile.collectionID = collectionID;
    localFiles.add(enteFile);
  }
  return localFiles;
}

DateTime? parseDateFromFileNam1e(String fileName) {
  if (fileName.startsWith('IMG-') || fileName.startsWith('VID-')) {
    // Whatsapp media files
    return DateTime.tryParse(fileName.split('-')[1]);
  } else if (fileName.startsWith("Screenshot_")) {
    // Screenshots on droid
    return DateTime.tryParse(
      (fileName).replaceAll('Screenshot_', '').replaceAll('-', 'T'),
    );
  } else {
    return DateTime.tryParse(
      (fileName)
          .replaceAll("IMG_", "")
          .replaceAll("VID_", "")
          .replaceAll("DCIM_", "")
          .replaceAll("_", " "),
    );
  }
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
