import 'package:flutter/foundation.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:test/test.dart';

void main() {
  test("parseDateTimeFromFile", () {
    final List<String> validParsing = [
      "IMG-20221109-WA0000",
      '''Screenshot_20220807-195908_Firefox''',
      '''Screenshot_20220507-195908''',
      "2019-02-18 16.00.12-DCMX",
      "20221107_231730",
      "2020-11-01 02.31.02",
      "IMG_20210921_144423",
      "2019-10-31 155703",
      "IMG_20210921_144423_783",
      "Screenshot_2022-06-21-16-51-29-164_newFormat",
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

  test("verify constants", () {
    final date = DateTime.fromMicrosecondsSinceEpoch(jan011981Time);
    expect(
      date.year == 1981 && date.month == 1,
      true,
      reason: "constant mismatch : ${date.toIso8601String()}",
    );
  });
}
