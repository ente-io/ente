import 'dart:io' as io;

import 'package:exif/exif.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_util.dart';

Future<Map<String, IfdTag>> getExif(File file) async {
  final originFile = await getFile(file, isOrigin: true);
  final exif = await readExifFromFile(originFile);
  if (!file.isRemoteFile() && io.Platform.isIOS) {
    originFile.delete();
  }
  return exif;
}
