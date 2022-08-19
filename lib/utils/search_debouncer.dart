import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final Duration _duration;
  Timer debounceTimer;
  final ValueNotifier<Timer> debounceNotifier = ValueNotifier(null);
  Debouncer(this._duration);

  void run(Function fn) {
    if (debounceTimer != null && debounceTimer.isActive) {
      debounceTimer.cancel();
    }
    debounceTimer = Timer(_duration, fn);
    debounceNotifier.value = debounceTimer;
  }

  void cancel() {
    if (debounceTimer != null) {
      debounceTimer.cancel();
    }
  }

  bool isActive() {
    return (debounceTimer != null) && debounceTimer.isActive;
  }
}
