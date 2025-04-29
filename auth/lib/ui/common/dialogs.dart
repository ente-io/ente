import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/models/typedefs.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:flutter/material.dart';

enum DialogUserChoice { firstChoice, secondChoice }

enum ActionType {
  confirm,
  critical,
}

// if dialog is dismissed by tapping outside, this will return null
Future<DialogUserChoice?> showChoiceDialogOld<T>(
  BuildContext context,
  String title,
  String content, {
  String firstAction = 'Ok',
  Color? firstActionColor,
  String secondAction = 'Cancel',
  Color? secondActionColor,
  ActionType actionType = ActionType.confirm,
}) {
  final AlertDialog alert = AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        color: actionType == ActionType.critical
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
      ),
    ),
    content: Text(
      content,
      style: const TextStyle(
        height: 1.4,
      ),
    ),
    actions: [
      TextButton(
        child: Text(
          firstAction,
          style: TextStyle(
            color: firstActionColor ??
                (actionType == ActionType.critical
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface),
          ),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true)
              .pop(DialogUserChoice.firstChoice);
        },
      ),
      TextButton(
        child: Text(
          secondAction,
          style: TextStyle(
            color: secondActionColor ??
                Theme.of(context).colorScheme.alternativeColor,
          ),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true)
              .pop(DialogUserChoice.secondChoice);
        },
      ),
    ],
  );

  return showDialog<DialogUserChoice>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
    barrierColor: Colors.black87,
  );
}

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showChoiceDialog(
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
