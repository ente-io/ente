// Example: How to use the reusable EnteColorScheme in your app
// filepath: example_app_colors.dart

import 'package:flutter/material.dart';
import 'colors.dart'; // Import the reusable color scheme
import 'ente_theme_data.dart'; // Import the theme data helper
import 'ente_theme.dart'; // Import for getEnteColorScheme

/// Example 1: Using the default color scheme
class DefaultThemeExample {
  static final lightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: lightScheme,
  );

  static final darkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: darkScheme,
  );
}

/// Example 2: Creating a custom theme with brand colors
class CustomBrandThemeExample {
  // Define your app's brand colors
  static const Color brandPrimaryColor = Color(0xFF6C5CE7); // Purple

  static final schemes = ColorSchemeBuilder.fromPrimaryColor(brandPrimaryColor);

  static final lightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: schemes.light,
  );

  static final darkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: schemes.dark,
  );
}

/// Example 3: Creating a theme with fully custom primary colors
class FullyCustomThemeExample {
  static final schemes = ColorSchemeBuilder.fromCustomColors(
    primary700: const Color(0xFF1565C0), // Dark blue
    primary500: const Color(0xFF2196F3), // Material blue
    primary400: const Color(0xFF42A5F5), // Light blue
    primary300: const Color(0xFF90CAF9), // Very light blue
    iconButtonColor: const Color(0xFF1976D2), // Custom icon color
    gradientButtonBgColors: const [
      Color(0xFF1565C0),
      Color(0xFF2196F3),
      Color(0xFF42A5F5),
    ],
  );

  static final lightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: schemes.light,
  );

  static final darkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: schemes.dark,
  );
}

/// Example 4: Using factory constructors for fine-grained control
class FactoryConstructorExample {
  static final lightScheme = EnteColorScheme.light(
    primary700: const Color(0xFFE91E63), // Pink 700
    primary500: const Color(0xFFF06292), // Pink 300
    primary400: const Color(0xFFF8BBD9), // Pink 200
    primary300: const Color(0xFFFCE4EC), // Pink 50
    warning500: const Color(0xFFFF5722), // Custom warning color
  );

  static final darkScheme = EnteColorScheme.dark(
    primary700: const Color(0xFFE91E63),
    primary500: const Color(0xFFF06292),
    primary400: const Color(0xFFF8BBD9),
    primary300: const Color(0xFFFCE4EC),
    warning500: const Color(0xFFFF5722),
  );

  static final lightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: lightScheme,
  );

  static final darkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: darkScheme,
  );
}

/// Helper function to get the current color scheme from context
EnteColorScheme getColorScheme(BuildContext context) {
  return getEnteColorScheme(context);
}

/// Example widget showing how to use the color scheme in your UI
class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);

    return Container(
      color: colorScheme.backgroundBase,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated,
              border: Border.all(color: colorScheme.strokeFaint),
            ),
            child: Text(
              'Example Text',
              style: TextStyle(color: colorScheme.textBase),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary500,
              foregroundColor: colorScheme.backgroundBase,
            ),
            onPressed: () {},
            child: const Text('Primary Button'),
          ),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorScheme.gradientButtonBgColors,
              ),
            ),
            child: Center(
              child: Text(
                'Gradient Button',
                style: TextStyle(
                  color: colorScheme.backgroundBase,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
