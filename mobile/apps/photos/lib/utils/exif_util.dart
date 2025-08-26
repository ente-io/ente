import "dart:async";
import "dart:io";

import "package:computer/computer.dart";
import 'package:exif_reader/exif_reader.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
// ignore: implementation_imports
import "package:motion_photos/src/xmp_extractor.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/location/location.dart";
import "package:photos/services/isolated_ffmpeg_service.dart";
import "package:photos/services/location_service.dart";
import 'package:photos/utils/file_util.dart';

const kDateTimeOriginal = "EXIF DateTimeOriginal";
const kImageDateTime = "Image DateTime";
const kExifOffSetKeys = [
  "EXIF OffsetTime",
  "EXIF OffsetTimeOriginal",
  "EXIF OffsetTimeDigitized",
];
const kExifDateTimePattern = "yyyy:MM:dd HH:mm:ss";
const kEmptyExifDateTime = "0000:00:00 00:00:00";

final _logger = Logger("ExifUtil");

Future<Map<String, IfdTag>> getExif(EnteFile file) async {
  try {
    final File? originFile = await getFile(file, isOrigin: true);
    if (originFile == null) {
      throw Exception("Failed to fetch origin file");
    }
    final exif = await readExifAsync(originFile);
    if (!file.isRemoteFile && Platform.isIOS) {
      await originFile.delete();
    }
    return exif;
  } catch (e) {
    _logger.severe("failed to getExif", e);
    rethrow;
  }
}

Future<Map<String, IfdTag>?> tryExifFromFile(File originFile) async {
  try {
    final exif = await readExifAsync(originFile);
    return exif;
  } catch (e, s) {
    _logger.severe("failed to get exif from origin file", e, s);
    return null;
  }
}

Future<Map<String, dynamic>> getXmp(File file) async {
  return Computer.shared().compute(
    _getXMPComputer,
    param: {"file": file},
    taskName: "getXMPAsync",
  );
}

Map<String, dynamic> _getXMPComputer(Map<String, dynamic> args) {
  final File originalFile = args["file"] as File;
  return XMPExtractor().extract(originalFile.readAsBytesSync());
}

Future<FFProbeProps?> getVideoPropsAsync(File originalFile) async {
  try {
    final stopwatch = Stopwatch()..start();

    final mediaInfo =
        await IsolatedFfmpegService.instance.getVideoInfo(originalFile.path);
    if (mediaInfo.isEmpty) {
      return null;
    }

    final properties = await FFProbeProps.parseData(mediaInfo);
    _logger.info("getVideoPropsAsync took ${stopwatch.elapsedMilliseconds}ms");

    stopwatch.stop();
    return properties;
  } catch (e, s) {
    _logger.severe("Failed to getVideoProps", e, s);
    return null;
  }
}

bool? checkPanoramaFromEXIF(File? file, Map<String, IfdTag>? exifData) {
  final element = exifData?["EXIF CustomRendered"];
  if (element?.printable == null) return null;
  return element?.printable == "6";
}

class ParsedExifDateTime {
  late final DateTime? time;
  late final String? dateTime;
  late final String? offsetTime;
  ParsedExifDateTime(DateTime this.time, String? dateTime, this.offsetTime) {
    if (dateTime != null && dateTime.endsWith('Z')) {
      this.dateTime = dateTime.substring(0, dateTime.length - 1);
    } else {
      this.dateTime = dateTime;
    }
  }

  @override
  String toString() {
    return "ParsedExifDateTime{time: $time, dateTime: $dateTime, offsetTime: $offsetTime}";
  }
}

Future<ParsedExifDateTime?> tryParseExifDateTime(
  File? file,
  Map<String, IfdTag>? exifData,
) async {
  try {
    assert(file != null || exifData != null);
    final exif = exifData ?? await readExifAsync(file!);
    final exifTime = exif.containsKey(kDateTimeOriginal)
        ? exif[kDateTimeOriginal]!.printable
        : exif.containsKey(kImageDateTime)
            ? exif[kImageDateTime]!.printable
            : null;
    if (exifTime == null || exifTime == kEmptyExifDateTime) {
      return null;
    }
    String? exifOffsetTime;
    for (final key in kExifOffSetKeys) {
      if (exif.containsKey(key)) {
        exifOffsetTime = exif[key]!.printable;
        break;
      }
    }
    return getDateTimeInDeviceTimezone(exifTime, exifOffsetTime);
  } catch (e) {
    _logger.severe("failed to getCreationTimeFromEXIF", e);
  }
  return null;
}

ParsedExifDateTime getDateTimeInDeviceTimezone(
  String exifTime,
  String? offsetString,
) {
  final hasOffset = (offsetString ?? '') != '';
  final DateTime result =
      DateFormat(kExifDateTimePattern).parse(exifTime, hasOffset);
  if (hasOffset && offsetString!.toUpperCase() != "Z") {
    try {
      final List<String> splitHHMM = offsetString.split(":");
      final int offsetHours = int.parse(splitHHMM[0]);
      final int offsetMinutes =
          int.parse(splitHHMM[1]) * (offsetHours.isNegative ? -1 : 1);
      // Adjust the date for the offset to get the photo's correct UTC time
      final photoUtcDate =
          result.add(Duration(hours: -offsetHours, minutes: -offsetMinutes));
      // Convert the UTC time to the device's local time
      final deviceLocalTime = photoUtcDate.toLocal();
      return ParsedExifDateTime(
        deviceLocalTime,
        result.toIso8601String(),
        offsetString,
      );
    } catch (e, s) {
      _logger.severe("offset parsing failed $exifTime &&  $offsetString", e, s);
    }
  }
  return ParsedExifDateTime(
    result,
    result.toIso8601String(),
    (offsetString ?? '').toUpperCase() == 'Z' ? 'Z' : null,
  );
}

Location? locationFromExif(Map<String, IfdTag> exif) {
  try {
    return gpsDataFromExif(exif).toLocationObj();
  } catch (e, s) {
    _logger.severe("failed to get location from exif", e, s);
    return null;
  }
}

Future<Map<String, IfdTag>> _readExifArgs(Map<String, dynamic> args) {
  return readExifFromFile(args["file"]);
}

Future<Map<String, IfdTag>> readExifAsync(File file) async {
  return await Computer.shared().compute(
    _readExifArgs,
    param: {"file": file},
    taskName: "readExifAsync",
  );
}

GPSData gpsDataFromExif(Map<String, IfdTag> exif) {
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
