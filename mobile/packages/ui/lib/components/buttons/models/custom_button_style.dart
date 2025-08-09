import 'package:flutter/material.dart';

class CustomButtonStyle {
  Color defaultButtonColor;
  Color? pressedButtonColor;
  Color? disabledButtonColor;
  Color defaultBorderColor;
  Color? pressedBorderColor;
  Color? disabledBorderColor;
  Color defaultIconColor;
  Color? pressedIconColor;
  Color? disabledIconColor;
  TextStyle defaultLabelStyle;
  TextStyle? pressedLabelStyle;
  TextStyle? disabledLabelStyle;
  Color? checkIconColor;

  CustomButtonStyle({
    required this.defaultButtonColor,
    this.pressedButtonColor,
    this.disabledButtonColor,
    required this.defaultBorderColor,
    this.pressedBorderColor,
    this.disabledBorderColor,
    required this.defaultIconColor,
    this.pressedIconColor,
    this.disabledIconColor,
    required this.defaultLabelStyle,
    this.pressedLabelStyle,
    this.disabledLabelStyle,
    this.checkIconColor,
  });
}
