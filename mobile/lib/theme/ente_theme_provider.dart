import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  ThemeProvider() {
    // No initialization here
  }

  ThemeOptions get currentTheme => _currentTheme;
  bool get isChangingTheme => _isChangingTheme;

  Future<void> initializeTheme(BuildContext context) async {
    if (_isChangingTheme) return;
    
    try {
      _isChangingTheme = true;
      final adaptiveTheme = AdaptiveTheme.of(context);
      
      // For system theme, use lightScheme and darkScheme (not enteDarkScheme)
      _updateThemeData(
        adaptiveTheme,
        _createCustomThemeFromEnteColorScheme(lightScheme, false),
        _createCustomThemeFromEnteColorScheme(darkScheme, true),
      );
      
      adaptiveTheme.setSystem();
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
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
      
      switch (theme) {
        case ThemeOptions.system:
          _updateThemeData(
            adaptiveTheme,
            _createCustomThemeFromEnteColorScheme(lightScheme, false),
            _createCustomThemeFromEnteColorScheme(darkScheme, true),
          );
          adaptiveTheme.setSystem();
          break;

        case ThemeOptions.light:
          _updateThemeData(
            adaptiveTheme,
            _createCustomThemeFromEnteColorScheme(lightScheme, false),
            _createCustomThemeFromEnteColorScheme(lightScheme, false),
          );
          adaptiveTheme.setLight();
          break;

        case ThemeOptions.dark:
          _updateThemeData(
            adaptiveTheme, 
            _createCustomThemeFromEnteColorScheme(enteDarkScheme, true),
            _createCustomThemeFromEnteColorScheme(enteDarkScheme, true),
          );
          adaptiveTheme.setDark();
          break;

        default:
          // Handle custom themes more efficiently
          final isLightTheme = theme.toString().toLowerCase().contains('light');
          final customTheme = _createCustomThemeFromEnteColorScheme(
            _getThemeScheme(theme),
            !isLightTheme,
          );
          _updateThemeData(adaptiveTheme, customTheme, customTheme);
          isLightTheme ? adaptiveTheme.setLight() : adaptiveTheme.setDark();
          break;
      }

      // Notify only after theme is fully applied
      await Future.delayed(const Duration(milliseconds: 50));
      notifyListeners();
      
    } catch (e) {
      print('Error setting theme: $e');
      rethrow;
    } finally {
      _isChangingTheme = false;
    }
  }

  // Helper method to get the correct color scheme
  EnteColorScheme _getThemeScheme(ThemeOptions theme) {
    switch (theme) {
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

  // New method for custom themes
  ThemeData _createCustomTheme(ThemeOptions theme) {
    late EnteColorScheme colorScheme;
    bool isDark = false;

    switch (theme) {
      case ThemeOptions.greenLight:
        colorScheme = greenLightScheme;
        break;
      case ThemeOptions.greenDark:
        colorScheme = greenDarkScheme;
        isDark = true;
        break;
      case ThemeOptions.redLight:
        colorScheme = redLightScheme;
        break;
      case ThemeOptions.redDark:
        colorScheme = redDarkScheme;
        isDark = true;
        break;
      case ThemeOptions.blueLight:
        colorScheme = blueLightScheme;
        break;
      case ThemeOptions.blueDark:
        colorScheme = blueDarkScheme;
        isDark = true;
        break;
      case ThemeOptions.yellowLight:
        colorScheme = yellowLightScheme;
        break;
      case ThemeOptions.yellowDark:
        colorScheme = yellowDarkScheme;
        isDark = true;
        break;
      default:
        colorScheme = lightScheme;
    }

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
      // ... add other necessary theme properties
    );
  }

  void _updateThemeData(AdaptiveThemeManager adaptiveTheme, ThemeData light, ThemeData dark) {
    adaptiveTheme.setTheme(
      light: light,
      dark: dark,
    );
  }

  ThemeData _createCustomThemeFromEnteColorScheme(EnteColorScheme enteColorScheme, bool isDark) {
    // Special handling for dark theme
    if (isDark && enteColorScheme == darkScheme) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [darkTheme],
        // Use the original dark theme data
        primaryColor: darkScheme.primary500,
        primaryColorDark: darkScheme.primary700,
        primaryColorLight: darkScheme.primary300,
        scaffoldBackgroundColor: darkScheme.backgroundBase,
        // ... other theme properties using darkScheme colors
      );
    }
    
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

    // Create system UI overlay style
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: enteColorScheme.backgroundBase, // Match background color
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: enteColorScheme.backgroundBase,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    // Create a new theme data from scratch instead of copying
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
        systemOverlayStyle: overlayStyle, // Add system overlay style
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

// ... rest of the code remains the same ... 