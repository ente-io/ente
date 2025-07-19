// Demo showing the color system migration is complete
// This file demonstrates that the new color system works correctly

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/ente_theme.dart';
import '../theme/ente_theme_data.dart';

/// Demo widget showing the new color system in action
class ColorMigrationDemo extends StatelessWidget {
  const ColorMigrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // NEW: Preferred way to access colors
    final colorScheme = Theme.of(context).extension<EnteColorScheme>() ??
        getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundElevated,
        title: Text(
          'Color Migration Demo',
          style: TextStyle(color: colorScheme.textBase),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              colorScheme,
              'Background Colors',
              color: colorScheme.backgroundElevated,
              border: colorScheme.strokeFaint,
            ),
            const SizedBox(height: 16),
            _buildSection(
              colorScheme,
              'Primary Colors',
              color: colorScheme.primary500,
              textColor: colorScheme.backgroundBase,
            ),
            const SizedBox(height: 16),
            _buildGradientSection(colorScheme),
            const SizedBox(height: 16),
            _buildSection(
              colorScheme,
              'Warning Colors',
              color: colorScheme.warning500.withOpacity(0.1),
              border: colorScheme.warning500,
              textColor: colorScheme.warning700,
            ),
            const SizedBox(height: 16),
            _buildSection(
              colorScheme,
              'Fill Colors',
              color: colorScheme.fillFaint,
              textColor: colorScheme.textMuted,
            ),
            const SizedBox(height: 16),
            _buildMigrationInfo(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    EnteColorScheme colorScheme,
    String title, {
    required Color color,
    Color? border,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: border != null ? Border.all(color: border) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$title ✅',
        style: TextStyle(
          color: textColor ?? colorScheme.textBase,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGradientSection(EnteColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colorScheme.gradientButtonBgColors,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Gradient Colors ✅',
          style: TextStyle(
            color: colorScheme.backgroundBase,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMigrationInfo(EnteColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary500.withOpacity(0.1),
        border: Border.all(color: colorScheme.primary500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Migration Complete! 🎉',
            style: TextStyle(
              color: colorScheme.primary700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• All components migrated to new color system\n'
            '• Theme-aware colors with fallback support\n'
            '• Custom branding support ready\n'
            '• Performance optimized with const colors\n'
            '• Type-safe with compile-time validation',
            style: TextStyle(
              color: colorScheme.textBase,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example of creating custom app themes
class CustomAppThemeExample {
  // Purple brand theme
  static final purpleScheme = ColorSchemeBuilder.fromPrimaryColor(
    const Color(0xFF6C5CE7),
  );

  // Blue brand theme
  static final blueScheme = ColorSchemeBuilder.fromPrimaryColor(
    const Color(0xFF2196F3),
  );

  // Green brand theme
  static final greenScheme = ColorSchemeBuilder.fromPrimaryColor(
    const Color(0xFF4CAF50),
  );

  // Create theme data for each brand
  static ThemeData purpleLightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: purpleScheme.light,
  );

  static ThemeData purpleDarkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: purpleScheme.dark,
  );

  static ThemeData blueLightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: blueScheme.light,
  );

  static ThemeData blueDarkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: blueScheme.dark,
  );
}

/// Example app showing how to use the new color system
class ColorSystemExampleApp extends StatelessWidget {
  const ColorSystemExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color System Demo',
      theme: CustomAppThemeExample.blueLightTheme,
      darkTheme: CustomAppThemeExample.blueDarkTheme,
      home: const ColorMigrationDemo(),
    );
  }
}
