import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/text_style.dart';

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

  static bool isDark(ThemeData theme) {
    return theme.brightness == Brightness.dark;
  }

  static EnteColorScheme getColorScheme(
    ThemeData theme, {
    bool inverse = false,
  }) {
    return inverse
        ? theme.colorScheme.inverseEnteTheme.colorScheme
        : theme.colorScheme.enteTheme.colorScheme;
  }

  static EnteTextTheme getTextTheme(
    ThemeData theme, {
    bool inverse = false,
  }) {
    return inverse
        ? theme.colorScheme.inverseEnteTheme.textTheme
        : theme.colorScheme.enteTheme.textTheme;
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
