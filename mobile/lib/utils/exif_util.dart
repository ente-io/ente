import "dart:async";
import "dart:developer";
import "dart:io";

import "package:computer/computer.dart";
import 'package:exif/exif.dart';
import "package:ffmpeg_kit_flutter_min/ffprobe_kit.dart";
import "package:ffmpeg_kit_flutter_min/media_information.dart";
import "package:ffmpeg_kit_flutter_min/media_information_session.dart";
import "package:flutter/foundation.dart";
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/location/location.dart";
import "package:photos/services/location_service.dart";
import "package:photos/utils/ffprobe_util.dart";
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

Future<Map<String, IfdTag>?> getExifFromSourceFile(File originFile) async {
  try {
    final exif = await readExifAsync(originFile);
    return exif;
  } catch (e, s) {
    _logger.severe("failed to get exif from origin file", e, s);
    return null;
  }
}

Future<FFProbeProps?> getVideoPropsAsync(File originalFile) async {
  try {
    final stopwatch = Stopwatch()..start();
    final Map<int, StringBuffer> logs = {};
    final completer = Completer<MediaInformation?>();

    final session = await FFprobeKit.getMediaInformationAsync(
      originalFile.path,
      (MediaInformationSession session) async {
        // This callback is called when the session is complete
        final mediaInfo = session.getMediaInformation();
        if (mediaInfo == null) {
          _logger.warning("Failed to get video metadata");
          final failStackTrace = await session.getFailStackTrace();
          final output = await session.getOutput();
          _logger.warning(
            'Failed to get video metadata. failStackTrace=$failStackTrace, output=$output',
          );
        }
        completer.complete(mediaInfo);
      },
      (log) {
        // put log messages into a map
        logs.putIfAbsent(log.getSessionId(), () => StringBuffer());
        logs[log.getSessionId()]!.write(log.getMessage());
      },
    );

    // Wait for the session to complete
    await session.getReturnCode();
    final mediaInfo = await completer.future;
    if (kDebugMode) {
      logs.forEach((key, value) {
        log("log for session $key: $value", name: "FFprobeKit");
      });
    }
    if (mediaInfo == null) {
      return null;
    }
    final properties = await FFProbeUtil.getProperties(mediaInfo);
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

Future<DateTime?> getCreationTimeFromEXIF(
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
    if (exifTime != null && exifTime != kEmptyExifDateTime) {
      String? exifOffsetTime;
      for (final key in kExifOffSetKeys) {
        if (exif.containsKey(key)) {
          exifOffsetTime = exif[key]!.printable;
          break;
        }
      }
      return getDateTimeInDeviceTimezone(exifTime, exifOffsetTime);
    }
  } catch (e) {
    _logger.severe("failed to getCreationTimeFromEXIF", e);
  }
  return null;
}

DateTime getDateTimeInDeviceTimezone(String exifTime, String? offsetString) {
  final DateTime result = DateFormat(kExifDateTimePattern).parse(exifTime);
  if (offsetString == null) {
    return result;
  }
  try {
    final List<String> splitHHMM = offsetString.split(":");
    // Parse the offset from the photo's time zone
    final int offsetHours = int.parse(splitHHMM[0]);
    final int offsetMinutes =
        int.parse(splitHHMM[1]) * (offsetHours.isNegative ? -1 : 1);
    // Adjust the date for the offset to get the photo's correct UTC time
    final photoUtcDate =
        result.add(Duration(hours: -offsetHours, minutes: -offsetMinutes));
    // Getting the current device's time zone offset from UTC
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset;
    // Adjusting the photo's UTC time to the device's local time
    final deviceLocalTime = photoUtcDate.add(localOffset);
    return deviceLocalTime;
  } catch (e, s) {
    _logger.severe("tz offset adjust failed $offsetString", e, s);
  }
  return result;
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
