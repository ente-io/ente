import 'package:flutter/material.dart';

const FontWeight regularWeight = FontWeight.w500;
const FontWeight boldWeight = FontWeight.w600;
const String _fontFamily = 'Inter';

const TextStyle h1 = TextStyle(
  fontSize: 48,
  height: 48 / 28,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle h2 = TextStyle(
  fontSize: 32,
  height: 39 / 32.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle h3 = TextStyle(
  fontSize: 24,
  height: 29 / 24.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle large = TextStyle(
  fontSize: 18,
  height: 22 / 18.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle body = TextStyle(
  fontSize: 16,
  height: 19.4 / 16.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle small = TextStyle(
  fontSize: 14,
  height: 17 / 14.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle mini = TextStyle(
  fontSize: 12,
  height: 15 / 12.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);
const TextStyle tiny = TextStyle(
  fontSize: 10,
  height: 12 / 10.0,
  fontWeight: regularWeight,
  fontFamily: _fontFamily,
);

class EnteTextStyle {
  final TextStyle? h1;
  final TextStyle? h1Bold;
  final TextStyle? h2;
  final TextStyle? h2Bold;
  final TextStyle? h3;
  final TextStyle? h3Bold;
  final TextStyle? large;
  final TextStyle? largeBold;
  final TextStyle? body;
  final TextStyle? bodyBold;
  final TextStyle? small;
  final TextStyle? smallBold;
  final TextStyle? mini;
  final TextStyle? miniBold;
  final TextStyle? tiny;
  final TextStyle? tinyBold;

  const EnteTextStyle({
    this.h1,
    this.h1Bold,
    this.h2,
    this.h2Bold,
    this.h3,
    this.h3Bold,
    this.large,
    this.largeBold,
    this.body,
    this.bodyBold,
    this.small,
    this.smallBold,
    this.mini,
    this.miniBold,
    this.tiny,
    this.tinyBold,
  });
}

EnteTextStyle lightTextStyle = _buildEnteTextStyle(Colors.white);
EnteTextStyle darkTextStyle = _buildEnteTextStyle(Colors.white);

EnteTextStyle _buildEnteTextStyle(Color color) {
  return EnteTextStyle(
    h1: h1.copyWith(color: color),
    h1Bold: h1.copyWith(color: color, fontWeight: boldWeight),
    h2: h2.copyWith(color: color),
    h3: h3.copyWith(color: color),
    h3Bold: h3.copyWith(color: color, fontWeight: boldWeight),
    large: large.copyWith(color: color),
    largeBold: large.copyWith(color: color, fontWeight: boldWeight),
    body: body.copyWith(color: color),
    bodyBold: body.copyWith(color: color, fontWeight: boldWeight),
    small: small.copyWith(color: color),
    smallBold: small.copyWith(color: color, fontWeight: boldWeight),
    mini: mini.copyWith(color: color),
    miniBold: mini.copyWith(color: color, fontWeight: boldWeight),
    tiny: tiny.copyWith(color: color),
    tinyBold: tiny.copyWith(color: color, fontWeight: boldWeight),
  );
}
