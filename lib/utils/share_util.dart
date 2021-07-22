import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
    //'0.0001'.replaceFirst(RegExp(r'0'), ''); // '.0001'
    var map = await readExifFromFile(dartio.File(media.path));
    var id = md5.convert(utf8.encode(media.path)).toString();
    var fromAsset = File();
    fromAsset.localID = "ente-upload-cache:" + media.path;
    fromAsset.collectionID = collectionID;
    fromAsset.fileType = FileType.image;
    fromAsset.title = basename(media.path);
    if (fromAsset.creationTime == null || fromAsset.creationTime == 0) {
      fromAsset.creationTime = 0;
      try {
        final parsedDateTime = DateTime.parse(
            basenameWithoutExtension(media.path)
                .replaceAll("IMG_", "")
                .replaceAll("DCIM_", "")
                .replaceAll("_", " "));
        fromAsset.creationTime = parsedDateTime.microsecondsSinceEpoch;
      } catch (e) {
        fromAsset.creationTime = 0;
      }
    }
    fromAsset.modificationTime = fromAsset.creationTime;
    localFiles.add(fromAsset);
  }
  return localFiles;
}
