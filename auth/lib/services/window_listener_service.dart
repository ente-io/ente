import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowListenerService {
  static const double initialWindowHeight = 1200.0;
  static const double initialWindowWidth = 800.0;
  static const double maxWindowHeight = 8192.0;
  static const double maxWindowWidth = 8192.0;
  late SharedPreferences _preferences;

  WindowListenerService._privateConstructor();

  static final WindowListenerService instance =
      WindowListenerService._privateConstructor();

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Size getWindowSize() {
    final double windowWidth =
        _preferences.getDouble('windowWidth') ?? initialWindowWidth;
    final double windowHeight =
        _preferences.getDouble('windowHeight') ?? initialWindowHeight;
    final w = windowWidth.clamp(200.0, maxWindowWidth);
    final h = windowHeight.clamp(400.0, maxWindowHeight);
    return Size(w, h);
  }

  Future<void> onWindowResize() async {
    final width = (await windowManager.getSize()).width;
    final height = (await windowManager.getSize()).height;
    // Save the window size to shared preferences
    await _preferences.setDouble('windowWidth', width);
    await _preferences.setDouble('windowHeight', height);
  }
}
