import 'dart:ui';

import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  Color get defaultTextColor =>
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
          elevation: 0)
      .style;
}

OutlinedButtonThemeData buildOutlinedButtonThemeData(
    {Color bgDisabled, Color bgEnabled, Color fgDisabled, Color fgEnabled}) {
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
    double elevation = 2 // background color of button
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
  ));
}

TextStyle gradientButtonTextTheme() {
  return TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
  );
}
