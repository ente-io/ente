// leading icon can be passed without specifing size, this component set size to 20x20
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class CaptionedTextWidget extends StatelessWidget {
  final String text;
  final String? subText;
  final TextStyle? textStyle;
  final bool makeTextBold;
  final Color? textColor;
  const CaptionedTextWidget({
    required this.text,
    this.subText,
    this.textStyle,
    this.makeTextBold = false,
    this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: textStyle ??
                      (makeTextBold
                          ? enteTheme.textTheme.bodyBold
                              .copyWith(color: textColor)
                          : enteTheme.textTheme.body
                              .copyWith(color: textColor)),
                  children: [
                    TextSpan(
                      text: text,
                    ),
                    subText != null
                        ? TextSpan(
                            text: ' \u2022 ',
                            style: enteTheme.textTheme.small.copyWith(
                              color: enteTheme.colorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                    subText != null
                        ? TextSpan(
                            text: subText,
                            style: enteTheme.textTheme.small.copyWith(
                              color: enteTheme.colorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
