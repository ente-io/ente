import "dart:convert";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class AuthThemePreferences {
  AuthThemePreferences._();

  static const _authThemeModeKey = "ente_auth_theme_mode";
  static const _adaptiveThemePrefKey = "adaptive_theme_preferences";
  static const _themeModeKey = "theme_mode";

  static Future<ThemeMode> getThemeMode() async {
    final authThemeMode = await _getAuthThemeMode();
    if (authThemeMode != null) {
      return authThemeMode;
    }

    final migratedThemeMode = await _getMigratedThemeMode();
    if (migratedThemeMode != null) {
      await _setAuthThemeMode(migratedThemeMode);
      return migratedThemeMode;
    }

    return ThemeMode.system;
  }

  static Future<void> setThemeMode(ThemeMode themeMode) =>
      _setAuthThemeMode(themeMode);

  static Future<ThemeMode?> _getAuthThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _themeModeFromIndex(prefs.getInt(_authThemeModeKey));
  }

  static Future<void> _setAuthThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_authThemeModeKey, _themeModeIndex(themeMode));
  }

  static Future<ThemeMode?> _getMigratedThemeMode() async {
    final prefs = SharedPreferencesAsync();
    return _parseThemeMode(await prefs.getString(_adaptiveThemePrefKey)) ??
        await _getLegacyAdaptiveThemeMode();
  }

  static Future<ThemeMode?> _getLegacyAdaptiveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseThemeMode(prefs.getString(_adaptiveThemePrefKey));
  }

  static ThemeMode? _parseThemeMode(String? themeDataString) {
    if (themeDataString == null || themeDataString.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(themeDataString);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final themeModeIndex = decoded[_themeModeKey];
      return _themeModeFromIndex(themeModeIndex);
    } on FormatException {
      return null;
    }
  }

  static ThemeMode? _themeModeFromIndex(Object? themeModeIndex) {
    switch (themeModeIndex) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return null;
    }
  }

  static int _themeModeIndex(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }
}
