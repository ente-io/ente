import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class CaptionedTextWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final TextStyle? textStyle;
  final bool makeTextBold;
  final Color? textColor;
  final Color? subTitleColor;
  const CaptionedTextWidget({
    required this.title,
    this.subTitle,
    this.textStyle,
    this.makeTextBold = false,
    this.textColor,
    this.subTitleColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final enteTextTheme = Theme.of(context).colorScheme.enteTheme.textTheme;

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: Row(
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: textStyle ??
                      (makeTextBold
                          ? enteTextTheme.bodyBold.copyWith(color: textColor)
                          : enteTextTheme.body.copyWith(color: textColor)),
                  children: [
                    TextSpan(
                      text: title,
                    ),
                    subTitle != null
                        ? TextSpan(
                            text: ' \u2022 $subTitle',
                            style: enteTextTheme.small.copyWith(
                              color: subTitleColor ?? enteColorScheme.textMuted,
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
