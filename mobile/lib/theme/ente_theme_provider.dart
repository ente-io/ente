import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';

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
}

class ThemeProvider extends ChangeNotifier {
  ThemeOptions _currentTheme = ThemeOptions.system;
  bool _isChangingTheme = false;

  ThemeOptions get currentTheme => _currentTheme;
  bool get isChangingTheme => _isChangingTheme;

  Future<void> initializeTheme(BuildContext context) async {
    if (_isChangingTheme) return;
    
    try {
      _isChangingTheme = true;
      final adaptiveTheme = AdaptiveTheme.of(context);
      
      final themeData = _createThemeData(lightScheme, false);
      final darkData = _createThemeData(darkScheme, true);
      
      adaptiveTheme.setTheme(light: themeData, dark: darkData);
      adaptiveTheme.setSystem();
      
      if (Theme.of(context).brightness == Brightness.dark) {
        _updateSystemUI(darkScheme, true);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme: $e');
    } finally {
      _isChangingTheme = false;
    }
  }

  Future<void> setTheme(ThemeOptions theme, BuildContext context) async {
    if (_isChangingTheme || theme == _currentTheme) return;
    
    try {
      _isChangingTheme = true;
      _currentTheme = theme;
      final adaptiveTheme = AdaptiveTheme.of(context);
      
      final isDark = _isDarkTheme(theme, context);
      final colorScheme = _getColorScheme(theme);
      final themeData = _createThemeData(colorScheme, isDark);

      _applyTheme(adaptiveTheme, theme, themeData, context);
      _updateSystemUI(colorScheme, isDark);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
      rethrow;
    } finally {
      _isChangingTheme = false;
    }
  }

  bool _isDarkTheme(ThemeOptions theme, BuildContext context) {
    return theme == ThemeOptions.dark || 
           (theme == ThemeOptions.system && Theme.of(context).brightness == Brightness.dark) ||
           (!theme.toString().toLowerCase().contains('light') && theme != ThemeOptions.system);
  }

  EnteColorScheme _getColorScheme(ThemeOptions theme) {
    switch (theme) {
      case ThemeOptions.system:
        return lightScheme;
      case ThemeOptions.dark:
        return enteDarkScheme;
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
      default:
        return lightScheme;
    }
  }

  void _applyTheme(
    AdaptiveThemeManager adaptiveTheme, 
    ThemeOptions theme, 
    ThemeData themeData,
    BuildContext context,
  ) {
    switch (theme) {
      case ThemeOptions.system:
        adaptiveTheme.setTheme(
          light: _createThemeData(lightScheme, false),
          dark: _createThemeData(darkScheme, true),
        );
        adaptiveTheme.setSystem();
        break;
      default:
        adaptiveTheme.setTheme(light: themeData, dark: themeData);
        _isDarkTheme(theme, context) 
            ? adaptiveTheme.setDark() 
            : adaptiveTheme.setLight();
        break;
    }
  }

  void _updateSystemUI(EnteColorScheme colorScheme, bool isDark) {
    final isDefaultDarkScheme = identical(colorScheme, darkScheme) || 
                               identical(colorScheme, enteDarkScheme);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: colorScheme.backgroundBase,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDefaultDarkScheme 
          ? Colors.transparent 
          : colorScheme.backgroundBase,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),);
  }

  ThemeData _createThemeData(EnteColorScheme colorScheme, bool isDark) {
    final isDefaultDarkScheme = identical(colorScheme, darkScheme) || 
                               identical(colorScheme, enteDarkScheme);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: colorScheme.backgroundBase,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDefaultDarkScheme 
          ? Colors.transparent 
          : colorScheme.backgroundBase,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      extensions: [
        EnteTheme(
          isDark ? darkTextTheme : lightTextTheme,
          colorScheme,
          shadowFloat: isDark ? shadowFloatDark : shadowFloatLight,
          shadowMenu: isDark ? shadowMenuDark : shadowMenuLight,
          shadowButton: isDark ? shadowButtonDark : shadowButtonLight,
        ),
      ],
      primaryColor: colorScheme.primary500,
      primaryColorDark: colorScheme.primary700,
      primaryColorLight: colorScheme.primary300,
      scaffoldBackgroundColor: colorScheme.backgroundBase,
      cardColor: colorScheme.backgroundElevated,
      canvasColor: colorScheme.backgroundBase,
      dialogBackgroundColor: colorScheme.backgroundElevated,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.backgroundBase,
        foregroundColor: colorScheme.textBase,
        iconTheme: IconThemeData(color: colorScheme.tabIcon),
        actionsIconTheme: IconThemeData(color: colorScheme.tabIcon),
        elevation: 0,
        systemOverlayStyle: overlayStyle,
      ),
    );
  }
}

// ... rest of the code remains the same ... 