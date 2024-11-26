import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart';

enum ThemeOptions {
  system,
  light,
  dark,
  greenLight,
  greenDark,
  redLight,
  redDark,
  blueLight,
  blueDark,
  yellowLight,
  yellowDark,
  purpleLight,
  purpleDark,
  orangeLight,
  orangeDark,
  tealLight,
  tealDark,
  roseLight,
  roseDark,
  indigoLight,
  indigoDark,
  mochaLight,
  mochaDark,
  aquaLight,
  aquaDark,
  lilacLight,
  lilacDark,
  emeraldLight,
  emeraldDark,
  slateLight,
  slateDark,
}

enum ThemeLoadingState {
  loading,
  loaded,
  error,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  ThemeOptions _currentTheme = ThemeOptions.system;
  bool _isChangingTheme = false;
  bool _initialized = false;
  final SharedPreferences _prefs;
  final Duration _transitionDuration = const Duration(milliseconds: 300);

  ThemeLoadingState _themeState = ThemeLoadingState.loading;
  String? _errorMessage;

  // Add getters
  ThemeLoadingState get themeState => _themeState;
  String? get errorMessage => _errorMessage;

  // Theme data caching
  late final ThemeData _lightThemeData;
  late final ThemeData _darkThemeData;
  final Map<ThemeOptions, ThemeData> _themeCache = {};

  ThemeProvider(this._prefs) {
    _initializeThemeData();
    _loadSavedTheme();
    _preCacheThemes();
    
    // Better system theme change handling
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = _handleSystemThemeChange;
  }

  @override
  void dispose() {
    // Clean up system theme listener
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  // Getters
  ThemeData get currentThemeData {
    if (_currentTheme == ThemeOptions.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.light ? _lightThemeData : _darkThemeData;
    }
    return _getOrCreateCustomTheme(_currentTheme);
  }

  bool get initialized => _initialized;
  ThemeOptions get currentTheme => _currentTheme;
  bool get isChangingTheme => _isChangingTheme;

  ThemeMode get themeMode {
    if (_currentTheme == ThemeOptions.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark;
    }
    return _currentTheme.toString().toLowerCase().contains('light') 
        ? ThemeMode.light 
        : ThemeMode.dark;
  }

  void _initializeThemeData() {
    _lightThemeData = _createCustomThemeFromEnteColorScheme(lightScheme, false);
    _darkThemeData = _createCustomThemeFromEnteColorScheme(darkScheme, true);
  }

  Future<void> _loadSavedTheme() async {
    try {
      _themeState = ThemeLoadingState.loading;
      notifyListeners();

      final savedTheme = _prefs.getString(_themeKey);
      if (savedTheme != null) {
        _currentTheme = ThemeOptions.values.firstWhere(
          (t) => t.toString() == savedTheme,
          orElse: () => ThemeOptions.system,
        );

        // Pre-cache this theme
        _themeCache[_currentTheme] = _getOrCreateCustomTheme(_currentTheme);
      }

      _themeState = ThemeLoadingState.loaded;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _themeState = ThemeLoadingState.error;
      _currentTheme = ThemeOptions.system;
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeOptions theme, BuildContext context) async {
    if (_isChangingTheme || theme == _currentTheme) return;
    
    try {
      _isChangingTheme = true;
      _themeState = ThemeLoadingState.loading;
      notifyListeners();

      // Save theme first
      await _prefs.setString(_themeKey, theme.toString());
      _currentTheme = theme;

      // Apply theme
      if (theme == ThemeOptions.system) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        final isDark = brightness == Brightness.dark;
        _updateSystemUIOverlay(
          isDark ? darkScheme : lightScheme,
          isDark,
        );
      } else {
        _updateSystemUIOverlay(
          _getThemeScheme(theme),
          !theme.toString().toLowerCase().contains('light'),
        );
      }

      await Future.delayed(const Duration(milliseconds: 16));
      _isChangingTheme = false;
      _themeState = ThemeLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _themeState = ThemeLoadingState.error;
      _currentTheme = ThemeOptions.system;
      _isChangingTheme = false;
      notifyListeners();
    }
  }

  ThemeData _getOrCreateCustomTheme(ThemeOptions theme) {
    return _themeCache.putIfAbsent(
      theme,
      () {
        final scheme = _getThemeScheme(theme);
        final isLightTheme = theme.toString().toLowerCase().contains('light');
        return _createCustomThemeFromEnteColorScheme(scheme, !isLightTheme);
      },
    );
  }

  EnteColorScheme _getThemeScheme(ThemeOptions theme) {
    switch (theme) {
      case ThemeOptions.system:
        return lightScheme;
      case ThemeOptions.light:
        return lightScheme;
      case ThemeOptions.dark:
        return darkScheme;
      case ThemeOptions.greenLight:
        return greenLightScheme;
      case ThemeOptions.greenDark:
        return greenDarkScheme;
      case ThemeOptions.redLight:
        return redLightScheme;
      case ThemeOptions.redDark:
        return redDarkScheme;
      case ThemeOptions.blueLight:
        return blueLightScheme;
      case ThemeOptions.blueDark:
        return blueDarkScheme;
      case ThemeOptions.yellowLight:
        return yellowLightScheme;
      case ThemeOptions.yellowDark:
        return yellowDarkScheme;
      case ThemeOptions.purpleLight:
        return purpleLightScheme;
      case ThemeOptions.purpleDark:
        return purpleDarkScheme;
      case ThemeOptions.orangeLight:
        return orangeLightScheme;
      case ThemeOptions.orangeDark:
        return orangeDarkScheme;
      case ThemeOptions.tealLight:
        return tealLightScheme;
      case ThemeOptions.tealDark:
        return tealDarkScheme;
      case ThemeOptions.roseLight:
        return roseLightScheme;
      case ThemeOptions.roseDark:
        return roseDarkScheme;
      case ThemeOptions.indigoLight:
        return indigoLightScheme;
      case ThemeOptions.indigoDark:
        return indigoDarkScheme;
      case ThemeOptions.mochaLight:
        return mochaLightScheme;
      case ThemeOptions.mochaDark:
        return mochaDarkScheme;
      case ThemeOptions.aquaLight:
        return aquaLightScheme;
      case ThemeOptions.aquaDark:
        return aquaDarkScheme;
      case ThemeOptions.lilacLight:
        return lilacLightScheme;
      case ThemeOptions.lilacDark:
        return lilacDarkScheme;
      case ThemeOptions.emeraldLight:
        return emeraldLightScheme;
      case ThemeOptions.emeraldDark:
        return emeraldDarkScheme;
      case ThemeOptions.slateLight:
        return slateLightScheme;
      case ThemeOptions.slateDark:
        return slateDarkScheme;
      default:
        return lightScheme;
    }
  }

  void _updateSystemUIOverlay(EnteColorScheme colorScheme, bool isDark) {
    // For system theme and default dark theme, always use transparent
    final bool isDefaultDarkTheme = isDark && (
      _currentTheme == ThemeOptions.system || 
      _currentTheme == ThemeOptions.dark ||
      identical(colorScheme, darkScheme) ||
      identical(colorScheme, enteDarkScheme)
    );

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: colorScheme.backgroundBase,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDefaultDarkTheme 
          ? Colors.transparent
          : colorScheme.backgroundBase,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),);
  }

  ThemeData _createCustomThemeFromEnteColorScheme(EnteColorScheme enteColorScheme, bool isDark) {
    final isDefaultDarkScheme = identical(enteColorScheme, darkScheme) ||
        identical(enteColorScheme, enteDarkScheme);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: enteColorScheme.backgroundBase,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDefaultDarkScheme
          ? Colors.transparent
          : enteColorScheme.backgroundBase,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      extensions: [
        EnteTheme(
          isDark ? darkTextTheme : lightTextTheme,
          enteColorScheme,
          shadowFloat: isDark ? shadowFloatDark : shadowFloatLight,
          shadowMenu: isDark ? shadowMenuDark : shadowMenuLight,
          shadowButton: isDark ? shadowButtonDark : shadowButtonLight,
        ),
      ],

      // Primary colors
      primaryColor: enteColorScheme.primary500,
      primaryColorDark: enteColorScheme.primary700,
      primaryColorLight: enteColorScheme.primary300,

      // Background colors
      scaffoldBackgroundColor: enteColorScheme.backgroundBase,
      cardColor: enteColorScheme.backgroundElevated,
      canvasColor: enteColorScheme.backgroundBase,
      dialogBackgroundColor: enteColorScheme.backgroundElevated,

      // Text colors
      textTheme: lightThemeData.textTheme.apply(
        bodyColor: enteColorScheme.textBase,
        displayColor: enteColorScheme.primary500,
      ),
      primaryTextTheme: lightThemeData.primaryTextTheme.apply(
        bodyColor: enteColorScheme.textBase,
        displayColor: enteColorScheme.primary500,
      ),

      // Icon themes
      iconTheme: IconThemeData(color: enteColorScheme.tabIcon),
      primaryIconTheme: IconThemeData(color: enteColorScheme.primary500),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: enteColorScheme.backgroundBase,
        foregroundColor: enteColorScheme.textBase,
        iconTheme: IconThemeData(color: enteColorScheme.tabIcon),
        actionsIconTheme: IconThemeData(color: enteColorScheme.tabIcon),
        elevation: 0,
        systemOverlayStyle: overlayStyle,
      ),

      // Button themes
      buttonTheme: ButtonThemeData(
        buttonColor: enteColorScheme.primary500,
        disabledColor: enteColorScheme.fillMuted,
        textTheme: ButtonTextTheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: enteColorScheme.textBase,
          backgroundColor: enteColorScheme.primary500,
          disabledForegroundColor: enteColorScheme.textMuted,
          disabledBackgroundColor: enteColorScheme.fillMuted,
        ),
      ),

      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: enteColorScheme.primary500,
        onPrimary: enteColorScheme.textBase,
        secondary: enteColorScheme.primary400,
        onSecondary: enteColorScheme.textBase,
        error: enteColorScheme.warning500,
        onError: Colors.white,
        background: enteColorScheme.backgroundBase,
        onBackground: enteColorScheme.textBase,
        surface: enteColorScheme.backgroundElevated,
        onSurface: enteColorScheme.textBase,
        primaryContainer: enteColorScheme.primary700,
        onPrimaryContainer: enteColorScheme.textBase,
        secondaryContainer: enteColorScheme.primary300,
        onSecondaryContainer: enteColorScheme.textBase,
        surfaceVariant: enteColorScheme.backgroundElevated2,
        onSurfaceVariant: enteColorScheme.textMuted,
      ),

      // Other theme data
      dividerColor: enteColorScheme.strokeFaint,
      hintColor: enteColorScheme.textMuted,
      disabledColor: enteColorScheme.fillMuted,
      shadowColor: enteColorScheme.strokeSolidMuted,
      splashColor: enteColorScheme.fillFaint,
      highlightColor: enteColorScheme.fillFaintPressed,
    );
  }

  // Add a method to handle system theme changes
  void _handleSystemThemeChange() {
    if (_currentTheme == ThemeOptions.system) {
      final isDark = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      _updateSystemUIOverlay(
        isDark ? darkScheme : lightScheme,
        isDark,
      );
      notifyListeners();
    }
  }

  // Add theme reset method
  Future<void> resetTheme(BuildContext context) async {
    await setTheme(ThemeOptions.system, context);
    _themeCache.clear();
    _preCacheThemes();
  }

  // Add method to check if theme is dark
  bool isThemeDark(ThemeOptions theme) {
    if (theme == ThemeOptions.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return theme.toString().toLowerCase().contains('dark');
  }

  // Add pre-cache method
  void _preCacheThemes() {
    _themeCache[ThemeOptions.system] = _createCustomThemeFromEnteColorScheme(lightScheme, false);
    _themeCache[ThemeOptions.light] = _createCustomThemeFromEnteColorScheme(lightScheme, false);
    _themeCache[ThemeOptions.dark] = _createCustomThemeFromEnteColorScheme(darkScheme, true);
    
    // Pre-cache commonly used themes
    _themeCache[ThemeOptions.greenLight] = _createCustomThemeFromEnteColorScheme(greenLightScheme, false);
    _themeCache[ThemeOptions.greenDark] = _createCustomThemeFromEnteColorScheme(greenDarkScheme, true);
    _themeCache[ThemeOptions.blueLight] = _createCustomThemeFromEnteColorScheme(blueLightScheme, false);
    _themeCache[ThemeOptions.blueDark] = _createCustomThemeFromEnteColorScheme(blueDarkScheme, true);
  }
}

// ... rest of the code remains the same ... 