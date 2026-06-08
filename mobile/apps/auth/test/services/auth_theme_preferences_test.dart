import "dart:convert";

import "package:ente_auth/services/auth_theme_preferences.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart";
import "package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart";

const _authThemeModeKey = "ente_auth_theme_mode";
const _adaptiveThemePrefKey = "adaptive_theme_preferences";

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  test("returns system when no theme preference exists", () async {
    expect(await AuthThemePreferences.getThemeMode(), ThemeMode.system);
  });

  test("prefers Auth theme preference", () async {
    await _setAuthThemeMode(ThemeMode.dark);
    await _setAsyncThemeMode(ThemeMode.light);
    await _setLegacyThemeMode(ThemeMode.light);

    expect(await AuthThemePreferences.getThemeMode(), ThemeMode.dark);
  });

  test("migrates adaptive theme async preference", () async {
    await _setAsyncThemeMode(ThemeMode.dark);
    await _setLegacyThemeMode(ThemeMode.light);

    expect(await AuthThemePreferences.getThemeMode(), ThemeMode.dark);
    expect(await _getAuthThemeMode(), ThemeMode.dark);
  });

  test("migrates legacy adaptive theme preference", () async {
    await _setLegacyThemeMode(ThemeMode.light);

    expect(await AuthThemePreferences.getThemeMode(), ThemeMode.light);
    expect(await _getAuthThemeMode(), ThemeMode.light);
  });

  test("keeps Auth theme preference when adaptive value resets", () async {
    await AuthThemePreferences.setThemeMode(ThemeMode.light);
    await _setAsyncThemeMode(ThemeMode.system);
    await _setLegacyThemeMode(ThemeMode.system);

    expect(await AuthThemePreferences.getThemeMode(), ThemeMode.light);
  });
}

Future<void> _setAuthThemeMode(ThemeMode themeMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_authThemeModeKey, _themeModeIndex(themeMode));
}

Future<ThemeMode?> _getAuthThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return _themeModeFromIndex(prefs.getInt(_authThemeModeKey));
}

Future<void> _setAsyncThemeMode(ThemeMode themeMode) async {
  final prefs = SharedPreferencesAsync();
  await prefs.setString(_adaptiveThemePrefKey, _themeModeJson(themeMode));
}

Future<void> _setLegacyThemeMode(ThemeMode themeMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_adaptiveThemePrefKey, _themeModeJson(themeMode));
}

String _themeModeJson(ThemeMode themeMode) {
  return json.encode({
    "theme_mode": _themeModeIndex(themeMode),
    "default_theme_mode": _themeModeIndex(ThemeMode.system),
  });
}

ThemeMode? _themeModeFromIndex(Object? themeModeIndex) {
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

int _themeModeIndex(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.light:
      return 0;
    case ThemeMode.dark:
      return 1;
    case ThemeMode.system:
      return 2;
  }
}
