import 'dart:async';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowListenerService {
  late SharedPreferences _preferences;

  WindowListenerService._privateConstructor();

  static final WindowListenerService instance =
      WindowListenerService._privateConstructor();

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Size getWindowSize() {
    final double windowWidth = _preferences.getDouble('windowWidth') ?? 450.0;
    final double windowHeight = _preferences.getDouble('windowHeight') ?? 800.0;
    return Size(windowWidth, windowHeight);
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
