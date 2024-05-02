import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class GradientButton extends StatefulWidget {
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
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;
    if (widget.iconData == null) {
      buttonContent = Text(
        widget.text,
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
            widget.iconData,
            size: 20,
            color: Colors.white,
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
          Text(
            widget.text,
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
      onTapDown: (_) {
        setState(() {
          isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          isTapped = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isTapped = false;
        });
      },
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap as void Function()?,
      child: Stack(
        children: [
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF531DAB),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFF000000),
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF9254DE).withOpacity(0.32),
                  offset: const Offset(0, 0),
                  spreadRadius: 0,
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: isTapped
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0, 0.18, 1],
                      colors: [
                        Color(0xFFEFDBFF),
                        Color(0x00D2AEF5),
                        Color(0xFFB37FEB),
                      ],
                    ),
              backgroundBlendMode: isTapped ? null : BlendMode.overlay,
              border: const GradientBoxBorder(
                width: 1,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB37FEB),
                    Color(0xFF22075E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(child: buttonContent),
          ),
        ],
      ),
    );
  }
}
