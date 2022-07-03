import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final List<Color> linearGradientColors;
  final Function onTap;

  GradientButton({Key key, this.child, this.linearGradientColors, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.1, -0.9),
            end: Alignment(-0.6, 0.9),
            colors: linearGradientColors,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: child),
      ),
    );
  }
}
