import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class SelectionActionButton extends StatefulWidget {
  final String labelText;
  final IconData icon;
  final VoidCallback? onTap;

  const SelectionActionButton({
    required this.labelText,
    required this.icon,
    required this.onTap,
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
  Widget build(BuildContext context) {
    widthOfButton = getWidthOfButton();
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
                  //textTheme in [getWidthOfLongestWord] should be same as this
                  style: getEnteTextTheme(context).miniMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getWidthOfButton() {
    final widthOfWidestWord = getWidthOfWidestWord(
      widget.labelText,
    );
    if (widthOfWidestWord > minWidth) return widthOfWidestWord;
    return minWidth;
  }

  double computeWidthOfWord(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    )..layout();

    return textPainter.size.width;
  }

  double getWidthOfWidestWord(String labelText) {
    final words = labelText.split(RegExp(r'\s+'));
    if (words.isEmpty) return 0.0;

    double maxWidth = 0.0;
    for (String word in words) {
      final width =
          computeWidthOfWord(word, getEnteTextTheme(context).miniMuted);
      if (width > maxWidth) {
        maxWidth = width;
      }
    }
    return maxWidth;
  }
}
