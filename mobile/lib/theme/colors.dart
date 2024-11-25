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

const EnteColorScheme darkScheme = EnteColorScheme(
  backgroundBaseDark,
  backgroundElevatedDark,
  backgroundElevated2Dark,
  backdropBaseDark,
  backdropMutedDark,
  backdropFaintDark,
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
  Color.fromRGBO(240, 255, 240, 1),    // backgroundBase
  Color.fromRGBO(245, 255, 245, 1),    // backgroundElevated
  Color.fromRGBO(251, 255, 251, 1),    // backgroundElevated2
  Color.fromRGBO(240, 255, 240, 0.92), // backdropBase
  Color.fromRGBO(240, 255, 240, 0.75), // backdropMuted
  Color.fromRGBO(240, 255, 240, 0.30), // backdropFaint
  Color.fromRGBO(27, 94, 32, 1),       // textBase
  Color.fromRGBO(46, 125, 50, 0.6),    // textMuted
  Color.fromRGBO(56, 142, 60, 0.5),    // textFaint
  Color.fromRGBO(67, 160, 71, 0.65),   // blurTextBase
  Color.fromRGBO(76, 175, 80, 1),      // fillBase
  Color.fromRGBO(102, 187, 106, 0.87), // fillBasePressed
  Color.fromRGBO(129, 199, 132, 0.24), // fillStrong
  Color.fromRGBO(165, 214, 167, 0.12), // fillMuted
  Color.fromRGBO(76, 175, 80, 0.3),    // fillFaint
  Color.fromRGBO(102, 187, 106, 0.08), // fillFaintPressed
  Color.fromRGBO(242, 255, 242, 1),    // fillBaseGrey
  Color.fromRGBO(27, 94, 32, 1),       // strokeBase
  Color.fromRGBO(46, 125, 50, 0.24),   // strokeMuted
  Color.fromRGBO(56, 142, 60, 0.12),   // strokeFaint
  Color.fromRGBO(67, 160, 71, 0.06),   // strokeFainter
  Color.fromRGBO(76, 175, 80, 0.65),   // blurStrokeBase
  Color.fromRGBO(102, 187, 106, 0.08), // blurStrokeFaint
  Color.fromRGBO(129, 199, 132, 0.50), // blurStrokePressed
  Color.fromRGBO(27, 94, 32, 0.85),    // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,               // fixedStrokeMutedWhite
  strokeSolidMutedLight,               // strokeSolidMuted
  strokeSolidFaintLight,               // strokeSolidFaint
  Color.fromRGBO(27, 94, 32, 1),       // primary700
  Color.fromRGBO(46, 125, 50, 1),      // primary500
  Color.fromRGBO(56, 142, 60, 1),      // primary400
  Color.fromRGBO(67, 160, 71, 1),      // primary300
  Color.fromRGBO(211, 47, 47, 1),      // warning700
  Color.fromRGBO(229, 57, 53, 1),      // warning500
  Color.fromRGBO(239, 83, 80, 1),      // warning400
  Color.fromRGBO(198, 40, 40, 1),      // warning800
  Color.fromRGBO(255, 179, 0, 1),      // caution500
  Color.fromRGBO(255, 179, 0, 1),      // golden700
  Color.fromRGBO(255, 202, 40, 1),     // golden500
);

const EnteColorScheme redDarkScheme = EnteColorScheme(
  Color.fromRGBO(31, 10, 10, 1),       // backgroundBase
  Color.fromRGBO(41, 19, 19, 1),       // backgroundElevated
  Color.fromRGBO(51, 27, 27, 1),       // backgroundElevated2
  Color.fromRGBO(31, 10, 10, 0.90),    // backdropBase
  Color.fromRGBO(41, 19, 19, 0.65),    // backdropMuted
  Color.fromRGBO(51, 27, 27, 0.20),    // backdropFaint
  Color.fromRGBO(239, 154, 154, 1),    // textBase
  Color.fromRGBO(229, 115, 115, 0.7),  // textMuted
  Color.fromRGBO(239, 83, 80, 0.5),    // textFaint
  Color.fromRGBO(239, 154, 154, 0.95), // blurTextBase
  Color.fromRGBO(211, 47, 47, 1),      // fillBase
  Color.fromRGBO(198, 40, 40, 0.9),    // fillBasePressed
  Color.fromRGBO(229, 57, 53, 0.32),   // fillStrong
  Color.fromRGBO(239, 83, 80, 0.16),   // fillMuted
  Color.fromRGBO(244, 67, 54, 0.3),    // fillFaint
  Color.fromRGBO(229, 115, 115, 0.06), // fillFaintPressed
  Color.fromRGBO(51, 27, 27, 1),       // fillBaseGrey
  Color.fromRGBO(211, 47, 47, 1),      // strokeBase
  Color.fromRGBO(198, 40, 40, 0.24),   // strokeMuted
  Color.fromRGBO(229, 57, 53, 0.16),   // strokeFaint
  Color.fromRGBO(239, 83, 80, 0.08),   // strokeFainter
  Color.fromRGBO(211, 47, 47, 0.90),   // blurStrokeBase
  Color.fromRGBO(198, 40, 40, 0.06),   // blurStrokeFaint
  Color.fromRGBO(229, 57, 53, 0.50),   // blurStrokePressed
  Color.fromRGBO(239, 154, 154, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(183, 28, 28, 1),     // primary700
  Color.fromRGBO(198, 40, 40, 1),     // primary500
  Color.fromRGBO(211, 47, 47, 1),     // primary400
  Color.fromRGBO(229, 57, 53, 1),     // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme greenDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 31, 10, 1),       // backgroundBase
  Color.fromRGBO(19, 41, 19, 1),       // backgroundElevated
  Color.fromRGBO(27, 51, 27, 1),       // backgroundElevated2
  Color.fromRGBO(10, 31, 10, 0.90),    // backdropBase
  Color.fromRGBO(19, 41, 19, 0.65),    // backdropMuted
  Color.fromRGBO(27, 51, 27, 0.20),    // backdropFaint
  Color.fromRGBO(165, 214, 167, 1),    // textBase
  Color.fromRGBO(129, 199, 132, 0.7),  // textMuted
  Color.fromRGBO(102, 187, 106, 0.5),  // textFaint
  Color.fromRGBO(165, 214, 167, 0.95), // blurTextBase
  Color.fromRGBO(46, 125, 50, 1),      // fillBase
  Color.fromRGBO(27, 94, 32, 0.9),     // fillBasePressed
  Color.fromRGBO(56, 142, 60, 0.32),   // fillStrong
  Color.fromRGBO(67, 160, 71, 0.16),   // fillMuted
  Color.fromRGBO(76, 175, 80, 0.3),    // fillFaint
  Color.fromRGBO(102, 187, 106, 0.06), // fillFaintPressed
  Color.fromRGBO(27, 51, 27, 1),       // fillBaseGrey
  Color.fromRGBO(46, 125, 50, 1),      // strokeBase
  Color.fromRGBO(56, 142, 60, 0.24),   // strokeMuted
  Color.fromRGBO(67, 160, 71, 0.16),   // strokeFaint
  Color.fromRGBO(76, 175, 80, 0.08),   // strokeFainter
  Color.fromRGBO(46, 125, 50, 0.90),   // blurStrokeBase
  Color.fromRGBO(56, 142, 60, 0.06),   // blurStrokeFaint
  Color.fromRGBO(27, 94, 32, 0.50),    // blurStrokePressed
  Color.fromRGBO(129, 199, 132, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(27, 94, 32, 1),      // primary700
  Color.fromRGBO(46, 125, 50, 1),     // primary500
  Color.fromRGBO(56, 142, 60, 1),     // primary400
  Color.fromRGBO(67, 160, 71, 1),     // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme redLightScheme = EnteColorScheme(
  Color.fromRGBO(255, 240, 240, 1),    // backgroundBase
  Color.fromRGBO(255, 245, 245, 1),    // backgroundElevated
  Color.fromRGBO(255, 251, 251, 1),    // backgroundElevated2
  Color.fromRGBO(255, 240, 240, 0.92), // backdropBase
  Color.fromRGBO(255, 240, 240, 0.75), // backdropMuted
  Color.fromRGBO(255, 240, 240, 0.30), // backdropFaint
  Color.fromRGBO(183, 28, 28, 1),      // textBase
  Color.fromRGBO(198, 40, 40, 0.6),    // textMuted
  Color.fromRGBO(211, 47, 47, 0.5),    // textFaint
  Color.fromRGBO(229, 57, 53, 0.65),   // blurTextBase
  Color.fromRGBO(239, 83, 80, 1),      // fillBase
  Color.fromRGBO(229, 115, 115, 0.87), // fillBasePressed
  Color.fromRGBO(239, 154, 154, 0.24), // fillStrong
  Color.fromRGBO(244, 67, 54, 0.12),   // fillMuted
  Color.fromRGBO(239, 83, 80, 0.3),    // fillFaint
  Color.fromRGBO(229, 115, 115, 0.08), // fillFaintPressed
  Color.fromRGBO(255, 242, 242, 1),    // fillBaseGrey
  Color.fromRGBO(183, 28, 28, 1),      // strokeBase
  Color.fromRGBO(198, 40, 40, 0.24),   // strokeMuted
  Color.fromRGBO(211, 47, 47, 0.12),   // strokeFaint
  Color.fromRGBO(229, 57, 53, 0.06),   // strokeFainter
  Color.fromRGBO(239, 83, 80, 0.65),   // blurStrokeBase
  Color.fromRGBO(229, 115, 115, 0.08), // blurStrokeFaint
  Color.fromRGBO(239, 154, 154, 0.50), // blurStrokePressed
  Color.fromRGBO(183, 28, 28, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(183, 28, 28, 1),     // primary700
  Color.fromRGBO(198, 40, 40, 1),     // primary500
  Color.fromRGBO(211, 47, 47, 1),     // primary400
  Color.fromRGBO(229, 57, 53, 1),     // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme blueLightScheme = EnteColorScheme(
  Color.fromRGBO(240, 240, 255, 1),    // backgroundBase
  Color.fromRGBO(245, 245, 255, 1),    // backgroundElevated
  Color.fromRGBO(251, 251, 255, 1),    // backgroundElevated2
  Color.fromRGBO(240, 240, 255, 0.92), // backdropBase
  Color.fromRGBO(240, 240, 255, 0.75), // backdropMuted
  Color.fromRGBO(240, 240, 255, 0.30), // backdropFaint
  Color.fromRGBO(13, 71, 161, 1),      // textBase
  Color.fromRGBO(25, 118, 210, 0.6),   // textMuted
  Color.fromRGBO(33, 150, 243, 0.5),   // textFaint
  Color.fromRGBO(66, 165, 245, 0.65),  // blurTextBase
  Color.fromRGBO(100, 181, 246, 1),    // fillBase
  Color.fromRGBO(144, 202, 249, 0.87), // fillBasePressed
  Color.fromRGBO(187, 222, 251, 0.24), // fillStrong
  Color.fromRGBO(227, 242, 253, 0.12), // fillMuted
  Color.fromRGBO(100, 181, 246, 0.3),  // fillFaint
  Color.fromRGBO(144, 202, 249, 0.08), // fillFaintPressed
  Color.fromRGBO(242, 242, 255, 1),    // fillBaseGrey
  Color.fromRGBO(13, 71, 161, 1),      // strokeBase
  Color.fromRGBO(25, 118, 210, 0.24),  // strokeMuted
  Color.fromRGBO(33, 150, 243, 0.12),  // strokeFaint
  Color.fromRGBO(66, 165, 245, 0.06),  // strokeFainter
  Color.fromRGBO(100, 181, 246, 0.65), // blurStrokeBase
  Color.fromRGBO(144, 202, 249, 0.08), // blurStrokeFaint
  Color.fromRGBO(187, 222, 251, 0.50), // blurStrokePressed
  Color.fromRGBO(13, 71, 161, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(13, 71, 161, 1),     // primary700
  Color.fromRGBO(25, 118, 210, 1),    // primary500
  Color.fromRGBO(33, 150, 243, 1),    // primary400
  Color.fromRGBO(66, 165, 245, 1),    // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme blueDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 10, 31, 1),       // backgroundBase
  Color.fromRGBO(19, 19, 41, 1),       // backgroundElevated
  Color.fromRGBO(27, 27, 51, 1),       // backgroundElevated2
  Color.fromRGBO(10, 10, 31, 0.90),    // backdropBase
  Color.fromRGBO(19, 19, 41, 0.65),    // backdropMuted
  Color.fromRGBO(27, 27, 51, 0.20),    // backdropFaint
  Color.fromRGBO(144, 202, 249, 1),    // textBase
  Color.fromRGBO(100, 181, 246, 0.7),  // textMuted
  Color.fromRGBO(66, 165, 245, 0.5),   // textFaint
  Color.fromRGBO(144, 202, 249, 0.95), // blurTextBase
  Color.fromRGBO(25, 118, 210, 1),     // fillBase
  Color.fromRGBO(13, 71, 161, 0.9),    // fillBasePressed
  Color.fromRGBO(33, 150, 243, 0.32),  // fillStrong
  Color.fromRGBO(66, 165, 245, 0.16),  // fillMuted
  Color.fromRGBO(100, 181, 246, 0.3),  // fillFaint
  Color.fromRGBO(144, 202, 249, 0.06), // fillFaintPressed
  Color.fromRGBO(27, 27, 51, 1),       // fillBaseGrey
  Color.fromRGBO(25, 118, 210, 1),     // strokeBase
  Color.fromRGBO(33, 150, 243, 0.24),  // strokeMuted
  Color.fromRGBO(66, 165, 245, 0.16),  // strokeFaint
  Color.fromRGBO(100, 181, 246, 0.08), // strokeFainter
  Color.fromRGBO(25, 118, 210, 0.90),  // blurStrokeBase
  Color.fromRGBO(33, 150, 243, 0.06),  // blurStrokeFaint
  Color.fromRGBO(13, 71, 161, 0.50),   // blurStrokePressed
  Color.fromRGBO(144, 202, 249, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(13, 71, 161, 1),     // primary700
  Color.fromRGBO(25, 118, 210, 1),    // primary500
  Color.fromRGBO(33, 150, 243, 1),    // primary400
  Color.fromRGBO(66, 165, 245, 1),    // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme yellowLightScheme = EnteColorScheme(
  Color.fromRGBO(255, 255, 240, 1),    // backgroundBase
  Color.fromRGBO(255, 255, 245, 1),    // backgroundElevated
  Color.fromRGBO(255, 255, 251, 1),    // backgroundElevated2
  Color.fromRGBO(255, 255, 240, 0.92), // backdropBase
  Color.fromRGBO(255, 255, 240, 0.75), // backdropMuted
  Color.fromRGBO(255, 255, 240, 0.30), // backdropFaint
  Color.fromRGBO(245, 127, 23, 1),     // textBase
  Color.fromRGBO(251, 140, 0, 0.6),    // textMuted
  Color.fromRGBO(255, 152, 0, 0.5),    // textFaint
  Color.fromRGBO(255, 167, 38, 0.65),  // blurTextBase
  Color.fromRGBO(255, 179, 0, 1),      // fillBase
  Color.fromRGBO(255, 183, 77, 0.87),  // fillBasePressed
  Color.fromRGBO(255, 204, 128, 0.24), // fillStrong
  Color.fromRGBO(255, 224, 178, 0.12), // fillMuted
  Color.fromRGBO(255, 179, 0, 0.3),    // fillFaint
  Color.fromRGBO(255, 183, 77, 0.08),  // fillFaintPressed
  Color.fromRGBO(255, 255, 242, 1),    // fillBaseGrey
  Color.fromRGBO(245, 127, 23, 1),     // strokeBase
  Color.fromRGBO(251, 140, 0, 0.24),   // strokeMuted
  Color.fromRGBO(255, 152, 0, 0.12),   // strokeFaint
  Color.fromRGBO(255, 167, 38, 0.06),  // strokeFainter
  Color.fromRGBO(255, 179, 0, 0.65),   // blurStrokeBase
  Color.fromRGBO(255, 183, 77, 0.08),  // blurStrokeFaint
  Color.fromRGBO(255, 204, 128, 0.50), // blurStrokePressed
  Color.fromRGBO(245, 127, 23, 0.85),  // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(245, 127, 23, 1),    // primary700
  Color.fromRGBO(251, 140, 0, 1),     // primary500
  Color.fromRGBO(255, 152, 0, 1),     // primary400
  Color.fromRGBO(255, 167, 38, 1),    // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme yellowDarkScheme = EnteColorScheme(
  Color.fromRGBO(31, 31, 10, 1),       // backgroundBase
  Color.fromRGBO(41, 41, 19, 1),       // backgroundElevated
  Color.fromRGBO(51, 51, 27, 1),       // backgroundElevated2
  Color.fromRGBO(31, 31, 10, 0.90),    // backdropBase
  Color.fromRGBO(41, 41, 19, 0.65),    // backdropMuted
  Color.fromRGBO(51, 51, 27, 0.20),    // backdropFaint
  Color.fromRGBO(255, 224, 178, 1),    // textBase
  Color.fromRGBO(255, 204, 128, 0.7),  // textMuted
  Color.fromRGBO(255, 183, 77, 0.5),   // textFaint
  Color.fromRGBO(255, 224, 178, 0.95), // blurTextBase
  Color.fromRGBO(251, 140, 0, 1),      // fillBase
  Color.fromRGBO(245, 127, 23, 0.9),   // fillBasePressed
  Color.fromRGBO(255, 152, 0, 0.32),   // fillStrong
  Color.fromRGBO(255, 167, 38, 0.16),  // fillMuted
  Color.fromRGBO(255, 179, 0, 0.3),    // fillFaint
  Color.fromRGBO(255, 183, 77, 0.06),  // fillFaintPressed
  Color.fromRGBO(51, 51, 27, 1),       // fillBaseGrey
  Color.fromRGBO(251, 140, 0, 1),      // strokeBase
  Color.fromRGBO(255, 152, 0, 0.24),   // strokeMuted
  Color.fromRGBO(255, 167, 38, 0.16),  // strokeFaint
  Color.fromRGBO(255, 179, 0, 0.08),   // strokeFainter
  Color.fromRGBO(251, 140, 0, 0.90),   // blurStrokeBase
  Color.fromRGBO(255, 152, 0, 0.06),   // blurStrokeFaint
  Color.fromRGBO(245, 127, 23, 0.50),  // blurStrokePressed
  Color.fromRGBO(255, 224, 178, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(245, 127, 23, 1),    // primary700
  Color.fromRGBO(251, 140, 0, 1),     // primary500
  Color.fromRGBO(255, 152, 0, 1),     // primary400
  Color.fromRGBO(255, 167, 38, 1),    // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
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


const Color _primary700 = Color.fromRGBO(27, 94, 32, 1);
const Color _primary500 = Color.fromRGBO(56, 142, 60, 1);
const Color _primary400 = Color.fromRGBO(67, 160, 71, 1);
const Color _primary300 = Color.fromRGBO(102, 187, 106, 1);

const Color _warning700 = Color.fromRGBO(234, 63, 63, 1);
const Color _warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color _warning400 = Color.fromRGBO(255, 111, 111, 1);
const Color _warning800 = Color.fromRGBO(245, 52, 52, 1);

const Color _caution500 = Color.fromRGBO(255, 194, 71, 1);

const Color _golden700 = Color.fromRGBO(253, 184, 22, 1);
const Color _golden500 = Color.fromRGBO(255, 195, 54, 1);

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