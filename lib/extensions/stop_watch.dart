import 'package:flutter/foundation.dart';

extension StopWatchExtension on Stopwatch {
  void log(String msg) {
    debugPrint("$msg took ${elapsed.inMilliseconds} ms");
  }

  void logAndReset(String msg) {
    debugPrint("$msg took ${elapsed.inMilliseconds} ms");
    reset();
  }
}
