import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget nothingToSeeHere({Color textColor}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "nothing to see here! 👀",
        style: TextStyle(
          fontFamily: "Inter",
          color: textColor.withOpacity(0.35),
        ),
      ),
    ),
  );
}

Widget button(
  String text, {
  double fontSize = 14,
  VoidCallback onPressed,
  double lineHeight,
  EdgeInsets padding,
}) {
  return InkWell(
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: padding ?? EdgeInsets.fromLTRB(50, 16, 50, 16),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter-SemiBold',
          fontSize: fontSize,
          height: lineHeight,
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey;
            }
            // return Color.fromRGBO(29, 184, 80, 1);
            return Colors.white;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
        alignment: Alignment.center,
      ),
      child: Text(text),
      onPressed: onPressed,
    ),
  );
}

final emptyContainer = Container();

Animatable<Color> passwordStrengthColors = TweenSequence<Color>(
  [
    TweenSequenceItem(
      weight: 1.0,
      tween: ColorTween(
        begin: Colors.red,
        end: Colors.yellow,
      ),
    ),
    TweenSequenceItem(
      weight: 1.0,
      tween: ColorTween(
        begin: Colors.yellow,
        end: Colors.lightGreen,
      ),
    ),
    TweenSequenceItem(
      weight: 1.0,
      tween: ColorTween(
        begin: Colors.lightGreen,
        end: Color.fromRGBO(45, 194, 98, 1.0),
      ),
    ),
  ],
);
