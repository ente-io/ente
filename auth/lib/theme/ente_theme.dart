import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/effects.dart';
import 'package:ente_auth/theme/text_style.dart';
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
  return inverse
      ? Theme.of(context).colorScheme.inverseEnteTheme.colorScheme
      : Theme.of(context).colorScheme.enteTheme.colorScheme;
}



EnteTextTheme getEnteTextTheme(
  BuildContext context, {
  bool inverse = false,
}) {
  return inverse
      ? Theme.of(context).colorScheme.inverseEnteTheme.textTheme
      : Theme.of(context).colorScheme.enteTheme.textTheme;
}
