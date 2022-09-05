import 'package:flutter/material.dart';

class SmallGradientButton extends StatelessWidget {
  final List<Color> linearGradientColors;
  final Function onTap;
  final Widget child;
  // text is ignored if child is specified
  final String text;
  // nullable
  final IconData iconData;
  // padding between the text and icon
  final double spacingBetweenItems;

  const SmallGradientButton({
    Key key,
    this.child,
    this.linearGradientColors = const [
      Color(0xFF2CD267),
      Color(0xFF1DB954),
    ],
    this.onTap,
    this.text,
    this.iconData,
    this.spacingBetweenItems = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;
    if (child != null) {
      buttonContent = child;
    } else if (iconData == null) {
      buttonContent = Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 16,
          ),
        ),
      );
    } else {
      buttonContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: spacingBetweenItems),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 16,
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.1, -0.9),
            end: const Alignment(-0.6, 0.9),
            colors: linearGradientColors,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 118),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
