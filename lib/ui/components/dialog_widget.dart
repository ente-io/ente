import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/separators_util.dart';

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showGenericErrorDialog({
  required BuildContext context,
}) async {
  return showDialogWidget(
    context: context,
    title: "Error",
    icon: Icons.error_outline_outlined,
    body: "It looks like something went wrong. Please try again.",
    buttons: const [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "OK",
        isInAlert: true,
      ),
    ],
  );
}

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showNewChoiceDialog({
  required BuildContext context,
  required String title,
  String? body,
  required String firstButtonLabel,
  String secondButtonLabel = "Cancel",
  ButtonType firstButtonType = ButtonType.neutral,
  ButtonType secondButtonType = ButtonType.secondary,
  ButtonAction firstButtonAction = ButtonAction.first,
  ButtonAction secondButtonAction = ButtonAction.cancel,
  FutureVoidCallback? firstButtonOnTap,
  FutureVoidCallback? secondButtonOnTap,
  bool isCritical = false,
  IconData? icon,
}) async {
  final buttons = [
    ButtonWidget(
      buttonType: isCritical ? ButtonType.critical : firstButtonType,
      labelText: firstButtonLabel,
      isInAlert: true,
      onTap: firstButtonOnTap,
      buttonAction: firstButtonAction,
    ),
    ButtonWidget(
      buttonType: secondButtonType,
      labelText: secondButtonLabel,
      isInAlert: true,
      onTap: secondButtonOnTap,
      buttonAction: secondButtonAction,
    ),
  ];
  return showDialogWidget(
    context: context,
    title: title,
    body: body,
    buttons: buttons,
    icon: icon,
  );
}

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showDialogWidget({
  required BuildContext context,
  required String title,
  String? body,
  required List<ButtonWidget> buttons,
  IconData? icon,
}) {
  return showDialog(
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
  final String? body;
  final List<ButtonWidget> buttons;
  final IconData? icon;
  final bool isMobileSmall;
  const DialogWidget({
    required this.title,
    this.body,
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
  final String? body;
  final IconData? icon;
  const ContentContainer({
    required this.title,
    this.body,
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
        body != null ? const SizedBox(height: 19) : const SizedBox.shrink(),
        body != null
            ? Text(
                body!,
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
              )
            : const SizedBox.shrink(),
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
          // In figma this white space is of height 8pts. But the Button
          // component has 1pts of invisible border by default in code. So two
          // 1pts borders will visually make the whitespace 8pts.
          // Height of button component in figma = 48, in code = 50 (2pts for
          // top + bottom border)
          height: 6,
        ),
      ),
    );
  }
}
