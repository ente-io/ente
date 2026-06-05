import "dart:convert";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:ente_auth/services/auth_theme_preferences.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart";
import "package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart";

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  test("returns system when no theme preference exists", () async {
    expect(await AuthThemePreferences.getThemeMode(), AdaptiveThemeMode.system);
  });

  test("prefers adaptive theme async preference", () async {
    await _setAsyncThemeMode(AdaptiveThemeMode.dark);
    await _setLegacyThemeMode(AdaptiveThemeMode.light);

    expect(await AuthThemePreferences.getThemeMode(), AdaptiveThemeMode.dark);
  });

  test("falls back to legacy adaptive theme preference", () async {
    await _setLegacyThemeMode(AdaptiveThemeMode.light);

    expect(await AuthThemePreferences.getThemeMode(), AdaptiveThemeMode.light);
  });
}

Future<void> _setAsyncThemeMode(AdaptiveThemeMode themeMode) async {
  final prefs = SharedPreferencesAsync();
  await prefs.setString(AdaptiveTheme.prefKey, _themeModeJson(themeMode));
}

Future<void> _setLegacyThemeMode(AdaptiveThemeMode themeMode) async {
  SharedPreferences.setMockInitialValues({
    AdaptiveTheme.prefKey: _themeModeJson(themeMode),
  });
}

String _themeModeJson(AdaptiveThemeMode themeMode) {
  return json.encode({
    "theme_mode": themeMode.index,
    "default_theme_mode": AdaptiveThemeMode.system.index,
  });
}
