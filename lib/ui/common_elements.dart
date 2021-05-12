import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final nothingToSeeHere = Center(
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "nothing to see here! 👀",
      style: TextStyle(
        color: Colors.white30,
      ),
    ),
  ),
);

Widget button(
  String text, {
  double fontSize = 14,
  VoidCallback onPressed,
}) {
  return InkWell(
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
        side: BorderSide(
          width: onPressed == null ? 1 : 2,
          color: onPressed == null
              ? Colors.grey
              : Color.fromRGBO(45, 194, 98, 1.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: onPressed == null ? Colors.grey : Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      onPressed: onPressed,
    ),
  );
}

final emptyContainer = Container();
