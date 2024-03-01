import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final Duration _duration;
  final ValueNotifier<bool> _debounceActiveNotifier = ValueNotifier(false);
  Timer? _debounceTimer;

  Debouncer(this._duration);

  void run(Future<void> Function() fn) {
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

  bool isActive() => _debounceTimer != null && _debounceTimer!.isActive;

  ValueNotifier<bool> get debounceActiveNotifier {
    return _debounceActiveNotifier;
  }
}
