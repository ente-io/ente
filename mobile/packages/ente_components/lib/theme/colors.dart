import 'package:flutter/material.dart';

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=57-6281&view=variables
/// Section: Colours / Semantic tokens
/// Specs: Color Tokens collection with Photos-Light and Photos-Dark modes.
enum EnteApp {
  photos,
  auth,
  locker,
}

class ColorTokens {
  const ColorTokens({
    required this.primaryLight,
    required this.primaryStroke,
    required this.primary,
    required this.primaryDark,
    required this.primaryDarker,
    required this.warningLight,
    required this.warning,
    required this.warningDark,
    required this.warningDarker,
    required this.cautionLight,
    required this.caution,
    required this.infoLight,
    required this.infoStroke,
    required this.info,
    required this.infoDark,
    required this.infoDarker,
    required this.textLight,
    required this.textBase,
    required this.textDark,
    required this.textDarker,
    required this.textLighter,
    required this.textLightest,
    required this.textReverse,
    required this.iconColor,
    required this.backgroundBase,
    required this.fillLight,
    required this.fillBase,
    required this.fillDark,
    required this.fillDarker,
    required this.fillDarkest,
    required this.strokeDark,
    required this.strokeFaint,
    required this.accentOrangeLight,
    required this.accentPinkLight,
    required this.accentPurpleLight,
    required this.accentTealLight,
    required this.accentOrange,
    required this.accentPink,
    required this.accentPurple,
    required this.accentTeal,
    required this.specialContentReverse,
    required this.specialScrim,
    required this.specialWhite,
    required this.specialWhiteOverlay,
  });

  final Color primaryLight;
  final Color primaryStroke;
  final Color primary;
  final Color primaryDark;
  final Color primaryDarker;
  final Color warningLight;
  final Color warning;
  final Color warningDark;
  final Color warningDarker;
  final Color cautionLight;
  final Color caution;
  final Color infoLight;
  final Color infoStroke;
  final Color info;
  final Color infoDark;
  final Color infoDarker;
  final Color textLight;
  final Color textBase;
  final Color textDark;
  final Color textDarker;
  final Color textLighter;
  final Color textLightest;
  final Color textReverse;
  final Color iconColor;
  final Color backgroundBase;
  final Color fillLight;
  final Color fillBase;
  final Color fillDark;
  final Color fillDarker;
  final Color fillDarkest;
  final Color strokeDark;
  final Color strokeFaint;
  final Color accentOrangeLight;
  final Color accentPinkLight;
  final Color accentPurpleLight;
  final Color accentTealLight;
  final Color accentOrange;
  final Color accentPink;
  final Color accentPurple;
  final Color accentTeal;
  final Color specialContentReverse;
  final Color specialScrim;
  final Color specialWhite;
  final Color specialWhiteOverlay;

  static const light = colorTokensLight;
  static const dark = colorTokensDark;

  factory ColorTokens.forApp(
    EnteApp app, {
    Brightness brightness = Brightness.light,
  }) {
    final base =
        brightness == Brightness.dark ? colorTokensDark : colorTokensLight;
    return base.withPrimary(_primaryTokensForApp(app, brightness));
  }

  ColorTokens withPrimary(PrimaryColorTokens primaryTokens) {
    return ColorTokens(
      primaryLight: primaryTokens.primaryLight,
      primaryStroke: primaryTokens.primaryStroke,
      primary: primaryTokens.primary,
      primaryDark: primaryTokens.primaryDark,
      primaryDarker: primaryTokens.primaryDarker,
      warningLight: warningLight,
      warning: warning,
      warningDark: warningDark,
      warningDarker: warningDarker,
      cautionLight: cautionLight,
      caution: caution,
      infoLight: infoLight,
      infoStroke: infoStroke,
      info: info,
      infoDark: infoDark,
      infoDarker: infoDarker,
      textLight: textLight,
      textBase: textBase,
      textDark: textDark,
      textDarker: textDarker,
      textLighter: textLighter,
      textLightest: textLightest,
      textReverse: textReverse,
      iconColor: iconColor,
      backgroundBase: backgroundBase,
      fillLight: fillLight,
      fillBase: fillBase,
      fillDark: fillDark,
      fillDarker: fillDarker,
      fillDarkest: fillDarkest,
      strokeDark: strokeDark,
      strokeFaint: strokeFaint,
      accentOrangeLight: accentOrangeLight,
      accentPinkLight: accentPinkLight,
      accentPurpleLight: accentPurpleLight,
      accentTealLight: accentTealLight,
      accentOrange: accentOrange,
      accentPink: accentPink,
      accentPurple: accentPurple,
      accentTeal: accentTeal,
      specialContentReverse: specialContentReverse,
      specialScrim: specialScrim,
      specialWhite: specialWhite,
      specialWhiteOverlay: specialWhiteOverlay,
    );
  }
}

class PrimaryColorTokens {
  const PrimaryColorTokens({
    required this.primaryLight,
    required this.primaryStroke,
    required this.primary,
    required this.primaryDark,
    required this.primaryDarker,
  });

  final Color primaryLight;
  final Color primaryStroke;
  final Color primary;
  final Color primaryDark;
  final Color primaryDarker;
}

PrimaryColorTokens _primaryTokensForApp(EnteApp app, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (app) {
    EnteApp.photos => dark ? photosPrimaryTokensDark : photosPrimaryTokensLight,
    EnteApp.auth => dark ? authPrimaryTokensDark : authPrimaryTokensLight,
    EnteApp.locker => dark ? lockerPrimaryTokensDark : lockerPrimaryTokensLight,
  };
}

const ColorTokens colorTokensLight = ColorTokens(
  primaryLight: primaryLightLight,
  primaryStroke: primaryStrokeLight,
  primary: primaryDefaultLight,
  primaryDark: primaryDarkLight,
  primaryDarker: primaryDarkerLight,
  warningLight: warningLightLight,
  warning: warningDefaultLight,
  warningDark: warningDarkLight,
  warningDarker: warningDarkerLight,
  cautionLight: cautionLightLight,
  caution: cautionDefaultLight,
  infoLight: infoLightLight,
  infoStroke: infoStrokeLight,
  info: infoDefaultLight,
  infoDark: infoDarkLight,
  infoDarker: infoDarkerLight,
  textLight: textLightLight,
  textBase: textBaseLight,
  textDark: textDarkLight,
  textDarker: textDarkerLight,
  textLighter: textLighterLight,
  textLightest: textLightestLight,
  textReverse: textReverseLight,
  iconColor: iconColorLight,
  backgroundBase: backgroundBaseLight,
  fillLight: fillLightLight,
  fillBase: fillBaseLight,
  fillDark: fillDarkLight,
  fillDarker: fillDarkerLight,
  fillDarkest: fillDarkestLight,
  strokeDark: strokeDarkLight,
  strokeFaint: strokeFaintLight,
  accentOrangeLight: accentOrangeLightLight,
  accentPinkLight: accentPinkLightLight,
  accentPurpleLight: accentPurpleLightLight,
  accentTealLight: accentTealLightLight,
  accentOrange: accentOrangeDefaultLight,
  accentPink: accentPinkDefaultLight,
  accentPurple: accentPurpleDefaultLight,
  accentTeal: accentTealDefaultLight,
  specialContentReverse: specialContentReverseLight,
  specialScrim: specialScrimLight,
  specialWhite: specialWhiteLight,
  specialWhiteOverlay: specialWhiteOverlayLight,
);

const ColorTokens colorTokensDark = ColorTokens(
  primaryLight: primaryLightDark,
  primaryStroke: primaryStrokeDark,
  primary: primaryDefaultDark,
  primaryDark: primaryDarkDark,
  primaryDarker: primaryDarkerDark,
  warningLight: warningLightDark,
  warning: warningDefaultDark,
  warningDark: warningDarkDark,
  warningDarker: warningDarkerDark,
  cautionLight: cautionLightDark,
  caution: cautionDefaultDark,
  infoLight: infoLightDark,
  infoStroke: infoStrokeDark,
  info: infoDefaultDark,
  infoDark: infoDarkDark,
  infoDarker: infoDarkerDark,
  textLight: textLightDark,
  textBase: textBaseDark,
  textDark: textDarkDark,
  textDarker: textDarkerDark,
  textLighter: textLighterDark,
  textLightest: textLightestDark,
  textReverse: textReverseDark,
  iconColor: iconColorDark,
  backgroundBase: backgroundBaseDark,
  fillLight: fillLightDark,
  fillBase: fillBaseDark,
  fillDark: fillDarkDark,
  fillDarker: fillDarkerDark,
  fillDarkest: fillDarkestDark,
  strokeDark: strokeDarkDark,
  strokeFaint: strokeFaintDark,
  accentOrangeLight: accentOrangeLightDark,
  accentPinkLight: accentPinkLightDark,
  accentPurpleLight: accentPurpleLightDark,
  accentTealLight: accentTealLightDark,
  accentOrange: accentOrangeDefaultDark,
  accentPink: accentPinkDefaultDark,
  accentPurple: accentPurpleDefaultDark,
  accentTeal: accentTealDefaultDark,
  specialContentReverse: specialContentReverseDark,
  specialScrim: specialScrimDark,
  specialWhite: specialWhiteDark,
  specialWhiteOverlay: specialWhiteOverlayDark,
);

const PrimaryColorTokens photosPrimaryTokensLight = PrimaryColorTokens(
  primaryLight: primaryLightLight,
  primaryStroke: primaryStrokeLight,
  primary: primaryDefaultLight,
  primaryDark: primaryDarkLight,
  primaryDarker: primaryDarkerLight,
);

const PrimaryColorTokens photosPrimaryTokensDark = PrimaryColorTokens(
  primaryLight: primaryLightDark,
  primaryStroke: primaryStrokeDark,
  primary: primaryDefaultDark,
  primaryDark: primaryDarkDark,
  primaryDarker: primaryDarkerDark,
);

const PrimaryColorTokens authPrimaryTokensLight = PrimaryColorTokens(
  primaryLight: authPrimaryLightLight,
  primaryStroke: authPrimaryStrokeLight,
  primary: authPrimaryDefaultLight,
  primaryDark: authPrimaryDarkLight,
  primaryDarker: authPrimaryDarkerLight,
);

const PrimaryColorTokens authPrimaryTokensDark = PrimaryColorTokens(
  primaryLight: authPrimaryLightDark,
  primaryStroke: authPrimaryStrokeDark,
  primary: authPrimaryDefaultDark,
  primaryDark: authPrimaryDarkDark,
  primaryDarker: authPrimaryDarkerDark,
);

const PrimaryColorTokens lockerPrimaryTokensLight = PrimaryColorTokens(
  primaryLight: lockerPrimaryLightLight,
  primaryStroke: lockerPrimaryStrokeLight,
  primary: lockerPrimaryDefaultLight,
  primaryDark: lockerPrimaryDarkLight,
  primaryDarker: lockerPrimaryDarkerLight,
);

const PrimaryColorTokens lockerPrimaryTokensDark = PrimaryColorTokens(
  primaryLight: lockerPrimaryLightDark,
  primaryStroke: lockerPrimaryStrokeDark,
  primary: lockerPrimaryDefaultDark,
  primaryDark: lockerPrimaryDarkDark,
  primaryDarker: lockerPrimaryDarkerDark,
);

// Primary Colors
const Color primaryLightLight = Color.fromRGBO(231, 246, 233, 1);
const Color primaryLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color primaryStrokeLight = Color.fromRGBO(186, 236, 194, 1);
const Color primaryStrokeDark = Color.fromRGBO(28, 65, 34, 1);

const Color primaryDefaultLight = Color.fromRGBO(8, 194, 37, 1);
const Color primaryDefaultDark = Color.fromRGBO(8, 194, 37, 1);

const Color primaryDarkLight = Color.fromRGBO(6, 157, 30, 1);
const Color primaryDarkDark = Color.fromRGBO(6, 157, 30, 1);

const Color primaryDarkerLight = Color.fromRGBO(5, 124, 24, 1);
const Color primaryDarkerDark = Color.fromRGBO(5, 124, 24, 1);

// Auth Primary Colors
const Color authPrimaryLightLight = Color.fromRGBO(248, 243, 254, 1);
const Color authPrimaryLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color authPrimaryStrokeLight = Color.fromRGBO(221, 191, 248, 1);
const Color authPrimaryStrokeDark = Color.fromRGBO(61, 34, 88, 1);

const Color authPrimaryDefaultLight = Color(0xFF8F33D6);
const Color authPrimaryDefaultDark = Color(0xFF8F33D6);

const Color authPrimaryDarkLight = Color(0xFF722ED1);
const Color authPrimaryDarkDark = Color(0xFF722ED1);

const Color authPrimaryDarkerLight = Color(0xFF5D25AD);
const Color authPrimaryDarkerDark = Color(0xFF5D25AD);

// Locker Primary Colors
const Color lockerPrimaryLightLight = Color.fromRGBO(231, 239, 250, 1);
const Color lockerPrimaryLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color lockerPrimaryStrokeLight = Color.fromRGBO(200, 216, 238, 1);
const Color lockerPrimaryStrokeDark = Color.fromRGBO(26, 43, 77, 1);

const Color lockerPrimaryDefaultLight = Color.fromRGBO(16, 113, 255, 1);
const Color lockerPrimaryDefaultDark = Color.fromRGBO(16, 113, 255, 1);

const Color lockerPrimaryDarkLight = Color.fromRGBO(14, 95, 217, 1);
const Color lockerPrimaryDarkDark = Color.fromRGBO(14, 95, 217, 1);

const Color lockerPrimaryDarkerLight = Color.fromRGBO(11, 76, 173, 1);
const Color lockerPrimaryDarkerDark = Color.fromRGBO(11, 76, 173, 1);

// Warning Colors
const Color warningLightLight = Color.fromRGBO(250, 235, 235, 1);
const Color warningLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color warningDefaultLight = Color.fromRGBO(246, 58, 58, 1);
const Color warningDefaultDark = Color.fromRGBO(246, 58, 58, 1);

const Color warningDarkLight = Color.fromRGBO(221, 52, 52, 1);
const Color warningDarkDark = Color.fromRGBO(221, 52, 52, 1);

const Color warningDarkerLight = Color.fromRGBO(197, 46, 46, 1);
const Color warningDarkerDark = Color.fromRGBO(197, 46, 46, 1);

// Caution Colors
const Color cautionLightLight = Color.fromRGBO(250, 244, 235, 1);
const Color cautionLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color cautionDefaultLight = Color.fromRGBO(255, 169, 57, 1);
const Color cautionDefaultDark = Color.fromRGBO(255, 169, 57, 1);

// Info Colors
const Color infoLightLight = Color.fromRGBO(231, 239, 250, 1);
const Color infoLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color infoStrokeLight = Color.fromRGBO(200, 216, 238, 1);
const Color infoStrokeDark = Color.fromRGBO(26, 43, 77, 1);

const Color infoDefaultLight = Color.fromRGBO(16, 113, 255, 1);
const Color infoDefaultDark = Color.fromRGBO(16, 113, 255, 1);

const Color infoDarkLight = Color.fromRGBO(14, 95, 217, 1);
const Color infoDarkDark = Color.fromRGBO(14, 95, 217, 1);

const Color infoDarkerLight = Color.fromRGBO(11, 76, 173, 1);
const Color infoDarkerDark = Color.fromRGBO(11, 76, 173, 1);

// Text Colors
const Color textLightLight = Color.fromRGBO(102, 102, 102, 1);
const Color textLightDark = Color.fromRGBO(153, 153, 153, 1);

const Color textBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color textBaseDark = Color.fromRGBO(255, 255, 255, 1);

const Color textDarkLight = Color.fromRGBO(26, 26, 26, 1);
const Color textDarkDark = Color.fromRGBO(229, 229, 229, 1);

const Color textDarkerLight = Color.fromRGBO(21, 21, 21, 1);
const Color textDarkerDark = Color.fromRGBO(204, 204, 204, 1);

const Color textLighterLight = Color.fromRGBO(150, 150, 150, 1);
const Color textLighterDark = Color.fromRGBO(150, 150, 150, 1);

const Color textLightestLight = Color.fromRGBO(222, 222, 222, 1);
const Color textLightestDark = Color.fromRGBO(10, 10, 10, 1);

const Color textReverseLight = Color.fromRGBO(255, 255, 255, 1);
const Color textReverseDark = Color.fromRGBO(0, 0, 0, 1);

// Icon Colors
const Color iconColorLight = Color.fromRGBO(0, 0, 0, 0.75);
const Color iconColorDark = Color.fromRGBO(255, 255, 255, 1);

// Background Colors
const Color backgroundBaseLight = Color.fromRGBO(250, 250, 250, 1);
const Color backgroundBaseDark = Color.fromRGBO(22, 22, 22, 1);

// Fill Colors
const Color fillLightLight = Color.fromRGBO(255, 255, 255, 1);
const Color fillLightDark = Color.fromRGBO(33, 33, 33, 1);

const Color fillBaseLight = Color.fromRGBO(0, 0, 0, 1);
const Color fillBaseDark = Color.fromRGBO(255, 255, 255, 1);

const Color fillDarkLight = Color.fromRGBO(245, 245, 245, 1);
const Color fillDarkDark = Color.fromRGBO(10, 10, 10, 1);

const Color fillDarkerLight = Color.fromRGBO(233, 233, 233, 1);
const Color fillDarkerDark = Color.fromRGBO(20, 20, 20, 1);

const Color fillDarkestLight = Color.fromRGBO(210, 210, 210, 1);
const Color fillDarkestDark = Color.fromRGBO(41, 41, 41, 1);

// Stroke Colors
const Color strokeDarkLight = Color.fromRGBO(224, 224, 224, 1);
const Color strokeDarkDark = Color.fromRGBO(62, 62, 62, 1);

const Color strokeFaintLight = Color.fromRGBO(235, 235, 235, 1);
const Color strokeFaintDark = Color.fromRGBO(33, 33, 33, 1);

// Accent Colors
const Color accentOrangeLightLight = Color.fromRGBO(255, 247, 244, 1);
const Color accentOrangeLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color accentPinkLightLight = Color.fromRGBO(253, 246, 251, 1);
const Color accentPinkLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color accentPurpleLightLight = Color.fromRGBO(248, 243, 254, 1);
const Color accentPurpleLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color accentTealLightLight = Color.fromRGBO(245, 251, 251, 1);
const Color accentTealLightDark = Color.fromRGBO(41, 41, 41, 1);

const Color accentOrangeDefaultLight = Color.fromRGBO(242, 72, 34, 1);
const Color accentOrangeDefaultDark = Color.fromRGBO(242, 72, 34, 1);

const Color accentPinkDefaultLight = Color.fromRGBO(223, 97, 187, 1);
const Color accentPinkDefaultDark = Color.fromRGBO(223, 97, 187, 1);

const Color accentPurpleDefaultLight = Color.fromRGBO(138, 56, 245, 1);
const Color accentPurpleDefaultDark = Color.fromRGBO(138, 56, 245, 1);

const Color accentTealDefaultLight = Color.fromRGBO(95, 183, 187, 1);
const Color accentTealDefaultDark = Color.fromRGBO(95, 183, 187, 1);

// Special Colors
const Color specialContentReverseLight = Color.fromRGBO(255, 255, 255, 1);
const Color specialContentReverseDark = Color.fromRGBO(0, 0, 0, 1);

const Color specialScrimLight = Color.fromRGBO(0, 0, 0, 0.4);
const Color specialScrimDark = Color.fromRGBO(0, 0, 0, 0.4);

const Color specialWhiteLight = Color.fromRGBO(255, 255, 255, 1);
const Color specialWhiteDark = Color.fromRGBO(255, 255, 255, 1);

const Color specialWhiteOverlayLight = Color.fromRGBO(255, 255, 255, 0.14);
const Color specialWhiteOverlayDark = Color.fromRGBO(255, 255, 255, 0.14);

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
