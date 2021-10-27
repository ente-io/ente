import 'dart:io' as io;

import 'package:exif/exif.dart';
import 'package:jiffy/jiffy.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_util.dart';
import 'package:logging/logging.dart';

const kDateTimeOriginal = "EXIF DateTimeOriginal";
const kImageDateTime = "Image DateTime";
const kExifDateTimePattern = "yyyy:MM:dd h:mm:s";

final _logger = Logger("ExifUtil");

Future<Map<String, IfdTag>> getExif(File file) async {
  try {
    final originFile = await getFile(file, isOrigin: true);
    final exif = await readExifFromFile(originFile);
    if (!file.isRemoteFile() && io.Platform.isIOS) {
      await originFile.delete();
    }
    return exif;
  } catch (e) {
    _logger.severe("failed to getExif", e);
    rethrow;
  }
}

Future<DateTime> getCreationTimeFromEXIF(io.File file) async {
  final exif = await readExifFromFile(file);
  final exifTime = exif.containsKey(kDateTimeOriginal)
      ? exif[kDateTimeOriginal].printable
      : exif.containsKey(kImageDateTime)
          ? exif[kImageDateTime].printable
          : null;
  if (exifTime != null) {
    try {
      return Jiffy(exifTime, kExifDateTimePattern).dateTime;
    } catch (e) {
      _logger.severe(e);
    }
  }
  return null;
}
