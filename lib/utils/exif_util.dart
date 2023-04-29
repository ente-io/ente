import 'dart:io' as io;

import 'package:exif/exif.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import "package:photos/models/location/location.dart";
import "package:photos/services/location_service.dart";
import 'package:photos/utils/file_util.dart';

const kDateTimeOriginal = "EXIF DateTimeOriginal";
const kImageDateTime = "Image DateTime";
const kExifDateTimePattern = "yyyy:MM:dd HH:mm:ss";
const kEmptyExifDateTime = "0000:00:00 00:00:00";

final _logger = Logger("ExifUtil");

Future<Map<String, IfdTag>> getExif(File file) async {
  try {
    final originFile = await getFile(file, isOrigin: true);
    if (originFile == null) {
      throw Exception("Failed to fetch origin file");
    }
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

Future<Map<String, IfdTag>?> getExifFromSourceFile(io.File originFile) async {
  try {
    final exif = await readExifFromFile(originFile);
    return exif;
  } catch (e, s) {
    _logger.severe("failed to get exif from origin file", e, s);
    return null;
  }
}

Future<DateTime?> getCreationTimeFromEXIF(
  io.File? file,
  Map<String, IfdTag>? exifData,
) async {
  try {
    assert(file != null || exifData != null);
    final exif = exifData ?? await readExifFromFile(file!);
    final exifTime = exif.containsKey(kDateTimeOriginal)
        ? exif[kDateTimeOriginal]!.printable
        : exif.containsKey(kImageDateTime)
            ? exif[kImageDateTime]!.printable
            : null;
    if (exifTime != null && exifTime != kEmptyExifDateTime) {
      return DateFormat(kExifDateTimePattern).parse(exifTime);
    }
  } catch (e) {
    _logger.severe("failed to getCreationTimeFromEXIF", e);
  }
  return null;
}

Location? locationFromExif(Map<String, IfdTag> exif) {
  try {
    return _gpsDataFromExif(exif).toLocationObj();
  } catch (e, s) {
    _logger.severe("failed to get location from exif", e, s);
    return null;
  }
}

Future<Location?> tryLocationFromExif(File file) async {
  try {
    final exif = await getExif(file);
    return locationFromExif(exif);
  } catch (e) {
    _logger.severe("failed to get location from exif", e);
    return null;
  }
}

GPSData _gpsDataFromExif(Map<String, IfdTag> exif) {
  final Map<String, dynamic> exifLocationData = {
    "lat": null,
    "long": null,
    "latRef": null,
    "longRef": null,
  };
  if (exif["GPS GPSLatitude"] != null) {
    exifLocationData["lat"] = exif["GPS GPSLatitude"]!
        .values
        .toList()
        .map((e) => ((e as Ratio).numerator / e.denominator))
        .toList();
  }
  if (exif["GPS GPSLongitude"] != null) {
    exifLocationData["long"] = exif["GPS GPSLongitude"]!
        .values
        .toList()
        .map((e) => ((e as Ratio).numerator / e.denominator))
        .toList();
  }
  if (exif["GPS GPSLatitudeRef"] != null) {
    exifLocationData["latRef"] = exif["GPS GPSLatitudeRef"].toString();
  }
  if (exif["GPS GPSLongitudeRef"] != null) {
    exifLocationData["longRef"] = exif["GPS GPSLongitudeRef"].toString();
  }
  return GPSData(
    exifLocationData["latRef"],
    exifLocationData["lat"],
    exifLocationData["longRef"],
    exifLocationData["long"],
  );
}
