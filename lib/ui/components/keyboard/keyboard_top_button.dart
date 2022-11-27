import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class KeyboardTopButton extends StatelessWidget {
  final Function? onDoneTap;
  final Function? onCancelTap;
  final String doneText;
  final String cancelText;

  const KeyboardTopButton({
    super.key,
    this.doneText = "Done",
    this.cancelText = "Cancel",
    this.onDoneTap,
    this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final enteTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1.0, color: colorScheme.strokeFaint),
          bottom: BorderSide(width: 1.0, color: colorScheme.strokeFaint),
        ),
        color: colorScheme.backgroundElevated2,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              onPressed: () {
                onCancelTap?.call();
              },
              child: Text(cancelText, style: enteTheme.bodyBold),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              onPressed: () {
                onDoneTap?.call();
              },
              child: Text(doneText, style: enteTheme.bodyBold),
            ),
          ],
        ),
      ),
    );
  }
}
