import 'package:flutter/foundation.dart';

class EnteWatch extends Stopwatch {
  final String context;

  EnteWatch(this.context) : super();

  void log(String msg) {
    debugPrint("[$context]: $msg took ${elapsed.inMilliseconds} ms");
  }

  void logAndReset(String msg) {
    debugPrint("[$context]: $msg took ${elapsed.inMilliseconds} ms");
    reset();
  }
}
