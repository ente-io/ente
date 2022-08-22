import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final Duration _duration;
  Timer _debounceTimer;
  final ValueNotifier<Timer> _debounceNotifier = ValueNotifier(null);
  Debouncer(this._duration);

  void run(Function fn) {
    if (_debounceTimer != null && _debounceTimer.isActive) {
      _debounceTimer.cancel();
    }
    _debounceTimer = Timer(_duration, fn);
    _debounceNotifier.value = _debounceTimer;
  }

  void cancel() {
    if (_debounceTimer != null) {
      _debounceTimer.cancel();
    }
  }

  bool isActive() {
    return (_debounceTimer != null) && _debounceTimer.isActive;
  }

  ValueNotifier<Timer> get debounceNotifierGetter {
    return _debounceNotifier;
  }
}
