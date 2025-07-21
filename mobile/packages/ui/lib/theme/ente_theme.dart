import 'package:ente_ui/theme/colors.dart';
import 'package:ente_ui/theme/effects.dart';
import 'package:ente_ui/theme/text_style.dart';
import 'package:flutter/material.dart';

class EnteTheme {
  final EnteTextTheme textTheme;
  final EnteColorScheme colorScheme;
  final List<BoxShadow> shadowFloat;
  final List<BoxShadow> shadowMenu;
  final List<BoxShadow> shadowButton;

  const EnteTheme(
    this.textTheme,
    this.colorScheme, {
    required this.shadowFloat,
    required this.shadowMenu,
    required this.shadowButton,
  });

  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

EnteTheme lightTheme = EnteTheme(
  lightTextTheme,
  lightScheme,
  shadowFloat: shadowFloatLight,
  shadowMenu: shadowMenuLight,
  shadowButton: shadowButtonLight,
);

EnteTheme darkTheme = EnteTheme(
  darkTextTheme,
  darkScheme,
  shadowFloat: shadowFloatDark,
  shadowMenu: shadowMenuDark,
  shadowButton: shadowButtonDark,
);

EnteColorScheme getEnteColorScheme(
  BuildContext context, {
  bool inverse = false,
}) {
  final colorScheme = Theme.of(context).extension<EnteColorScheme>();
  if (colorScheme != null) {
    return colorScheme;
  }

  // Fallback to old system if new system is not available
  return inverse
      ? getEnteColorScheme(context).inverseEnteTheme.colorScheme
      : getEnteColorScheme(context);
}

EnteTextTheme getEnteTextTheme(
  BuildContext context, {
  bool inverse = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (inverse) {
    return isDark ? lightTextTheme : darkTextTheme;
  } else {
    return isDark ? darkTextTheme : lightTextTheme;
  }
}

/// Get theme-aware shadow for floating elements (dialogs, modals, etc.)
List<BoxShadow> getEnteShadowFloat(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? shadowFloatDark : shadowFloatLight;
}

/// Get theme-aware shadow for menu elements
List<BoxShadow> getEnteShadowMenu(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? shadowMenuDark : shadowMenuLight;
}

/// Get theme-aware shadow for button elements
List<BoxShadow> getEnteShadowButton(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? shadowButtonDark : shadowButtonLight;
}
