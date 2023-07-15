import 'package:flutter/foundation.dart';
import 'package:photos/core/constants.dart';
import "package:photos/utils/converters.dart";
import 'package:photos/utils/date_time_util.dart';
import 'package:test/test.dart';

void main() {
  test("bytesToHex", () {
    final byteToHex = bytesToHex(Uint8List.fromList([1,1,1]));
    expect(byteToHex, "010101");
  });
}
