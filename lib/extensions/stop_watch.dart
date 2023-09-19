import 'package:flutter/foundation.dart';

class EnteWatch extends Stopwatch {
  final String context;
  int previousElapsed = 0;

  EnteWatch(this.context) : super();

  void log(String msg) {
    if (kDebugMode) {
      debugPrint("[$context]: $msg took ${Duration(
        microseconds: elapsedMicroseconds - previousElapsed,
      ).inMilliseconds} ms  total: "
          "${elapsed.inMilliseconds} ms");
    }
    previousElapsed = elapsedMicroseconds;
  }

  void logAndReset(String msg) {
    if (kDebugMode) {
      debugPrint("[$context]: $msg took ${elapsed.inMilliseconds} ms");
    }
    reset();
    previousElapsed = 0;
  }
}
