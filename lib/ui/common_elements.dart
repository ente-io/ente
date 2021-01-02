import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final nothingToSeeHere = Center(
  child: Text(
    "nothing to see here! 👀",
    style: TextStyle(
      color: Colors.white30,
    ),
  ),
);

RaisedButton button(
  String text, {
  double fontSize = 14,
  VoidCallback onPressed,
}) {
  return RaisedButton(
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
      textAlign: TextAlign.center,
    ),
    onPressed: onPressed,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
  );
}
