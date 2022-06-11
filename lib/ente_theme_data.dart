import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

extension CustomColorScheme on ColorScheme {
  Color get defaultTextColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  Color get inverseTextColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get inverseIconColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get inverseBackgroundColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  Color get boxSelectColor => brightness == Brightness.light
      ? Color.fromRGBO(67, 186, 108, 1)
      : Color.fromRGBO(16, 32, 32, 1);

  Color get boxUnSelectColor => brightness == Brightness.light
      ? Color.fromRGBO(240, 240, 240, 1)
      : Color.fromRGBO(8, 18, 18, 0.4);

  Color get dynamicFABBackgroundColor =>
      brightness == Brightness.light ? Colors.black : Colors.grey[850];

  Color get dynamicFABTextColor => Colors.white; //same for both themes

  // todo: use brightness == Brightness.light for changing color for dark/light theme
  ButtonStyle get optionalActionButtonStyle => buildElevatedButtonThemeData(
          onPrimary: Color(0xFF777777),
          primary: Color(0xFFF0F0F0),
          elevation: 0,)
      .style;

  Color get recoveryKeyBoxColor => brightness == Brightness.light
      ? Color.fromRGBO(49, 155, 86, 0.2)
      : Color(0xFF1DB954);

  Color get frostyBlurBackdropFilterColor => brightness == Brightness.light
      ? Color.fromRGBO(238, 238, 238, 0.5)
      : Color.fromRGBO(48, 48, 48, 0.5);

  Color get iconColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  Color get cancelSelectedButtonColor => brightness == Brightness.light
      ? Color.fromRGBO(238, 238, 238, 1)
      : Color.fromRGBO(48, 48, 48, 0.5);

  Color get bgColorForQuestions => brightness == Brightness.light
      ? Colors.white
      : Color.fromRGBO(10, 15, 15, 1.0);

  Color get greenText => Color.fromARGB(255, 40, 190, 113);

  Color get cupertinoPickerTopColor => brightness == Brightness.light
      ? Color.fromARGB(255, 238, 238, 238)
      : Colors.white.withOpacity(0.1);

  DatePickerTheme get dateTimePickertheme => brightness == Brightness.light
      ? DatePickerTheme(
          backgroundColor: Colors.white,
          itemStyle: TextStyle(color: Colors.black),
          cancelStyle: TextStyle(color: Colors.black),)
      : DatePickerTheme(
          backgroundColor: Colors.black,
          itemStyle: TextStyle(color: Colors.white),
          cancelStyle: TextStyle(color: Colors.white),);

  Color get stepProgressUnselectedColor => brightness == Brightness.light
      ? Color.fromRGBO(196, 196, 196, 0.6)
      : Color.fromRGBO(255, 255, 255, 0.7);

  Color get gNavBackgroundColor => brightness == Brightness.light
      ? Color.fromRGBO(196, 196, 196, 0.6)
      : Color.fromRGBO(40, 40, 40, 0.6);

  Color get gNavBarActiveColor => brightness == Brightness.light
      ? Color.fromRGBO(255, 255, 255, 0.6)
      : Color.fromRGBO(255, 255, 255, 0.9);

  Color get gNavIconColor => brightness == Brightness.light
      ? Color.fromRGBO(0, 0, 0, 0.8)
      : Color.fromRGBO(255, 255, 255, 0.8);

  Color get gNavActiveIconColor => brightness == Brightness.light
      ? Color.fromRGBO(0, 0, 0, 0.8)
      : Color.fromRGBO(0, 0, 0, 0.8);

  Color get galleryThumbBackgroundColor => brightness == Brightness.light
      ? Color.fromRGBO(240, 240, 240, 1)
      : Color.fromRGBO(20, 20, 20, 1);

  Color get galleryThumbDrawColor => brightness == Brightness.light
      ? Colors.black.withOpacity(0.8)
      : Colors.white.withOpacity(0.5);

  Color get backupEnabledBgColor => brightness == Brightness.light
      ? Color.fromRGBO(230, 230, 230, 0.95)
      : Color.fromRGBO(10, 40, 40, 0.3);

  Color get dotsIndicatorActiveColor => brightness == Brightness.light
      ? Colors.black.withOpacity(0.5)
      : Colors.white.withOpacity(0.5);

  Color get dotsIndicatorInactiveColor => brightness == Brightness.light
      ? Colors.black.withOpacity(0.12)
      : Colors.white.withOpacity(0.12);

  Color get toastTextColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get toastBackgroundColor => brightness == Brightness.light
      ? Color.fromRGBO(24, 24, 24, 0.95)
      : Color.fromRGBO(255, 255, 255, 0.95);

  Color get subTextColor => brightness == Brightness.light
      ? Color.fromRGBO(180, 180, 180, 1)
      : Color.fromRGBO(100, 100, 100, 1);
}

OutlinedButtonThemeData buildOutlinedButtonThemeData(
    {Color bgDisabled, Color bgEnabled, Color fgDisabled, Color fgEnabled,}) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter-SemiBold',
        fontSize: 18,
      ),
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return bgDisabled;
          }
          return bgEnabled;
        },
      ),
      foregroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return fgDisabled;
          }
          return fgEnabled;
        },
      ),
      alignment: Alignment.center,
    ),
  );
}

ElevatedButtonThemeData buildElevatedButtonThemeData(
    {@required Color onPrimary, // text button color
    @required Color primary,
    double elevation = 2, // background color of button
    }) {
  return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
    elevation: elevation,
    onPrimary: onPrimary,
    primary: primary,
    alignment: Alignment.center,
    textStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter-SemiBold',
      fontSize: 18,
    ),
    padding: EdgeInsets.symmetric(vertical: 18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),);
}

TextStyle gradientButtonTextTheme() {
  return TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
  );
}
