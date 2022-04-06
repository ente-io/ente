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

  Color get fabBackgroundColor =>
      brightness == Brightness.light ? Colors.black : Colors.grey[850];

  Color get fabTextOrIconColor =>
      brightness == Brightness.light ? Colors.white : Colors.white;

  ButtonStyle get primaryActionButtonStyle => ElevatedButton.styleFrom(
        onPrimary: Colors.white,
        primary: Color.fromRGBO(29, 185, 84, 1.0),
        minimumSize: Size(88, 36),
        alignment: Alignment.center,
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter-SemiBold',
          fontSize: 18,
        ),
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      );

  ButtonStyle get optionalActionButtonStyle => ElevatedButton.styleFrom(
        onPrimary: Colors.black87,
        primary: Color.fromRGBO(240, 240, 240, 1),
        minimumSize: Size(88, 36),
        alignment: Alignment.center,
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter-SemiBold',
          fontSize: 18,
        ),
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      );
}
