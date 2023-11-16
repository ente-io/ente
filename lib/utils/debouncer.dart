import 'dart:async';

import 'package:flutter/material.dart';
import "package:photos/models/typedefs.dart";

class Debouncer {
  final Duration _duration;

  ///in milliseconds
  final ValueNotifier<bool> _debounceActiveNotifier = ValueNotifier(false);

  /// If executionInterval is not null, then the debouncer will execute the
  /// current callback it has in run() method repeatedly in the given interval.
  final int? executionInterval;
  Timer? _debounceTimer;

  Debouncer(this._duration, {this.executionInterval});

  final Stopwatch _stopwatch = Stopwatch();

  void run(FutureVoidCallback fn) {
    if (executionInterval != null) {
      runCallbackIfIntervalTimeElapses(fn);
    }

    if (isActive()) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(_duration, () async {
      await fn();
      _debounceActiveNotifier.value = false;
    });
    _debounceActiveNotifier.value = true;
  }

  void cancelDebounce() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
  }

  runCallbackIfIntervalTimeElapses(FutureVoidCallback fn) {
    _stopwatch.isRunning ? null : _stopwatch.start();
    if (_stopwatch.elapsedMilliseconds > executionInterval!) {
      _stopwatch.reset();
      fn();
    }
  }

  bool isActive() => _debounceTimer != null && _debounceTimer!.isActive;

  ValueNotifier<bool> get debounceActiveNotifier {
    return _debounceActiveNotifier;
  }
}
