// @dart=2.9

import 'dart:io' as io;

import 'package:exif/exif.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_util.dart';

const kDateTimeOriginal = "EXIF DateTimeOriginal";
const kImageDateTime = "Image DateTime";
const kExifDateTimePattern = "yyyy:MM:dd HH:mm:ss";
const kEmptyExifDateTime = "0000:00:00 00:00:00";

final _logger = Logger("ExifUtil");

Future<Map<String, IfdTag>> getExif(File file) async {
  try {
    final originFile = await getFile(file, isOrigin: true);
    final exif = await readExifFromFile(originFile);
    if (!file.isRemoteFile && io.Platform.isIOS) {
      await originFile.delete();
    }
    return exif;
  } catch (e) {
    _logger.severe("failed to getExif", e);
    rethrow;
  }
}

Future<DateTime> getCreationTimeFromEXIF(io.File file) async {
  try {
    final exif = await readExifFromFile(file);
    if (exif != null) {
      final exifTime = exif.containsKey(kDateTimeOriginal)
          ? exif[kDateTimeOriginal].printable
          : exif.containsKey(kImageDateTime)
              ? exif[kImageDateTime].printable
              : null;
      if (exifTime != null && exifTime != kEmptyExifDateTime) {
        return DateFormat(kExifDateTimePattern).parse(exifTime);
      }
    }
  } catch (e) {
    _logger.severe("failed to getCreationTimeFromEXIF", e);
  }
  return null;
}
