import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final nothingToSeeHere = Center(child: Text("Nothing to see here! 👀"));

RaisedButton button(String text, {VoidCallback onPressed}) {
  return RaisedButton(
    child: Text(text),
    onPressed: onPressed,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6.0),
    ),
  );
}
