import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';

enum ThemeOptions {
  system,
  light,
  dark,
  greenLight,
  redDark,
}

class EnteThemeProvider extends ChangeNotifier {
  ThemeOptions _currentTheme = ThemeOptions.system;

  ThemeOptions get currentTheme => _currentTheme;

  Future<void> setTheme(ThemeOptions theme, BuildContext context) async {
    _currentTheme = theme;
    
    try {
      final adaptiveTheme = AdaptiveTheme.of(context);
      
      switch (theme) {
        case ThemeOptions.system:
          adaptiveTheme.setLight();
          adaptiveTheme.setDark();
          await Future.delayed(const Duration(milliseconds: 100));
          adaptiveTheme.setSystem();
          _updateThemeData(adaptiveTheme, lightThemeData, darkThemeData);
          break;
        case ThemeOptions.light:
          adaptiveTheme.setLight();
          await Future.delayed(const Duration(milliseconds: 100));
          _updateThemeData(adaptiveTheme, lightThemeData, lightThemeData);
          break;
        case ThemeOptions.dark:
          adaptiveTheme.setDark();
          await Future.delayed(const Duration(milliseconds: 100));
          _updateThemeData(adaptiveTheme, darkThemeData, darkThemeData);
          break;
        case ThemeOptions.greenLight:
          final customTheme = _createCustomThemeFromEnteColorScheme(greenLightScheme, false);
          adaptiveTheme.setLight();
          await Future.delayed(const Duration(milliseconds: 100));
          _updateThemeData(adaptiveTheme, customTheme, customTheme);
          break;
        case ThemeOptions.redDark:
          final customTheme = _createCustomThemeFromEnteColorScheme(redDarkScheme, true);
          adaptiveTheme.setDark();
          await Future.delayed(const Duration(milliseconds: 100));
          _updateThemeData(adaptiveTheme, customTheme, customTheme);
          break;
      }

      notifyListeners();
      
    } catch (e) {
      print('Error setting theme: $e');
      rethrow;
    }
  }

  void _updateThemeData(AdaptiveThemeManager adaptiveTheme, ThemeData light, ThemeData dark) {
    adaptiveTheme.setTheme(
      light: light,
      dark: dark,
    );
  }

  ThemeData _createCustomThemeFromEnteColorScheme(EnteColorScheme enteColorScheme, bool isDark) {
    // Create base theme data
    final baseTheme = isDark ? darkThemeData : lightThemeData;
    
    // Create EnteTheme instance with the custom color scheme
    final customEnteTheme = EnteTheme(
      isDark ? darkTextTheme : lightTextTheme,
      enteColorScheme,
      shadowFloat: isDark ? shadowFloatDark : shadowFloatLight,
      shadowMenu: isDark ? shadowMenuDark : shadowMenuLight,
      shadowButton: isDark ? shadowButtonDark : shadowButtonLight,
    );

    // Create theme data
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      extensions: [customEnteTheme],
      
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
      textTheme: baseTheme.textTheme.apply(
        bodyColor: enteColorScheme.textBase,
        displayColor: enteColorScheme.primary500,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
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
} 