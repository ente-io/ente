import 'package:flutter/material.dart';

const blurBase = 96.0;
const blurMuted = 48.0;
const blurFaint = 24.0;

List<BoxShadow> shadowFloatLight = const [
  BoxShadow(blurRadius: 10, color: Color.fromRGBO(0, 0, 0, 0.25)),
];

List<BoxShadow> shadowMenuLight = const [
  BoxShadow(blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.16)),
  BoxShadow(
    blurRadius: 6,
    color: Color.fromRGBO(0, 0, 0, 0.12),
    offset: Offset(0, 3),
  ),
];

List<BoxShadow> shadowButtonLight = const [
  BoxShadow(
    blurRadius: 4,
    color: Color.fromRGBO(0, 0, 0, 0.25),
    offset: Offset(0, 4),
  ),
];

List<BoxShadow> shadowFloatDark = const [
  BoxShadow(
    blurRadius: 12,
    color: Color.fromRGBO(0, 0, 0, 0.75),
    offset: Offset(0, 2),
  ),
];

List<BoxShadow> shadowMenuDark = const [
  BoxShadow(blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.50)),
  BoxShadow(
    blurRadius: 6,
    color: Color.fromRGBO(0, 0, 0, 0.25),
    offset: Offset(0, 3),
  ),
];

List<BoxShadow> shadowButtonDark = const [
  BoxShadow(
    blurRadius: 4,
    color: Color.fromRGBO(0, 0, 0, 0.75),
    offset: Offset(0, 4),
  ),
];
