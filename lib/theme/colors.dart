import 'dart:ui';

import 'package:flutter/material.dart';

class EnteColorScheme {
  // Background Colors
  final Color backgroundBase;
  final Color backgroundElevated;
  final Color backgroundElevated2;

  // Backdrop Colors
  final Color backdropBase;
  final Color backdropBaseMute;

  // Text Colors
  final Color textBase;
  final Color textMuted;
  final Color textFaint;

  // Fill Colors
  final Color fillBase;
  final Color fillMuted;
  final Color fillFaint;

  // Stroke Colors
  final Color strokeBase;
  final Color strokeMuted;
  final Color strokeFaint;
  final Color strokeFainter;

  // Fixed Colors
  final Color primary700;
  final Color primary500;
  final Color primary400;
  final Color primary300;

  //warning colors
  final Color warning700;
  final Color warning500;
  final Color warning400;
  final Color caution500;

  //other colors
  final Color tabIcon;

  const EnteColorScheme(
    this.backgroundBase,
    this.backgroundElevated,
    this.backgroundElevated2,
    this.backdropBase,
    this.backdropBaseMute,
    this.textBase,
    this.textMuted,
    this.textFaint,
    this.fillBase,
    this.fillMuted,
    this.fillFaint,
    this.strokeBase,
    this.strokeMuted,
    this.strokeFaint,
    this.strokeFainter,
    this.tabIcon, {
    this.primary700 = _primary700,
    this.primary500 = _primary500,
    this.primary400 = _primary400,
    this.primary300 = _primary300,
    this.warning700 = _warning700,
    this.warning500 = _warning500,
    this.warning400 = _warning700,
    this.caution500 = _caution500,
  });
}

const EnteColorScheme lightScheme = EnteColorScheme(
  backgroundBaseLight,
  backgroundElevatedLight,
  backgroundElevated2Light,
  backdropBaseLight,
  backdropBaseMuteLight,
  textBaseLight,
  textMutedLight,
  textFaintLight,
  fillBaseLight,
  fillMutedLight,
  fillFaintLight,
  strokeBaseLight,
  strokeMutedLight,
  strokeFaintLight,
  strokeFainterLight,
  tabIconLight,
);

const EnteColorScheme darkScheme = EnteColorScheme(
  backgroundBaseDark,
  backgroundElevatedDark,
  backgroundElevated2Dark,
  backdropBaseDark,
  backdropBaseMuteDark,
  textBaseDark,
  textMutedDark,
  textFaintDark,
  fillBaseDark,
  fillMutedDark,
  fillFaintDark,
  strokeBaseDark,
  strokeMutedDark,
  strokeFaintDark,
  strokeFainterDark,
  tabIconDark,
);

// Background Colors
const Color backgroundBaseLight = Color.fromRGBO(255, 255, 255, 1);
const Color backgroundElevatedLight = Color.fromRGBO(255, 255, 255, 1);
const Color backgroundElevated2Light = Color.fromRGBO(251, 251, 251, 1);

const Color backgroundBaseDark = Color.fromRGBO(0, 0, 0, 1);
const Color backgroundElevatedDark = Color.fromRGBO(27, 27, 27, 1);
const Color backgroundElevated2Dark = Color.fromRGBO(37, 37, 37, 1);

// Backdrop Colors
const Color backdropBaseLight = Color.fromRGBO(255, 255, 255, 0.75);
const Color backdropBaseMuteLight = Color.fromRGBO(255, 255, 255, 0.30);

const Color backdropBaseDark = Color.fromRGBO(0, 0, 0, 0.65);
const Color backdropBaseMuteDark = Color.fromRGBO(0, 0, 0, 0.20);

// Text Colors
const Color textBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color textMutedLight = Color.fromRGBO(0, 0, 0, 0.6);
const Color textFaintLight = Color.fromRGBO(0, 0, 0, 0.5);

const Color textBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color textMutedDark = Color.fromRGBO(255, 255, 255, 0.7);
const Color textFaintDark = Color.fromRGBO(255, 255, 255, 0.5);

// Fill Colors
const Color fillBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color fillMutedLight = Color.fromRGBO(0, 0, 0, 0.12);
const Color fillFaintLight = Color.fromRGBO(0, 0, 0, 0.04);

const Color fillBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color fillMutedDark = Color.fromRGBO(255, 255, 255, 0.16);
const Color fillFaintDark = Color.fromRGBO(255, 255, 255, 0.12);

// Stroke Colors
const Color strokeBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color strokeMutedLight = Color.fromRGBO(0, 0, 0, 0.24);
const Color strokeFaintLight = Color.fromRGBO(0, 0, 0, 0.12);
const Color strokeFainterLight = Color.fromRGBO(0, 0, 0, 0.06);

const Color strokeBaseDark = Color.fromRGBO(255, 255, 255, 1);
const Color strokeMutedDark = Color.fromRGBO(255, 255, 255, 0.24);
const Color strokeFaintDark = Color.fromRGBO(255, 255, 255, 0.16);
const Color strokeFainterDark = Color.fromRGBO(255, 255, 255, 0.08);

// Other colors
const Color tabIconLight = Color.fromRGBO(0, 0, 0, 0.85);

const Color tabIconDark = Color.fromRGBO(255, 255, 255, 0.80);

// Fixed Colors

const Color _primary700 = Color.fromRGBO(0, 179, 60, 1);
const Color _primary500 = Color.fromRGBO(29, 185, 84, 1);
const Color _primary400 = Color.fromRGBO(38, 203, 95, 1);
const Color _primary300 = Color.fromRGBO(1, 222, 77, 1);

const Color _warning700 = Color.fromRGBO(234, 63, 63, 1);
const Color _warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color warning500 = Color.fromRGBO(255, 101, 101, 1);
const Color _warning400 = Color.fromRGBO(255, 111, 111, 1);

const Color _caution500 = Color.fromRGBO(255, 194, 71, 1);
