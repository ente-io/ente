// Test to validate the color system migration
// This file is for verification purposes only

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/ente_theme.dart';
import '../theme/ente_theme_data.dart';

/// Test widget to verify the new color system works correctly
class ColorSystemTestWidget extends StatelessWidget {
  const ColorSystemTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Test that we can access the color scheme from theme
    final colorScheme = Theme.of(context).extension<EnteColorScheme>();

    // Test that fallback to old system works
    final fallbackColorScheme = colorScheme ?? getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: fallbackColorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: fallbackColorScheme.backgroundElevated,
        title: Text(
          'Color System Test',
          style: TextStyle(color: fallbackColorScheme.textBase),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test basic colors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fallbackColorScheme.backgroundElevated,
                border: Border.all(color: fallbackColorScheme.strokeFaint),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Background Colors Working',
                style: TextStyle(color: fallbackColorScheme.textBase),
              ),
            ),
            const SizedBox(height: 16),

            // Test primary colors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fallbackColorScheme.primary500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Primary Colors Working',
                style: TextStyle(color: fallbackColorScheme.backgroundBase),
              ),
            ),
            const SizedBox(height: 16),

            // Test gradient colors
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: fallbackColorScheme.gradientButtonBgColors,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Gradient Colors Working',
                  style: TextStyle(
                    color: fallbackColorScheme.backgroundBase,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test warning colors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fallbackColorScheme.warning500.withOpacity(0.1),
                border: Border.all(color: fallbackColorScheme.warning500),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Warning Colors Working',
                style: TextStyle(color: fallbackColorScheme.warning700),
              ),
            ),
            const SizedBox(height: 16),

            // Test fill colors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fallbackColorScheme.fillFaint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Fill Colors Working',
                style: TextStyle(color: fallbackColorScheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example showing how apps can create custom themes
class CustomThemeExample {
  // Create a custom purple theme
  static final purpleSchemes = ColorSchemeBuilder.fromPrimaryColor(
    const Color(0xFF6C5CE7), // Purple brand color
  );

  static final lightTheme = createAppThemeData(
    brightness: Brightness.light,
    colorScheme: purpleSchemes.light,
  );

  static final darkTheme = createAppThemeData(
    brightness: Brightness.dark,
    colorScheme: purpleSchemes.dark,
  );
}

/// Example showing migration from old to new system
class MigrationExample extends StatelessWidget {
  const MigrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    // OLD WAY (still works for backward compatibility)
    // final colorScheme = getEnteColorScheme(context);

    // NEW WAY (preferred)
    // final colorScheme = Theme.of(context).extension<EnteColorScheme>()!;

    // SAFE WAY (with fallback)
    final safeColorScheme = Theme.of(context).extension<EnteColorScheme>() ??
        getEnteColorScheme(context);

    return Container(
      color: safeColorScheme.backgroundBase,
      child: Text(
        'Migration Example',
        style: TextStyle(color: safeColorScheme.textBase),
      ),
    );
  }
}
