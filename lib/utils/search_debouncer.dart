import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final Duration duration;
  Timer debounceTimer;
  final ValueNotifier<Timer> debounceNotifier = ValueNotifier(null);
  Debouncer(this.duration);

  run(Function fn) {
    if (debounceTimer != null && debounceTimer.isActive) {
      debounceTimer.cancel();
    }
    debounceTimer = Timer(const Duration(milliseconds: 250), fn);
    debounceNotifier.value = debounceTimer;
  }

  cancel() {
    if (debounceTimer != null) {
      debounceTimer.cancel();
    }
  }
}
