import 'dart:ui';

import 'package:flutter/material.dart';

class EnteColorScheme {
  // Background Colors
  final Color backgroundBase;
  final Color backgroundElevated;
  final Color backgroundElevated2;

  // Backdrop Colors
  final Color backdropBase;
  final Color backdropMuted;
  final Color backdropFaint;
  final Color xdaColor;


  // Text Colors
  final Color textBase;
  final Color textMuted;
  final Color textFaint;
  final Color blurTextBase;

  // Fill Colors
  final Color fillBase;
  final Color fillBasePressed;
  final Color fillStrong;
  final Color fillMuted;
  final Color fillFaint;
  final Color fillFaintPressed;
  final Color fillBaseGrey;

  // Stroke Colors
  final Color strokeBase;
  final Color strokeMuted;
  final Color strokeFaint;
  final Color strokeFainter;
  final Color blurStrokeBase;
  final Color blurStrokeFaint;
  final Color blurStrokePressed;

  // Fixed Colors
  final Color fixedStrokeMutedWhite;
  final Color strokeSolidMuted;
  final Color strokeSolidFaint;
  final Color primary700;
  final Color primary500;
  final Color primary400;
  final Color primary300;
  final Color warning700;
  final Color warning500;
  final Color warning400;
  final Color warning800;
  final Color caution500;
  final Color golden700;
  final Color golden500;

  //other colors
  final Color tabIcon;
  final List<Color> avatarColors;

  const EnteColorScheme(
      this.backgroundBase,
      this.backgroundElevated,
      this.backgroundElevated2,
      this.backdropBase,
      this.backdropMuted,
      this.backdropFaint,
      this.xdaColor,
      this.textBase,
      this.textMuted,
      this.textFaint,
      this.blurTextBase,
      this.fillBase,
      this.fillBasePressed,
      this.fillStrong,
      this.fillMuted,
      this.fillFaint,
      this.fillFaintPressed,
      this.fillBaseGrey,
      this.strokeBase,
      this.strokeMuted,
      this.strokeFaint,
      this.strokeFainter,
      this.blurStrokeBase,
      this.blurStrokeFaint,
      this.blurStrokePressed,
      this.tabIcon,
      this.avatarColors,
      this.fixedStrokeMutedWhite,
      this.strokeSolidMuted,
      this.strokeSolidFaint,
      this.primary700,
      this.primary500,
      this.primary400,
      this.primary300,
      this.warning700,
      this.warning500,
      this.warning400,
      this.warning800,
      this.caution500,
      this.golden700,
      this.golden500,
      );
}

const EnteColorScheme lightScheme = EnteColorScheme(
  backgroundBaseLight,
  backgroundElevatedLight,
  backgroundElevated2Light,
  backdropBaseLight,
  backdropMutedLight,
  backdropFaintLight,
  Color(0xFF1224D3),
  textBaseLight,
  textMutedLight,
  textFaintLight,
  blurTextBaseLight,
  fillBaseLight,
  fillBasePressedLight,
  fillStrongLight,
  fillMutedLight,
  fillFaintLight,
  fillFaintPressedLight,
  fillBaseGreyLight,
  strokeBaseLight,
  strokeMutedLight,
  strokeFaintLight,
  strokeFainterLight,
  blurStrokeBaseLight,
  blurStrokeFaintLight,
  blurStrokePressedLight,
  tabIconLight,
  avatarLight,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color.fromRGBO(13, 71, 161, 1),    // primary700 - Dark Blue
  Color.fromRGBO(25, 118, 210, 1),   // primary500 - Medium Blue
  Color.fromRGBO(33, 150, 243, 1),   // primary400 - Light Blue
  Color.fromRGBO(66, 165, 245, 1),   // primary300 - Very Light Blue
  _warning700,
  _warning500,
  _warning400,
  _warning800,
  _caution500,
  _golden700,
  _golden500,
);

const EnteColorScheme darkScheme = EnteColorScheme(
  backgroundBaseDark,
  backgroundElevatedDark,
  backgroundElevated2Dark,
  backdropBaseDark,
  backdropMutedDark,
  backdropFaintDark,
  Color(0xFF590000),
  textBaseDark,
  textMutedDark,
  textFaintDark,
  blurTextBaseDark,
  fillBaseDark,
  fillBasePressedDark,
  fillStrongDark,
  fillMutedDark,
  fillFaintDark,
  fillFaintPressedDark,
  fillBaseGreyDark,
  strokeBaseDark,
  strokeMutedDark,
  strokeFaintDark,
  strokeFainterDark,
  blurStrokeBaseDark,
  blurStrokeFaintDark,
  blurStrokePressedDark,
  tabIconDark,
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  _primary700,
  _primary500,
  _primary400,
  _primary300,
  _warning700,
  _warning500,
  _warning400,
  _warning800,
  _caution500,
  _golden700,
  _golden500,
);

const EnteColorScheme enteDarkScheme = EnteColorScheme(
  backgroundBaseDark,
  backgroundElevatedDark,
  backgroundElevated2Dark,
  backdropBaseDark,
  backdropMutedDark,
  backdropFaintDark,
  Color(0xFF590000),
  textBaseDark,
  textMutedDark,
  textFaintDark,
  blurTextBaseDark,
  fillBaseDark,
  fillBasePressedDark,
  fillStrongDark,
  fillMutedDark,
  fillFaintDark,
  fillFaintPressedDark,
  fillBaseGreyDark,
  strokeBaseDark,
  strokeMutedDark,
  strokeFaintDark,
  strokeFainterDark,
  blurStrokeBaseDark,
  blurStrokeFaintDark,
  blurStrokePressedDark,
  tabIconDark,
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  _primary700,
  _primary500,
  _primary400,
  _primary300,
  _warning700,
  _warning500,
  _warning400,
  _warning800,
  _caution500,
  _golden700,
  _golden500,
);

const EnteColorScheme greenLightScheme = EnteColorScheme(
  Color(0xFFE8F5E9),
  Color(0xFFC8E6C9),
  Color(0xFFA5D6A7),
  Color(0xFF81C784),
  Color(0xFF66BB6A),
  Color(0xFF4CAF50),
  Color(0xBDD56060),
  Color(0xFF2E7D32),
  Color(0xFF388E3C),
  Color(0xFF43A047),
  Color(0xFF2E7D32),
  Color(0xFF4CAF50),
  Color(0xFF43A047),
  Color(0xFF388E3C),
  Color(0xFF66BB6A),
  Color(0xFFA5D6A7),
  Color(0xFF81C784),
  Color(0xFFC8E6C9),
  Color(0xFF4CAF50),
  Color(0xFF66BB6A),
  Color(0xFFA5D6A7),
  Color(0xFFC8E6C9),
  Color(0xFF4CAF50),
  Color(0xFF66BB6A),
  Color(0xFF43A047),
  Color(0xFF2E7D32),
  avatarLight,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFF2E7D32),  // primary700 - Dark Green
  Color(0xFF388E3C),  // primary500 - Medium Green
  Color(0xFF43A047),  // primary400 - Light Green
  Color(0xFF66BB6A),  // primary300 - Very Light Green
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);

const EnteColorScheme redDarkScheme = EnteColorScheme(
  Color(0xFF1A0000),
  Color(0xFF260000),
  Color(0xFF330000),
  Color(0xFF400000),
  Color(0xFF4D0000),
  Color(0xFF590000),
  Color(0xC8289F20),
  Color(0xFFFFCDD2),
  Color(0xFFEF9A9A),
  Color(0xFFE57373),
  Color(0xFFFFCDD2),
  Color(0xFFE53935),
  Color(0xFFD32F2F),
  Color(0xFFC62828),
  Color(0xFFEF5350),
  Color(0xFFE57373),
  Color(0xFFEF9A9A),
  Color(0xFF4D0000),
  Color(0xFFE53935),
  Color(0xFFEF5350),
  Color(0xFFE57373),
  Color(0xFFEF9A9A),
  Color(0xFFE53935),
  Color(0xFFEF5350),
  Color(0xFFD32F2F),
  Color(0xFFEF5350),
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFFB71C1C),  // primary700 - Dark Red
  Color(0xFFC62828),  // primary500 - Medium Red
  Color(0xFFD32F2F),  // primary400 - Light Red
  Color(0xFFE53935),  // primary300 - Very Light Red
  Color(0xFF8B0000),  // warning700
  Color(0xFFA00000),  // warning500
  Color(0xFFB71C1C),  // warning400
  Color(0xFF7B1FA2),  // warning800
  Color(0xFFFF6F00),  // caution500
  Color(0xFFFF8F00),  // golden700
  Color(0xFFFFB300),  // golden500
);

const EnteColorScheme greenDarkScheme = EnteColorScheme(
  Color(0xFF0A1F0A),  // Very dark green background
  Color(0xFF132913),
  Color(0xFF1B331B),
  Color(0xFF0A1F0A),
  Color(0xFF132913),
  Color(0xFF1B331B),
  Color(0xFF512727),
  Color(0xFFA5D6A7),  // Light text for dark theme
  Color(0xFF81C784),
  Color(0xFF66BB6A),
  Color(0xFFA5D6A7),
  Color(0xFF2E7D32),
  Color(0xFF1B5E20),
  Color(0xFF388E3C),
  Color(0xFF43A047),
  Color(0xFF4CAF50),
  Color(0xFF66BB6A),
  Color(0xFF1B331B),
  Color(0xFF2E7D32),
  Color(0xFF388E3C),
  Color(0xFF43A047),
  Color(0xFF4CAF50),
  Color(0xFF2E7D32),
  Color(0xFF388E3C),
  Color(0xFF1B5E20),
  Color(0xFF81C784),
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFF1B5E20),  // primary700 - Darkest Green
  Color(0xFF2E7D32),  // primary500 - Dark Green
  Color(0xFF388E3C),  // primary400 - Medium Green
  Color(0xFF43A047),  // primary300 - Light Green
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);

const EnteColorScheme redLightScheme = EnteColorScheme(
  Color(0xFFFFEBEE),  // Very light red background
  Color(0xFFFFCDD2),
  Color(0xFFEF9A9A),
  Color(0xFFE57373),
  Color(0xFFEF5350),
  Color(0xFFF44336),
  Color(0xFF2752A8),
  Color(0xFF212121),  // Dark text for light theme
  Color(0xFF424242),
  Color(0xFF616161),
  Color(0xFF212121),
  Color(0xFFD32F2F),
  Color(0xFFC62828),
  Color(0xFFB71C1C),
  Color(0xFFE53935),
  Color(0xFFEF5350),
  Color(0xFFE57373),
  Color(0xFFFFCDD2),
  Color(0xFFD32F2F),
  Color(0xFFE53935),
  Color(0xFFEF5350),
  Color(0xFFE57373),
  Color(0xFFD32F2F),
  Color(0xFFE53935),
  Color(0xFFC62828),
  Color(0xFFD32F2F),
  avatarLight,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color.fromRGBO(13, 71, 161, 1),    // primary700 - Dark Blue
  Color.fromRGBO(25, 118, 210, 1),   // primary500 - Medium Blue
  Color.fromRGBO(33, 150, 243, 1),   // primary400 - Light Blue
  Color.fromRGBO(66, 165, 245, 1),   // primary300 - Very Light Blue
  _warning700,
  _warning500,
  _warning400,
  _warning800,
  _caution500,
  _golden700,
  _golden500,
);

// Background Colors
const Color backgroundBaseLight = Color.fromRGBO(255, 255, 255, 1);
const Color backgroundElevatedLight = Color.fromRGBO(255, 255, 255, 1);
const Color backgroundElevated2Light = Color.fromRGBO(251, 251, 251, 1);

const Color backgroundBaseDark = Color.fromRGBO(0, 0, 0, 1);
const Color backgroundElevatedDark = Color.fromRGBO(27, 27, 27, 1);
const Color backgroundElevated2Dark = Color.fromRGBO(37, 37, 37, 1);

// Backdrop Colors
const Color backdropBaseLight = Color.fromRGBO(255, 255, 255, 0.92);
const Color backdropMutedLight = Color.fromRGBO(255, 255, 255, 0.75);
const Color backdropFaintLight = Color.fromRGBO(255, 255, 255, 0.30);

const Color backdropBaseDark = Color.fromRGBO(0, 0, 0, 0.90);
const Color backdropMutedDark = Color.fromRGBO(0, 0, 0, 0.65);
const Color backdropFaintDark = Color.fromRGBO(0, 0, 0, 0.20);

// Text Colors
const Color textBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color textMutedLight = Color.fromRGBO(0, 0, 0, 0.6);
const Color textFaintLight = Color.fromRGBO(0, 0, 0, 0.5);
const Color blurTextBaseLight = Color.fromRGBO(0, 0, 0, 0.65);

const Color textBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color textMutedDark = Color.fromRGBO(255, 255, 255, 0.7);
const Color textFaintDark = Color.fromRGBO(255, 255, 255, 0.5);
const Color blurTextBaseDark = Color.fromRGBO(255, 255, 255, 0.95);

// Fill Colors
const Color fillBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color fillBasePressedLight = Color.fromRGBO(0, 0, 0, 0.87);
const Color fillStrongLight = Color.fromRGBO(0, 0, 0, 0.24);
const Color fillMutedLight = Color.fromRGBO(0, 0, 0, 0.12);
const Color fillFaintLight = Color.fromRGBO(0, 0, 0, 0.04);
const Color fillFaintPressedLight = Color.fromRGBO(0, 0, 0, 0.08);
const Color fillBaseGreyLight = Color.fromRGBO(242, 242, 242, 1);

const Color fillBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color fillBasePressedDark = Color.fromRGBO(255, 255, 255, 0.9);
const Color fillStrongDark = Color.fromRGBO(255, 255, 255, 0.32);
const Color fillMutedDark = Color.fromRGBO(255, 255, 255, 0.16);
const Color fillFaintDark = Color.fromRGBO(255, 255, 255, 0.12);
const Color fillFaintPressedDark = Color.fromRGBO(255, 255, 255, 0.06);
const Color fillBaseGreyDark = Color.fromRGBO(66, 66, 66, 1);

// Stroke Colors
const Color strokeBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color strokeMutedLight = Color.fromRGBO(0, 0, 0, 0.24);
const Color strokeFaintLight = Color.fromRGBO(0, 0, 0, 0.12);
const Color strokeFainterLight = Color.fromRGBO(0, 0, 0, 0.06);
const Color blurStrokeBaseLight = Color.fromRGBO(0, 0, 0, 0.65);
const Color blurStrokeFaintLight = Color.fromRGBO(0, 0, 0, 0.08);
const Color blurStrokePressedLight = Color.fromRGBO(0, 0, 0, 0.50);

const Color strokeBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color strokeMutedDark = Color.fromRGBO(255, 255, 255, 0.24);
const Color strokeFaintDark = Color.fromRGBO(255, 255, 255, 0.16);
const Color strokeFainterDark = Color.fromRGBO(255, 255, 255, 0.08);
const Color blurStrokeBaseDark = Color.fromRGBO(255, 255, 255, 0.90);
const Color blurStrokeFaintDark = Color.fromRGBO(255, 255, 255, 0.06);
const Color blurStrokePressedDark = Color.fromRGBO(255, 255, 255, 0.50);

// Other colors
const Color tabIconLight = Color.fromRGBO(0, 0, 0, 0.85);
const Color tabIconDark = Color.fromRGBO(255, 255, 255, 0.80);

// Fixed Colors

const Color fixedStrokeMutedWhite = Color.fromRGBO(255, 255, 255, 0.50);
const Color strokeSolidMutedLight = Color.fromRGBO(147, 147, 147, 1);
const Color strokeSolidFaintLight = Color.fromRGBO(221, 221, 221, 1);

const Color _primary700 = Color.fromRGBO(0, 179, 60, 1);
const Color _primary500 = Color.fromRGBO(29, 185, 84, 1);
const Color _primary400 = Color.fromRGBO(38, 203, 95, 1);
const Color _primary300 = Color.fromRGBO(1, 222, 77, 1);

const Color _warning700 = Color.fromRGBO(234, 63, 63, 1);
const Color _warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color _warning400 = Color.fromRGBO(255, 111, 111, 1);
const Color _warning800 = Color(0xFFF53434);

const Color _caution500 = Color.fromRGBO(255, 194, 71, 1);

const Color _golden700 = Color(0xFFFDB816);
const Color _golden500 = Color(0xFFFFC336);

const List<Color> avatarLight = [
  Color.fromRGBO(118, 84, 154, 1),
  Color.fromRGBO(223, 120, 97, 1),
  Color.fromRGBO(148, 180, 159, 1),
  Color.fromRGBO(135, 162, 251, 1),
  Color.fromRGBO(198, 137, 198, 1),
  Color.fromRGBO(198, 137, 198, 1),
  Color.fromRGBO(50, 82, 136, 1),
  Color.fromRGBO(133, 180, 224, 1),
  Color.fromRGBO(193, 163, 163, 1),
  Color.fromRGBO(193, 163, 163, 1),
  Color.fromRGBO(66, 97, 101, 1),
  Color.fromRGBO(66, 97, 101, 1),
  Color.fromRGBO(66, 97, 101, 1),
  Color.fromRGBO(221, 157, 226, 1),
  Color.fromRGBO(130, 171, 139, 1),
  Color.fromRGBO(155, 187, 232, 1),
  Color.fromRGBO(143, 190, 190, 1),
  Color.fromRGBO(138, 195, 161, 1),
  Color.fromRGBO(168, 176, 242, 1),
  Color.fromRGBO(176, 198, 149, 1),
  Color.fromRGBO(233, 154, 173, 1),
  Color.fromRGBO(209, 132, 132, 1),
  Color.fromRGBO(120, 181, 167, 1),
];

const List<Color> avatarDark = [
  Color.fromRGBO(118, 84, 154, 1),
  Color.fromRGBO(223, 120, 97, 1),
  Color.fromRGBO(148, 180, 159, 1),
  Color.fromRGBO(135, 162, 251, 1),
  Color.fromRGBO(198, 137, 198, 1),
  Color.fromRGBO(147, 125, 194, 1),
  Color.fromRGBO(50, 82, 136, 1),
  Color.fromRGBO(133, 180, 224, 1),
  Color.fromRGBO(193, 163, 163, 1),
  Color.fromRGBO(225, 160, 89, 1),
  Color.fromRGBO(66, 97, 101, 1),
  Color.fromRGBO(107, 119, 178, 1),
  Color.fromRGBO(149, 127, 239, 1),
  Color.fromRGBO(221, 157, 226, 1),
  Color.fromRGBO(130, 171, 139, 1),
  Color.fromRGBO(155, 187, 232, 1),
  Color.fromRGBO(143, 190, 190, 1),
  Color.fromRGBO(138, 195, 161, 1),
  Color.fromRGBO(168, 176, 242, 1),
  Color.fromRGBO(176, 198, 149, 1),
  Color.fromRGBO(233, 154, 173, 1),
  Color.fromRGBO(209, 132, 132, 1),
  Color.fromRGBO(120, 181, 167, 1),
];

const EnteColorScheme blueLightScheme = EnteColorScheme(
  Color(0xFFE3F2FD),  // Very light blue background
  Color(0xFFBBDEFB),
  Color(0xFF90CAF9),
  Color(0xFF64B5F6),
  Color(0xFF42A5F5),
  Color(0xFF2196F3),
  Color(0xC81AC69C),
  Color(0xFF1565C0),  // Dark text for light theme
  Color(0xFF1976D2),
  Color(0xFF1E88E5),
  Color(0xFF1565C0),
  Color(0xFF2196F3),
  Color(0xFF1E88E5),
  Color(0xFF1976D2),
  Color(0xFF42A5F5),
  Color(0xFF90CAF9),
  Color(0xFF64B5F6),
  Color(0xFFBBDEFB),
  Color(0xFF2196F3),
  Color(0xFF42A5F5),
  Color(0xFF90CAF9),
  Color(0xFFBBDEFB),
  Color(0xFF2196F3),
  Color(0xFF42A5F5),
  Color(0xFF1E88E5),
  Color(0xFF1565C0),
  avatarLight,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFF0D47A1),  // primary700 - Darkest Blue
  Color(0xFF1565C0),  // primary500 - Dark Blue
  Color(0xFF1976D2),  // primary400 - Medium Blue
  Color(0xFF1E88E5),  // primary300 - Light Blue
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);

const EnteColorScheme blueDarkScheme = EnteColorScheme(
  Color(0xFF0D2A4A),  // Very dark blue background
  Color(0xFF0D3A67),
  Color(0xFF0D4B84),
  Color(0xFF0D47A1),
  Color(0xFF1565C0),
  Color(0xFF1976D2),
  Color(0xFFEC9292),
  Color(0xFFE3F2FD),  // Light text for dark theme
  Color(0xFFBBDEFB),
  Color(0xFF90CAF9),
  Color(0xFFE3F2FD),
  Color(0xFF2196F3),
  Color(0xFF1E88E5),
  Color(0xFF1976D2),
  Color(0xFF42A5F5),
  Color(0xFF90CAF9),
  Color(0xFF64B5F6),
  Color(0xFF0D4B84),
  Color(0xFF2196F3),
  Color(0xFF42A5F5),
  Color(0xFF90CAF9),
  Color(0xFFBBDEFB),
  Color(0xFF2196F3),
  Color(0xFF42A5F5),
  Color(0xFF1E88E5),
  Color(0xFF42A5F5),
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFF0D47A1),  // primary700 - Darkest Blue
  Color(0xFF1565C0),  // primary500 - Dark Blue
  Color(0xFF1976D2),  // primary400 - Medium Blue
  Color(0xFF1E88E5),  // primary300 - Light Blue
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);

const EnteColorScheme yellowLightScheme = EnteColorScheme(
  Color(0xFFFFFDE7),  // Very light yellow background
  Color(0xFFFFF9C4),
  Color(0xFFFFF59D),
  Color(0xFFFFEE58),
  Color(0xFFFFEB3B),
  Color(0xFFFDD835),
  Color(0xFFE6D32F),
  Color(0xFF212121),  // Dark text for light theme
  Color(0xFF424242),
  Color(0xFF616161),
  Color(0xFF212121),
  Color(0xFFFDD835),
  Color(0xFFFBC02D),
  Color(0xFFF9A825),
  Color(0xFFFFEE58),
  Color(0xFFFFF59D),
  Color(0xFFFFEE58),
  Color(0xFFFFF9C4),
  Color(0xFFFDD835),
  Color(0xFFFFEE58),
  Color(0xFFFFF59D),
  Color(0xFFFFF9C4),
  Color(0xFFFDD835),
  Color(0xFFFFEE58),
  Color(0xFFFBC02D),
  Color(0xFFFDD835),
  avatarLight,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFFF57F17),  // primary700 - Darkest Yellow
  Color(0xFFF9A825),  // primary500 - Dark Yellow
  Color(0xFFFBC02D),  // primary400 - Medium Yellow
  Color(0xFFFDD835),  // primary300 - Light Yellow
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);

const EnteColorScheme yellowDarkScheme = EnteColorScheme(
  Color(0xFF332D00),  // Very dark yellow background
  Color(0xFF403800),
  Color(0xFF4D4200),
  Color(0xFF5A4D00),
  Color(0xFF665800),
  Color(0xFF736300),
  Color(0xBD081839),
  Color(0xFFFFF9C4),  // Light text for dark theme
  Color(0xFFFFF59D),
  Color(0xFFFFEE58),
  Color(0xFFFFF9C4),
  Color(0xFFFDD835),
  Color(0xFFFBC02D),
  Color(0xFFF9A825),
  Color(0xFFFFEE58),
  Color(0xFFFFF59D),
  Color(0xFFFFEE58),
  Color(0xFF4D4200),
  Color(0xFFFDD835),
  Color(0xFFFFEE58),
  Color(0xFFFFF59D),
  Color(0xFFFFF9C4),
  Color(0xFFFDD835),
  Color(0xFFFFEE58),
  Color(0xFFFBC02D),
  Color(0xFFFFEE58),
  avatarDark,
  fixedStrokeMutedWhite,
  strokeSolidMutedLight,
  strokeSolidFaintLight,
  Color(0xFFF57F17),  // primary700 - Darkest Yellow
  Color(0xFFF9A825),  // primary500 - Dark Yellow
  Color(0xFFFBC02D),  // primary400 - Medium Yellow
  Color(0xFFFDD835),  // primary300 - Light Yellow
  Color(0xFFD32F2F),  // warning700
  Color(0xFFE53935),  // warning500
  Color(0xFFEF5350),  // warning400
  Color(0xFFC62828),  // warning800
  Color(0xFFFFB300),  // caution500
  Color(0xFFFFB300),  // golden700
  Color(0xFFFFCA28),  // golden500
);
