import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final Duration _duration;
  Timer _debounceTimer;
  final ValueNotifier<bool> _debounceNotifier = ValueNotifier(false);
  Debouncer(this._duration);

  void run(Function fn) {
    if (_debounceTimer != null && _debounceTimer.isActive) {
      _debounceTimer.cancel();
    }
    _debounceTimer = Timer(_duration, fn);
    _debounceNotifier.value = isActive();
  }

  void cancel() {
    if (_debounceTimer != null) {
      _debounceTimer.cancel();
    }
  }

  bool isActive() {
    return (_debounceTimer != null) && _debounceTimer.isActive;
  }

  ValueNotifier<bool> get debounceNotifierGetter {
    return _debounceNotifier;
  }

  void setDebounceNotifier() {
    _debounceNotifier.value = false;
  }
}
