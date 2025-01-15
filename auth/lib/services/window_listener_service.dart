import 'dart:async';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowListenerService {
  static const double minWindowHeight = 600.0;
  static const double minWindowWidth = 800.0;
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
        _preferences.getDouble('windowWidth') ?? minWindowWidth;
    final double windowHeight =
        _preferences.getDouble('windowHeight') ?? minWindowHeight;
    return Size(
      windowWidth.clamp(minWindowWidth, maxWindowWidth),
      windowHeight.clamp(minWindowHeight, maxWindowHeight),
    );
  }

  Future<void> onWindowResize() async {
    // Save the window size to shared preferences
    await _preferences.setDouble(
      'windowWidth',
      (await windowManager.getSize()).width,
    );
    await _preferences.setDouble(
      'windowHeight',
      (await windowManager.getSize()).height,
    );
  }
}
