import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

// Figma: https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?node-id=11219%3A62974&t=BRCLJhxXP11Q3Wyw-0
class ReferralCodeWidget extends StatelessWidget {
  final String codeValue;

  const ReferralCodeWidget(this.codeValue, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    return Center(
      child: DottedBorder(
        color: colorScheme.strokeMuted,
        strokeWidth: 1,
        dashPattern: const [6, 6],
        radius: const Radius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 26.0,
            top: 14,
            right: 12,
            bottom: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                codeValue,
                style: textStyle.bodyBold.copyWith(
                  color: colorScheme.primary700,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.adaptive.share,
                size: 22,
                color: colorScheme.strokeMuted,
              )
            ],
          ),
        ),
      ),
    );
  }
}
