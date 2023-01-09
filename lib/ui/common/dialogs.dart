import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

enum DialogUserChoice { firstChoice, secondChoice }

enum ActionType {
  confirm,
  critical,
}

// if dialog is dismissed by tapping outside, this will return null
Future<DialogUserChoice?> showChoiceDialog<T>(
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
                Theme.of(context).colorScheme.greenAlternative,
          ),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true)
              .pop(DialogUserChoice.secondChoice);
        },
      ),
    ],
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
    barrierColor: Colors.black87,
  );
}
