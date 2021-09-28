import 'dart:io' as io;

import 'package:exif/exif.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_util.dart';
import 'package:logging/logging.dart';

Future<Map<String, IfdTag>> getExif(File file) async {
  try {
    final originFile = await getFile(file, isOrigin: true);
    final exif = await readExifFromFile(originFile);
    if (!file.isRemoteFile() && io.Platform.isIOS) {
      await originFile.delete();
    }
    return exif;
  } catch (e) {
    Logger("getExif").severe("failed to getExif", e);
    rethrow;
  }
}
