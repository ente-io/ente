import "dart:convert";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class AuthThemePreferences {
  AuthThemePreferences._();

  static const _themeModeKey = "theme_mode";
  static const _defaultThemeModeKey = "default_theme_mode";

  static Future<AdaptiveThemeMode> getThemeMode() async {
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    if (savedThemeMode != null) {
      return savedThemeMode;
    }

    return await _getLegacyThemeMode() ?? AdaptiveThemeMode.system;
  }

  static Future<void> setThemeMode(
    AdaptiveThemeManager<ThemeData> adaptiveTheme,
    AdaptiveThemeMode themeMode,
  ) async {
    adaptiveTheme.setThemeMode(themeMode);
    await adaptiveTheme.persist();
    await _setLegacyThemeMode(themeMode);
  }

  static Future<AdaptiveThemeMode?> _getLegacyThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeDataString = prefs.getString(AdaptiveTheme.prefKey);
    if (themeDataString == null || themeDataString.isEmpty) {
      return null;
    }

    return _parseThemeMode(themeDataString);
  }

  static AdaptiveThemeMode? _parseThemeMode(String themeDataString) {
    try {
      final decoded = json.decode(themeDataString);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final themeModeIndex = decoded[_themeModeKey];
      if (themeModeIndex is! int ||
          themeModeIndex < 0 ||
          themeModeIndex >= AdaptiveThemeMode.values.length) {
        return null;
      }

      return AdaptiveThemeMode.values[themeModeIndex];
    } on FormatException {
      return null;
    }
  }

  static Future<void> _setLegacyThemeMode(AdaptiveThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AdaptiveTheme.prefKey,
      json.encode({
        _themeModeKey: themeMode.index,
        _defaultThemeModeKey: AdaptiveThemeMode.system.index,
      }),
    );
  }
}
