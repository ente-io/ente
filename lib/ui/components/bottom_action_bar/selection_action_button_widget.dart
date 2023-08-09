import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class SelectionActionButton extends StatefulWidget {
  final String labelText;
  final IconData icon;
  final VoidCallback? onTap;
  final TextStyle textStyle;

  const SelectionActionButton({
    required this.labelText,
    required this.icon,
    required this.onTap,
    required this.textStyle,
    super.key,
  });

  @override
  State<SelectionActionButton> createState() => _SelectionActionButtonState();
}

class _SelectionActionButtonState extends State<SelectionActionButton> {
  static const minWidth = 64.0;
  late double widthOfButton;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    widthOfButton = getWidthOfButton();
  }

  getWidthOfButton() {
    final widthOfWidestWord = getWidthOfLongestWord(
      widget.labelText,
      widget.textStyle,
    );
    if (widthOfWidestWord > minWidth) return widthOfWidestWord;
    return minWidth;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) {
        setState(() {
          backgroundColor = colorScheme.fillFaintPressed;
        });
      },
      onTapUp: (details) {
        setState(() {
          backgroundColor = null;
        });
      },
      onTapCancel: () {
        setState(() {
          backgroundColor = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: SizedBox(
            width: widthOfButton,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 24,
                  color: getEnteColorScheme(context).textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.labelText,
                  textAlign: TextAlign.center,
                  style: widget.textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double getWidthOfText(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.size.width;
  }

  double getWidthOfLongestWord(String labelText, TextStyle style) {
    final words = labelText.split(RegExp(r'\s+'));
    if (words.isEmpty) return 0.0;

    double maxWidth = 0.0;
    for (String word in words) {
      final width = getWidthOfText(word, style);
      if (width > maxWidth) {
        maxWidth = width;
      }
    }
    return maxWidth;
  }
}
