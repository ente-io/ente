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
  strokeSolidMutedLight,            // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
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
  strokeSolidMutedLight,            // strokeSolidMuted
  strokeSolidFaintLight,          // strokeSolidFaint
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
  strokeSolidMutedLight,            // strokeSolidMuted
  strokeSolidFaintLight,          // strokeSolidFaint
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
  Color.fromRGBO(255, 245, 242, 1),    // fillBaseGrey
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
  Color.fromRGBO(239, 108, 0, 1),      // fillBase
  Color.fromRGBO(230, 81, 0, 0.9),     // fillBasePressed
  Color.fromRGBO(245, 124, 0, 0.32),   // fillStrong
  Color.fromRGBO(251, 140, 0, 0.16),   // fillMuted
  Color.fromRGBO(255, 152, 0, 0.3),    // fillFaint
  Color.fromRGBO(255, 167, 38, 0.06),  // fillFaintPressed
  Color.fromRGBO(51, 51, 27, 1),       // fillBaseGrey
  Color.fromRGBO(239, 108, 0, 1),      // strokeBase
  Color.fromRGBO(245, 124, 0, 0.24),   // strokeMuted
  Color.fromRGBO(251, 140, 0, 0.16),   // strokeFaint
  Color.fromRGBO(255, 152, 0, 0.08),   // strokeFainter
  Color.fromRGBO(239, 108, 0, 0.90),   // blurStrokeBase
  Color.fromRGBO(245, 124, 0, 0.06),   // blurStrokeFaint
  Color.fromRGBO(230, 81, 0, 0.50),    // blurStrokePressed
  Color.fromRGBO(255, 224, 178, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(230, 81, 0, 1),      // primary700
  Color.fromRGBO(239, 108, 0, 1),     // primary500
  Color.fromRGBO(245, 124, 0, 1),     // primary400
  Color.fromRGBO(251, 140, 0, 1),     // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme purpleLightScheme = EnteColorScheme(
  Color.fromRGBO(250, 240, 255, 1),    // backgroundBase
  Color.fromRGBO(252, 245, 255, 1),    // backgroundElevated
  Color.fromRGBO(253, 251, 255, 1),    // backgroundElevated2
  Color.fromRGBO(250, 240, 255, 0.92), // backdropBase
  Color.fromRGBO(250, 240, 255, 0.75), // backdropMuted
  Color.fromRGBO(250, 240, 255, 0.30), // backdropFaint
  Color.fromRGBO(106, 27, 154, 1),     // textBase
  Color.fromRGBO(123, 31, 162, 0.6),   // textMuted
  Color.fromRGBO(142, 36, 170, 0.5),   // textFaint
  Color.fromRGBO(156, 39, 176, 0.65),  // blurTextBase
  Color.fromRGBO(171, 71, 188, 1),     // fillBase
  Color.fromRGBO(186, 104, 200, 0.87), // fillBasePressed
  Color.fromRGBO(206, 147, 216, 0.24), // fillStrong
  Color.fromRGBO(225, 190, 231, 0.12), // fillMuted
  Color.fromRGBO(171, 71, 188, 0.3),   // fillFaint
  Color.fromRGBO(186, 104, 200, 0.08), // fillFaintPressed
  Color.fromRGBO(252, 242, 255, 1),    // fillBaseGrey
  Color.fromRGBO(106, 27, 154, 1),     // strokeBase
  Color.fromRGBO(123, 31, 162, 0.24),  // strokeMuted
  Color.fromRGBO(142, 36, 170, 0.12),  // strokeFaint
  Color.fromRGBO(156, 39, 176, 0.06),  // strokeFainter
  Color.fromRGBO(171, 71, 188, 0.65),  // blurStrokeBase
  Color.fromRGBO(186, 104, 200, 0.08), // blurStrokeFaint
  Color.fromRGBO(206, 147, 216, 0.50), // blurStrokePressed
  Color.fromRGBO(106, 27, 154, 0.85),  // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(106, 27, 154, 1),    // primary700 - Deep Purple
  Color.fromRGBO(123, 31, 162, 1),    // primary500 - Purple
  Color.fromRGBO(142, 36, 170, 1),    // primary400 - Light Purple
  Color.fromRGBO(156, 39, 176, 1),    // primary300 - Lighter Purple
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme purpleDarkScheme = EnteColorScheme(
  Color.fromRGBO(31, 10, 31, 1),       // backgroundBase
  Color.fromRGBO(41, 19, 41, 1),       // backgroundElevated
  Color.fromRGBO(51, 27, 51, 1),       // backgroundElevated2
  Color.fromRGBO(31, 10, 31, 0.90),    // backdropBase
  Color.fromRGBO(41, 19, 41, 0.65),    // backdropMuted
  Color.fromRGBO(51, 27, 51, 0.20),    // backdropFaint
  Color.fromRGBO(206, 147, 216, 1),    // textBase
  Color.fromRGBO(186, 104, 200, 0.7),  // textMuted
  Color.fromRGBO(171, 71, 188, 0.5),   // textFaint
  Color.fromRGBO(206, 147, 216, 0.95), // blurTextBase
  Color.fromRGBO(123, 31, 162, 1),     // fillBase
  Color.fromRGBO(106, 27, 154, 0.9),   // fillBasePressed
  Color.fromRGBO(142, 36, 170, 0.32),  // fillStrong
  Color.fromRGBO(156, 39, 176, 0.16),  // fillMuted
  Color.fromRGBO(171, 71, 188, 0.3),   // fillFaint
  Color.fromRGBO(186, 104, 200, 0.06), // fillFaintPressed
  Color.fromRGBO(51, 27, 51, 1),       // fillBaseGrey
  Color.fromRGBO(123, 31, 162, 1),     // strokeBase
  Color.fromRGBO(142, 36, 170, 0.24),  // strokeMuted
  Color.fromRGBO(156, 39, 176, 0.16),  // strokeFaint
  Color.fromRGBO(171, 71, 188, 0.08),  // strokeFainter
  Color.fromRGBO(123, 31, 162, 0.90),  // blurStrokeBase
  Color.fromRGBO(142, 36, 170, 0.06),  // blurStrokeFaint
  Color.fromRGBO(106, 27, 154, 0.50),  // blurStrokePressed
  Color.fromRGBO(206, 147, 216, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(106, 27, 154, 1),    // primary700 - Deep Purple
  Color.fromRGBO(123, 31, 162, 1),    // primary500 - Purple
  Color.fromRGBO(142, 36, 170, 1),    // primary400 - Light Purple
  Color.fromRGBO(156, 39, 176, 1),    // primary300 - Lighter Purple
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme orangeLightScheme = EnteColorScheme(
  Color.fromRGBO(255, 243, 240, 1),    // backgroundBase
  Color.fromRGBO(255, 246, 245, 1),    // backgroundElevated
  Color.fromRGBO(255, 251, 251, 1),    // backgroundElevated2
  Color.fromRGBO(255, 243, 240, 0.92), // backdropBase
  Color.fromRGBO(255, 243, 240, 0.75), // backdropMuted
  Color.fromRGBO(255, 243, 240, 0.30), // backdropFaint
  Color.fromRGBO(230, 81, 0, 1),       // textBase
  Color.fromRGBO(239, 108, 0, 0.6),    // textMuted
  Color.fromRGBO(245, 124, 0, 0.5),    // textFaint
  Color.fromRGBO(251, 140, 0, 0.65),   // blurTextBase
  Color.fromRGBO(255, 152, 0, 1),      // fillBase
  Color.fromRGBO(255, 167, 38, 0.87),  // fillBasePressed
  Color.fromRGBO(255, 183, 77, 0.24),  // fillStrong
  Color.fromRGBO(255, 204, 128, 0.12), // fillMuted
  Color.fromRGBO(255, 152, 0, 0.3),    // fillFaint
  Color.fromRGBO(255, 167, 38, 0.08),  // fillFaintPressed
  Color.fromRGBO(255, 245, 242, 1),    // fillBaseGrey
  Color.fromRGBO(230, 81, 0, 1),       // strokeBase
  Color.fromRGBO(239, 108, 0, 0.24),   // strokeMuted
  Color.fromRGBO(245, 124, 0, 0.12),   // strokeFaint
  Color.fromRGBO(251, 140, 0, 0.06),   // strokeFainter
  Color.fromRGBO(255, 152, 0, 0.65),   // blurStrokeBase
  Color.fromRGBO(255, 167, 38, 0.08),  // blurStrokeFaint
  Color.fromRGBO(255, 183, 77, 0.50), // blurStrokePressed
  Color.fromRGBO(230, 81, 0, 0.85),    // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(230, 81, 0, 1),      // primary700 - Deep Orange
  Color.fromRGBO(239, 108, 0, 1),     // primary500 - Orange
  Color.fromRGBO(245, 124, 0, 1),     // primary400 - Light Orange
  Color.fromRGBO(251, 140, 0, 1),     // primary300 - Lighter Orange
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme orangeDarkScheme = EnteColorScheme(
  Color.fromRGBO(31, 15, 10, 1),       // backgroundBase
  Color.fromRGBO(41, 21, 19, 1),       // backgroundElevated
  Color.fromRGBO(51, 27, 27, 1),       // backgroundElevated2
  Color.fromRGBO(31, 15, 10, 0.90),    // backdropBase
  Color.fromRGBO(41, 21, 19, 0.65),    // backdropMuted
  Color.fromRGBO(51, 27, 27, 0.20),    // backdropFaint
  Color.fromRGBO(255, 204, 128, 1),    // textBase
  Color.fromRGBO(255, 183, 77, 0.7),   // textMuted
  Color.fromRGBO(255, 167, 38, 0.5),   // textFaint
  Color.fromRGBO(255, 204, 128, 0.95), // blurTextBase
  Color.fromRGBO(239, 108, 0, 1),      // fillBase
  Color.fromRGBO(230, 81, 0, 0.9),     // fillBasePressed
  Color.fromRGBO(245, 124, 0, 0.32),   // fillStrong
  Color.fromRGBO(251, 140, 0, 0.16),   // fillMuted
  Color.fromRGBO(255, 152, 0, 0.3),    // fillFaint
  Color.fromRGBO(255, 167, 38, 0.06),  // fillFaintPressed
  Color.fromRGBO(51, 51, 27, 1),       // fillBaseGrey
  Color.fromRGBO(239, 108, 0, 1),      // strokeBase
  Color.fromRGBO(245, 124, 0, 0.24),   // strokeMuted
  Color.fromRGBO(251, 140, 0, 0.16),   // strokeFaint
  Color.fromRGBO(255, 152, 0, 0.08),   // strokeFainter
  Color.fromRGBO(239, 108, 0, 0.90),   // blurStrokeBase
  Color.fromRGBO(245, 124, 0, 0.06),   // blurStrokeFaint
  Color.fromRGBO(230, 81, 0, 0.50),    // blurStrokePressed
  Color.fromRGBO(255, 204, 128, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(230, 81, 0, 1),      // primary700
  Color.fromRGBO(239, 108, 0, 1),     // primary500
  Color.fromRGBO(245, 124, 0, 1),     // primary400
  Color.fromRGBO(251, 140, 0, 1),     // primary300
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme tealLightScheme = EnteColorScheme(
  Color.fromRGBO(240, 255, 250, 1),    // backgroundBase - Soft mint white
  Color.fromRGBO(245, 255, 252, 1),    // backgroundElevated
  Color.fromRGBO(251, 255, 253, 1),    // backgroundElevated2
  Color.fromRGBO(240, 255, 250, 0.92), // backdropBase
  Color.fromRGBO(240, 255, 250, 0.75), // backdropMuted
  Color.fromRGBO(240, 255, 250, 0.30), // backdropFaint
  Color.fromRGBO(0, 121, 107, 1),      // textBase - Deep teal
  Color.fromRGBO(0, 137, 123, 0.6),    // textMuted
  Color.fromRGBO(0, 150, 136, 0.5),    // textFaint
  Color.fromRGBO(38, 166, 154, 0.65),  // blurTextBase
  Color.fromRGBO(77, 182, 172, 1),     // fillBase
  Color.fromRGBO(128, 203, 196, 0.87), // fillBasePressed
  Color.fromRGBO(178, 223, 219, 0.24), // fillStrong
  Color.fromRGBO(224, 242, 241, 0.12), // fillMuted
  Color.fromRGBO(77, 182, 172, 0.3),   // fillFaint
  Color.fromRGBO(128, 203, 196, 0.08), // fillFaintPressed
  Color.fromRGBO(242, 255, 252, 1),    // fillBaseGrey
  Color.fromRGBO(0, 121, 107, 1),      // strokeBase
  Color.fromRGBO(0, 137, 123, 0.24),   // strokeMuted
  Color.fromRGBO(0, 150, 136, 0.12),   // strokeFaint
  Color.fromRGBO(38, 166, 154, 0.06),  // strokeFainter
  Color.fromRGBO(77, 182, 172, 0.65),  // blurStrokeBase
  Color.fromRGBO(128, 203, 196, 0.08), // blurStrokeFaint
  Color.fromRGBO(178, 223, 219, 0.50), // blurStrokePressed
  Color.fromRGBO(0, 121, 107, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 121, 107, 1),     // primary700 - Deep Teal
  Color.fromRGBO(0, 137, 123, 1),     // primary500 - Teal
  Color.fromRGBO(0, 150, 136, 1),     // primary400 - Light Teal
  Color.fromRGBO(38, 166, 154, 1),    // primary300 - Lighter Teal
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme tealDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 31, 27, 1),       // backgroundBase - Deep teal black
  Color.fromRGBO(19, 41, 37, 1),       // backgroundElevated
  Color.fromRGBO(27, 51, 47, 1),       // backgroundElevated2
  Color.fromRGBO(10, 31, 27, 0.90),    // backdropBase
  Color.fromRGBO(19, 41, 37, 0.65),    // backdropMuted
  Color.fromRGBO(27, 51, 47, 0.20),    // backdropFaint
  Color.fromRGBO(178, 223, 219, 1),    // textBase - Light mint
  Color.fromRGBO(128, 203, 196, 0.7),  // textMuted
  Color.fromRGBO(77, 182, 172, 0.5),   // textFaint
  Color.fromRGBO(178, 223, 219, 0.95), // blurTextBase
  Color.fromRGBO(0, 137, 123, 1),      // fillBase
  Color.fromRGBO(0, 121, 107, 0.9),    // fillBasePressed
  Color.fromRGBO(0, 150, 136, 0.32),   // fillStrong
  Color.fromRGBO(38, 166, 154, 0.16),  // fillMuted
  Color.fromRGBO(77, 182, 172, 0.3),   // fillFaint
  Color.fromRGBO(128, 203, 196, 0.06), // fillFaintPressed
  Color.fromRGBO(27, 27, 51, 1),       // fillBaseGrey
  Color.fromRGBO(0, 137, 123, 1),      // strokeBase
  Color.fromRGBO(0, 150, 136, 0.24),   // strokeMuted
  Color.fromRGBO(38, 166, 154, 0.16),  // strokeFaint
  Color.fromRGBO(77, 182, 172, 0.08),  // strokeFainter
  Color.fromRGBO(0, 137, 123, 0.90),   // blurStrokeBase
  Color.fromRGBO(0, 150, 136, 0.06),   // blurStrokeFaint
  Color.fromRGBO(0, 121, 107, 0.50),   // blurStrokePressed
  Color.fromRGBO(178, 223, 219, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 121, 107, 1),     // primary700 - Deep Teal
  Color.fromRGBO(0, 137, 123, 1),     // primary500 - Teal
  Color.fromRGBO(0, 150, 136, 1),     // primary400 - Light Teal
  Color.fromRGBO(38, 166, 154, 1),    // primary300 - Lighter Teal
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

const EnteColorScheme roseLightScheme = EnteColorScheme(
  Color.fromRGBO(255, 240, 245, 1),    // backgroundBase - Soft rose white
  Color.fromRGBO(255, 245, 248, 1),    // backgroundElevated
  Color.fromRGBO(255, 251, 252, 1),    // backgroundElevated2
  Color.fromRGBO(255, 240, 245, 0.92), // backdropBase
  Color.fromRGBO(255, 240, 245, 0.75), // backdropMuted
  Color.fromRGBO(255, 240, 245, 0.30), // backdropFaint
  Color.fromRGBO(173, 20, 87, 1),      // textBase - Deep pink
  Color.fromRGBO(186, 104, 200, 0.6),  // textMuted
  Color.fromRGBO(216, 27, 96, 0.5),    // textFaint
  Color.fromRGBO(236, 64, 122, 0.65),  // blurTextBase
  Color.fromRGBO(240, 98, 146, 1),     // fillBase
  Color.fromRGBO(244, 143, 177, 0.87), // fillBasePressed
  Color.fromRGBO(248, 187, 208, 0.24), // fillStrong
  Color.fromRGBO(252, 228, 236, 0.12), // fillMuted
  Color.fromRGBO(240, 98, 146, 0.3),   // fillFaint
  Color.fromRGBO(244, 143, 177, 0.08), // fillFaintPressed
  Color.fromRGBO(253, 242, 248, 1),    // fillBaseGrey
  Color.fromRGBO(173, 20, 87, 1),      // strokeBase
  Color.fromRGBO(194, 24, 91, 0.24),   // strokeMuted
  Color.fromRGBO(216, 27, 96, 0.12),   // strokeFaint
  Color.fromRGBO(236, 64, 122, 0.06),  // strokeFainter
  Color.fromRGBO(240, 98, 146, 0.65),  // blurStrokeBase
  Color.fromRGBO(244, 143, 177, 0.08), // blurStrokeFaint
  Color.fromRGBO(248, 187, 208, 0.50), // blurStrokePressed
  Color.fromRGBO(173, 20, 87, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(173, 20, 87, 1),     // primary700 - Deep Rose
  Color.fromRGBO(194, 24, 91, 1),     // primary500 - Rose
  Color.fromRGBO(216, 27, 96, 1),     // primary400 - Light Rose
  Color.fromRGBO(236, 64, 122, 1),    // primary300 - Lighter Rose
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme roseDarkScheme = EnteColorScheme(
  Color.fromRGBO(31, 10, 20, 1),       // backgroundBase - Deep rose black
  Color.fromRGBO(41, 19, 29, 1),       // backgroundElevated
  Color.fromRGBO(51, 27, 37, 1),       // backgroundElevated2
  Color.fromRGBO(31, 10, 20, 0.90),    // backdropBase
  Color.fromRGBO(41, 19, 29, 0.65),    // backdropMuted
  Color.fromRGBO(51, 27, 37, 0.20),    // backdropFaint
  Color.fromRGBO(248, 187, 208, 1),    // textBase - Light rose
  Color.fromRGBO(244, 143, 177, 0.7),  // textMuted
  Color.fromRGBO(240, 98, 146, 0.5),   // textFaint
  Color.fromRGBO(248, 187, 208, 0.95), // blurTextBase
  Color.fromRGBO(194, 24, 91, 1),      // fillBase
  Color.fromRGBO(173, 20, 87, 0.9),    // fillBasePressed
  Color.fromRGBO(216, 27, 96, 0.32),   // fillStrong
  Color.fromRGBO(236, 64, 122, 0.16),  // fillMuted
  Color.fromRGBO(240, 98, 146, 0.3),   // fillFaint
  Color.fromRGBO(244, 143, 177, 0.06), // fillFaintPressed
  Color.fromRGBO(51, 27, 37, 1),       // fillBaseGrey
  Color.fromRGBO(194, 24, 91, 1),      // strokeBase
  Color.fromRGBO(216, 27, 96, 0.24),   // strokeMuted
  Color.fromRGBO(236, 64, 122, 0.16),  // strokeFaint
  Color.fromRGBO(240, 98, 146, 0.08),  // strokeFainter
  Color.fromRGBO(194, 24, 91, 0.90),   // blurStrokeBase
  Color.fromRGBO(216, 27, 96, 0.06),   // blurStrokeFaint
  Color.fromRGBO(173, 20, 87, 0.50),   // blurStrokePressed
  Color.fromRGBO(248, 187, 208, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(173, 20, 87, 1),     // primary700 - Deep Rose
  Color.fromRGBO(194, 24, 91, 1),     // primary500 - Rose
  Color.fromRGBO(216, 27, 96, 1),     // primary400 - Light Rose
  Color.fromRGBO(236, 64, 122, 1),    // primary300 - Lighter Rose
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme indigoLightScheme = EnteColorScheme(
  Color.fromRGBO(240, 240, 255, 1),    // backgroundBase - Soft indigo white
  Color.fromRGBO(245, 245, 255, 1),    // backgroundElevated
  Color.fromRGBO(251, 251, 255, 1),    // backgroundElevated2
  Color.fromRGBO(240, 240, 255, 0.92), // backdropBase
  Color.fromRGBO(240, 240, 255, 0.75), // backdropMuted
  Color.fromRGBO(240, 240, 255, 0.30), // backdropFaint
  Color.fromRGBO(40, 53, 147, 1),      // textBase - Deep indigo
  Color.fromRGBO(48, 63, 159, 0.6),    // textMuted
  Color.fromRGBO(57, 73, 171, 0.5),    // textFaint
  Color.fromRGBO(63, 81, 181, 0.65),   // blurTextBase
  Color.fromRGBO(92, 107, 192, 1),     // fillBase
  Color.fromRGBO(121, 134, 203, 0.87), // fillBasePressed
  Color.fromRGBO(159, 168, 218, 0.24), // fillStrong
  Color.fromRGBO(197, 202, 233, 0.12), // fillMuted
  Color.fromRGBO(92, 107, 192, 0.3),   // fillFaint
  Color.fromRGBO(121, 134, 203, 0.08), // fillFaintPressed
  Color.fromRGBO(242, 242, 255, 1),    // fillBaseGrey
  Color.fromRGBO(40, 53, 147, 1),      // strokeBase
  Color.fromRGBO(48, 63, 159, 0.24),   // strokeMuted
  Color.fromRGBO(57, 73, 171, 0.12),   // strokeFaint
  Color.fromRGBO(63, 81, 181, 0.06),   // strokeFainter
  Color.fromRGBO(92, 107, 192, 0.65),  // blurStrokeBase
  Color.fromRGBO(121, 134, 203, 0.08), // blurStrokeFaint
  Color.fromRGBO(159, 168, 218, 0.50), // blurStrokePressed
  Color.fromRGBO(40, 53, 147, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(40, 53, 147, 1),     // primary700 - Deep Indigo
  Color.fromRGBO(48, 63, 159, 1),     // primary500 - Indigo
  Color.fromRGBO(57, 73, 171, 1),     // primary400 - Light Indigo
  Color.fromRGBO(63, 81, 181, 1),     // primary300 - Lighter Indigo
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme indigoDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 10, 31, 1),       // backgroundBase - Deep indigo black
  Color.fromRGBO(19, 19, 41, 1),       // backgroundElevated
  Color.fromRGBO(27, 27, 51, 1),       // backgroundElevated2
  Color.fromRGBO(10, 10, 31, 0.90),    // backdropBase
  Color.fromRGBO(19, 19, 41, 0.65),    // backdropMuted
  Color.fromRGBO(27, 27, 51, 0.20),    // backdropFaint
  Color.fromRGBO(159, 168, 218, 1),    // textBase - Light indigo
  Color.fromRGBO(121, 134, 203, 0.7),  // textMuted
  Color.fromRGBO(92, 107, 192, 0.5),   // textFaint
  Color.fromRGBO(159, 168, 218, 0.95), // blurTextBase
  Color.fromRGBO(48, 63, 159, 1),      // fillBase
  Color.fromRGBO(40, 53, 147, 0.9),    // fillBasePressed
  Color.fromRGBO(57, 73, 171, 0.32),   // fillStrong
  Color.fromRGBO(63, 81, 181, 0.16),   // fillMuted
  Color.fromRGBO(92, 107, 192, 0.3),   // fillFaint
  Color.fromRGBO(121, 134, 203, 0.06), // fillFaintPressed
  Color.fromRGBO(27, 27, 51, 1),       // fillBaseGrey
  Color.fromRGBO(48, 63, 159, 1),      // strokeBase
  Color.fromRGBO(57, 73, 171, 0.24),   // strokeMuted
  Color.fromRGBO(63, 81, 181, 0.16),   // strokeFaint
  Color.fromRGBO(92, 107, 192, 0.08),  // strokeFainter
  Color.fromRGBO(48, 63, 159, 0.90),   // blurStrokeBase
  Color.fromRGBO(57, 73, 171, 0.06),   // blurStrokeFaint
  Color.fromRGBO(40, 53, 147, 0.50),   // blurStrokePressed
  Color.fromRGBO(159, 168, 218, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(40, 53, 147, 1),     // primary700 - Deep Indigo
  Color.fromRGBO(48, 63, 159, 1),     // primary500 - Indigo
  Color.fromRGBO(57, 73, 171, 1),     // primary400 - Light Indigo
  Color.fromRGBO(63, 81, 181, 1),     // primary300 - Lighter Indigo
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme mochaLightScheme = EnteColorScheme(
  Color.fromRGBO(251, 245, 240, 1),    // backgroundBase - Warm latte
  Color.fromRGBO(253, 248, 245, 1),    // backgroundElevated
  Color.fromRGBO(255, 251, 248, 1),    // backgroundElevated2
  Color.fromRGBO(251, 245, 240, 0.92), // backdropBase
  Color.fromRGBO(251, 245, 240, 0.75), // backdropMuted
  Color.fromRGBO(251, 245, 240, 0.30), // backdropFaint
  Color.fromRGBO(93, 64, 55, 1),       // textBase - Deep mocha
  Color.fromRGBO(109, 76, 65, 0.6),    // textMuted
  Color.fromRGBO(121, 85, 72, 0.5),    // textFaint
  Color.fromRGBO(141, 110, 99, 0.65),  // blurTextBase
  Color.fromRGBO(161, 136, 127, 1),    // fillBase
  Color.fromRGBO(188, 170, 164, 0.87), // fillBasePressed
  Color.fromRGBO(215, 204, 200, 0.24), // fillStrong
  Color.fromRGBO(239, 235, 233, 0.12), // fillMuted
  Color.fromRGBO(161, 136, 127, 0.3),  // fillFaint
  Color.fromRGBO(188, 170, 164, 0.08), // fillFaintPressed
  Color.fromRGBO(252, 247, 243, 1),    // fillBaseGrey
  Color.fromRGBO(93, 64, 55, 1),       // strokeBase
  Color.fromRGBO(109, 76, 65, 0.24),   // strokeMuted
  Color.fromRGBO(121, 85, 72, 0.12),   // strokeFaint
  Color.fromRGBO(141, 110, 99, 0.06),  // strokeFainter
  Color.fromRGBO(161, 136, 127, 0.65), // blurStrokeBase
  Color.fromRGBO(188, 170, 164, 0.08), // blurStrokeFaint
  Color.fromRGBO(215, 204, 200, 0.50), // blurStrokePressed
  Color.fromRGBO(93, 64, 55, 0.85),    // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(93, 64, 55, 1),      // primary700 - Deep Mocha
  Color.fromRGBO(109, 76, 65, 1),     // primary500 - Mocha
  Color.fromRGBO(121, 85, 72, 1),     // primary400 - Light Mocha
  Color.fromRGBO(141, 110, 99, 1),    // primary300 - Lighter Mocha
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme mochaDarkScheme = EnteColorScheme(
  Color.fromRGBO(20, 15, 10, 1),       // backgroundBase - Deep espresso
  Color.fromRGBO(29, 21, 19, 1),       // backgroundElevated
  Color.fromRGBO(37, 27, 27, 1),       // backgroundElevated2
  Color.fromRGBO(20, 15, 10, 0.90),    // backdropBase
  Color.fromRGBO(29, 21, 19, 0.65),    // backdropMuted
  Color.fromRGBO(37, 27, 27, 0.20),    // backdropFaint
  Color.fromRGBO(215, 204, 200, 1),    // textBase - Light mocha
  Color.fromRGBO(188, 170, 164, 0.7),  // textMuted
  Color.fromRGBO(161, 136, 127, 0.5),  // textFaint
  Color.fromRGBO(215, 204, 200, 0.95), // blurTextBase
  Color.fromRGBO(109, 76, 65, 1),      // fillBase
  Color.fromRGBO(93, 64, 55, 0.9),     // fillBasePressed
  Color.fromRGBO(121, 85, 72, 0.32),   // fillStrong
  Color.fromRGBO(141, 110, 99, 0.16),  // fillMuted
  Color.fromRGBO(161, 136, 127, 0.3),  // fillFaint
  Color.fromRGBO(188, 170, 164, 0.06), // fillFaintPressed
  Color.fromRGBO(37, 27, 27, 1),       // fillBaseGrey
  Color.fromRGBO(109, 76, 65, 1),      // strokeBase
  Color.fromRGBO(121, 85, 72, 0.24),   // strokeMuted
  Color.fromRGBO(141, 110, 99, 0.16),  // strokeFaint
  Color.fromRGBO(161, 136, 127, 0.08), // strokeFainter
  Color.fromRGBO(109, 76, 65, 0.90),   // blurStrokeBase
  Color.fromRGBO(121, 85, 72, 0.06),   // blurStrokeFaint
  Color.fromRGBO(93, 64, 55, 0.50),    // blurStrokePressed
  Color.fromRGBO(215, 204, 200, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(93, 64, 55, 1),      // primary700 - Deep Mocha
  Color.fromRGBO(109, 76, 65, 1),     // primary500 - Mocha
  Color.fromRGBO(121, 85, 72, 1),     // primary400 - Light Mocha
  Color.fromRGBO(141, 110, 99, 1),    // primary300 - Lighter Mocha
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme aquaLightScheme = EnteColorScheme(
  Color.fromRGBO(240, 255, 255, 1),    // backgroundBase - Soft cyan white
  Color.fromRGBO(245, 255, 255, 1),    // backgroundElevated
  Color.fromRGBO(251, 255, 255, 1),    // backgroundElevated2
  Color.fromRGBO(240, 255, 255, 0.92), // backdropBase
  Color.fromRGBO(240, 255, 255, 0.75), // backdropMuted
  Color.fromRGBO(240, 255, 255, 0.30), // backdropFaint
  Color.fromRGBO(0, 131, 143, 1),      // textBase - Deep cyan
  Color.fromRGBO(0, 151, 167, 0.6),    // textMuted
  Color.fromRGBO(0, 172, 193, 0.5),    // textFaint
  Color.fromRGBO(0, 188, 212, 0.65),   // blurTextBase
  Color.fromRGBO(77, 208, 225, 1),     // fillBase
  Color.fromRGBO(128, 222, 234, 0.87), // fillBasePressed
  Color.fromRGBO(178, 235, 242, 0.24), // fillStrong
  Color.fromRGBO(224, 247, 250, 0.12), // fillMuted
  Color.fromRGBO(77, 208, 225, 0.3),   // fillFaint
  Color.fromRGBO(128, 222, 234, 0.08), // fillFaintPressed
  Color.fromRGBO(242, 255, 255, 1),    // fillBaseGrey
  Color.fromRGBO(0, 131, 143, 1),      // strokeBase
  Color.fromRGBO(0, 151, 167, 0.24),   // strokeMuted
  Color.fromRGBO(0, 172, 193, 0.12),   // strokeFaint
  Color.fromRGBO(0, 188, 212, 0.06),   // strokeFainter
  Color.fromRGBO(77, 208, 225, 0.65),  // blurStrokeBase
  Color.fromRGBO(128, 222, 234, 0.08), // blurStrokeFaint
  Color.fromRGBO(178, 235, 242, 0.50), // blurStrokePressed
  Color.fromRGBO(0, 131, 143, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 131, 143, 1),     // primary700 - Deep Cyan
  Color.fromRGBO(0, 151, 167, 1),     // primary500 - Cyan
  Color.fromRGBO(0, 172, 193, 1),     // primary400 - Light Cyan
  Color.fromRGBO(0, 188, 212, 1),     // primary300 - Lighter Cyan
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme aquaDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 31, 31, 1),       // backgroundBase - Deep ocean
  Color.fromRGBO(19, 41, 41, 1),       // backgroundElevated
  Color.fromRGBO(27, 51, 51, 1),       // backgroundElevated2
  Color.fromRGBO(10, 31, 31, 0.90),    // backdropBase
  Color.fromRGBO(19, 41, 41, 0.65),    // backdropMuted
  Color.fromRGBO(27, 51, 51, 0.20),    // backdropFaint
  Color.fromRGBO(178, 235, 242, 1),    // textBase - Light cyan
  Color.fromRGBO(128, 222, 234, 0.7),  // textMuted
  Color.fromRGBO(77, 208, 225, 0.5),   // textFaint
  Color.fromRGBO(178, 235, 242, 0.95), // blurTextBase
  Color.fromRGBO(0, 151, 167, 1),      // fillBase
  Color.fromRGBO(0, 131, 143, 0.9),    // fillBasePressed
  Color.fromRGBO(0, 172, 193, 0.32),   // fillStrong
  Color.fromRGBO(0, 188, 212, 0.16),   // fillMuted
  Color.fromRGBO(77, 208, 225, 0.3),   // fillFaint
  Color.fromRGBO(128, 222, 234, 0.06), // fillFaintPressed
  Color.fromRGBO(27, 51, 51, 1),       // fillBaseGrey
  Color.fromRGBO(0, 151, 167, 1),      // strokeBase
  Color.fromRGBO(0, 172, 193, 0.24),   // strokeMuted
  Color.fromRGBO(0, 188, 212, 0.16),   // strokeFaint
  Color.fromRGBO(77, 208, 225, 0.08),  // strokeFainter
  Color.fromRGBO(0, 151, 167, 0.90),   // blurStrokeBase
  Color.fromRGBO(0, 172, 193, 0.06),   // blurStrokeFaint
  Color.fromRGBO(0, 131, 143, 0.50),   // blurStrokePressed
  Color.fromRGBO(178, 235, 242, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 131, 143, 1),     // primary700 - Deep Cyan
  Color.fromRGBO(0, 151, 167, 1),     // primary500 - Cyan
  Color.fromRGBO(0, 172, 193, 1),     // primary400 - Light Cyan
  Color.fromRGBO(0, 188, 212, 1),     // primary300 - Lighter Cyan
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme lilacLightScheme = EnteColorScheme(
  Color.fromRGBO(250, 240, 255, 1),    // backgroundBase - Soft lilac white
  Color.fromRGBO(252, 245, 255, 1),    // backgroundElevated
  Color.fromRGBO(253, 251, 255, 1),    // backgroundElevated2
  Color.fromRGBO(250, 240, 255, 0.92), // backdropBase
  Color.fromRGBO(250, 240, 255, 0.75), // backdropMuted
  Color.fromRGBO(250, 240, 255, 0.30), // backdropFaint
  Color.fromRGBO(149, 117, 205, 1),    // textBase - Deep lavender
  Color.fromRGBO(156, 126, 208, 0.6),  // textMuted
  Color.fromRGBO(165, 137, 211, 0.5),  // textFaint
  Color.fromRGBO(179, 157, 219, 0.65), // blurTextBase
  Color.fromRGBO(186, 165, 223, 1),    // fillBase
  Color.fromRGBO(197, 179, 227, 0.87), // fillBasePressed
  Color.fromRGBO(209, 196, 233, 0.24), // fillStrong
  Color.fromRGBO(237, 231, 246, 0.12), // fillMuted
  Color.fromRGBO(186, 165, 223, 0.3),  // fillFaint
  Color.fromRGBO(197, 179, 227, 0.08), // fillFaintPressed
  Color.fromRGBO(252, 247, 255, 1),    // fillBaseGrey
  Color.fromRGBO(149, 117, 205, 1),    // strokeBase
  Color.fromRGBO(156, 126, 208, 0.24), // strokeMuted
  Color.fromRGBO(165, 137, 211, 0.12), // strokeFaint
  Color.fromRGBO(179, 157, 219, 0.06), // strokeFainter
  Color.fromRGBO(186, 165, 223, 0.65), // blurStrokeBase
  Color.fromRGBO(197, 179, 227, 0.08), // blurStrokeFaint
  Color.fromRGBO(209, 196, 233, 0.50), // blurStrokePressed
  Color.fromRGBO(149, 117, 205, 0.85), // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(149, 117, 205, 1),   // primary700 - Deep Lavender
  Color.fromRGBO(156, 126, 208, 1),   // primary500 - Lavender
  Color.fromRGBO(165, 137, 211, 1),   // primary400 - Light Lavender
  Color.fromRGBO(179, 157, 219, 1),   // primary300 - Lighter Lavender
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme lilacDarkScheme = EnteColorScheme(
  Color.fromRGBO(25, 15, 31, 1),       // backgroundBase - Deep lavender black
  Color.fromRGBO(33, 21, 41, 1),       // backgroundElevated
  Color.fromRGBO(41, 27, 51, 1),       // backgroundElevated2
  Color.fromRGBO(25, 15, 31, 0.90),    // backdropBase
  Color.fromRGBO(33, 21, 41, 0.65),    // backdropMuted
  Color.fromRGBO(41, 27, 51, 0.20),    // backdropFaint
  Color.fromRGBO(209, 196, 233, 1),    // textBase - Light lavender
  Color.fromRGBO(197, 179, 227, 0.7),  // textMuted
  Color.fromRGBO(186, 165, 223, 0.5),  // textFaint
  Color.fromRGBO(209, 196, 233, 0.95), // blurTextBase
  Color.fromRGBO(156, 126, 208, 1),    // fillBase
  Color.fromRGBO(149, 117, 205, 0.9),  // fillBasePressed
  Color.fromRGBO(165, 137, 211, 0.32), // fillStrong
  Color.fromRGBO(179, 157, 219, 0.16), // fillMuted
  Color.fromRGBO(186, 165, 223, 0.3),  // fillFaint
  Color.fromRGBO(197, 179, 227, 0.06), // fillFaintPressed
  Color.fromRGBO(41, 27, 51, 1),       // fillBaseGrey
  Color.fromRGBO(156, 126, 208, 1),    // strokeBase
  Color.fromRGBO(165, 137, 211, 0.24), // strokeMuted
  Color.fromRGBO(179, 157, 219, 0.16), // strokeFaint
  Color.fromRGBO(186, 165, 223, 0.08), // strokeFainter
  Color.fromRGBO(156, 126, 208, 0.90), // blurStrokeBase
  Color.fromRGBO(165, 137, 211, 0.06), // blurStrokeFaint
  Color.fromRGBO(149, 117, 205, 0.50), // blurStrokePressed
  Color.fromRGBO(209, 196, 233, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(149, 117, 205, 1),   // primary700 - Deep Lavender
  Color.fromRGBO(156, 126, 208, 1),   // primary500 - Lavender
  Color.fromRGBO(165, 137, 211, 1),   // primary400 - Light Lavender
  Color.fromRGBO(179, 157, 219, 1),   // primary300 - Lighter Lavender
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme emeraldLightScheme = EnteColorScheme(
  Color.fromRGBO(240, 255, 246, 1),    // backgroundBase - Soft emerald white
  Color.fromRGBO(245, 255, 249, 1),    // backgroundElevated
  Color.fromRGBO(251, 255, 252, 1),    // backgroundElevated2
  Color.fromRGBO(240, 255, 246, 0.92), // backdropBase
  Color.fromRGBO(240, 255, 246, 0.75), // backdropMuted
  Color.fromRGBO(240, 255, 246, 0.30), // backdropFaint
  Color.fromRGBO(0, 148, 115, 1),      // textBase - Deep emerald
  Color.fromRGBO(0, 168, 132, 0.6),    // textMuted
  Color.fromRGBO(0, 188, 149, 0.5),    // textFaint
  Color.fromRGBO(0, 200, 159, 0.65),   // blurTextBase
  Color.fromRGBO(29, 209, 161, 1),     // fillBase
  Color.fromRGBO(72, 219, 177, 0.87),  // fillBasePressed
  Color.fromRGBO(111, 230, 184, 0.24), // fillStrong
  Color.fromRGBO(200, 247, 230, 0.12), // fillMuted
  Color.fromRGBO(29, 209, 161, 0.3),   // fillFaint
  Color.fromRGBO(72, 219, 177, 0.08),  // fillFaintPressed
  Color.fromRGBO(242, 255, 248, 1),    // fillBaseGrey
  Color.fromRGBO(0, 148, 115, 1),      // strokeBase
  Color.fromRGBO(0, 168, 132, 0.24),   // strokeMuted
  Color.fromRGBO(0, 188, 149, 0.12),   // strokeFaint
  Color.fromRGBO(0, 200, 159, 0.06),   // strokeFainter
  Color.fromRGBO(29, 209, 161, 0.65),  // blurStrokeBase
  Color.fromRGBO(72, 219, 177, 0.08),  // blurStrokeFaint
  Color.fromRGBO(111, 230, 184, 0.50), // blurStrokePressed
  Color.fromRGBO(0, 148, 115, 0.85),   // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 148, 115, 1),     // primary700 - Deep Emerald
  Color.fromRGBO(0, 168, 132, 1),     // primary500 - Emerald
  Color.fromRGBO(0, 188, 149, 1),     // primary400 - Light Emerald
  Color.fromRGBO(0, 200, 159, 1),     // primary300 - Lighter Emerald
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme emeraldDarkScheme = EnteColorScheme(
  Color.fromRGBO(10, 31, 25, 1),       // backgroundBase - Deep emerald black
  Color.fromRGBO(19, 41, 33, 1),       // backgroundElevated
  Color.fromRGBO(27, 51, 41, 1),       // backgroundElevated2
  Color.fromRGBO(10, 31, 25, 0.90),    // backdropBase
  Color.fromRGBO(19, 41, 33, 0.65),    // backdropMuted
  Color.fromRGBO(27, 51, 41, 0.20),    // backdropFaint
  Color.fromRGBO(111, 230, 184, 1),    // textBase - Light emerald
  Color.fromRGBO(72, 219, 177, 0.7),   // textMuted
  Color.fromRGBO(29, 209, 161, 0.5),   // textFaint
  Color.fromRGBO(111, 230, 184, 0.95), // blurTextBase
  Color.fromRGBO(0, 168, 132, 1),      // fillBase
  Color.fromRGBO(0, 148, 115, 0.9),    // fillBasePressed
  Color.fromRGBO(0, 188, 149, 0.32),   // fillStrong
  Color.fromRGBO(0, 200, 159, 0.16),   // fillMuted
  Color.fromRGBO(29, 209, 161, 0.3),   // fillFaint
  Color.fromRGBO(72, 219, 177, 0.06),  // fillFaintPressed
  Color.fromRGBO(27, 51, 41, 1),       // fillBaseGrey
  Color.fromRGBO(0, 168, 132, 1),      // strokeBase
  Color.fromRGBO(0, 188, 149, 0.24),   // strokeMuted
  Color.fromRGBO(0, 200, 159, 0.16),   // strokeFaint
  Color.fromRGBO(29, 209, 161, 0.08),  // strokeFainter
  Color.fromRGBO(0, 168, 132, 0.90),   // blurStrokeBase
  Color.fromRGBO(0, 188, 149, 0.06),   // blurStrokeFaint
  Color.fromRGBO(0, 148, 115, 0.50),   // blurStrokePressed
  Color.fromRGBO(111, 230, 184, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(0, 148, 115, 1),     // primary700 - Deep Emerald
  Color.fromRGBO(0, 168, 132, 1),     // primary500 - Emerald
  Color.fromRGBO(0, 188, 149, 1),     // primary400 - Light Emerald
  Color.fromRGBO(0, 200, 159, 1),     // primary300 - Lighter Emerald
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme slateLightScheme = EnteColorScheme(
  Color.fromRGBO(245, 247, 250, 1),    // backgroundBase - Soft slate white
  Color.fromRGBO(248, 249, 252, 1),    // backgroundElevated
  Color.fromRGBO(251, 252, 254, 1),    // backgroundElevated2
  Color.fromRGBO(245, 247, 250, 0.92), // backdropBase
  Color.fromRGBO(245, 247, 250, 0.75), // backdropMuted
  Color.fromRGBO(245, 247, 250, 0.30), // backdropFaint
  Color.fromRGBO(66, 71, 80, 1),       // textBase - Deep slate
  Color.fromRGBO(76, 82, 92, 0.6),     // textMuted
  Color.fromRGBO(86, 93, 104, 0.5),    // textFaint
  Color.fromRGBO(96, 104, 116, 0.65),  // blurTextBase
  Color.fromRGBO(108, 116, 128, 1),    // fillBase
  Color.fromRGBO(120, 128, 140, 0.87), // fillBasePressed
  Color.fromRGBO(144, 152, 164, 0.24), // fillStrong
  Color.fromRGBO(176, 184, 196, 0.12), // fillMuted
  Color.fromRGBO(108, 116, 128, 0.3),  // fillFaint
  Color.fromRGBO(120, 128, 140, 0.08), // fillFaintPressed
  Color.fromRGBO(247, 248, 251, 1),    // fillBaseGrey
  Color.fromRGBO(66, 71, 80, 1),       // strokeBase
  Color.fromRGBO(76, 82, 92, 0.24),    // strokeMuted
  Color.fromRGBO(86, 93, 104, 0.12),   // strokeFaint
  Color.fromRGBO(96, 104, 116, 0.06),  // strokeFainter
  Color.fromRGBO(108, 116, 128, 0.65), // blurStrokeBase
  Color.fromRGBO(120, 128, 140, 0.08), // blurStrokeFaint
  Color.fromRGBO(144, 152, 164, 0.50), // blurStrokePressed
  Color.fromRGBO(66, 71, 80, 0.85),    // tabIcon
  avatarLight,                         // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(66, 71, 80, 1),      // primary700 - Deep Slate
  Color.fromRGBO(76, 82, 92, 1),      // primary500 - Slate
  Color.fromRGBO(86, 93, 104, 1),     // primary400 - Light Slate
  Color.fromRGBO(96, 104, 116, 1),    // primary300 - Lighter Slate
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);

const EnteColorScheme slateDarkScheme = EnteColorScheme(
  Color.fromRGBO(22, 24, 28, 1),       // backgroundBase - Deep steel black
  Color.fromRGBO(28, 30, 34, 1),       // backgroundElevated
  Color.fromRGBO(34, 36, 40, 1),       // backgroundElevated2
  Color.fromRGBO(22, 24, 28, 0.90),    // backdropBase
  Color.fromRGBO(28, 30, 34, 0.65),    // backdropMuted
  Color.fromRGBO(34, 36, 40, 0.20),    // backdropFaint
  Color.fromRGBO(176, 184, 196, 1),    // textBase - Light slate
  Color.fromRGBO(144, 152, 164, 0.7),  // textMuted
  Color.fromRGBO(108, 116, 128, 0.5),  // textFaint
  Color.fromRGBO(176, 184, 196, 0.95), // blurTextBase
  Color.fromRGBO(76, 82, 92, 1),       // fillBase
  Color.fromRGBO(66, 71, 80, 0.9),     // fillBasePressed
  Color.fromRGBO(86, 93, 104, 0.32),   // fillStrong
  Color.fromRGBO(96, 104, 116, 0.16),  // fillMuted
  Color.fromRGBO(108, 116, 128, 0.3),  // fillFaint
  Color.fromRGBO(120, 128, 140, 0.06), // fillFaintPressed
  Color.fromRGBO(34, 36, 40, 1),       // fillBaseGrey
  Color.fromRGBO(76, 82, 92, 1),       // strokeBase
  Color.fromRGBO(86, 93, 104, 0.24),   // strokeMuted
  Color.fromRGBO(96, 104, 116, 0.16),  // strokeFaint
  Color.fromRGBO(108, 116, 128, 0.08), // strokeFainter
  Color.fromRGBO(76, 82, 92, 0.90),    // blurStrokeBase
  Color.fromRGBO(86, 93, 104, 0.06),   // blurStrokeFaint
  Color.fromRGBO(66, 71, 80, 0.50),    // blurStrokePressed
  Color.fromRGBO(176, 184, 196, 0.80), // tabIcon
  avatarDark,                          // avatarColors
  fixedStrokeMutedWhite,              // fixedStrokeMutedWhite
  strokeSolidMutedLight,              // strokeSolidMuted
  strokeSolidFaintLight,              // strokeSolidFaint
  Color.fromRGBO(66, 71, 80, 1),      // primary700 - Deep Slate
  Color.fromRGBO(76, 82, 92, 1),      // primary500 - Slate
  Color.fromRGBO(86, 93, 104, 1),     // primary400 - Light Slate
  Color.fromRGBO(96, 104, 116, 1),    // primary300 - Lighter Slate
  Color.fromRGBO(211, 47, 47, 1),     // warning700
  Color.fromRGBO(229, 57, 53, 1),     // warning500
  Color.fromRGBO(239, 83, 80, 1),     // warning400
  Color.fromRGBO(198, 40, 40, 1),     // warning800
  Color.fromRGBO(255, 179, 0, 1),     // caution500
  Color.fromRGBO(255, 179, 0, 1),     // golden700
  Color.fromRGBO(255, 202, 40, 1),    // golden500
);
