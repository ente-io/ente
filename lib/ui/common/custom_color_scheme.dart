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
}
