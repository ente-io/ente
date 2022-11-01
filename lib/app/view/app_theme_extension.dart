import "package:flutter/material.dart";

final lightTheme = ThemeData(
  fontFamily: "Inter",
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme().copyWith(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    iconTheme: const IconThemeData(color: Colors.black),
    elevation: 0,
  ),
  colorScheme: const ColorScheme.light(
    primary: Colors.black,
  ),
  textTheme: _buildTextTheme(Colors.black),
  outlinedButtonTheme: buildOutlinedButtonThemeData(
    bgDisabled: Colors.grey.shade500,
    bgEnabled: Colors.black,
    fgDisabled: Colors.white,
    fgEnabled: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: null,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(6),
    ),
  ),
);

final darkTheme = ThemeData(
  fontFamily: "Inter",
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(color: Colors.orange),
  colorScheme: const ColorScheme.dark(primary: Colors.white),
  textTheme: _buildTextTheme(Colors.white),
  outlinedButtonTheme: buildOutlinedButtonThemeData(
    bgDisabled: Colors.grey.shade500,
    bgEnabled: Colors.white,
    fgDisabled: Colors.white,
    fgEnabled: Colors.black,
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: null,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(6),
    ),
  ),
);

TextTheme _buildTextTheme(Color textColor) {
  return const TextTheme().copyWith(
    headline4: TextStyle(
      color: textColor,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontFamily: "Inter",
    ),
    headline5: TextStyle(
      color: textColor,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      fontFamily: "Inter",
    ),
    // AG: Body
    headline6: TextStyle(
      color: textColor,
      fontSize: 18,
      fontFamily: "Inter",
      fontWeight: FontWeight.w500,
    ),
    // Use labels for buttons or notifications
    labelMedium: TextStyle(
      color: textColor,
      fontFamily: "Inter",
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 28,
    ),

    subtitle1: TextStyle(
      color: textColor,
      fontFamily: "Inter",
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    subtitle2: TextStyle(
      color: textColor,
      fontFamily: "Inter",
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyText1: TextStyle(
      fontFamily: "Inter",
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyText2: TextStyle(
      fontFamily: "Inter",
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    caption: TextStyle(
      color: textColor.withOpacity(0.6),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonThemeData({
  required Color bgDisabled,
  required Color bgEnabled,
  required Color fgDisabled,
  required Color fgEnabled,
}) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontFamily: "Inter",
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
