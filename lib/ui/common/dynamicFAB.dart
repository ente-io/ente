import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class DynamicFAB extends StatelessWidget {
  final bool isKeypadOpen;
  final bool isFormValid;
  final String buttonText;
  final Function onPressedFunction;

  const DynamicFAB(
      {this.isKeypadOpen,
      this.buttonText,
      this.isFormValid,
      this.onPressedFunction});

  @override
  Widget build(BuildContext context) {
    if (isKeypadOpen) {
      //var here
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).backgroundColor,
              spreadRadius: 200,
              blurRadius: 100,
              offset: Offset(0, 230),
            )
          ],
        ),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                //mini: true,
                backgroundColor:
                    Theme.of(context).colorScheme.dynamicFABBackgroundColor,
                foregroundColor:
                    Theme.of(context).colorScheme.dynamicFABTextColor,
                child: Transform.rotate(
                  angle: isFormValid ? 0 : math.pi / 2, //var here
                  child: Icon(
                    Icons.chevron_right,
                    size: 36,
                  ),
                ),
                onPressed: isFormValid
                    ? onPressedFunction
                    : () {
                        FocusScope.of(context).unfocus();
                      } //keypad down here
                ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: OutlinedButton(
          //style: Theme.of(context).elevatedButtonTheme.style,
          onPressed: isFormValid //var here
              ? onPressedFunction
              : null,
          child: Text(buttonText),
        ),
      );
    }
  }
}
