import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget nothingToSeeHere({Color textColor}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Nothing to see here! 👀",
        style: TextStyle(
          color: textColor.withOpacity(0.35),
        ),
      ),
    ),
  );
}
