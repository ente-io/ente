import 'dart:async';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'dart:io' as dartio;
import 'package:exif/exif.dart';
import 'package:photos/models/file_type.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share/share.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
DateFormat _exifDateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
final _logger = Logger("ShareUtil");
// share is used to share media/files from ente to other apps
Future<void> share(BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "preparing...");
  await dialog.show();
  final List<Future<String>> pathFutures = [];
  for (File file in files) {
    pathFutures.add(getFile(file).then((file) => file.path));
  }
  final paths = await Future.wait(pathFutures);
  await dialog.hide();
  return Share.shareFiles(paths);
}

Future<void> shareText(String text) async {
  return Share.share(text);
}

Future<List<File>> convertIncomingSharedMediaToFile(
    List<SharedMediaFile> sharedMedia, int collectionID) async {
  List<File> localFiles = [];
  for (var media in sharedMedia) {
    var enteFile = File();
    var exifMap = await readExifFromFile(dartio.File(media.path));
    if (exifMap != null && exifMap["Image DateTime"] != null) {
      try {
        final exifTime =
            _exifDateFormat.parse(exifMap["Image DateTime"].toString());
        enteFile.creationTime = exifTime.microsecondsSinceEpoch;
      } catch (e) {
        _logger.warning("Failed to parse time from exif",
            exifMap["Image DateTime"].toString());
        // ignore
      }
    }
    enteFile.localID = "ente-upload-cache:" + media.path;
    enteFile.collectionID = collectionID;
    enteFile.fileType = FileType.image;
    enteFile.title = basename(media.path);
    if (enteFile.creationTime == null || enteFile.creationTime == 0) {
      enteFile.creationTime = 0;
      try {
        final parsedDateTime = DateTime.parse(
            basenameWithoutExtension(media.path)
                .replaceAll("IMG_", "")
                .replaceAll("DCIM_", "")
                .replaceAll("_", " "));
        enteFile.creationTime = parsedDateTime.microsecondsSinceEpoch;
      } catch (e) {
        enteFile.creationTime =
            dartio.File(media.path).lastModifiedSync().microsecondsSinceEpoch;
      }
    }
    enteFile.modificationTime = enteFile.creationTime;
    localFiles.add(enteFile);
  }
  return localFiles;
}
