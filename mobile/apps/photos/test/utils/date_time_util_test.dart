import 'package:flutter/foundation.dart';
import 'package:photos/core/constants.dart';
import "package:photos/utils/standalone/date_time.dart";
import 'package:test/test.dart';

void main() {
  test("parseDateTimeFromFile", () {
    final List<String> validParsing = [
      "IMG-20221109-WA0000",
      '''Screenshot_20220807-195908_Firefox''',
      '''Screenshot_20220507-195908''',
      "2022-02-18 16.00.12-DCMX.png",
      "20221107_231730",
      "2020-11-01 02.31.02",
      "IMG_20210921_144423",
      "2019-10-31 155703",
      "IMG_20210921_144423_783",
      "Screenshot_2022-06-21-16-51-29-164_newFormat.heic",
      "Screenshot 20221106 211633.com.google.android.apps.nbu.paisa.user.jpg",
      "signal-2022-12-17-15-16-04-718.jpg",
      "signal-2022-12-17-15-16-04-718-2.jpg",
    ];
    for (String val in validParsing) {
      final parsedValue = parseDateTimeFromFileNameV2(val);
      expect(
        parsedValue != null,
        true,
        reason: "Failed to parse time from $val",
      );
      if (kDebugMode) {
        debugPrint("Parsed $val as ${parsedValue?.toIso8601String()}");
      }
    }
  });

  test("test invalid datetime parsing", () {
    final List<String> badParsing = [
      "Snapchat-431959199.mp4.",
      "Snapchat-400000000.mp4",
      "Snapchat-900000000.mp4",
    ];
    for (String val in badParsing) {
      final parsedValue = parseDateTimeFromFileNameV2(val);
      expect(
        parsedValue == null,
        true,
        reason: "parsing should have failed $val",
      );
      if (kDebugMode) {
        debugPrint("Parsed $val as ${parsedValue?.toIso8601String()}");
      }
    }
  });

  test("verify constants", () {
    final date = DateTime.fromMicrosecondsSinceEpoch(jan011981Time).toUtc();
    expect(
      date.year == 1981 && date.month == 1,
      true,
      reason: "constant mismatch : ${date.toIso8601String()}",
    );
  });
}
