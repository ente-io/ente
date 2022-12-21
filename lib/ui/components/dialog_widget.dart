import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/utils/separators_util.dart';

Future<dynamic> showDialogWidget({
  required BuildContext context,
  required String title,
  required String body,
  required List<ButtonWidget> buttons,
  IconData? icon,
}) {
  return showDialog(
    barrierDismissible: false,
    barrierColor: backdropFaintDark,
    context: context,
    builder: (context) {
      final widthOfScreen = MediaQuery.of(context).size.width;
      final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobileSmall ? 8 : 0),
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          child: DialogWidget(
            title: title,
            body: body,
            buttons: buttons,
            isMobileSmall: isMobileSmall,
            icon: icon,
          ),
        ),
      );
    },
  );
}

class DialogWidget extends StatelessWidget {
  final String title;
  final String body;
  final List<ButtonWidget> buttons;
  final IconData? icon;
  final bool isMobileSmall;
  const DialogWidget({
    required this.title,
    required this.body,
    required this.buttons,
    required this.isMobileSmall,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.of(context).size.width;
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: min(widthOfScreen, 320),
      padding: isMobileSmall
          ? const EdgeInsets.all(0)
          : const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        boxShadow: shadowFloatLight,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentContainer(
              title: title,
              body: body,
              icon: icon,
            ),
            const SizedBox(height: 36),
            Actions(buttons),
          ],
        ),
      ),
    );
  }
}

class ContentContainer extends StatelessWidget {
  final String title;
  final String body;
  final IconData? icon;
  const ContentContainer({
    required this.title,
    required this.body,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        icon == null
            ? const SizedBox.shrink()
            : Row(
                children: [
                  Icon(
                    icon,
                    size: 48,
                  ),
                ],
              ),
        icon == null ? const SizedBox.shrink() : const SizedBox(height: 19),
        Text(title, style: textTheme.h3Bold),
        const SizedBox(height: 19),
        Text(
          body,
          style: textTheme.body.copyWith(color: colorScheme.textMuted),
        ),
      ],
    );
  }
}

class Actions extends StatelessWidget {
  final List<ButtonWidget> buttons;
  const Actions(this.buttons, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: addSeparators(
        buttons,
        const SizedBox(
          height: 8,
        ),
      ),
    );
  }
}
