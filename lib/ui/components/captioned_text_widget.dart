// leading icon can be passed without specifing size, this component sets size to 20x20
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class CaptionedTextWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final TextStyle? textStyle;
  final bool makeTextBold;
  final Color? textColor;
  const CaptionedTextWidget({
    required this.title,
    this.subTitle,
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
                      text: title,
                    ),
                    subTitle != null
                        ? TextSpan(
                            text: ' \u2022 ',
                            style: enteTheme.textTheme.small.copyWith(
                              color: enteTheme.colorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                    subTitle != null
                        ? TextSpan(
                            text: subTitle,
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
