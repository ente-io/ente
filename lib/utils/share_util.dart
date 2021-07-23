import 'dart:async';
import 'dart:io';
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
    enteFile.localID = "ente-upload-cache:" + media.path;
    enteFile.collectionID = collectionID;
    enteFile.fileType = FileType.image;
    enteFile.title = basename(media.path);

    var exifMap = await readExifFromFile(dartio.File(media.path));
    if (exifMap != null &&
        exifMap["Image DateTime"] != null &&
        '0000:00:00 00:00:00' != exifMap["Image DateTime"].toString()) {
      try {
        final exifTime =
            _exifDateFormat.parse(exifMap["Image DateTime"].toString());
        enteFile.creationTime = exifTime.microsecondsSinceEpoch;
      } catch (e) {
        //ignore
      }
    }
    if (enteFile.creationTime == null || enteFile.creationTime == 0) {
      final parsedDateTime =
          parseDateFromFileName(basenameWithoutExtension(media.path));
      if (parsedDateTime != null) {
        enteFile.creationTime = parsedDateTime.microsecondsSinceEpoch;
      } else {
        enteFile.creationTime = DateTime.now().microsecondsSinceEpoch;
      }
    }
    enteFile.modificationTime = enteFile.creationTime;
    localFiles.add(enteFile);
  }
  return localFiles;
}

DateTime parseDateFromFileName(String fileName) {
  if (fileName.startsWith('IMG-') || fileName.startsWith('VID-')) {
    // Whatsapp media files
    return DateTime.tryParse(fileName.split('-')[1]);
  } else if (fileName.startsWith("Screenshot_")) {
    // Screenshots on droid
    return DateTime.tryParse(
        (fileName).replaceAll('Screenshot_', '').replaceAll('-', 'T'));
  } else {
    return DateTime.tryParse((fileName)
        .replaceAll("IMG_", "")
        .replaceAll("DCIM_", "")
        .replaceAll("_", " "));
  }
}
