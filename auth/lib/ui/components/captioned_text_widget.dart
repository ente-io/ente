import 'package:ente_auth/ente_theme_data.dart';
import 'package:flutter/material.dart';

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final enteTextTheme = Theme.of(context).colorScheme.enteTheme.textTheme;

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
                              color: enteColorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
