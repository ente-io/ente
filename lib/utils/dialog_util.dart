import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';

typedef DialogBuilder = DialogWidget Function(BuildContext context);

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showErrorDialog(
  BuildContext context,
  String title,
  String? body, {
  bool isDismissable = true,
}) async {
  return showDialogWidget(
    context: context,
    title: title,
    body: body,
    isDismissible: isDismissable,
    buttons: const [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "OK",
        isInAlert: true,
        buttonAction: ButtonAction.first,
      ),
    ],
  );
}

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showGenericErrorDialog({
  required BuildContext context,
  bool isDismissible = true,
}) async {
  return showDialogWidget(
    context: context,
    title: "Error",
    icon: Icons.error_outline_outlined,
    body: "It looks like something went wrong. Please try again.",
    isDismissible: isDismissible,
    buttons: const [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "OK",
        isInAlert: true,
      ),
    ],
  );
}

DialogWidget choiceDialog({
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
}) {
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

  return DialogWidget(title: title, body: body, buttons: buttons, icon: icon);
}

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showNewChoiceDialog(
  BuildContext context, {
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
  bool isDismissible = true,
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
    isDismissible: isDismissible,
  );
}

ProgressDialog createProgressDialog(
  BuildContext context,
  String message, {
  isDismissible = false,
}) {
  final dialog = ProgressDialog(
    context,
    type: ProgressDialogType.normal,
    isDismissible: isDismissible,
    barrierColor: Colors.black12,
  );
  dialog.style(
    message: message,
    messageTextStyle: Theme.of(context).textTheme.caption,
    backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
    progressWidget: const EnteLoadingWidget(),
    borderRadius: 10,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

Future<ButtonAction?> showConfettiDialog<T>({
  required BuildContext context,
  required DialogBuilder dialogBuilder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Alignment confettiAlignment = Alignment.center,
}) {
  final widthOfScreen = MediaQuery.of(context).size.width;
  final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
  final pageBuilder = Builder(
    builder: dialogBuilder,
  );
  final ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  confettiController.play();
  return showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobileSmall ? 8 : 0),
        child: Stack(
          children: [
            Align(alignment: Alignment.center, child: pageBuilder),
            Align(
              alignment: confettiAlignment,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0,
                numberOfParticles: 100,
                // a lot of particles at once
                gravity: 1,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
          ],
        ),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}
