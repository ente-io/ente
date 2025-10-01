import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Function? onTap;

  // text is ignored if child is specified
  final String text;

  // nullable
  final IconData? iconData;

  // padding between the text and icon
  final double paddingValue;

  const GradientButton({
    super.key,
    this.onTap,
    this.text = '',
    this.iconData,
    this.paddingValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;
    if (iconData == null) {
      buttonContent = Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter-SemiBold',
          fontSize: 18,
        ),
      );
    } else {
      buttonContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 20,
            color: Colors.white,
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter-SemiBold',
              fontSize: 18,
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: onTap as void Function()?,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0.1, -0.9),
              end: const Alignment(-0.6, 0.9),
              colors: onTap != null
                  ? getEnteColorScheme(context).gradientButtonBgColors
                  : [
                      getEnteColorScheme(context).fillMuted,
                      getEnteColorScheme(context).fillMuted,
                    ],
            ), 
          ),
          child: Center(child: buttonContent),
        ),
      ),
    );
  }
}
